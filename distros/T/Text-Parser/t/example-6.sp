
.subckt res a b
.ends

.subckt inv in out vdd vss
Mp out in vss vss nmos
Mn out in vdd vdd pmos
.ends

.subckt nand a b y vdd vss
Mn1 y a n1 vss nmos
Mn2 n1 b vss vss nmos
Mp1 y a vdd vdd pmos
Mp2 y b vdd vdd pmos
.ends

.subckt nor a b y vdd vss
Mn1 y a vss vss nmos
Mn2 y b vss vss nmos
Mp1 y a n1 vdd pmos
Mp2 n1 b vdd vdd pmos
.ends

.subckt ro en out vdd vss
X1 en out net1 vdd vss nand
X2 net1 net2 vdd vss inv
X3 net2 net3 vdd vss inv
X4 net3 net4 vdd vss inv
X5 net4 out vdd vss inv
.ends

.subckt xor a b y vdd vss
Xa a a_bar vdd vss inv
Xb b b_bar vdd vss inv
Mp1 n1 a vdd vdd pmos
Mp2 y b_bar n1 vdd pmos
Mp3 n2 a_bar vdd vdd pmos
Mp4 y b n2 vdd pmos
Mn1 y a n3 vss nmos
Mn2 n3 a_bar vss vss nmos
Mn3 y b_bar n3 vss nmos
Mn4 n3 b vss vss nmos
.ends

.subckt ha a b s c vdd vss
Xs a b s vdd vss xor
Xcbar a b c_bar vdd vss nand
Xc c_bar c vdd vss inv
.ends

.subckt fa a b cin s cout vdd vss
Xcarry cin b n1 vdd vss xor
Xha a n1 s cout vdd vss ha
.ends

