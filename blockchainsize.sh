#!/bin/bash
## getBlockchainSize

## GET FROM RPC
COIN_CLI="$HOME/git/SUGAR/sugarchain-v0.16.3/src/sugarchain-cli"
# COIN_OPTION="-rpcuser=rpcuser -rpcpassword=rpcpassword -mainnet" # MAIN: -main | TESTNET: -testnet | REGTEST: -regtest
COIN_OPTION="-main -rpcuser=rpcuser -rpcpassword=rpcpassword -port=24230 -rpcport=24229"
GET_INFO="$COIN_CLI $COIN_OPTION"
GET_TOTAL_BLOCK_AMOUNT=$($GET_INFO getblockcount)
# GET_TOTAL_BLOCK_AMOUNT=20500 # test

CHAIN_TYPE=$( $GET_INFO getblockchaininfo | jq -r '[.chain] | "\(.[0])"' )

COIN_NAME="$CHAIN_TYPE.Sugarchain(t$BLOCK_TIME)"
POW_NAME="YP"
DIFF_NAME="DS"
DIFF_N_SIZE="510"

BLOCKCHAINSIZE_FILE_NAME="./csv/BLOCKCHAINSIZE-$COIN_NAME-$POW_NAME-$DIFF_NAME(n$DIFF_N_SIZE).csv"

# POW_LIMIT="1.192074847720173e-07"
POW_LIMIT=$( $GET_INFO getblock $($GET_INFO getblockhash 0) | jq -r '[.difficulty] | "\(.[0])"' )

# check COIN_CLI
if [ ! -e $COIN_CLI ]; then
    echo "ERROR: NO COIN_CLI: $COIN_CLI"
    exit 1
fi

# new? or continue?
if [ ! -e $BLOCKCHAINSIZE_FILE_NAME ]; then
    # echo "NEW: $BLOCKCHAINSIZE_FILE_NAME"
    echo -e "\e[32mNEW: \t$BLOCKCHAINSIZE_FILE_NAME\e[39m"
    # START_BLOCK=1
    START_BLOCK=0 # from first
    TOTAL_BLOCKCHAINSIZE=0
else
    # echo "CONTINUE: $BLOCKCHAINSIZE_FILE_NAME"
    echo -e "\e[36mKEEP: \t$BLOCKCHAINSIZE_FILE_NAME\e[39m"
    START_BLOCK=$(( $( tail -n1 $BLOCKCHAINSIZE_FILE_NAME | awk '{print $1}' ) + 1 ))
    echo -e "\e[36mCONTINUE FROM $START_BLOCK\e[39m"
    TOTAL_BLOCKCHAINSIZE=$(( $( tail -n1 $BLOCKCHAINSIZE_FILE_NAME | awk '{print $3}' ) + 0 ))
fi

# loop
for BLOCK_COUNT in `seq $START_BLOCK $GET_TOTAL_BLOCK_AMOUNT`;
do
    CUR_BLOCKSIZE=$( $GET_INFO getblock $($GET_INFO getblockhash $BLOCK_COUNT) | jq .size )
    TOTAL_BLOCKCHAINSIZE=$(( $(($TOTAL_BLOCKCHAINSIZE + $CUR_BLOCKSIZE)) ))

    printf "%s %s %s\n" $BLOCK_COUNT $CUR_BLOCKSIZE $TOTAL_BLOCKCHAINSIZE | tee -a $BLOCKCHAINSIZE_FILE_NAME
done

# find minmax
GET_BLOCKSIZE_MINMAX=$( awk '{print $2}' $BLOCKCHAINSIZE_FILE_NAME | awk 'NR == 1 {max=$1 ; min=$1} $1 >= max {max = $1} $1 <= min {min = $1} END { print min, max }' )
GET_BLOCKSIZE_MIN=$( echo $GET_BLOCKSIZE_MINMAX | awk '{print $1}' )
GET_BLOCKSIZE_MAX=$( echo $GET_BLOCKSIZE_MINMAX | awk '{print $2}' )

# SCALE_FACTOR=9

## DRAW PLOT & LAUNCH QT
OUTPUT_PNG="./png/blockchainsize.png"
gnuplot -persist <<-EOFMarker
# set terminal qt size 1200,600 font "VL P Gothic,10";
set terminal pngcairo size 1500,750 enhanced font "VL P Gothic,11";
set output "$OUTPUT_PNG";

set title "BLOCKS={/:Bold$GET_TOTAL_BLOCK_AMOUNT}       FILE=$BLOCKCHAINSIZE_FILE_NAME       LIMIT=$POW_LIMIT       MINMAX=$GET_BLOCKSIZE_MIN:$GET_BLOCKSIZE_MAX (Byte)" offset -0;
set xlabel "Block Height";
# set xrange [0:*]; set xtics 1, 17*50*4 rotate by 45 right; set xtics add ("GENESIS" 0) ("N+1=511" 511) ("1[day]=17280+1" 17280+1) ("2[day]=17280*2+1" 17280*2+1) ("3[day]=17280*3+1" 17280*3+1);
# set xrange [0:*]; set xtics 1, 17*50*75 rotate by 45 right; set xtics add ("GENESIS" 0) ("N+1=511" 511) ("1[day]=17280+1" 17280+1) ("2[day]=17280*2+1" 17280*2+1) ("3[day]=17280*3+1" 17280*3+1);
set xrange [0:*]; set format x '%.0f'; set xtics 1, (17280*7)+1 rotate by 45 right; set xtics add ("1" 1) ("N+1=511" 511);
set ylabel "Total Blockchain Size (MB)" tc rgb "black";
set yrange [0:*]; set ytics nomirror;
set format y "%.2s %cB";
set y2label "Each Block Size (Byte)" tc rgb "red";
# set y2range [$GET_BLOCKSIZE_MIN:$GET_BLOCKSIZE_MAX]; set y2tics $GET_BLOCKSIZE_MIN, $(( ($GET_BLOCKSIZE_MAX-$GET_BLOCKSIZE_MIN)/4 )); #set y2tics add ("1000=1kB" 1000);
set y2range [$GET_BLOCKSIZE_MIN:$GET_BLOCKSIZE_MAX]; set y2tics 0, 2.5e+5; set y2tics add ("%.3s %cB" $GET_BLOCKSIZE_MAX);
set format y2 "%.2s %cB";
set grid xtics ytics mxtics mytics my2tics;
set mxtics 1;
set key top left; set key box opaque;
plot \
"$BLOCKCHAINSIZE_FILE_NAME" using 0:2 axis x1y2 w l title "Each Block Size (bytes)" lc rgb "red" lw 1.5, \
"$BLOCKCHAINSIZE_FILE_NAME" using 0:3 axis x1y1 w l title "Total Blockchain Size (MB)" lc rgb "black" lw 1.5,
EOFMarker

# echo
echo ""
echo -e "  \e[32m..PRINTING TO FILE $OUTPUT_PNG\e[39m"
echo ""

# copy to clipboard
xclip -selection clipboard -t image/png -i $OUTPUT_PNG

# open PNG
feh --scale-down $OUTPUT_PNG &
