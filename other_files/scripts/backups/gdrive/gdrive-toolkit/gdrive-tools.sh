#!/bin/bash


. /bit_server/other_files/scripts/backups/gdrive/gdrive-toolkit/lib/tools.sh
. /bit_server/other_files/scripts/backups/gdrive/gdrive-toolkit/lib/queue.sh

VERBOSE=0

# LEVEL for verbose
QUIET=0         # if verbose is >= 0 error will be displayed <- default
WARN=1          # if verbose is >= 1 some big changes to file or folders will be desplayed + QUIET level
INFO=2          # if verbose is >= 2 the creation of file will be desplayed + WARN level
DEBUG=3         # if verbose is >= 3 all logs will be deplayed

# persistent mode, the script will create a temporary folder where it store all the created csv files that describes the content of your drive, if this option is enabled the folder will not be romoved at the end, this could resoult in faster search but if you modify the content of the drive could leave in an inconsistant state
# 0 -> disabled, folder will be deleted at the end of the script <- default
# 1 -> enabled, folder will not be deleted at the end of the script
PERSISTENT=0


#### GETID ####

# get-id search algorithm:
# 0 -> DFS Deep First Search
# 1 -> BFS Branch First Search <- default
MODE=1

# variable for specifing path, always use absolutes paths starting with root/
GIVEN_PATH=""

#### GETLIST ####

# for get list what tipe of result you want
# b -> both <id>,<name> in a single string <- dafault (--id and --name, or nothing)
# i -> just id (--id)
# n -> just names (--name)
RESULTS=()

#select type of file in commands, if more than two are used it will be automatically set to all
# - all types <- default
# f folder
# d document (google documents)
# r regular
# s shortcut
SELECTOR=()

# variable used for specifiing some arguments to be passed directly to gdrive while constructiong the csv file
OPTIONS=""


########################################

FUNCTION=()
ARG=""

TEMP_FOLDER_NAME=".temp"
ROOT_CSV="root"

mk-cd-folder() {
    if [[ -e $1 ]] && [[ -d $1 ]]; then
        [[ $VERBOSE -ge $DEBUG ]] && echo "$1 folder already created" >&2
    else
        mkdir $1
        [[ $VERBOSE -ge $INFO ]] && echo "$1 folder just created">&2
    fi
    cd $1
    return 0
}

cd-rm-folder () {
    cd ..

    if [[ $PERSISTENT -eq 0 ]]; then
        rm -r -f $1
        [[ $VERBOSE -ge $WARN ]] && echo "removed $1 folder">&2
    fi
}

Help() {
   echo "TODO help"
}

GetId() {

    mk-cd-folder $TEMP_FOLDER_NAME

    if [[ ! -z $GIVEN_PATH ]]; then
        IFS='/' read -a path <<< "$GIVEN_PATH"
        if [[ "$ROOT_CSV" != "${path[0]}" ]]; then
            [[ $VERBOSE -ge $QUIET ]] && echo "GIVEN_PATH not starting with required incipit root/">&2
            cd-rm-folder $TEMP_FOLDER_NAME
            return 1
        fi
        if [[ "$1" != "${path[-1]}" ]]; then
            [[ $VERBOSE -ge $QUIET ]] && echo "the required file and the path do not corrispond">&2
            cd-rm-folder $TEMP_FOLDER_NAME
            return 1
        fi
        echo "$(search-directly-id path)"
    else
        if [[ $MODE -eq 1 ]]; then
            echo "$(bfs-get-id "$1")"
        elif [[ $MODE -eq 0 ]]; then
            echo "$(dfs-get-id "$1")"
        else
            [[ $VERBOSE -ge $QUIET ]] && echo "\$MODE error can be only 0 (DFS) or 1 (BFS), -> $MODE">&2
            cd-rm-folder $TEMP_FOLDER_NAME
            return 1
        fi
    fi
    cd-rm-folder $TEMP_FOLDER_NAME
    return 0
}

Invalidate() {
    mk-cd-folder $TEMP_FOLDER_NAME
    cd-rm-folder $TEMP_FOLDER_NAME
    return 0
}

GetList(){

    local folder_id=$(GetId "$1")

    if [[ -z $folder_id ]]; then
        echo "Folder not found"
        return 1
    fi
    
    mk-cd-folder $TEMP_FOLDER_NAME

    local string="$folder_id,$1"

    if [[ ! -z $OPTIONS ]]; then
        local csv_name="$(tr -d "[:punct:]\n " <<< $(echo $OPTIONS)-$1)"
        modified-gen-folder-csv "$string" "$OPTIONS" "$csv_name" > /dev/null
    else
        local csv_name=$1
        gen-folder-csv "$string" > /dev/null
    fi

    

    local -a results

    if [[ ${#SELECTOR[@]} -eq 0 ]]; then
        get-list results "$csv_name"
    elif [[ ${#SELECTOR[@]} -eq 1 ]]; then
        get-list results "$csv_name" "${SELECTOR[0]}"
    fi

    cd-rm-folder $TEMP_FOLDER_NAME

    if [[ ${#RESULTS[@]} -gt 0 ]]; then

        if [[ "${RESULTS[0]}" == "i" ]]; then
            local pos=0
        elif [[ ${RESULTS[0]} == "n" ]]; then
            local pos=1
        fi

        filtered_results=()

        for elem in "${results[@]}"; do
            IFS=',' read -a arg <<< "$elem"
            filtered_results+=("${arg[$pos]}")
        done

        results=()
        for elem in "${filtered_results[@]}"; do
            results+=("$elem")
        done
    fi
    
    if [[ -z ${results[@]} ]]; then
        echo ""
        return 1
    else
        echo "${results[@]}"
        return 0
    fi
}

# $1 file or folder name, use -f option for getting the complessive size of all file in a folder
GetSize () {

    local selected_id=$(GetId "$1")

    if [[ -z $selected_id ]]; then
        echo "Not found"
        return 1
    fi


    if [[ ${#SELECTOR[@]} -eq 1 && "${SELECTOR[0]}" == "f" ]]; then # request for the size of a folder
        mk-cd-folder $TEMP_FOLDER_NAME
        local temp=$1
        echo "$(get-folder-size-recursive "${selected_id},${temp}")"
        cd-rm-folder $TEMP_FOLDER_NAME
    else
        echo "$(get-file-size "$selected_id")"
    fi
}

OPSTRING=":hg:cvmil:pfdrs"
OPLONGSTRING="help,get-id:,cached,verbose::,mode,invalidate,persistent,get-list:,id,name,get-size:,path:,options:"
TEMP=$(getopt -o $OPSTRING --long $OPLONGSTRING -n 'gdrive-tools.bash' -- "$@")

if [ $? -ne 0 ]; then
        echo 'Error parsing argouments'
        Help
        exit 1
fi

# Note the quotes around "$TEMP": they are essential!
eval set -- "$TEMP"
unset TEMP

while true; do
    case "$1" in
        '-h'|'--help')
            Help
            exit 0
            ;;
        '-g'|'--get-id') # required argoument
            ARG=${ARG:-$2} 
            FUNCTION+=('GetId')
            shift 2
            continue
            ;;
        '-l'|'--get-list') # required argoument
            ARG=${ARG:-$2} 
            FUNCTION+=('GetList')
            shift 2
            continue
            ;;
        '--get-size') # required argoument
            ARG=${ARG:-$2} 
            FUNCTION+=('GetSize')
            shift 2
            continue
            ;;
        '--path') # required argoument
            GIVEN_PATH="$2"
            shift 2
            continue
            ;;
        '--id')
            RESULTS+=("i")
            shift
            continue
            ;;
        '--name')
            RESULTS+=("n")
            shift
            continue
            ;;
        '--options')
            OPTIONS="$2"
            shift 2
            continue
            ;;
        '-i'|'--invalidate') 
            FUNCTION+=('Invalidate')
            shift
            continue
            ;;
        '-v')
            VERBOSE=$(($VERBOSE+1))
            shift
            continue
            ;;
        '-f')
            SELECTOR+=("f")
            shift
            continue
            ;;
        '-d')
            SELECTOR+=("d")
            shift
            continue
            ;;
        '-r')
            SELECTOR+=("r")
            shift
            continue
            ;;
        '-s')
            SELECTOR+=("s")
            shift
            continue
            ;;
        '--verbose') # optional argouments
            case "$2" in
                '')
                    VERBOSE=$(($VERBOSE+1))
                    ;;
                *)
                    VERBOSE="$2"
                    ;;
            esac
            shift 2
            continue
            ;;
        '-p'|'--persistent')
            PERSISTENT=1
            shift
            continue
            ;;
        '-m'|'--mode')
            MODE=0
            shift
            continue
            ;;
        '--')
            shift
            break
            ;;
        *)
            echo 'Internal error!' >&2
            exit 1
            ;;
    esac
done

if [[ $VERBOSE -ge $DEBUG ]]; then
    echo 'Remaining arguments:'
    for arg; do
            echo "--> '$arg'"
    done
fi


if [[ ${#FUNCTION[@]} -gt 1 ]]; then
    [[ $VERBOSE -ge $QUIET ]] && echo "you can use only one of this argouments in one call: -g or --get-id, -i or --invalidate, --get-list, --get-size"
    exit
fi

if [[ $PERSISTEN -eq 0 ]]; then
    [[ $VERBOSE -ge $DEBUG ]] && echo "Not Persistent Mode"
else
    [[ $VERBOSE -ge $DEBUG ]] && echo "Persistent Mode"
fi

if [[ $MODE -eq 0 ]]; then
    [[ $VERBOSE -ge $DEBUG ]] && echo "Deep First Search algorithm"
else
    [[ $VERBOSE -ge $DEBUG ]] && echo "Branch First Search algorithm"
fi

if [[ ${#SELECTOR[@]} -gt 1 ]]; then
    [[ $VERBOSE -ge $DEBUG ]] && echo "More selector chosen, reset to default all"
    SELECTOR=()
fi

if [[ ${#RESULTS[@]} -gt 1 ]]; then
    [[ $VERBOSE -ge $DEBUG ]] && echo "Both result mode choosen, putting both"
    RESULTS=()
fi

if [[ ${#FUNCTION[@]} -gt 0 ]]; then
    ${FUNCTION[0]} "$ARG"
fi

exit 0






