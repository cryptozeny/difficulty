#AVG+Ratio
#!/bin/bash
powLimit="1.907323166912278e-06" && \
difficultyInit=$(echo $powLimit | sed 's#\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)#(\1*10^\2\3)#g' | bc -l) && \
blockIntervalAVG=0 && \
blockIntervalAVGtotal=-5430806 && \
curBlockNumber=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password getblockcount) && \
printf "\n\n\n\n\n" && \
printf "%-6s %10s %22s %8s %8s %8s\n" BLOCK TIMESTAMP DIFF RATIO INTERVAL AVG && \
sleep 3 && \
for(( i=0; i<=( $curBlockNumber / 1 ); i++ )); do 
curBlockHash=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password getblockhash $i) && \
curBlockTime=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password getblockheader $curBlockHash | jq -r .time) && \
curBlockDiff=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password getblockheader $curBlockHash | jq -r .difficulty) && \
if [ $i != 0 ]; then
preBLockNumber=$(($i-1)) && \
preBlockHash=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password getblockhash $preBLockNumber) && \
preBlockTime=$(./src/sugarchain-cli -rpcuser=username -rpcpassword=password getblockheader $preBlockHash | jq -r .time) && \
blockInterval=$(($curBlockTime - $preBlockTime)) && \
blockIntervalAVGtotal=$(bc <<< "$blockIntervalAVGtotal + $blockInterval") && \
blockIntervalAVG=$(bc <<< "scale=2; $blockIntervalAVGtotal / $i") && \
difficultyCurrent=$(echo $curBlockDiff | sed 's#\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)#(\1*10^\2\3)#g' | bc -l) && \
difficultyRatio=$(bc <<< "scale=2; $difficultyCurrent / $difficultyInit") && \
printf "%-6s %10s %22s %8s %8s %8s \n" $i $curBlockTime $curBlockDiff $difficultyRatio $blockInterval $blockIntervalAVG;
elif [ $i -eq 0 ]; then
preBLockNumber="GENESIS" && \
printf "%-6s %10s %22s %8s %8s %8s \n" $i $curBlockTime $curBlockDiff $difficultyRatio $preBLockNumber $preBLockNumber;
fi;
done
