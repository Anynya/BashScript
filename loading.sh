#!/bin/bash
i=0
bar=''
index=0
arr=( "|" "/" "-" "\\" )
while [ $i -le 200 ]
do
    sleep 0.01
    let index=index%4
    let i++
    let index++
    [ $(($i % 2)) == 0 ] && bar+='-' || bar=`echo $bar | sed 's/-$/=/'`
    printf "[%-100s][%d%%][\e[41;41;1m%c\e[0m]\r" "$bar" "$(($i/2))" "${arr[$index]}"
done
printf "\n"
