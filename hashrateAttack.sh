#!/bin/bash
## hashAttack

# COIN
COIN_CLI="$HOME/git/SUGAR/WALLET/sugarchain-v0.16.3/src/sugarchain-cli"
COIN_OPTION="-rpcuser=username -rpcpassword=password -main" # MAIN: -main | TESTNET: -testnet | REGTEST: -regtest
GET_INFO="$COIN_CLI $COIN_OPTION"

# DEBUG 
COIN_DEBUG_LOCATION="$HOME/.sugarchain/debug.log"

# CPUMINER
# ./cpuminer 
# -a yespower -o http://localhost:7978 -u username -p password --api-bind=127.0.0.1:4049
# --coinbase-addr=SMdY7R4Ag6iiGAtxT4ky8tX1Y41hpb5tzv
# -t1
CPUMINER_CLI="$HOME/git/SUGAR/CPUMINER/cpuminer-opt-sugarchain/cpuminer"
CPUMINER_OPTION="-a yespower -o http://localhost:7978 -u username -p password --api-bind=127.0.0.1:4049 -q"
CPUMINER_ADDRESS="--coinbase-addr=SMdY7R4Ag6iiGAtxT4ky8tX1Y41hpb5tzv"

CPUMINER_TEMP="-a yespower --benchmark"
RUN_TEMP="$CPUMINER_CLI $CPUMINER_TEMP"

RUN_CPUMINER="$CPUMINER_CLI $CPUMINER_OPTION $CPUMINER_ADDRESS"

KILL_CPUMINER="killall cpuminer"

# UTILITY
CHECK_INTEGER='^[0-9]+$'
PID=NULL

tail -f $COIN_DEBUG_LOCATION | while read line; 
do
    # 2019-01-22 18:26:59 UpdateTip: 
    # new best=f156dee6a813325c7df6dbf8cd187bf7cdfc93e2cb5c3de719d8fa1cc121415f 
    # height=6860 version=0x20000000 log2_work=23.116788 tx=6861 
    # date='2019-01-22 18:26:54' progress=1.000000 cache=0.5MiB(3688txo)
    
    CBN=$(echo $line | grep "height=" | cut -f 6 -d " " | cut -c8-)
    
    if [[ $CBN =~ $CHECK_INTEGER ]]; then
        
        printf "CURRENT BLOCK NUMBER = %d   PID = \033[31;1m %s \033[0m \n" $CBN $PID # \033[31;1m RED \033[0m
        
        if (( "$CBN" < "5100+1" )) && [ $PID != 1 ]; then
            PID=1
            CPUMINER_CORE_AMOUNT="-t2"
            # echo "PID_1: CUR_BLOCK_NUMBER < 5100+1 $CPUMINER_CORE_AMOUNT"
            printf "PID = %d \t CPU = %s \t 1 < CUR_BLOCK_NUMBER < 5100+1 \n" $PID $CPUMINER_CORE_AMOUNT
            killall cpuminer
            $RUN_CPUMINER $CPUMINER_CORE_AMOUNT &
            
        elif (( "$CBN" >= "5100+1" )) && (( "$CBN" < "10200+1" )) && [ $PID != 2 ]; then
            PID=2
            CPUMINER_CORE_AMOUNT="-t4"
            # echo "PID_2: CUR_BLOCK_NUMBER < 10200+1 $CPUMINER_CORE_AMOUNT"
            printf "PID = %d \t CPU = %s \t 5100+1 < CUR_BLOCK_NUMBER < 10200+1 \n" $PID $CPUMINER_CORE_AMOUNT
            killall cpuminer
            $RUN_CPUMINER $CPUMINER_CORE_AMOUNT &
            
        elif (( "$CBN" >= "10200+1" )) && (( "$CBN" < "15300+1" )) && [ $PID != 3 ]; then
            PID=3
            CPUMINER_CORE_AMOUNT="-t6"
            # echo "PID_3: CUR_BLOCK_NUMBER < 15300+1 $CPUMINER_CORE_AMOUNT"
            printf "PID = %d \t CPU = %s \t 10200+1 < CUR_BLOCK_NUMBER < 15300+1 \n" $PID $CPUMINER_CORE_AMOUNT
            killall cpuminer
            $RUN_CPUMINER $CPUMINER_CORE_AMOUNT &
            
        elif (( "$CBN" >= "15300+1" )) && (( "$CBN" < "20400+1" )) && [ $PID != 4 ]; then
            PID=4
            CPUMINER_CORE_AMOUNT="-t8"
            # echo "PID_4: CUR_BLOCK_NUMBER < 20400+1 $CPUMINER_CORE_AMOUNT"
            printf "PID = %d \t CPU = %s \t 15300+1 < CUR_BLOCK_NUMBER < 20400+1 \n" $PID $CPUMINER_CORE_AMOUNT
            killall cpuminer
            $RUN_CPUMINER $CPUMINER_CORE_AMOUNT &
    
        elif (( "$CBN" >= "20400+1" )) && (( "$CBN" < "25500+1" )) && [[ ${PID} != 5 ]]; then
            PID=5
            CPUMINER_CORE_AMOUNT="-t6"
            # echo "PID_5: CUR_BLOCK_NUMBER < 25500+1 $CPUMINER_CORE_AMOUNT"
            printf "\033[31;1m \n"
            printf "PID = %d \t CPU = %s \t 20400+1 < CUR_BLOCK_NUMBER < 25500+1 \n" $PID $CPUMINER_CORE_AMOUNT
            printf "\033[0m \n"
            killall cpuminer
            $RUN_CPUMINER $CPUMINER_CORE_AMOUNT &
            
        elif (( "$CBN" >= "25500+1" )) && (( "$CBN" < "30600+1" )) && [[ ${PID} != 6 ]]; then
            PID=6
            CPUMINER_CORE_AMOUNT="-t4"
            # echo "PID_6: CUR_BLOCK_NUMBER < 30600+1 $CPUMINER_CORE_AMOUNT"
            printf "PID = %d \t CPU = %s \t 25500+1 < CUR_BLOCK_NUMBER < 30600+1 \n" $PID $CPUMINER_CORE_AMOUNT
            killall cpuminer
            $RUN_CPUMINER $CPUMINER_CORE_AMOUNT &
            
        elif (( "$CBN" >= "30600+1" )) && (( "$CBN" < "35700+1" )) && [[ ${PID} != 7 ]]; then
            PID=7
            CPUMINER_CORE_AMOUNT="-t2"
            # echo "PID_7: CUR_BLOCK_NUMBER < 35700+1 $CPUMINER_CORE_AMOUNT"
            printf "PID = %d \t CPU = %s \t 30600+1 < CUR_BLOCK_NUMBER < 35700+1 \n" $PID $CPUMINER_CORE_AMOUNT
            killall cpuminer
            $RUN_CPUMINER $CPUMINER_CORE_AMOUNT &

        fi
    fi
done 
