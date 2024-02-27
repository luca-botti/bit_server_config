import json

def substitute (codes, mode, fan, swing, temp):
    if mode == "dry":
        if fan == "powerful":
            return codes.get(f"{mode}_{fan}_{swing}")
        else:
            return codes.get(f"{mode}_auto_{swing}")
    elif mode == "fan_only":
        return codes.get(f"{mode}_{fan}_{swing}")
    elif mode == "heat" or mode == "cool":
        if fan == "powerful":
            return codes.get(f"{mode}_{fan}_{swing}")
    return codes[f"{mode}_{fan}_{swing}_{temp}"]

hvac_modes = ["heat_cool", "dry", "cool", "fan_only", "heat"]
temperature_range = list(range(18, 31, 1))
fan_modes = [
    "auto",
    "silent",
    "low",
    "lowMedium",
    "medium",
    "mediumHigh",
    "high",
    "powerful",
]
swing_modes = ["on", "off"]

comment = """
heat_cool suports all the combinations so all 8 of fan modes, all 2 of swing modes and all 13 of temperature range
dry supports only auto and powerful fan mode and all 2 swing modes, no temperature support
fan_only supports all 8 of fan modes, all 2 of swing modes, no temperature support
heat and cool support all 8 fan modes, all 2 swing modes and all 13 of te range, but in powerful modes temperatures are disabled
"""

output = {
    "_comment" : comment,
    "manufacturer" : "Daikin",
    "supportedModels" : ["FTXS35BVMB"],
    "commandsEncoding" : "Base64",
    "supportedController" : "Broadlink",
    "minTemperature" : 18.0,
    "maxTemperature" : 30.0,
    "precision" : 1.0,
    "operationModes" : hvac_modes,
    "fanModes" : fan_modes,
    "swingModes" : swing_modes
}


commands = dict()

with open("ac_codes.json", 'r') as json_file:
    data = json.load(json_file)

    
    commands["off"] = data["off"]


    for mode in hvac_modes:

        fan_dict = dict()

        for f_mode in fan_modes:

            swing_dict = dict()

            for s_mode in swing_modes:

                temps_dict = dict()

                for temp in temperature_range:

                    temps_dict[str(temp)] = data.get(f"{mode}_{f_mode}_{s_mode}_{temp}", substitute(data, mode, f_mode, s_mode, temp))
                
                swing_dict[s_mode] = temps_dict
            
            fan_dict[f_mode] = swing_dict
        
        commands[mode] = fan_dict

output["commands"] = commands



with open("1120.json", "w+") as outfile:
    json.dump(output, outfile, indent=4)
    