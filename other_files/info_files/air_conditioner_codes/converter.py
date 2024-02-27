
input_strings = []
output_strings = []

with open("", 'r') as input, open("", 'w') as output:

    lines = input.readlines()

    for line in lines:
        for i in range(len(input_strings)):
            if input_strings[i] in line:
                line = line.replace(input_strings[i], output_strings[i])
        output.write(line)
    