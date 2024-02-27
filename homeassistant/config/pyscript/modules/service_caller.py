def switch_turn_off(id):
    log.info(f'Turning off switch id = {id}')
    switch.turn_off(entity_id=id)

def switch_turn_on(id):
    log.info(f'Turning on switch id = {id}')
    switch.turn_on(entity_id=id)

def switch_off(id):
    if state.get(id) == 'on':
        switch_turn_off(id)

def switch_on(id):
    if state.get(id) == 'off':
        switch_turn_on(id)

def send_telegram_notification(message):
    notify.telegram_default(message=message,blocking=True)

if __name__ == "__main__":
    pass