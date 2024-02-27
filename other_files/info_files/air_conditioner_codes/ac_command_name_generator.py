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

with open("ac_command_names.txt", "w+") as file:
    file.write("Start\n\n")

    for mode in hvac_modes:
        if mode == "heat_cool":
            for f_mode in fan_modes:
                for s_mode in swing_modes:
                    for temp in temperature_range:
                        file.write(f"- {mode}_{f_mode}_{s_mode}_{temp}\n")
                    file.write("\n")
                file.write("\n")

        elif mode == "dry":
            for f_mode in fan_modes:
                if f_mode == "auto" or f_mode == "powerful":
                    for s_mode in swing_modes:
                        file.write(f"- {mode}_{f_mode}_{s_mode}\n")
                    file.write("\n\n")
        
        elif mode == "fan_only":
            for s_mode in swing_modes:
                for f_mode in fan_modes:
                    file.write(f"- {mode}_{f_mode}_{s_mode}\n")
                file.write("\n")
            file.write("\n")
                

        else:
            for f_mode in fan_modes:
                if f_mode == "powerful":
                    for s_mode in swing_modes:
                        file.write(f"- {mode}_{f_mode}_{s_mode}\n")
                    file.write("\n\n")
                else:
                    for s_mode in swing_modes:
                        for temp in temperature_range:
                            file.write(f"- {mode}_{f_mode}_{s_mode}_{temp}\n")
                        file.write("\n")
                    file.write("\n")
        file.write("\n")
    file.write("End\n")