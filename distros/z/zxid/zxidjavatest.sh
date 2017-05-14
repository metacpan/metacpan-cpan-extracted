#!/bin/sh
# 20131116, sampo@synergetics.be
#
# If this test does not work, you may want to play with
# 1. LD_LIBRARY_PATH to make sure libzxidjni.so is found
# 2. Move libzxidjni.so or zxidjni.dll to a system location
#    where dynalic link libraries are searched by default.
# 3. Playing with -classpath and -Djava.library.path may
#    help in locating the .class files that make up
#    the zxidjava package
#
# javac -J-Xmx128m -g zxidjavatest.java
# ./zxidjavatest.sh

#java zxidjavatest
#LD_LIBRARY_PATH=./zxidjava java zxidjavatest
#LD_LIBRARY_PATH=./zxidjava java -classpath . -Djava.library.path=. zxidjavatest
#LD_LIBRARY_PATH=./zxidjava strace -e open java -verbose -classpath .:zxidjava -Djava.library.path=.:zxidjava zxidjavatest
LD_LIBRARY_PATH=./zxidjava java -Djava.library.path=.:zxidjava zxidjavatest

#EOF