#!/bin/bash
input="/home/ahmed/Desktop/Senior2/Semester2/GP/codes/gen/full_controller_ports_description.csv"
i=0
while IFS="," read -r direction type width name_un
do
  name=$(sed 's/,/\t/g' <<< $name_un)
  #echo $line 
  if [ $i -eq 0 ] 
  then
      printf "module %s_tb();\n" $direction
      printf "\n/************ TB Wires Decleration ************/\n"
  else
    arr_w=$(expr $width)
    arr_w=$((arr_w-1))
    if [ $arr_w -gt 0 ]
    then
        if [ "$direction" = "In" ] || [  "$direction" = "in" ]
        then
            printf "reg\t\t[%d\t:\t0]\t\t%s_tb\t\t\t;\n" $arr_w $name
        elif [ "$direction" = "Out" ] || [ "$direction" = "out" ]
        then
            printf "wire\t[%d\t:\t0]\t\t%s_tb\t\t\t;\n" $arr_w $name
        fi
    else
        if [ "$direction" = "In" ] ||  [ "$direction" = "in" ]
        then
            printf "reg\t\t\t\t\t\t%s_tb\t\t\t;\n" $name 
        elif [ "$direction" = "Out" ] || [ "$direction" = "out" ]
        then
            printf "wire\t\t\t\t\t%s_tb\t\t\t;\n" $name
        fi

    fi
  fi
  i=$((i+1))
done < "$input"

printf "\n\n\n/************ Setting clk ************/\n"
printf "integer h_clk=5;\ninteger f_clk=2*h_clk;\nalways #half_clk clk_tb=!clk_tb;"

printf "\n\n\n/************ Functions ************/\n"
printf "\n\n\n/************ Variables ************/\n"
printf "\n\n\n/************ Initial Block ************/\n"
printf "initial begin\n\nend"

printf "\n\n\n/************ Module Instantiation ************/\n"

input="/home/ahmed/Desktop/Senior2/Semester2/GP/codes/gen/full_controller_ports_description.csv"
i=0
while IFS="," read -r direction type width name_un
do
  name=$(sed 's/,/\t/g' <<< $name_un)
  #echo $line 
  if [ $i -eq 0 ] 
  then
    printf "%s DUT(\n" $direction
  else
      printf "\t .%s(%s_tb),\n" $name $name
  fi
  i=$((i+1))
done < "$input"
printf ");\nendmodule"
