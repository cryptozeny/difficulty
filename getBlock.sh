#!/bin/bash
## getBlock

# DO GET
# "hash": "9a5c10895dd9b9bce312a400644552878d3bf9c510a444400e39e5ebfb7e7ae8",
# "strippedsize": 226,
# "size": 262,
# "weight": 940,
# "height": 1,
# "version": 536870912,
# "versionHex": "20000000",
# "merkleroot": "ecc8fb2948d67b1841a3ab362711667819df8a7185072e06a3bce6e483116262",
# "time": 1548260437,
# "mediantime": 1548260437,
# "nonce": 664,
# "bits": "1f3fffff",
# "difficulty": 2.384149979653205e-07,
# "chainwork": "0000000000000000000000000000000000000000000000000000000000000800",
# "nTx": 1,
# "previousblockhash": "8e8e0270b7a6bc36e42cb4dca7ffee7e7648447fe102d1e4006cbc1bc9f8cc19",

# DO NOT GET
# "confirmations": 5589,
# "tx": [
# "ecc8fb2948d67b1841a3ab362711667819df8a7185072e06a3bce6e483116262"
# ],
# "nextblockhash": "1f4c4ac62b1bccacc65f3a60a8468bcab58e08de21951404156ba2933f09c423"

## GET FROM RPC
COIN_NAME="Sugarchain"
COIN_CLI="$HOME/git/SUGAR/WALLET/sugarchain-v0.16.3/src/sugarchain-cli"
COIN_OPTION="-rpcuser=username -rpcpassword=password -main" # MAIN: -main | TESTNET: -testnet | REGTEST: -regtest
GET_INFO="$COIN_CLI $COIN_OPTION"

GETBLOCK_FILE_NAME="GETBLOCK-$COIN_NAME.csv"

BLOCK_TIME="5"

## loop forever...
while true; do
    # TOTAL_BLOCK_AMOUNT=200 # test
    TOTAL_BLOCK_AMOUNT=$($GET_INFO getblockcount)
    
    # check COIN_CLI
    if [ ! -e $COIN_CLI ]; then
        echo "ERROR: NO COIN_CLI: $COIN_CLI"
        exit 1
    fi
    
    # new? or continue?
    if [ ! -e $GETBLOCK_FILE_NAME ]; then
        # echo "NEW: $GETBLOCK_FILE_NAME"
        echo -e "\e[32mNEW: \t$GETBLOCK_FILE_NAME\e[39m"
        START_BLOCK=1
    else 
        # echo "CONTINUE: $GETBLOCK_FILE_NAME"
        echo -e "\e[36mKEEP: \t$GETBLOCK_FILE_NAME\e[39m"
        START_BLOCK=$(( $( tail -n1 $GETBLOCK_FILE_NAME | awk '{print $1}' ) + 1 ))
        echo -e "\e[36mCONTINUE FROM $START_BLOCK\e[39m"
    fi 
    
    # make header
    ## 16 items & height at first
    printf "\n"
    printf "height hash strippedsize size weight version versionHex merkleroot time mediantime nonce bits difficulty chainwork nTx previousblockhash \n"
    printf "\n"
    sleep 1
    
    # loop main
    for BLOCK_COUNT in `seq $START_BLOCK $TOTAL_BLOCK_AMOUNT`;
    do
        CUR_DATA=$( $GET_INFO getblock $($GET_INFO getblockhash $BLOCK_COUNT) | \
        jq -r \
        '[.height, .hash, .strippedsize, .size, .weight, .version, .versionHex, .merkleroot, .time, .mediantime, .nonce, .bits, .difficulty, .chainwork, .nTx, .previousblockhash] | "\(.[0]) \(.[1]) \(.[2]) \(.[3]) \(.[4]) \(.[5]) \(.[6]) \(.[7]) \(.[8]) \(.[9]) \(.[10]) \(.[11]) \(.[12]) \(.[13]) \(.[14]) \(.[15])"' 
        )
        echo $CUR_DATA | tee -a $GETBLOCK_FILE_NAME
        # '[.time, .difficulty, .previousblockhash] | "\(.[0]) \(.[1]) \(.[2])"'
    done
    
    sleep $BLOCK_TIME # update every blocktime
done
