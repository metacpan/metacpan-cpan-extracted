#!/usr/bin/perl

# script to test and improve the patent document identifier parser.
# when a patent document identifier string fails in the parser,
# or you make a parser improvement, please send to wanda_b_anon@yahoo.com .
# Thanks
#
my ($country,$type,$number,$kind,$comment,$unparsed)=(undef,undef,undef,undef,undef);
my $count;
foreach my $target( 'US_6_123_456a1'  #a1 is comment not kind
	, 'US6123456', 'US6,123,456', 'US_6_123_456', 'US_6_123_456A1',
	'US_6_123_456B2_Comment two ', '  US_6_123_456_B2_Comment, comma', 'US_6_123_456_B2',
	'US_6_123_456_Comment',
	'US_6_123_456_C', 'US_6_123_456C', 'US_6_123_456_C_Comment trailing spaces          ',
	'US_6_123_456CC_Comment_Comment',
	'US_6_123_456C,C_Comment_Comment',
	'us6123456', 'us6,123,456', 'us_6_123_456', 'us_6_123_456A1',
	'us_6_123_456B2_Comment', 'us_6_123_456_B2_Comment', 'us_6_123_456_B2',
	'us_6_123_456_Comment', 'uspp6123456', 'uspp6,123,456', 'uspp_6_123_456', 'uspp_6_123_456A1',
	'uspp_6_123_456B2_Comment', 'uspp_6_123_456_B2_Comment', 'uspp_6_123_456_B2',
	'uspp_6_123_456_Comment', 'pp6123456', 'pp6,123,456', 'pp_6_123_456', 'pp_6_123_456A1',
	'pp_6_123_456B2_Comment', 'pp_6_123_456_B2_Comment', 'pp_6_123_456_B2',
	'pp_6_123_456_Comment', '6123456', '6,123,456', '_6_123_456', '_6_123_456A1',
	'_6_123_456B2_Comment', '_6_123_456_B2_Comment', '_6_123_456_B2',
	'_6_123_456_Comment', 'pp6123456', 'pp6,123,456', 'pp_6_123_456', 'pp_6_123_456A1',
	'pp_6_123_456B2_Comment', 'pp_6_123_456_B2_Comment', 'pp_6_123_456_B2',
	'  _6_123_456_Comment', 'pp6123456', 'pp6,123,456', 'pp_6_123_456', 'pp_6_123_456A1',
	'pp_6_123_456B2_Comment', 'pp_6_123_456_B2_Comment', 'pp_6_123_456_B2',
	'pp_6_123_456_Comment', 'pp_6_123_456_CComment', 'pp_6_123_456_C_Comment', 'pp_6_123_456_Comment',
	'US 6 123 456', 'pp_6_123_456_ Comment', 'pp_6_123_456 _Comment',
	'pp_6_123_456 _ Fomment', 'pp_6_123_456 _Fomment',
	'5,146,634', '6923014', '0000001', 'D339,456', 'D321987', 'D000152',
'PP08,901', 'PP07514', 'PP00003', 'RE35,312', 'RE12345', 'RE00007',
'T109,201', 'T855019', 'T100001', 'H001,523', 'H001234', 'H000001',
'RX29,194', 'RE29183', 'RE00125', 'AI00,002', 'AI000318', 'AI00007',
'US5,146,634', 'US6923014', 'US0000001', 'USD339,456', 'USD321987',
'USD000152', 'USPP08,901', 'USPP07514', 'USPP00003', 'USRE35,312',
'USRE12345', 'USRE00007', 'UST109,201', 'UST855019', 'UST100001',
'USH001,523', 'USH001234', 'USH000001', 'USRX29,194', 'USRE29183',
'USRE00125', 'USAI00,002', 'USAI000318', 'USAI00007',

'5,146,634', '6923014', '0000001', 'd339,456', 'd321987', 'd000152',
'pp08,901', 'pp07514', 'pp00003', 're35,312', 're12345', 're00007',
't109,201', 't855019', 't100001', 'h001,523', 'h001234', 'h000001',
'rx29,194', 're29183', 're00125', 'ai00,002', 'ai000318', 'ai00007',
'us5,146,634', 'us6923014', 'us0000001', 'usd339,456', 'usd321987',
'usd000152', 'uspp08,901', 'uspp07514', 'uspp00003', 'usre35,312',
'usre12345', 'usre00007', 'ust109,201', 'ust855019', 'ust100001',
'ush001,523', 'ush001234', 'ush000001', 'usrx29,194', 'usre29183',
'usre00125', 'usai00,002', 'usai000318', 'usai00007', 'unparseable',

	) {
$count++;
if ($target =~ m/^    # anchor to beginning of string
	[, _\-\t]*   #      #separator(s) (optional)
	(\D\D){0,1}   # country (optional) (well, sometimes the type, if country not supplied because known by other means)
	[, _\-\t]*            #separator(s) (optional)
	(D|PP|RE|T|H|RX|AI|d|pp|re|t|h|rx|ai){0,1}   # type, if accompanied by country
	[, _\-\t]*            #separator(s) (optional)
	([, _\-\d]+)  # "number" REQUIRED to have digits - with interspersed separator(s) (optional)
	[, _\-\t]*            #separator(s) (optional)
	(
		A$|A[, _\-\t]+|B$|B[, _\-\t]+|D$|D[, _\-\t]+|E$|E[, _\-\t]+|H$|H[, _\-\t]+|
		L$|L[, _\-\t]+|M$|M[, _\-\t]+|O$|O[, _\-\t]+|P$|P[, _\-\t]+|S$|S[, _\-\t]+|
		T$|T[, _\-\t]+|U$|U[, _\-\t]+|W$|W[, _\-\t]+|X$|X[, _\-\t]+|Y$|Y[, _\-\t]+|
		Z$|Z[, _\-\t]+|
		A0|A1|A2|A3|A4|A5|A6|A7|A8|A9|B1|B2|B3|B4|B5|B6|B8|B9|C$|C0|C1|C2|C3|C4|C5|
		C8|C[, _\-\t]+|F1|F2|H1|H2|P1|P2|P3|P4|P9|T1|T2|T3|T4|T5|T9|U0|U1|U2|U3|U4|
		U8|W1|W2|X0|X1|X2|Y1|Y2|Y3|Y4|Y5|Y6|Y8|

		a$|a[, _\-\t]+|b$|b[, _\-\t]+|d$|d[, _\-\t]+|e$|e[, _\-\t]+|h$|h[, _\-\t]+|
		l$|l[, _\-\t]+|m$|m[, _\-\t]+|o$|o[, _\-\t]+|p$|p[, _\-\t]+|s$|s[, _\-\t]+|
		t$|t[, _\-\t]+|u$|u[, _\-\t]+|w$|w[, _\-\t]+|x$|x[, _\-\t]+|y$|y[, _\-\t]+|
		z$|z[, _\-\t]+|
		a0|a1|a2|a3|a4|a5|a6|a7|a8|a9|b1|b2|b3|b4|b5|b6|b8|b9|c$|c0|c1|c2|c3|c4|c5|
		c8|c[, _\-\t]+|f1|f2|h1|h2|p1|p2|p3|p4|p9|t1|t2|t3|t4|t5|t9|u0|u1|u2|u3|u4|
		u8|w1|w2|x0|x1|x2|y1|y2|y3|y4|y5|y6|y8

		){0,1}
	              # kind code (eats up separator required before comment)
	(.*)     # comment (optional, if used, required to be preceded by at least one separator)
	/mx) {
		$country=$1; $country= uc $country;
		$type=$2; $type= uc $type;  #actually, required to be upper case
		if ($type eq '' and $country eq '') {$country='US'; }
		elsif ($type eq '' and $country ne 'US') {$type = $country; $country='US'}
		$number=$3; if ($number) {$number=~s/[, _\- ]//mxg; } else{print "\nno number!!!\n"}
		$kind=$4;  if ($kind) {$kind =~ s/[, _\- ]//mxg; }
		$comment=$5; if ($comment) {$comment =~ s/^[,_\- ]*//mxg; $comment =~ s/[,_\- ]*$//mxg; }
	}
	else {print "String '$target' NOT PARSED.\n"; $unparsed++; }
print " [ '$target','$country','$type','$number','$kind','$comment'] , \n" ;
($country,$type,$number,$kind,$comment)=(undef,undef,undef,undef,undef);
	}
print "Unparsed: $unparsed of $count (does not count the incorrectly parsed!)\n" ;