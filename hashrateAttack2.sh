#!/bin/bash
## hashAttack

# CPUMINER
# ./cpuminer 
# -a yespower -o http://localhost:7978 -u username -p password --api-bind=127.0.0.1:4049
# --coinbase-addr=SMdY7R4Ag6iiGAtxT4ky8tX1Y41hpb5tzv
# -t1
CPUMINER_CLI="$HOME/git/cpuminer-opt-sugarchain/cpuminer"
CPUMINER_OPTION="-a yespower -o http://localhost:7978 -u username -p password --api-bind=127.0.0.1:4049 -q"
CPUMINER_ADDRESS="--coinbase-addr=SXGVdV1xf1Djm5ZAbgR9MEfS3j9oBPNRbz"

RUN_CPUMINER="$CPUMINER_CLI $CPUMINER_OPTION $CPUMINER_ADDRESS"

CPUMINER_TMP="-a yespower --benchmark"
RUN_TMP="$CPUMINER_CLI $CPUMINER_TMP"
DUMMY_APP=./dummyApp

# COIN
COIN_CLI="$HOME/git/TEST-SUGAR/sugarchain-v0.16.3/src/sugarchain-cli"
COIN_OPTION="-rpcuser=username -rpcpassword=password -main"  # MAIN: -main | TESTNET: -testnet | REGTEST: -regtest
GET_INFO="$COIN_CLI $COIN_OPTION"
COIN_BLOCK_TIME="5"

# DEBUG 
COIN_DEBUG_LOCATION="$HOME/.sugarchain/debug.log"

# UTILITY
CHECK_INTEGER='^[0-9]+$'

# START_BLOCK=1
START_BLOCK=$($GET_INFO getblockcount)
# START_BLOCK=$(( $START_BLOCK + 1 )) # start from 2nd

ATTACK_INTERVAL=10200 # 10200*5=51000/3600 =~ 14 hours
ATTACK_PROGRAM_AMOUNT=7 # 2-4-6-8-6-4-2
N_NUMBER=0

# END_BLOCK=100 # actual amount
END_BLOCK=$(( ($ATTACK_INTERVAL * $ATTACK_PROGRAM_AMOUNT) + $START_BLOCK ))  # actual amount
# END_BLOCK=$(( $END_BLOCK + 1 )) # last block +1


(killall cpuminer 2>&1) >/dev/null
printf "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"

printf "  \n"
printf "  ATTACK START!  \n"
printf "  ATTACK BLOCK RANGE is \t \e[36m %d to %d \e[39m \n" $START_BLOCK $END_BLOCK # cyan
printf "  ATTACK_INTERVAL is \t\t \e[36m %d (%d hours) \e[39m \n" $ATTACK_INTERVAL $(( $ATTACK_INTERVAL * $COIN_BLOCK_TIME / 3600 ))  # cyan
printf "  ATTACK_PROGRAM_AMOUNT is \t \e[36m %d \e[39m \n" $ATTACK_PROGRAM_AMOUNT # cyan
printf "  TOTAL ATTACKED BLOCKS is \t \e[36m %d (%d hours) \e[39m \n" $(( $ATTACK_INTERVAL * $ATTACK_PROGRAM_AMOUNT )) $(( $(($ATTACK_INTERVAL * $ATTACK_PROGRAM_AMOUNT)) * $COIN_BLOCK_TIME / 3600 ))  # cyan
printf "  \n"

# for BLOCK_COUNT in `seq $START_BLOCK $END_BLOCK`;
# do
tail -f $COIN_DEBUG_LOCATION | while read line;
do
    BLOCK_COUNT=$(echo $line | grep "height=" | cut -f 6 -d " " | cut -c8-)
    BLOCK_COUNT=$(($BLOCK_COUNT))
    
    if [[ $BLOCK_COUNT =~ $CHECK_INTEGER ]] && (( $BLOCK_COUNT != 0 )); then
        echo -ne "\t\t\t BLOCK_COUNT: $BLOCK_COUNT\r"
    fi
    
    N_ATTACK_INTERVAL=$(( $(($START_BLOCK)) % $(($ATTACK_INTERVAL)) ))  # 20000 % 10
    # echo $N_ATTACK_INTERVAL
    
    if (( $N_ATTACK_INTERVAL == $(( $BLOCK_COUNT % $ATTACK_INTERVAL )) )); then  # start from 2
        
        if (( "$N_NUMBER" < "$ATTACK_PROGRAM_AMOUNT" )); then
            N_NUMBER=$(($N_NUMBER+1)) # increse N_state
        fi
        
        PERIOD_BEGIN=$BLOCK_COUNT
        PERIOD_END=$(($BLOCK_COUNT + $ATTACK_INTERVAL - 1))
        
        case $N_NUMBER in
            1)
            (killall cpuminer 2>&1) >/dev/null
            CPUMINER_CORE_AMOUNT=2;;
            2)
            (killall cpuminer 2>&1) >/dev/null
            CPUMINER_CORE_AMOUNT=4;;
            3)
            (killall cpuminer 2>&1) >/dev/null
            CPUMINER_CORE_AMOUNT=6;;
            4)
            (killall cpuminer 2>&1) >/dev/null
            CPUMINER_CORE_AMOUNT=8;;
            5)
            (killall cpuminer 2>&1) >/dev/null
            CPUMINER_CORE_AMOUNT=6;;
            6)
            (killall cpuminer 2>&1) >/dev/null
            CPUMINER_CORE_AMOUNT=4;;
            7)
            (killall cpuminer 2>&1) >/dev/null
            CPUMINER_CORE_AMOUNT=2;;
        esac
        # \033[31;1m %s \033[0m
        PERIOD_AMOUNT=$(( $PERIOD_END - $PERIOD_BEGIN + 1))
        printf "PHASE: %d BLOCK: %d to %d (%d) \033[31;1m CPU: %d \033[0m \n" $N_NUMBER $PERIOD_BEGIN $PERIOD_END $PERIOD_AMOUNT $CPUMINER_CORE_AMOUNT  # red
        
        # $DUMMY_APP &
        $RUN_CPUMINER -t$CPUMINER_CORE_AMOUNT -q | grep "9999Accepted" &
        #$RUN_CPUMINER -t$CPUMINER_CORE_AMOUNT & 

        # echo -ne "\t\t BLOCK_COUNT: $BLOCK_COUNT\r"
        # echo "  BLOCK_COUNT: $BLOCK_COUNT"
        # sleep 0.1
    fi
done

TOTAL_ATTACKED_BLOCK_AMOUNT=$(( $BLOCK_COUNT - $START_BLOCK + 1 ))

printf "  \n"
printf "  ATTACK FINISHED!  \n"
printf "  TOTAL ATTACKED BLOCKS is \t \e[36m $TOTAL_ATTACKED_BLOCK_AMOUNT \e[39m"  # cyan
printf "  \n"
