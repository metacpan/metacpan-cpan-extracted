cd ..
cd src
make all
cd ..
cd perl
cd i2c_lpt
perl Makefile.PL
# make test
make install
make clean
cd ..
cd i2c_ser
perl Makefile.PL
# make test
make install
make clean

