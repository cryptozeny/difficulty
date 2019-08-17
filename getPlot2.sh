#!/bin/bash
## getDifficulty

# init
COIN_CLI="$HOME/git/SUGAR/sugarchain-v0.16.3/src/sugarchain-cli"
COIN_OPTION="-rpcuser=rpcuser -rpcpassword=rpcpassword -testnet" # MAIN: -main | TESTNET: -testnet | REGTEST: -regtest
GET_INFO="$COIN_CLI $COIN_OPTION"

CHAIN_TYPE=$( $GET_INFO getblockchaininfo | jq -r '[.chain] | "\(.[0])"' )

BLOCK_TIME="5"
COIN_NAME="$CHAIN_TYPE.Sugarchain(t$BLOCK_TIME)"
POW_NAME="YP"
DIFF_NAME="DS"
DIFF_N_SIZE="510"

GENESIS_HASH=$( $GET_INFO getblockhash 0 )

# POW_LIMIT="1.192074847720173e-07"
# POW_LIMIT="2.384149979653205e-07"
POW_LIMIT=$( $GET_INFO getblock $GENESIS_HASH | jq -r '[.difficulty] | "\(.[0])"' )

# TOTAL_BLOCK_AMOUNT=600 # test
TOTAL_BLOCK_AMOUNT=$($GET_INFO getblockcount)

FILE_NAME="$COIN_NAME-$POW_NAME-$DIFF_NAME(n$DIFF_N_SIZE).csv"

function GET_GENESIS_OFFSET() {
    #statements
    genesisData=$( $GET_INFO getblock $($GET_INFO getblockhash 0) | jq -r '[.time, .difficulty, .previousblockhash] | "\(.[0]) \(.[1]) \(.[2])"' )
    genesisTime=$( echo $genesisData | awk '{print $1}' )
    firstData=$( $GET_INFO getblock $($GET_INFO getblockhash 1) | jq -r '[.time, .difficulty, .previousblockhash] | "\(.[0]) \(.[1]) \(.[2])"' )
    firstTime=$( echo $firstData | awk '{print $1}' )
    genesisOffset=$(( $firstTime - $genesisTime ))
    echo $genesisOffset
}
GENESIS_OFFSET=$(GET_GENESIS_OFFSET)

function CONVERT_SCIENTIFIC_NOTATION() {
    # BC to handle scientific notation
    # https://stackoverflow.com/questions/12882611/how-to-get-bc-to-handle-numbers-in-scientific-aka-exponential-notation
    echo ${@} | sed 's#\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)#(\1*10^\2\3)#g' | bc -l
}


# check COIN_CLI
if [ ! -e $COIN_CLI ]; then
    echo "ERROR: NO COIN_CLI: $COIN_CLI"
    exit 1
fi

# new? or continue?
if [ ! -e $FILE_NAME ]; then
    # echo "NEW: $FILE_NAME"
    echo -e "\e[32mNEW: \t$FILE_NAME\e[39m" # green
    START_BLOCK=1
    INTERVAL_TOTAL=0
else 
    # echo "CONTINUE: $FILE_NAME"
    echo -e "\e[36mKEEP: \t$FILE_NAME\e[39m" # cyan
    START_BLOCK=$(( $( tail -n1 $FILE_NAME | awk '{print $1}' ) + 1 ))
    echo -e "\e[36mCONTINUE FROM $START_BLOCK\e[39m" # cyan
    INTERVAL_TOTAL=$(( $( tail -n1 $FILE_NAME | awk '{print $6}' ) + 0 ))
fi 

# make header
printf "\n"
printf "Block / Time / Diff / DiffRatio / Interval / Total / Mean / MA"
printf "\n\n"
sleep 1

# loop
for BLOCK_COUNT in `seq $START_BLOCK $TOTAL_BLOCK_AMOUNT`;
do
    CUR_DATA=$( $GET_INFO getblock $($GET_INFO getblockhash $BLOCK_COUNT) | jq -r '[.time, .difficulty, .previousblockhash] | "\(.[0]) \(.[1]) \(.[2])"' )
    CUR_TIME=$( echo $CUR_DATA | awk '{print $1}' )
    CUR_DIFF=$( echo $CUR_DATA | awk '{print $2}' )
    PRE_HASH=$( echo $CUR_DATA | awk '{print $3}' )
    PRE_DATA=$( $GET_INFO getblock $PRE_HASH | jq -r '[.time] | "\(.[0])"') # call RPC twice: it slows 2x
    PRE_TIME=$( echo $PRE_DATA | awk '{print $1}' )
    CUR_DIFF_RATIO=$( echo "scale=3; $(CONVERT_SCIENTIFIC_NOTATION $CUR_DIFF) / $(CONVERT_SCIENTIFIC_NOTATION $POW_LIMIT)" | bc )
    
    if [ $BLOCK_COUNT == 1 ]; then
        CUR_INTERVAL=$(( $CUR_TIME - $PRE_TIME - $GENESIS_OFFSET ))
    else
        CUR_INTERVAL=$(( $CUR_TIME - $PRE_TIME ))
    fi
    INTERVAL_TOTAL=$(( $(($INTERVAL_TOTAL + $CUR_INTERVAL)) ))
    INTERVAL_MEAN=$( echo "scale=2; $INTERVAL_TOTAL / $BLOCK_COUNT" | bc )
    
    printf "%s %s %21s %s %2s %s %s\n" $BLOCK_COUNT $CUR_TIME $CUR_DIFF $CUR_DIFF_RATIO $CUR_INTERVAL $INTERVAL_TOTAL $INTERVAL_MEAN | tee -a $FILE_NAME
done

# remove ma file before calculate for clean result
if [ -e $FILE_NAME.MA-$DIFF_N_SIZE ]; then
    rm $FILE_NAME.MA-*
fi 

# calculate MA
# https://rosettacode.org/wiki/Averages/Simple_moving_average#AWK
# P = MA_WINDOW

MA_SIZE_1="170"
MA_SIZE_2="34"

awk '{print $1, $5}' $FILE_NAME | awk -v DIFF_N_SIZE="$DIFF_N_SIZE" 'BEGIN { P = DIFF_N_SIZE; } { x = $2; i = NR % P; MA += (x - Z[i]) / P; Z[i] = x; print $1, MA; }' > $FILE_NAME.MA-$DIFF_N_SIZE
awk '{print $1, $5}' $FILE_NAME | awk -v MA_SIZE="$MA_SIZE_1" 'BEGIN { P = MA_SIZE; } { x = $2; i = NR % P; MA += (x - Z[i]) / P; Z[i] = x; print $1, MA; }' > $FILE_NAME.MA-$MA_SIZE_1
awk '{print $1, $5}' $FILE_NAME | awk -v MA_SIZE="$MA_SIZE_2" 'BEGIN { P = MA_SIZE; } { x = $2; i = NR % P; MA += (x - Z[i]) / P; Z[i] = x; print $1, MA; }' > $FILE_NAME.MA-$MA_SIZE_2

# plot parameters
SET_XRANGE="[1:*]"
SET_YRANGE="[0:5*2]"

PL_RATIO="2"
# SET_Y2RANGE="[$POW_LIMIT:$POW_LIMIT*5]"
# SET_Y2RANGE="[$POW_LIMIT:$POW_LIMIT*6]"
SET_Y2RANGE="[$POW_LIMIT:$POW_LIMIT*2]"
# SET_Y2RANGE="[$POW_LIMIT:2.584149979653205e-07]"
# SET_Y2RANGE="[$POW_LIMIT:*]"

# plot draw
gnuplot -persist <<-EOFMarker 
set term qt size 1200, 600;
set title "BLOCKS=$TOTAL_BLOCK_AMOUNT       FILE=$FILE_NAME       LIMIT=$POW_LIMIT" offset -30;
# set label 1 "LIMIT = $POW_LIMIT"; set label 1 at graph 0.81, 1.03 tc rgb "black";
# set label 2 "BLOCKS = $TOTAL_BLOCK_AMOUNT"; set label 2 at graph 0.81, 1.06 tc rgb "black";
set xlabel "Block Number";
set xrange $SET_XRANGE; set xtics 1, 17*50 rotate by 45 right; set xtics add ("1" 1) ("N+1=511" 511);
set ylabel "Block Time";
set yrange $SET_YRANGE; set ytics 0, 1; set ytics add ($BLOCK_TIME);
set ytics nomirror;
set y2label "Difficulty" tc rgb "red";
set y2range $SET_Y2RANGE; set format y2 '%.3g'; set y2tics $POW_LIMIT, $POW_LIMIT/$PL_RATIO; set y2tics add ($POW_LIMIT);
# set grid xtics ytics y2tics mxtics mytics my2tics;
set grid xtics y2tics;
set key top left invert; set key box opaque;
plot \
"$FILE_NAME.MA-$MA_SIZE_2" using 0:2 axis x1y1 w l title "(MA-$MA_SIZE_2) Block Time" lc rgb "#eeeeee" lw 1.0, \
"$FILE_NAME.MA-$MA_SIZE_1" using 0:2 axis x1y1 w l title "(MA-$MA_SIZE_1) Block Time" lc rgb "#cccccc" lw 1.0, \
"$FILE_NAME.MA-$DIFF_N_SIZE" using 0:2 axis x1y1 w l title "(MA-$DIFF_N_SIZE) Block Time" lc rgb "black" lw 1.25, \
"$FILE_NAME" using 1:3 axis x1y2 w l title "Difficulty" lc rgb "red" lw 1.25,
# caution at the end: no "\"
EOFMarker
