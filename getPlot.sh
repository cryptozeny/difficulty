#190107 #FULL-GnuPlot
#!/bin/bash
COIN_NAME=SugarchainTestnet && \
COIN_CLI="$HOME/git/SUGAR/WALLET/sugarchain-v0.16.3/src/sugarchain-cli" && \
COIN_OPTION="-rpcuser=username -rpcpassword=password -testnet" && \
curBlockNumber=$($COIN_CLI $COIN_OPTION getblockcount) && \
powLimit="1.192074847720173e-07"
difficultyInit=$(echo $powLimit | sed 's#\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)#(\1*10^\2\3)#g' | bc -l) && \
blockIntervalAVG=0 && \
blockIntervalAVGtotal=-5991042 && \
printf "\n\n\n\n\n" && \
printf "%-5s %16s %22s %6s %3s %6s\n" BLOCK TIMESTAMP DIFFICULTY RATIO IV AVERG && \
sleep 1 && \
for i in `seq 1 $curBlockNumber`; do 
curBlockHash=$($COIN_CLI $COIN_OPTION getblockhash $i) && \
curBlockTime=$($COIN_CLI $COIN_OPTION getblockheader $curBlockHash | jq -r .time) && \
curDate=$(date -d @$curBlockTime '+%y%m%d-%H:%M:%S') && \
curBlockDiff=$($COIN_CLI $COIN_OPTION getblockheader $curBlockHash | jq -r .difficulty) && \
preBLockNumber=$(($i-1)) && \
preBlockHash=$($COIN_CLI $COIN_OPTION getblockhash $preBLockNumber) && \
preBlockTime=$($COIN_CLI $COIN_OPTION getblockheader $preBlockHash | jq -r .time) && \
blockInterval=$(($curBlockTime - $preBlockTime)) && \
blockIntervalAVGtotal=$(bc <<< "$blockIntervalAVGtotal + $blockInterval") && \
blockIntervalAVG=$(bc <<< "scale=2; $blockIntervalAVGtotal / $i") && \
difficultyCurrent=$(echo $curBlockDiff | sed 's#\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)#(\1*10^\2\3)#g' | bc -l) && \
difficultyRatio=$(bc <<< "scale=3; $difficultyCurrent / $difficultyInit") && \
printf "%-5s %16s %22s %6s %3s %6s \n" $i $curDate $curBlockDiff $difficultyRatio $blockInterval $blockIntervalAVG 2>&1 | tee -a $COIN_NAME-$curBlockNumber.dat;
done && \
gnuplot -persist <<-EOFMarker 
set title "$COIN_NAME-$curBlockNumber.dat"; set grid; set term qt size 800, 400;
set label 1 "powLimit = $powLimit"; set label 1 at graph 0.015, 0.96 tc lt 4;
set label 2 "totalBlocks = $curBlockNumber"; set label 2 at graph 0.015, 0.90 tc lt 4;
set xrange [0:*]; set xlabel "Block Number"; set xtics 0, 17*100;
set yrange [0:20]; set ylabel "Block Time (sec)"; set ytics 0, 2; set ytics nomirror;
set y2range [$powLimit:*]; set y2label "Difficulty"; set format y2 '%.2g'; set y2tics 0, $powLimit;
plot \
"$COIN_NAME-$curBlockNumber.dat" using 0:6 axis x1y1 w l title "(mean) Block Time" linecolor 1, \
"$COIN_NAME-$curBlockNumber.dat" using 0:3 axis x1y2 w l title "Difficulty" linecolor 3, 
#"$COIN_NAME-$curBlockNumber.dat" using 0:5 axis x1y1 w points pointtype 5 pointsize 0.3 title "(actual) Block Time",
EOFMarker
