@service
def hello_world(name=None):
    """hello_world example using pyscript."""
    if (name != None):
        print(f"hello world {name}")
    else:
        print(f"hello world <instert name here>")