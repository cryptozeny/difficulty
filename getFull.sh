#FULL-Date#190107
#!/bin/bash
difficultyInit=$(echo "1.907323166912278e-06" | sed 's#\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)#(\1*10^\2\3)#g' | bc -l) && \
blockIntervalAVG=0 && \
blockIntervalAVGtotal=-5602258 && \
curBlockNumber=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password getblockcount) && \
printf "\n\n\n\n\n" && \
printf "%-5s %16s %22s %6s %3s %6s\n" BLOCK TIMESTAMP DIFFICULTY RATIO IV AVERG && \
sleep 1 && \
for(( i=0; i<=( $curBlockNumber / 1 ); i++ )); do 
curBlockHash=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password getblockhash $i) && \
curBlockTime=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password getblockheader $curBlockHash | jq -r .time) && \
curDate=$(date -d @$curBlockTime '+%y%m%d-%H:%M:%S') && \
curBlockDiff=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password getblockheader $curBlockHash | jq -r .difficulty) && \
if [ $i != 0 ]; then
preBLockNumber=$(($i-1)) && \
preBlockHash=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password getblockhash $preBLockNumber) && \
preBlockTime=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password getblockheader $preBlockHash | jq -r .time) && \
blockInterval=$(($curBlockTime - $preBlockTime)) && \
blockIntervalAVGtotal=$(bc <<< "$blockIntervalAVGtotal + $blockInterval") && \
blockIntervalAVG=$(bc <<< "scale=2; $blockIntervalAVGtotal / $i") && \
difficultyCurrent=$(echo $curBlockDiff | sed 's#\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)#(\1*10^\2\3)#g' | bc -l) && \
difficultyRatio=$(bc <<< "scale=3; $difficultyCurrent / $difficultyInit") && \
printf "%-5s %16s %22s %6s %3s %6s \n" $i $curDate $curBlockDiff $difficultyRatio $blockInterval $blockIntervalAVG;
elif [ $i -eq 0 ]; then
preBLockNumber="GENESIS" && \
printf "%-5s %16s %22s %6s %3s %6s \n" $i $curDate $curBlockDiff $difficultyRatio $preBLockNumber $preBLockNumber;
fi;
done 2>&1 | tee ../dgw-T10-N200-$curBlockNumber.txt
