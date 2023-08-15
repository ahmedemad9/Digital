#!/bin/bash
input="/home/ahmed/Desktop/Senior2/Semester2/GP/codes/Integration/RTL/csv/directed_testcases.csv"
i=0

while IFS="," read -r comment R_Ready W_Valid W_Data W_STRB W_Address R_Valid_Address R_Address delay delay_count
 
do
  name=$(sed 's/,/\t/g' <<< $name_un)
  #echo $line 
  if [ $i -gt 0 ] 
  then
   printf "\n/* test case %d : %s */\n" $i $comment 
   printf "\$display(\"test %d @ %%0t : %s\",\$realtime);\n" $i $comment
   printf "R_Ready_tb         =%s;\n"  $R_Ready
   printf "W_Valid_tb        =%s;\n"  $W_Valid
   printf "W_Data_tb          =%s;\n"  $W_Data
   printf "W_STRB_tb          =%s;\n"  $W_STRB
   printf "W_Address_tb       =%s;\n"  $W_Address
   printf "R_Valid_Address_tb =%s;\n"  $R_Valid_Address
   printf "R_Address_tb       =%s;\n"  $R_Address
   printf "#xclk;              \n"
   printf "W_Valid_tb         =1'b0;\n"
   printf "R_Valid_Address_tb =1'b0;\n"
   printf "for(i=0;i<=%d;i=i+1) #%s;\n" $delay_count $delay
  fi
  i=$((i+1))
done < "$input"
printf "\n"
