#!/bin/bash
## hashAttack

# CPUMINER
# ./cpuminer 
# -a yespower -o http://localhost:7978 -u username -p password --api-bind=127.0.0.1:4049
# --coinbase-addr=SMdY7R4Ag6iiGAtxT4ky8tX1Y41hpb5tzv
# -t1
CPUMINER_CLI="$HOME/git/SUGAR/CPUMINER/cpuminer-opt-sugarchain/cpuminer"
# CPUMINER_OPTION="-a yespower -o http://localhost:7978 -u username -p password --api-bind=127.0.0.1:4049 -q"
CPUMINER_OPTION="-a yespower -o http://localhost:17798 -u username -p password --api-bind=127.0.0.1:4049 -q"
CPUMINER_ADDRESS="--coinbase-addr=RqAcnDGirfQgMQ8JkqFrSbJeKEQJEYYCiN"

RUN_CPUMINER="$CPUMINER_CLI $CPUMINER_OPTION $CPUMINER_ADDRESS"

CPUMINER_TMP="-a yespower --benchmark"
RUN_TMP="$CPUMINER_CLI $CPUMINER_TMP"
DUMMY_APP=./dummyApp

# COIN
COIN_CLI="$HOME/git/SUGAR/WALLET/sugarchain-v0.16.3/src/sugarchain-cli"
COIN_OPTION="-rpcuser=username -rpcpassword=password -regtest"  # MAIN: -main | TESTNET: -testnet | REGTEST: -regtest
GET_INFO="$COIN_CLI $COIN_OPTION"
COIN_BLOCK_TIME="5"

CHAIN_TYPE=$( $GET_INFO getblockchaininfo | jq -r '[.chain] | "\(.[0])"' )
COIN_NAME="$CHAIN_TYPE.Sugarchain(t$BLOCK_TIME)"
POW_NAME="YP"
DIFF_NAME="DS"
DIFF_N_SIZE="17" #regtest
HASHATTACK_FILE_NAME="HASHATTACK-$COIN_NAME-$POW_NAME-$DIFF_NAME(n$DIFF_N_SIZE).csv"

# DEBUG 
COIN_DEBUG_LOCATION="$HOME/.sugarchain/regtest/debug.log"

# UTILITY
CHECK_INTEGER='^[0-9]+$'

# START_BLOCK=1
START_BLOCK=$($GET_INFO getblockcount)
# START_BLOCK=$(( $START_BLOCK + 1 )) # start from 2nd

ATTACK_INTERVAL=1700 # 2*5 = 10 =~ 10 seconds
ATTACK_PROGRAM_AMOUNT=3 # 1-2-1
P_NUMBER=0 # init PROGRAM_NUMBER

# END_BLOCK=100 # actual amount
END_BLOCK=$(( ($ATTACK_INTERVAL * $ATTACK_PROGRAM_AMOUNT) + $START_BLOCK ))  # 2*3 + $START_BLOCK

printf "=====\n"
printf "  \n"
printf "  ATTACK START!  \n"
printf "  BLOCK RANGE is \t \e[36m %d to %d \e[39m \n" $START_BLOCK $END_BLOCK # cyan

AINTERVAL_IN_MINUTES=$( bc <<< "scale=12; $ATTACK_INTERVAL * $COIN_BLOCK_TIME / 60" )
printf "  INTERVAL is \t\t \e[36m %d (%.2f minutes) \e[39m \n" $ATTACK_INTERVAL $AINTERVAL_IN_MINUTES # cyan
printf "  PROGRAM_AMOUNT is \t \e[36m %d \e[39m \n" $ATTACK_PROGRAM_AMOUNT # cyan

ATIME_IN_MINUTES=$( bc <<< "scale=12; $ATTACK_INTERVAL * $ATTACK_PROGRAM_AMOUNT * $COIN_BLOCK_TIME / 60" )
ABLOCK_AMOUNT=$( bc <<< "$ATTACK_INTERVAL * $ATTACK_PROGRAM_AMOUNT" )
printf "  TOTAL BLOCKS is \t \e[36m %d (%.2f minutes) \e[39m \n" $ABLOCK_AMOUNT $ATIME_IN_MINUTES # cyan
printf "  \n"
printf "=====\n"

### READY
# CPUMINER_CORE_AMOUNT=1
# (killall cpuminer 2>&1) >/dev/null
# $RUN_CPUMINER -t$CPUMINER_CORE_AMOUNT -q | grep "Accepted" 2>&1 >/dev/null &

### LOOP
# for BLOCK_COUNT in `seq $START_BLOCK $END_BLOCK`;
# do
tail -f $COIN_DEBUG_LOCATION | while read line;
do
    # 2019-01-25 12:43:35 UpdateTip: new best=1cb1030e22bda4bfcec76619cabfe22619eb663512e847ccebf9de64e2572614 
    # height=13 version=0x20000000 log2_work=7.8948178 tx=14 date='2019-01-25 12:43:35' progress=1.000000 cache=0.0MiB(13txo)
    
    # BLOCK_COUNT=$(echo $line | grep "height=" | cut -f 6 -d " " | cut -c8-)
    BLOCK_COUNT=$( echo $line | grep -E "UpdateTip: new best=.*.height=" ) # select line
    BLOCK_COUNT=$( echo $BLOCK_COUNT | awk '{print $6}') # height=13
    BLOCK_COUNT=$( echo $BLOCK_COUNT | cut -c8- ) # 13
    
    if [[ $BLOCK_COUNT =~ $CHECK_INTEGER ]]; then
        
        if (( $(( $(($BLOCK_COUNT % $ATTACK_INTERVAL)) - $START_BLOCK)) == 0 )) && (( $(($P_NUMBER)) < $(($ATTACK_PROGRAM_AMOUNT)) )); then
            ## ATTACK
            # echo $BLOCK_COUNT
            # echo "ATTACK START: $BLOCK_COUNT"
            
            P_NUMBER=$(($P_NUMBER+1))
            
            case $P_NUMBER in
                    1)
                    CPUMINER_CORE_AMOUNT=1
                    printf "  $BLOCK_COUNT: ATTACK START \t"
                    printf "  PROG=%d\t CPU=%d \n" $P_NUMBER $CPUMINER_CORE_AMOUNT
                    (killall cpuminer 2>&1) >/dev/null
                    $RUN_CPUMINER -t$CPUMINER_CORE_AMOUNT -q | grep "Accepted" 2>&1 >/dev/null &
                    ;;
                    
                    2)
                    CPUMINER_CORE_AMOUNT=2
                    printf "  $BLOCK_COUNT: ATTACK START \t"
                    printf "  PROG=%d\t CPU=%d \n" $P_NUMBER $CPUMINER_CORE_AMOUNT
                    (killall cpuminer 2>&1) >/dev/null
                    $RUN_CPUMINER -t$CPUMINER_CORE_AMOUNT -q | grep "Accepted" 2>&1 >/dev/null &
                    ;;
                    
                    3)
                    CPUMINER_CORE_AMOUNT=1
                    printf "  $BLOCK_COUNT: ATTACK START \t"
                    printf "  PROG=%d\t CPU=%d \n" $P_NUMBER $CPUMINER_CORE_AMOUNT
                    (killall cpuminer 2>&1) >/dev/null
                    $RUN_CPUMINER -t$CPUMINER_CORE_AMOUNT -q | grep "Accepted" 2>&1 >/dev/null &
                    ;;
                    
                    *)
                    echo "ERROR: P_NUMBER overflow"
                    (killall cpuminer 2>&1) >/dev/null
                esac
            
        # elif (( $(($BLOCK_COUNT % $ATTACK_INTERVAL)) != 0 )) && (( $(($P_NUMBER)) < $(($ATTACK_PROGRAM_AMOUNT)) )); then
        else
            ## COUNT
            # echo "$BLOCK_COUNT: CURRENT"
            # echo -ne "$BLOCK_COUNT\r"
            
            INFO=$( $GET_INFO getblock $($GET_INFO getblockhash $BLOCK_COUNT) | jq -r '[.time, .difficulty, .previousblockhash] | "\(.[0]) \(.[1]) \(.[2])"' )
            
            CUR_HASHRATE=$( $GET_INFO getnetworkhashps $DIFF_N_SIZE $BLOCK_COUNT ) # N=17
            # BLOCK_DATA=$( $GET_INFO getblock $($GET_INFO getblockhash $BLOCK_COUNT) | jq -r '[.difficulty] | "\(.[0])"' )
            # CUR_DIFF=$( echo $BLOCK_DATA | awk '{print $1}' )
            # printf "%d \t \e[36m%.2f hash/s\e[39m \t DIFF %.16g \r" $BLOCK_COUNT $CUR_HASHRATE $CUR_DIFF
            
            printf "%d\t \033[31;1m %.2f hash/s \033[0m \r" $BLOCK_COUNT $CUR_HASHRATE
        fi
    fi
    
    trap "killall cpuminer 2>&1 >/dev/null" SIGINT # prevent cpu overheat
    
done
