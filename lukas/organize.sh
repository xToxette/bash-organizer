# Making a array that holds the order of the arguments
# which will be used to check if they are passed in the
# correct order
something_wong=false
log_path="${PWD}/log.txt"
touch $log_path

## logs the errors, checks if file is greater 10 lines -> removes the first one
errorLogger () {
    if [ $something_wong = false ]; then
        something_wong=true
    fi
    if [ $(wc -l < $log_path) -lt 10 ]; then
        echo "$1" >> $log_path
    else
        sed -i 1d $log_path
        echo "$1" >> $log_path
    fi
}

loggerInit () {
  while IFS= read -r line; do errorLogger "$line"; done
}


overwrite=false

declare -a seen
seen=()

d_parameter_used=false
output_directory=archive


password_Array=()

while [ $# -gt 0 ]; do
    if [[ $seen =~ (^|[[:space:]])$1($|[[:space:]]) ]]; then
        echo "Argument '$1' was already passed";
        exit 1
    else
        if [ $1 = "-o" ]; then
            seen+=($1)
            if [[ $seen =~ (^|[[:space:]])-d($|[[:space:]]) ]] || [[ $seen =~ (^|[[:space:]])-p($|[[:space:]]) ]]; then
                echo "Unexpected argument '$1' passed"
                exit 1
            fi
            overwrite=true
        elif [ $1 = "-d" ]; then
            if [[ $seen =~ (^|[[:space:]])-p($|[[:space:]]) ]]; then 
                echo "Unexpected argument '$1' passed"
                exit 1
            fi 
            seen+=($1)
            shift
            if [ $# -eq 0 ]; then
                echo "No directory passed with -d"
                exit 1
            fi
            d_parameter_used=true
            if [[ "$1" != /* ]]; then
                if [ -d "$PWD/$1" ]; then
                    output_directory="$PWD/$1"
                else
                    echo "Directory '$1' was not found"
                    exit 1
                fi
            else
                if [ -d "$1" ]; then
                    output_directory="$1"
                else
                    echo "Directory '$1' was not found"
                    exit 1
                fi
            fi
        elif [ $1 = "-p" ]; then
            seen+=($1)
            shift
            while [ $# -gt 0 ]; do
                password_Array+=( $1 )
                for arg in $@; do
                        for char in `grep -o . <<< $arg`; do
                            if [[ ! ( $char =~ [0-9] || $char =~ [/] || $char =~ [a-z] || $char =~ [-] || $char =~ [A-Z] || $char =~ '\' || $char =~ [_] ) ]]; then
                                echo "Given password is not allowed: $arg"
                                exit
                            fi
                        done
                    done
                shift
            done
        else
            echo "Unexpected value: $1"
            exit 1
        fi
    fi
    shift
done

if [[ $output_directory = */ ]]; then
    output_directory=${output_directory::-1}
fi



{
    if [ $d_parameter_used = false ]; then
        isAvailable=false
        number=0  
        numberToAdd=""
        while true
        do
          output_directory="archive${numberToAdd}" 
          isAvailable=false
          if [ ! -d $output_directory ]; then isAvailable=true; fi
    
          if [ "$isAvailable" = false ]; then
              number=$((number+1))
              numberToAdd=$number 
          else 
              break
          fi  
        done    
        mkdir "${PWD}/${output_directory}"
    fi
    

    for F in $(find $PWD -name "*.zip"); do
        file_Amount1=$(find $PWD -type f | wc -l)
        if [ ! 7z l -slt $F | grep -q ZipCrypto ]; then
            unzip -qq $F
            rm -r $F
        else 
            for password in "${password_Array[@]}"
            do
                unzip -qq -P $password $F
                if [  $(find $PWD -type f | wc -l) -ne $file_Amount1  ]; then
                    rm -r $F
                    break
                fi
            done
        fi
    done

    for F in $(find "$PWD" -type f); do
        count=1
        old_File=$F
        new_File=$F
        ext="${file_Name##*.}"
        name="${file_Name%.*}"
        mod_Date=$(date +%F -r $F)
    
        if [ $F = "${PWD}/organize.sh" ] || [ $F = "${PWD}/log.txt" ]; then
            continue
        elif [[ $F = ${output_directory}/${mod_Date}* ]]; then
            continue
        else
            current_Directory="$PWD"

            changed_Dir=false
            results=$(find $output_directory -type d -name mod_Date)
            if [  -d "${output_directory}/${mod_Date}" ] ; then
                if [ $overwrite = true ]; then
                    mv $F "${output_directory}/${mod_Date}"
                else
                    while true; do
                        file_Name=$(basename $F)
                        file_Directory=$(dirname $F)

                        length_before=$(find "$output_directory" -type f | wc -l)
                        mv -n $new_File "${output_directory}/${mod_Date}"

                        LengthAfter=$(find "$output_directory" -type f | wc -l)

                        if [ "$length_before" -lt "$LengthAfter" ]; then
                            changed_Dir=true
                            break
                        fi

                        ext="${file_Name##*.}"
                        name="${file_Name%.*}"
                        if [ ! -f "${file_Directory}/${name}${count}.${ext}" ]; then
                            new_File="${file_Directory}/${name}${count}.${ext}"
                            mv -n $old_File $new_File
                            old_File=$new_File
                        fi
                        count=$((count+1))
                    done
                fi
            else
                mkdir "${output_directory}/${mod_Date}"
                mv $F "${output_directory}/${mod_Date}"
            fi
        fi
    done

} 3>&1 1>&2 2>&3 | loggerInit


find $output_directory -type f | sed -n 's/..*\.//p' | sort | uniq -c


if [ $something_wong = true ]; then
    echo "warning: Something went wrong while executing the script. Please check the log.txt for more information"
fi


