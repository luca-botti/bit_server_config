from datetime import datetime, timedelta
from time import time
from yaml import scan

import pytz

import service_caller as sc


def setup_chargers(**kwargs):
    
    battery = kwargs.get('battery')
    c_state = kwargs.get('charging_state')
    charger = kwargs.get('charger')
    alarm = kwargs.get('alarm_time')
    start = kwargs.get('day_start_time')
    end = kwargs.get('day_end_time')


    @state_trigger(battery, kwargs=kwargs) #battery_changed
    @state_trigger(c_state, kwargs=kwargs) #charge_changed
    @time_trigger(f'once({end})', kwargs=kwargs) #start_night_charge
    @task_unique('charger_' + battery, kill_me=True)
    def charger(**kwargs): #log.info(kwargs)

        battery_level = int(state.get(battery))
        charging = state.get(c_state) == 'on'
        charger = kwargs.get('charger')
        d_start = datetime.strptime(start, '%H:%M:%S').time()
        d_end = datetime.strptime(end, '%H:%M:%S').time()
        alarm_state = state.get(alarm) #log.info(state.get(alarm)) ex. 2022-07-25T04:30:00+00:00, unavailable
        alarm_time = None
        if alarm_state != 'unavailable':
            alarm_time = datetime.strptime(alarm_state, '%Y-%m-%dT%H:%M:%S%z')
            alarm_time = alarm_time.replace(tzinfo=pytz.utc).astimezone(pytz.timezone('Europe/Rome'))
        
        #log.info(f'battery_level = {battery_level}, charging = {charging}, day_start = {d_start}, day_end = {d_end}, alarm = {alarm_time}') ex. battery_level = 83, charging = False, day_start = 08:00:00, day_end = 23:00:00, alarm = 2022-07-25 04:30:00+00:00

        day = d_start <= datetime.now().time() < d_end

        if day:
            if battery_level < 70:
                sc.switch_on(charger)
            elif battery_level > 79:
                sc.switch_off(charger)

        if kwargs.get('trigger_type') == 'state' and kwargs.get('var_name') == c_state and not day and charging:

            night_charge(d_end, d_start, alarm_time, charger, battery)

        elif kwargs.get('trigger_type') == 'time': 

            sc.switch_turn_on(charger)

    return charger



def night_charge(start_time=None, end_time=None, alarm=None, charger_id=None, battery_id=None):
    
    log.info('Night charge')

    italy = pytz.timezone('Europe/Rome')

    now = italy.localize(datetime.now())

    start_time = now.replace(hour=start_time.hour, minute=start_time.minute, second=start_time.second)
    end_time = now.replace(hour=end_time.hour, minute=end_time.minute, second=end_time.second)

    if now.time() < end_time.time():
        start_time = start_time - timedelta(days=1)
        log.info('After Midnight')

    if end_time < start_time:
        end_time = end_time + timedelta(days=1)

    if alarm != None:
        log.info(f'Alarm = {alarm}')
        end_time = alarm

    log.info(f'StartTime = {start_time}, Now = {now}, EndTime = {end_time}')

    if not(start_time <= now < end_time):
        log.info('Not right time')
        return
    
    if int(state.get(battery_id)) <= 70:

        log.info(f'Battery below 70, level = {state.get(battery_id)}')

        sc.switch_turn_on(charger_id)

        dict_result = task.wait_until(state_trigger=f'int({battery_id}) > 70', time_trigger=f'once({end_time})', timeout=28800)
        trigger_t = dict_result.get('trigger_type')

        if trigger_t == 'state':
            log.info(f'Battery go over 70, level = {state.get(battery_id)}')
            sc.switch_turn_off(charger_id)
        elif trigger_t == 'time' or trigger_t == 'timeout' or trigger_t == 'none':
            log.info(f'Time exceeded, result = {trigger_t}')
            return
    
    if now < (end_time - timedelta(minutes=30)) and int(state.get(battery_id)) < 80:

        log.info(f'Now before end - 30 minutes = {end_time - timedelta(minutes=30)}')

        dict_result = task.wait_until(time_trigger=f'once({end_time} - 30m)', timeout=43200)
        trigger_t = dict_result.get('trigger_type')

        if trigger_t == 'time':
            log.info(f'Now after end - 30 minutes = {end_time - timedelta(minutes=30)}')
            sc.switch_turn_on(charger_id)
        elif trigger_t == 'timeout' or trigger_t == 'none':
            log.info(f'Time exceeded, result = {trigger_t}')
            return
    
    if int(state.get(battery_id)) < 80:

        log.info(f'Battery below 80, level = {state.get(battery_id)}')

        dict_result = task.wait_until(state_trigger=f'int({battery_id}) >= 80', time_trigger=f'once({end_time})', timeout=28800)
        trigger_t = dict_result.get('trigger_type')

        if trigger_t == 'state':
            log.info(f'Battery over 80, level = {state.get(battery_id)}')
            sc.switch_turn_off(charger_id)
        elif trigger_t == 'time' or trigger_t == 'timeout' or trigger_t == 'none':
            log.info(f'Time exceeded, result = {trigger_t}')
            return
    
    else:

        log.info(f'Battery over 80, level = {state.get(battery_id)}')

        sc.switch_turn_off(charger_id)



if __name__ == 'charger': #pyscript app

    chargers = []
    #print('Name Test ' + __name__)

    for instance in pyscript.app_config:
        chargers.append(setup_chargers(**instance))


