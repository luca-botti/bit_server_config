# useless, it just nuke everything inside the variable
# $1 empty array - O(1)
queue-constructor() {
    if [[ $# -ne 1 ]]; then
        [[ $VERBOSE -ge $QUIET ]] && echo "constructor queue - error arguments - $*" >&2
    fi
    local -n arr=$1
    arr=()
    return 0
}

# $1 queue, $2 element to append - O(1)
append() {
    if [[ $# -ne 2 ]]; then
        [[ $VERBOSE -ge $QUIET ]] && echo "append queue - error arguments - $*" >&2
    fi
    local -n arr=$1
    arr+=("$2")
    return 0
}

# $1 queue - O(n),  O(1) implementation does not work, also you can't get the return value using $(...) or the queue will not be modified
pop() {
    if [[ $# -ne 1 ]]; then
        [[ $VERBOSE -ge $QUIET ]] && echo "pop queue - error arguments - $*" >&2
    fi
    local -n arr=$1
    local temp=${arr[0]}
    local -a temp_arr

    for elem in "${arr[@]}"; do
        if [[ $elem != $temp ]]; then
            temp_arr+=("$elem")
        fi
    done

    arr=()

    for elem in "${temp_arr[@]}"; do
        arr+=("$elem")
    done

    echo "$temp"
    return 0
}

# $1 queue - O(1)
length() {
    if [[ $# -ne 1 ]]; then
        [[ $VERBOSE -ge $QUIET ]] && echo "length queue - error arguments - $*" >&2
    fi
    local -n arr=$1
    echo "${#arr[@]}"
    return 0
}

test () {
    local -a queue
    queue-constructor queue
    append queue "ciao" && append queue "come" && append queue "va" && append queue "?"
    echo $(length queue)
    pop queue > .tempvalue
    value=$(<.tempvalue)
    echo "$value"
    echo $(length queue)
}

# test

