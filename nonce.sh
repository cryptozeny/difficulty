#!/bin/bash
## getNonce

## GET FROM RPC
COIN_CLI="$HOME/git/SUGAR/sugarchain-v0.16.3/src/sugarchain-cli"
COIN_OPTION="-rpcuser=rpcuser -rpcpassword=rpcpassword -testnet" # MAIN: -main | TESTNET: -testnet | REGTEST: -regtest
GET_INFO="$COIN_CLI $COIN_OPTION"
GET_TOTAL_BLOCK_AMOUNT=$($GET_INFO getblockcount)
# GET_TOTAL_BLOCK_AMOUNT=510 # test

CHAIN_TYPE=$( $GET_INFO getblockchaininfo | jq -r '[.chain] | "\(.[0])"' )

BLOCK_TIME="5"
COIN_NAME="$CHAIN_TYPE.Sugarchain(t$BLOCK_TIME)"
POW_NAME="YP"
DIFF_NAME="DS"
DIFF_N_SIZE="510"

NONCE_FILE_NAME="NONCE-$COIN_NAME-$POW_NAME-$DIFF_NAME(n$DIFF_N_SIZE).csv"

# POW_LIMIT="1.192074847720173e-07"
POW_LIMIT=$( $GET_INFO getblock $($GET_INFO getblockhash 1) | jq -r '[.difficulty] | "\(.[0])"' )

# check COIN_CLI
if [ ! -e $COIN_CLI ]; then
    echo "ERROR: NO COIN_CLI: $COIN_CLI"
    exit 1
fi

# new? or continue?
if [ ! -e $NONCE_FILE_NAME ]; then
    # echo "NEW: $NONCE_FILE_NAME"
    echo -e "\e[32mNEW: \t$NONCE_FILE_NAME\e[39m"
    # START_BLOCK=1
    START_BLOCK=0 # from genesis
else
    # echo "CONTINUE: $NONCE_FILE_NAME"
    echo -e "\e[36mKEEP: \t$NONCE_FILE_NAME\e[39m"
    START_BLOCK=$(( $( tail -n1 $NONCE_FILE_NAME | awk '{print $1}' ) + 1 ))
    echo -e "\e[36mCONTINUE FROM $START_BLOCK\e[39m"
fi

# loop
for BLOCK_COUNT in `seq $START_BLOCK $GET_TOTAL_BLOCK_AMOUNT`;
do
	$GET_INFO getblock $($GET_INFO getblockhash $BLOCK_COUNT) | jq -r '[.height, .time, .nonce, .difficulty] | "\(.[0]) \(.[1]) \(.[2]) \(.[3])"' | tee -a $NONCE_FILE_NAME
done

SET_XRANGE="[1:*]"

# PL_RATIO="2"
PL_RATIO="4"

SET_Y2RANGE="[$POW_LIMIT:$POW_LIMIT*1.5]"

## DRAW PLOT & LAUNCH QT
gnuplot -persist <<-EOFMarker
set terminal qt size 1200,600 font "VL P Gothic,10";
set title "BLOCKS=$GET_TOTAL_BLOCK_AMOUNT       FILE=$NONCE_FILE_NAME       LIMIT=$POW_LIMIT" offset -19;
set xlabel "Block Height";
set xrange [0:*]; set xtics 1, 17*50 rotate by 45 right; set xtics add ("GENESIS" 0) ( "N+1=$(($DIFF_N_SIZE+1))" $(($DIFF_N_SIZE+1)) );
set ylabel "Nonce";
set yrange [8.5e+08*-1:8.5e+08*(5+1)]; set ytics 8.5e+08; set format y '%.3g'; set ytics nomirror;
set y2label "Difficulty" tc rgb "red";
set y2range $SET_Y2RANGE; set format y2 '%.3g'; set y2tics $POW_LIMIT, $POW_LIMIT/$PL_RATIO; set y2tics add ($POW_LIMIT);
set grid xtics ytics mxtics mytics;
set key top left; set key box opaque;
plot \
"$NONCE_FILE_NAME" using 0:3 axis x1y1 w p title "Nonce" pt 7 ps 0.05*4 lc rgb "black", \
"$NONCE_FILE_NAME" using 0:4 axis x1y2 w l title "Difficulty" lc rgb "red" lw 1.25,
EOFMarker
