#!/bin/bash
## getHashrate

# getnetworkhashps ( nblocks height )

## GET FROM RPC
COIN_CLI="$HOME/git/SUGAR/sugarchain-v0.16.3/src/sugarchain-cli"
COIN_OPTION="-rpcuser=rpcuser -rpcpassword=rpcpassword -testnet" # MAIN: nothing | TESTNET: -testnet | REGTEST: -regtest
GET_INFO="$COIN_CLI $COIN_OPTION"
GET_TOTAL_BLOCK_AMOUNT=$($GET_INFO getblockcount)
# GET_TOTAL_BLOCK_AMOUNT=3500 # test

CHAIN_TYPE=$( $GET_INFO getblockchaininfo | jq -r '[.chain] | "\(.[0])"' )

BLOCK_TIME="5"
COIN_NAME="$CHAIN_TYPE.Sugarchain(t$BLOCK_TIME)"
POW_NAME="YP"
DIFF_NAME="DS"
DIFF_N_SIZE="510"

HASHRATE_FILE_NAME="HASHRATE-$COIN_NAME-$POW_NAME-$DIFF_NAME(n$DIFF_N_SIZE).csv"

# POW_LIMIT="1.192074847720173e-07"
POW_LIMIT=$( $GET_INFO getblock $($GET_INFO getblockhash 0) | jq -r '[.difficulty] | "\(.[0])"' )

# check COIN_CLI
if [ ! -e $COIN_CLI ]; then
    echo "ERROR: NO COIN_CLI: $COIN_CLI"
    exit 1
fi

# new? or continue?
if [ ! -e $HASHRATE_FILE_NAME ]; then
    # echo "NEW: $HASHRATE_FILE_NAME"
    echo -e "\e[32mNEW: \t$HASHRATE_FILE_NAME\e[39m"
    # START_BLOCK=1
    START_BLOCK=1 # from first
else 
    # echo "CONTINUE: $HASHRATE_FILE_NAME"
    echo -e "\e[36mKEEP: \t$HASHRATE_FILE_NAME\e[39m"
    START_BLOCK=$(( $( tail -n1 $HASHRATE_FILE_NAME | awk '{print $1}' ) + 1 ))
    echo -e "\e[36mCONTINUE FROM $START_BLOCK\e[39m"
fi 

# loop
for BLOCK_COUNT in `seq $START_BLOCK $GET_TOTAL_BLOCK_AMOUNT`; 
do
    CUR_HASHRATE=$( $GET_INFO getnetworkhashps 510 $BLOCK_COUNT )
	BLOCK_DATA=$( $GET_INFO getblock $($GET_INFO getblockhash $BLOCK_COUNT) | jq -r '[.difficulty] | "\(.[0])"' )
    CUR_DIFF=$( echo $BLOCK_DATA | awk '{print $1}' )
    printf "%s %s %s\n" $BLOCK_COUNT $CUR_HASHRATE $CUR_DIFF | tee -a $HASHRATE_FILE_NAME
done

Y_SCALE=4.5
Y2_SCALE=1.65
PL_RATIO="4"

## DRAW PLOT & LAUNCH QT
gnuplot -persist <<-EOFMarker 
set terminal qt size 1200,600 font "VL P Gothic,10";
set title "BLOCKS=$GET_TOTAL_BLOCK_AMOUNT       FILE=$HASHRATE_FILE_NAME       LIMIT=$POW_LIMIT" offset -19;
set xlabel "Block Height";
set xrange [1:*]; set xtics 1, 17*50 rotate by 45 right; set xtics add ("1" 1) ("N+1=511" 511);
set ylabel "Hashrate (hash/s)";
set yrange [100:100*$Y_SCALE]; set ytics 100; set ytics nomirror;
set y2label "Difficulty" tc rgb "red";
set y2range [$POW_LIMIT:$POW_LIMIT*$Y2_SCALE]; set format y2 '%.3g'; set y2tics 0, $POW_LIMIT/$PL_RATIO; set y2tics add ($POW_LIMIT);
set grid xtics ytics mxtics mytics my2tics;
set key top left; set key box opaque;
plot \
"$HASHRATE_FILE_NAME" using 0:2 axis x1y1 w l title "Hashrate (hash/s)" lc rgb "black" lw 1.0, \
"$HASHRATE_FILE_NAME" using 0:3 axis x1y2 w l title "Difficulty" lc rgb "red" lw 1.0,
EOFMarker
