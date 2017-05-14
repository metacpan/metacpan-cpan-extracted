#!/bin/sh
# 20101122 sampo@iki.fi
# Silly tests just to improve test coverage
# http://sp1.zxidsp.org:8081/zxidhlo?o=E
# http://sp.tas3.pt:8080/zxidservlet/appdemo
# http://idp.tas3.pt:8081/zxididp?o=F
# killall -X java
# gprof zxcall

./zxididp -h --
./zxcall -dc -din 2 -q -v --
./zxcall -s FOO
./zxcall -s FOO -l
./zxcall -n -u 'http://localhost/'

echo TESTING DECODE

echo foo | ./zxdecode -sha1 -q -v --
echo foo | ./zxdecode -d -b -z -i 2 --  # Dumps core
./zxdecode -d -i 2 </dev/null
./zxdecode -d -i 2 -b -B -z -Z </dev/null

echo TESTING ENCDEC

./zxencdectest -h -q -v --
./zxencdectest -d -di test -q -v -rf -rg -ra -wo /tmp -rand /tmp -egd /tmp -uid 1111 -- </dev/null
./zxencdectest -license
./zxencdectest -r 1 <t/ibm-enc-a7n.xml  # Dumps core
./zxencdectest -r 2
./zxencdectest -r 3
./zxencdectest -r 4
./zxencdectest -r 5
./zxencdectest -r 6

echo TESTING PASSWD

./zxpasswd   # too few args
./zxpasswd -d -s foo
./zxpasswd -q -v --
./zxpasswd -d -l foo /impossible
./zxpasswd -l
echo -n 60e1cbb066c6c5179defd4974303dd33 | ./zxpasswd -t y -c testy tmp/test/
echo -n 60e1cbb066c6c5179defd4974303dd33 | ./zxpasswd -t x -c testy tmp/test/
echo -n 60e1cbb066c6c5179defd4974303dd33 | ./zxpasswd -t x -c testy2 tmp/test/

echo TESTING LOGVIEW

./zxlogview -q -v -- </dev/null
./zxlogview -d -di test -rf -ra </dev/null
./zxlogview -license >/dev/null

echo TESTING ZXCOT

./zxcot -q -v -a -- </dev/null
./zxcot -c PATH=/foo -d -dc
./zxcot -e http://localhost Abstract http://localhost urn:x-testi | ./zxcot -n -b
./zxcot /impossible
rm -rf tmp/test
./zxmkdirs.sh tmp/test/
./zxcot -c PATH=tmp/test/ -m >tmp/meta.xml

echo TESTING MISC

./zxidhrxmlwsp 1
QUERY_STRING=o=S ./zxidhrxmlwsp
QUERY_STRING=o=B ./zxidhrxmlwsp

#EOF