#RT-Date#190107#Testnet
#!/bin/bash
difficultyInit=$(echo "1.192074847720173e-07" | sed 's#\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)#(\1*10^\2\3)#g' | bc -l) && \
checkInteger='^[0-9]+$' && \
count=0 && \
blockIntervalAVG=0 && \
blockIntervalAVGtotal=-0 && \
printf "\n\n\n\n\n" && \
printf "%-5s %16s %22s %6s %3s %6s\n" BLOCK TIMESTAMP DIFFICULTY RATIO IV AVERG && \
sleep 1 && \
tail -f ~/.sugarchain/testnet3/debug.log | while read line; do
curBlockNumber=$(echo $line | grep "height=" | cut -f 6 -d " " | cut -c8-) && \
if [[ $curBlockNumber =~ $checkInteger ]]; then
curBlockHash=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password -testnet getblockhash $curBlockNumber) && \
curBlockTime=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password -testnet getblockheader $curBlockHash | jq -r .time) && \
curDate=$(date -d @$curBlockTime '+%y%m%d-%H:%M:%S') && \
curBlockDiff=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password -testnet getblockheader $curBlockHash | jq -r .difficulty) && \
preBlockHash=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password -testnet getblockheader $curBlockHash | jq -r .previousblockhash) && \
preBlockTime=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password -testnet getblockheader $preBlockHash | jq -r .time) && \
blockInterval=$(($curBlockTime - $preBlockTime)) && \
blockIntervalAVGtotal=$(bc <<< "$blockIntervalAVGtotal + $blockInterval") && \
count=$(($count + 1)) && \
blockIntervalAVG=$(bc <<< "scale=2; $blockIntervalAVGtotal / $count") && \
difficultyCurrent=$(echo $curBlockDiff | sed 's#\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)#(\1*10^\2\3)#g' | bc -l) && \
difficultyRatio=$(bc <<< "scale=3; $difficultyCurrent / $difficultyInit") && \
printf "%-5s %16s %22s %6s %3s %6s \n" $curBlockNumber $curDate $curBlockDiff $difficultyRatio $blockInterval $blockIntervalAVG;
fi
done
