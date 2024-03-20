#!/bin/bash

ID_PREFIX_LENGTH=3
NAME_PREFIX_LENGTH=5
SIZE_PREFIX_LENGTH=6

# $1 (optional) a string '<i>,<name>' of the folder: default root
gen-folder-csv() {

    if [[ $# -eq 0 ]]; then
        [[ $VERBOSE -ge $DEBUG ]] && echo "gen-folder-csv - root" >&2
        if [[ ! -e "$ROOT_CSV.csv" ]]; then
            gdrive files list --field-separator "," --full-name > "$ROOT_CSV.csv"
            [[ $VERBOSE -ge $INFO ]] && echo "gen-folder-csv - created $ROOT_CSV.csv" >&2
        fi
        echo "$ROOT_CSV"
    elif [[ $# -eq 1 ]]; then
        [[ $VERBOSE -ge $DEBUG ]] && echo "gen-folder-csv - $1" >&2
        IFS=',' read -a arg <<< "$1"
        local id=${arg[0]}
        local name=${arg[1]}
        if [[ ! -e "$name.csv" ]]; then
            gdrive files list --field-separator "," --full-name --parent "$id" > "$name.csv"
            [[ $VERBOSE -ge $INFO ]] && echo "gen-folder-csv - created $name.csv" >&2
        fi
        echo "$name"
    else
        [[ $VERBOSE -ge $QUIET ]] && echo "gen-folder-csv - error wrong argument - $*" >&2
        return 1
    fi
    return 0
}

# $1 csv file name to search, $2 exact string to search
# return value 0 -> found, return value 1 -> not found
retrieve-id() {
    local regex="(?<![\w\d])"$2"(?![\w\d])"

    if [[ $# -eq 2 ]]; then
        [[ $VERBOSE -ge $DEBUG ]] && echo "retrieve-id - default $*" >&2
        local result=$(csvcut -c Id,Name "$1.csv" | csvgrep -c Name -r "$regex" | csvcut -c Id)
    # elif [[ $3 == "f" || $3 == "folder" ]]; then
    #     [[ $VERBOSE -ge $DEBUG ]] && echo "retrieve-id - folder $*" >&2
    #     local result=$(csvcut -c Id,Name,Type "$1.csv" | csvgrep -c Type -m folder | csvgrep -c Name -r $regex | csvcut -c Id)
    # elif [[ $3 == "d" || $3 == "document" ]]; then
    #     [[ $VERBOSE -ge $DEBUG ]] && echo "retrieve-id - document $*" >&2
    #     local result=$(csvcut -c Id,Name,Type "$1.csv" | csvgrep -c Type -m document | csvgrep -c Name -r $regex | csvcut -c Id)
    # elif [[ $3 == "r" || $3 == "regular" ]]; then
    #     [[ $VERBOSE -ge $DEBUG ]] && echo "retrieve-id - regular $*" >&2
    #     local result=$(csvcut -c Id,Name,Type "$1.csv" | csvgrep -c Type -m regular | csvgrep -c Name -r $regex | csvcut -c Id)
    # elif [[ $3 == "s" || $3 == "shortcut" ]]; then
    #     [[ $VERBOSE -ge $DEBUG ]] && echo "retrieve-id - shortcut $*" >&2
    #     local result=$(csvcut -c Id,Name,Type "$1.csv" | csvgrep -c Type -m shortcut | csvgrep -c Name -r $regex | csvcut -c Id)
    else
        [[ $VERBOSE -ge $QUIET ]] && echo "retrieve-id - error wrong argument - $*" >&2
        return 1
    fi

    local length=${#result}
    local result=${result:ID_PREFIX_LENGTH:length}
    
    echo "$result"

    if [[ -z $result ]]; then
        return 1
    else
        return 0
    fi
}

# $1 csv file name to search, $2 exact id to search
# return value 0 -> found, return value 1 -> not found
retrieve-name() {
    local regex="(?<![\w\d])"$2"(?![\w\d])"

    if [[ $# -eq 2 ]]; then
        [[ $VERBOSE -ge $DEBUG ]] && echo "retrieve-name - default $*" >&2
        local result=$(csvcut -c Id,Name "$1.csv" | csvgrep -c Id -r "$regex" | csvcut -c Name)
    # elif [[ $3 == "f" || $3 == "folder" ]]; then
    #     [[ $VERBOSE -ge $DEBUG ]] && echo "retrieve-id - folder $*" >&2
    #     local result=$(csvcut -c Id,Name,Type "$1.csv" | csvgrep -c Type -m folder | csvgrep -c Id -r $regex | csvcut -c Name)
    # elif [[ $3 == "d" || $3 == "document" ]]; then
    #     [[ $VERBOSE -ge $DEBUG ]] && echo "retrieve-id - document $*" >&2
    #     local result=$(csvcut -c Id,Name,Type "$1.csv" | csvgrep -c Type -m document | csvgrep -c Id -r $regex | csvcut -c Name)
    # elif [[ $3 == "r" || $3 == "regular" ]]; then
    #     [[ $VERBOSE -ge $DEBUG ]] && echo "retrieve-id - regular $*" >&2
    #     local result=$(csvcut -c Id,Name,Type "$1.csv" | csvgrep -c Type -m regular | csvgrep -c Id -r $regex | csvcut -c Name)
    # elif [[ $3 == "s" || $3 == "shortcut" ]]; then
    #     [[ $VERBOSE -ge $DEBUG ]] && echo "retrieve-id - shortcut $*" >&2
    #     local result=$(csvcut -c Id,Name,Type "$1.csv" | csvgrep -c Type -m shortcut | csvgrep -c Id -r $regex | csvcut -c Name)
    else
        [[ $VERBOSE -ge $QUIET ]] && echo "retrieve-name - error wrong argument - $*" >&2
        return 1
    fi

    local length=${#result}
    local result=${result:NAME_PREFIX_LENGTH:length}
    
    echo "$result"

    if [[ -z $result ]]; then
        return 1
    else
        return 0
    fi
}

# $1 must be the empty array, $2 the folder-csv name, $3 (optional) file type: folder, regular, document, shortcut: default all (no $3)
# return an array of '<id>,<name>' strings
get-list() {

    if [[ $# -eq 2 ]]; then
        [[ $VERBOSE -ge $DEBUG ]] && echo "get-list - $2" >&2
        local result_id=$(csvcut -c Id "$2.csv")
        local result_name=$(csvcut -c Name "$2.csv")
    elif [[ $3 == "f" || $3 == "folder" ]]; then
        [[ $VERBOSE -ge $DEBUG ]] && echo "get-folder-list - $2" >&2
        local result_id=$(csvcut -c Id,Type "$2.csv" | csvgrep -c Type -m folder | csvcut -c Id)
        local result_name=$(csvcut -c Name,Type "$2.csv" | csvgrep -c Type -m folder | csvcut -c Name)
    elif [[ $3 == "d" || $3 == "document" ]]; then
        [[ $VERBOSE -ge $DEBUG ]] && echo "get-document-list - $2" >&2
        local result_id=$(csvcut -c Id,Type "$2.csv" | csvgrep -c Type -m document | csvcut -c Id)
        local result_name=$(csvcut -c Name,Type "$2.csv" | csvgrep -c Type -m document | csvcut -c Name)
    elif [[ $3 == "r" || $3 == "regular" ]]; then
        [[ $VERBOSE -ge $DEBUG ]] && echo "get-regular-list - $2" >&2
        local result_id=$(csvcut -c Id,Type "$2.csv" | csvgrep -c Type -m regular | csvcut -c Id)
        local result_name=$(csvcut -c Name,Type "$2.csv" | csvgrep -c Type -m regular | csvcut -c Name)
    elif [[ $3 == "s" || $3 == "shortcut" ]]; then
        [[ $VERBOSE -ge $DEBUG ]] && echo "get-shortcut-list - $2" >&2
        local result_id=$(csvcut -c Id,Type "$2.csv" | csvgrep -c Type -m shortcut | csvcut -c Id)
        local result_name=$(csvcut -c Name,Type "$2.csv" | csvgrep -c Type -m shortcut | csvcut -c Name)
    else
        [[ $VERBOSE -ge $QUIET ]] && echo "get-list - error wrong argument - $*" >&2
        return 1
    fi

    local -n arr=$1
    arr=()

    #formatting results

    local length=${#result_id}
    result_id=${result_id:ID_PREFIX_LENGTH:length}
    result_id=$(tr '\n' ',' <<< "$result_id")
    result_id=${result_id::-1}
    IFS="," read -a res_arr_id <<< $result_id

    length=${#result_name}
    result_name=${result_name:NAME_PREFIX_LENGTH:length}
    result_name=$(tr '\n' ',' <<< "$result_name")
    result_name=${result_name::-1}
    IFS="," read -a res_arr_name <<< $result_name


    if [[ ${#res_arr_id[@]} -ne ${#res_arr_name[@]} ]]; then
        [[ $VERBOSE -ge $QUIET ]] && echo "get-list - Error Ids and Names do not correspond" >&2
        return 1
    fi

    local len=${#res_arr_id[@]}

    for ((i = 0 ; i < $len ; i++)); do
        arr+=("${res_arr_id[$i]},${res_arr_name[$i]}")
    done
    return 0
}

# $1 file or folder name, $2 folder to search from('<id>,<name>' strings): dafult root
dfs-get-id() {

    [[ $VERBOSE -ge $DEBUG ]] && echo "dfs-get-id - starting - $*" >&2
    
    if [[ $# -eq 1 ]]; then
        local folder=$(gen-folder-csv)
    elif [[ $# -eq 2 ]]; then
        local folder=$(gen-folder-csv "$2")
    else
        [[ $VERBOSE -ge $QUIET ]] && echo "dfs-get-id - error wrong argument - $*" >&2
        return 1
    fi

    local result=$(retrieve-id "$folder" "$1")
    
    if [[ -z $result ]]; then
        local folders_list
        get-list folders_list "$folder" "f"

        for i in "${folders_list[@]}"; do
            result=$(dfs-get-id "$1" "$i")
            if [[ ! -z $result ]]; then
                break
            fi
        done
    fi

    echo "$result"

    if [[ -z $result ]]; then
        return 1
    else
        return 0
    fi
}

# $1 file or folder name, $2 folder to search from('<id>,<name>' strings): dafult root
bfs-get-id() {

    [[ $VERBOSE -ge $DEBUG ]] && echo "bfs-get-id - starting - $*" >&2
    
    if [[ $# -eq 1 ]]; then
        local folder=$(gen-folder-csv)
    elif [[ $# -eq 2 ]]; then
        local folder=$(gen-folder-csv "$2")
    else
        [[ $VERBOSE -ge $QUIET ]] && echo "bfs-get-id - error wrong argument - $*" >&2
        return 1
    fi

    local result=$(retrieve-id "$folder" "$1")

    if [[ ! -z $result ]]; then
        echo "$result"
        return 0
    fi
    
    local queue
    queue-constructor queue

    local folders_list
    get-list folders_list "$folder" "f"

    for i in "${folders_list[@]}"; do
        append queue "$i"
    done
    
    local size=$(length queue)
    while [[ $size -gt 0 ]]; do
        pop queue > .tempfile && local val=$(<.tempfile) ; rm -f .tempfile
        folder=$(gen-folder-csv "$val")
        result=$(retrieve-id "$folder" "$1")

        if [[ ! -z $result ]]; then
            break
        fi

        get-list folders_list "$folder" "f"

        for i in "${folders_list[@]}"; do
            append queue "$i"
        done

        size=$(length queue)
    done

    echo "$result"

    if [[ -z $result ]]; then
        return 1
    else
        return 0
    fi
}

# $1 file id
get-file-size() {

    if [[ $# -ne 1 ]]; then
        [[ $VERBOSE -ge $QUIET ]] && echo "get-file-size - error wrong argument - $*" >&2
        return 1
    fi

    [[ $VERBOSE -ge $DEBUG ]] && echo "get-file-size - starting - $*" >&2

    local result=$(gdrive files info --size-in-bytes "$1" | grep "Size:")
    local size=${#result}
    echo "${result:$SIZE_PREFIX_LENGTH:$size}"
    return 0
}

# $1 array of file ids
get-size-file-list() {
    if [[ $# -ne 1 ]]; then
        [[ $VERBOSE -ge $QUIET ]] && echo "get-size-file-list - error wrong argument - $*" >&2
        return 1
    fi

    local -i size=0
    local -n list=$1

    for elem in "${list[@]}"; do
        local temp=$(get-file-size "$elem")
        size+=$(($temp + 0))
    done

    echo "$size"
    return 0
}

# $1 folder name
get-folder-size() {
    if [[ $# -ne 1 ]]; then
        [[ $VERBOSE -ge $QUIET ]] && echo "get-folder-size - error wrong argument - $*" >&2
        return 1
    fi

    local -a temp
    local -a files

    get-list temp "$1" "r"
    get-list files "$1" "d"

    for elem in "${files[@]}"; do
        temp+=("$elem")
    done
    files=()

    for elem in "${temp[@]}"; do
        IFS=',' read -a arg <<< "$elem"
        files+=("${arg[0]}")
    done

    echo "$(get-size-file-list files)"
}

# $1 folder ('<id>,<name>' string)
get-folder-size-recursive() {
    if [[ $# -ne 1 ]]; then
        [[ $VERBOSE -ge $QUIET ]] && echo "get-folder-size-recursive - error wrong argument - $*" >&2
        return 1
    fi

    local -i tot_size=0

    local folder_name=$(gen-folder-csv "$1")

    local folder_tot=$(get-folder-size "$folder_name")
    tot_size+=$(($folder_tot + 0))

    local queue
    queue-constructor queue

    local folders_list
    get-list folders_list "$folder_name" "f"

    for i in "${folders_list[@]}"; do
        append queue "$i"
    done

    local size=$(length queue)
    while [[ $size -gt 0 ]]; do
        pop queue > .tempfile && local val=$(<.tempfile) ; rm -f .tempfile

        folder_name=$(gen-folder-csv "$val")
        folder_tot=$(get-folder-size "$folder_name")
        tot_size+=$(($folder_tot + 0))

        get-list folders_list "$folder_name" "f"

        for i in "${folders_list[@]}"; do
            append queue "$i"
        done

        size=$(length queue)
    done

    echo "$tot_size"
    return 0
}

# $1 array with path 
search-directly-id () {
    if [[ $# -ne 1 ]]; then
        [[ $VERBOSE -ge $QUIET ]] && echo "search-directly-id - error wrong argument - $*" >&2
        return 1
    fi

    local -n arr=$1
    [[ $VERBOSE -ge $DEBUG ]] && echo "search-directly-id - ${arr[@]}" >&2

    local -i size=${#arr[@]}

    local folder=$(gen-folder-csv)
    local id=""

    for (( i = 1 ; i < (( $size - 1 )) ; i++ )); do
        id=$(retrieve-id "$folder" "${arr[$i]}")
        if [[ -z $id ]]; then
            [[ $VERBOSE -ge $QUIET ]] && echo "search-directly-id - path not correcct - ${arr[@]}" >&2
            return 1
        fi
        folder=$(gen-folder-csv "${id},${arr[$i]}")
        if [[ -z $folder ]]; then
            [[ $VERBOSE -ge $QUIET ]] && echo "search-directly-id - path not correcct - ${arr[@]}" >&2
            return 1
        fi
    done
    id=$(retrieve-id "$folder" "${arr[-1]}")
    echo "$id"
    if [[ -z $id ]]; then
        return 1
    else
        return 0
    fi
}