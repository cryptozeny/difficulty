#!/bin/bash
## getBlocktime-RT 

## GET FROM RPC
COIN_CLI="$HOME/git/SUGAR/sugarchain-v0.16.3/src/sugarchain-cli"
COIN_OPTION="-rpcuser=username -rpcpassword=password -regtest" # MAIN: -main | TESTNET: -testnet | REGTEST: -regtest
LOG_LOCATION="$HOME/.sugarchain/regtest/debug.log"

GET_INFO="$COIN_CLI $COIN_OPTION"

## GET INFO
GENESIS_HASH=$( $GET_INFO getblockhash 0 )
POW_LIMIT=$( $GET_INFO getblock $GENESIS_HASH | jq -r '[.difficulty] | "\(.[0])"' )

function CONVERT_SCIENTIFIC_NOTATION() {
    # BC to handle scientific notation
    # https://stackoverflow.com/questions/12882611/how-to-get-bc-to-handle-numbers-in-scientific-aka-exponential-notation
    echo ${@} | sed 's#\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)#(\1*10^\2\3)#g' | bc -l
}

CHECK_INTEGER='^[0-9]+$'

COUNT=0

printf "\n\n\n\n\n"
printf "%s\t %s   %s\t\t\t %s   %s\t %s\n" BLOCK TIMESTAMP DIFFICULTY RATIO INTVL AVG

tail -f $LOG_LOCATION | while read line;
do
    # CBN=$(echo $line | grep "height=" | cut -f 6 -d " " | cut -c8-) ## grep height from line
    CBN=$(echo $line | grep "height=" | cut -f 6 -d " " | cut -c8-) ## grep height from line
    
    if [[ $CBN =~ $CHECK_INTEGER ]] && (( "$CBN" >= "2" )); ## start from block height 2
    then
        CUR_DATA=$( $GET_INFO getblock $($GET_INFO getblockhash $CBN) | jq -r '[.time, .difficulty, .previousblockhash] | "\(.[0]) \(.[1]) \(.[2])"' )
        CUR_TIME=$( echo $CUR_DATA | awk '{print $1}' )
        CUR_DIFF=$( echo $CUR_DATA | awk '{print $2}' )
        PRE_HASH=$( echo $CUR_DATA | awk '{print $3}' )
        PRE_DATA=$( $GET_INFO getblock $PRE_HASH | jq -r '[.time] | "\(.[0])"') # call RPC twice: it slows 2x
        PRE_TIME=$( echo $PRE_DATA | awk '{print $1}' )
        CUR_DIFF_RATIO=$( echo "scale=3; $(CONVERT_SCIENTIFIC_NOTATION $CUR_DIFF) / $(CONVERT_SCIENTIFIC_NOTATION $POW_LIMIT)" | bc )
        CUR_INTERVAL=$(( $CUR_TIME - $PRE_TIME ))
        INTERVAL_TOTAL=$(( $(($INTERVAL_TOTAL + $CUR_INTERVAL)) ))
        
        COUNT=$(($COUNT + 1))
        
        INTERVAL_MEAN=$( echo "scale=2; $INTERVAL_TOTAL / $COUNT" | bc )
        
        # CUR_TIME=$(date -d @$CUR_TIME '+%y%m%d-%H:%M:%S') ## convert format: 1548284490 to 190124-08:01:30
        
        printf "%s\t %s  %s\t %s  %s\t %s\n" $CBN $CUR_TIME $CUR_DIFF $CUR_DIFF_RATIO $CUR_INTERVAL $INTERVAL_MEAN 
    fi
done
