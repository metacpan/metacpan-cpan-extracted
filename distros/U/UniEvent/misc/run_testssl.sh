set -e

if [ ! -d "testssl.sh" ]; then
  git clone https://github.com/drwetter/testssl.sh.git 
fi

perl -Mblib misc/testssl.pl & SERV=$!
testssl.sh/testssl.sh --full --mode parallel localhost:4502 & TEST=$!

wait $TEST
echo $SERV
kill -9 $SERV
wait $SERV
wait
