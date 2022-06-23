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

# Getting all the passed arguments and storing them in
# the above made variables. This part also exits with an
# error message if it fails
{
declare -A arguments_order
arguments_order=([-o]=1 [-d]=2 [-p]=3)
current_argument=0
# Variables to store the passed argument values
overwrite=false

d_parameter_used=false
relative_Directory=archive
absolute_Directory=none

output_directory=none
password_Array=()


while [ $# -gt 0 ]; do
    if [ ${arguments_order[$1]} ]; then
        if [ ${arguments_order[$1]} -ge $current_argument ]; then
            current_argument=${arguments_order[$1]}
            if [ $1 = "-o" ]; then
                overwrite=true
            elif [ $1 = "-d" ]; then
                shift
                if [ ! $# -eq 0 ]; then
                    echo "Expected folder path after -d"
                    exit
                fi  
                given_directory=$1
                if [[ "$given_directory" = /* ]]; then
                    if [ ! -d $given_directory ]; then
                        echo "Given directory '$given_directory' does not exist"
                        exit
                    fi
                    absolute_Directory="$given_directory"
                else
                    if [ ! -d "$PWD/$given_directory" ]; then
                        echo "Given directory '$given_directory' does not exist"
                        exit
                    fi
                    relative_Directory="$given_directory"
                fi
                d_parameter_used=true
            elif [ $1 = "-p" ]; then
                while [ $# -gt 0 ]; do
                    shift
                    for arg in $@; do 
                        for char in `grep -o . <<< $arg`; do
                            if [[ ! ( $char =~ [a-z] || $char =~ [A-Z] || $char =~ [0-9] || $char =~ [_] || $char =~ [/] || $char =~ '\' || $char =~ [-] ) ]]; then
                                echo "Given password is not allowed: $arg"
                                exit
                            fi
                        done
                    done
                    password_Array+=( $1 )
                done
            fi
        else
            echo "Unexpected argument passed: $1"
            exit 1
        fi
    else
        echo "Unexpected value passed: $1"
        exit 1
    fi
    shift
done


find $path -type f | sed -n 's/..*\.//p' | sort | uniq -c


# Making sure to unzip all the zip files in the directory before
# moving all the files in the folder to the output directory.
for F in $(find $PWD -name "*.zip"); do
    if 7z l -slt $F | grep -q ZipCrypto; then
			  file_Amount1=$(find $PWD -type f | wc -l)
        for password in "${password_Array[@]}"
        do
            unzip -qq -P $password $F
				    if [ $file_Amount1 -ne $(find $PWD -type f | wc -l)  ]; then
					      break
				    fi
		    done
			  if [ $file_Amount1 -ne $(find $PWD -type f | wc -l) ]; then
			      rm -r $F
			  fi
    else
			  unzip -qq $F 
			  rm -r $F
    fi       
done


# This piece of code only runs of no -d path is given.
# It will make sure that a number is added to the end of
# archive
if [ $d_parameter_used = false ]; then
    current_Directory="$PWD"
    number=0
    numberToAdd=""
    while true
    do
      isAvailable=false
      file="${relative_Directory}${numberToAdd}"
      if [ -d $file ]; then
          isAvailable=false
      else
          isAvailable=true
      fi
      if [ "$isAvailable" = true ]; then
          relative_Directory="${relative_Directory}${numberToAdd}"
          break
      else
          number=$((number+1))
          numberToAdd=$number
      fi
  done
  output_directory="${PWD}/${relative_Directory}"
  mkdir $output_directory
else
    if [ $absolute_Directory = none ]; then
        output_directory="${PWD}/${relative_Directory}"
    else
        output_directory="$absolute_Directory"
    fi
fi


for F in $(find $PWD -not \( -path "$PWD/${relative_Directory}" -prune \) -type \f ); do
		count=1
    if [ $F != "${PWD}/organize.sh" ] && [ $F != "${PWD}/log.txt" ]; then
        current_Directory="$PWD"
        mod_Date=$(date +%F -r $F)

        changed_Dir=false
        #verander naar plek waar het is
        results=$(find $output_directory -type d -name mod_Date)
        if [ ! -d "${output_directory}/${mod_Date}" ] ; then
            mkdir "${output_directory}/${mod_Date}"
            mv $F "${output_directory}/${mod_Date}"
        else
            if [ $overwrite = true ]; then
					      mv $F "${output_directory}/${mod_Date}"
				    else
					      old_File=$F
					      new_File=$F
					      while true; do
						        length_before=$(find "$output_directory" -type f | wc -l)
						        mv -n $new_File "${output_directory}/${mod_Date}"
						        if [ "$length_before" -lt $(find "$output_directory" -type f | wc -l) ]; then
							          changed_Dir=true
						    	      break
                    fi
                    if [ $changed_Dir = false ]; then
							
							          file_Name=$(basename $F)
							          file_Directory=$(dirname $F)

							          ext="${file_Name##*.}"
							          name="${file_Name%.*}"
							
							          if [ ! -f "${file_Directory}/${name}${count}.${ext}" ]; then
								            new_File="${file_Directory}/${name}${count}.${ext}"
								            mv -n $old_File $new_File
                            old_File=$new_File
							          fi
                    fi
						    count=$((count+1))
					      done
            fi
        fi
    fi
		if [ $(find $PWD -not \( -path "$PWD/archive" -prune \) -type \f | wc -l) -eq 1 ]; then
        break
    fi
done
} 3>&1 1>&2 2>&3 | loggerInit

if [ $something_wong = true ]; then
    echo "warning: Something went wrong while executing the script. Please check the log.txt for more information"
fi


