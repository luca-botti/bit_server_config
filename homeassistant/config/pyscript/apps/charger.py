from datetime import datetime, timedelta
from time import time

import pytz
import service_caller as sc


def setup_chargers(**kwargs):

    battery_name = kwargs.get('battery')
    charging_name = kwargs.get('charging_state')
    charger_name = kwargs.get('charger')
    alarm_name = kwargs.get('alarm_time')
    start_str = kwargs.get('day_start_time')
    end_str = kwargs.get('day_end_time')

    #log.info(f'battery_level = {battery_name}, charging = {charging_name}, day_start = {start_str}, day_end = {end_str}, alarm = {alarm_name}') 
    #ex. battery_level = sensor.poco_f1_battery_level, charging = binary_sensor.poco_f1_is_charging, day_start = 08:00:00, day_end = 23:00:00, alarm = sensor.poco_f1_next_alarm

    @task_unique('charger_' + battery_name, kill_me=True)
    @state_trigger(battery_name, charging_name)
    @time_trigger(f'once({end_str})')
    def charger(trigger_type=None, var_name=None, value=None, old_value=None):
        #ex. kwargs {'trigger_type': 'state', 'var_name': 'binary_sensor.poco_f1_is_charging', 'value': 'on', 'old_value': 'off', 'context': <homeassistant.core.Context object at 0x7f66bbfac0>}

        log.info("triggered by " + trigger_type)

        battery = int(state.get(battery_name))
        start = datetime.strptime(start_str, '%H:%M:%S').time()
        end = datetime.strptime(end_str, '%H:%M:%S').time()

        if (trigger_type == "state"):

            log.info("triggered by variable " + var_name + " changed from " + old_value + " to " + value)

            day = start <= datetime.now().time() < end

            log.info ("is day: " + str(day) + " [actual_time: " + str(datetime.now().time()) + ", battery_level: " + str(battery) + "]")

            if day:
                if battery < 70:
                    sc.switch_on(charger_name)
                elif battery > 79:
                    sc.switch_off(charger_name)
        
        else:

            night_charge(start, end, alarm_name, charger_name, battery_name)
    
    return charger

def night_charge(start=None, end=None, alarm=None, charger=None, battery=None, debug=None): #debug is used for setting an arbitrary actual time leave None for use the actual time
    # switching start and end time so now start will be the start of the night charge and end its end
    temp = start
    start = end
    end = temp

    log.info("start: " + str(start) + " end: " + str(end) + " alarm: " + alarm + " charger: " + charger + " battery: " + battery)

    if (start == None or charger == None or battery == None or not(end != None or alarm != None)):
        log.info("not enough data to start the ngiht charge, exit")
        return
    
    if debug == None:

        italy = pytz.timezone('Europe/Rome')
        now = italy.localize(datetime.now())
    
    else: 
        now = debug

    start = now.replace(hour=start.hour, minute=start.minute, second=start.second)
    end = now.replace(hour=end.hour, minute=end.minute, second=end.second)

    if now < start: 
        start = start - timedelta(days=1)
        log.info('After Midnight')
    
    if end < start:
        end = end + timedelta(days=1)
        log.info('Before Midnight')
    
    if alarm != None and state.get(alarm) != 'unavailable':
        alarm = datetime.strptime(state.get(alarm), '%Y-%m-%dT%H:%M:%S%z')
        alarm = alarm.replace(tzinfo=pytz.utc).astimezone(pytz.timezone('Europe/Rome'))
        end = alarm

    if not(start <= now < end):
        log.info("Error not right time, now: " + str(now) + " start: " + str(start) + " end: " + str(end))
        return
    
    log.info("Starting night charge, now: " + str(now) + " start: " + str(start) + " end: " + str(end))

    start = start.replace(tzinfo=None)
    now = now.replace(tzinfo=None)
    end = end.replace(tzinfo=None)

    sc.switch_turn_on(charger)

    if int(state.get(battery)) <= 70:

        log.info(f'Battery below 70, level = {state.get(battery)}')

        dict_result = task.wait_until(state_trigger=f'int({battery}) > 70', time_trigger=f'once({end})', timeout=28800)
        trigger_t = dict_result.get('trigger_type')

        if trigger_t == 'state':
            log.info(f'Battery go over 70, level = {state.get(battery)}')
            sc.switch_turn_off(charger)
        elif trigger_t == 'time' or trigger_t == 'timeout' or trigger_t == 'none':
            log.info(f'Time exceeded, result = {trigger_t}')
            return
    
    if now < (end - timedelta(minutes=30)) and int(state.get(battery)) < 80:

        log.info(f'Now before end - 30 minutes = {end - timedelta(minutes=30)}')

        dict_result = task.wait_until(time_trigger=f'once({end} - 30m)', timeout=43200)
        trigger_t = dict_result.get('trigger_type')

        if trigger_t == 'time':
            log.info(f'Now after end - 30 minutes = {end - timedelta(minutes=30)}')
            sc.switch_turn_on(charger)
        elif trigger_t == 'timeout' or trigger_t == 'none':
            log.info(f'Time exceeded, result = {trigger_t}')
            return
    
    if int(state.get(battery)) < 80:

        log.info(f'Battery below 80, level = {state.get(battery)}')

        dict_result = task.wait_until(state_trigger=f'int({battery}) >= 80', time_trigger=f'once({end})', timeout=28800)
        trigger_t = dict_result.get('trigger_type')

        if trigger_t == 'state':
            log.info(f'Battery over 80, level = {state.get(battery)}')
            sc.switch_turn_off(charger)
        elif trigger_t == 'time' or trigger_t == 'timeout' or trigger_t == 'none':
            log.info(f'Time exceeded, result = {trigger_t}')
            return
    
    else:

        log.info(f'Battery over 80, level = {state.get(battery)}')

        sc.switch_turn_off(charger)

    return


if __name__ == 'charger': #pyscript app

    chargers = []
    #log.info('Name Test ' + __name__)

    for instance in pyscript.app_config:
        chargers.append(setup_chargers(**instance))