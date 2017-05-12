require XSTEST::RPCB1;

print "1..$last\n";  # $last is set below

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB1::rpcb_gettime( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 1\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 2\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB2::rpcb_gettime( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 3\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 4\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB3::rpcb_gettime( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 5\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 6\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB4::rpcb_gettime( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 7\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 8\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB5::rpcb_gettime( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 9\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 10\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB6::rpcb_gettime( $timep, 'localhost' );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 11\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 12\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB6::rpcb_gettime( $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 13\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 14\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB11::rpcb_gettime( $timep, 'localhost' );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 15\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 16\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB11::rpcb_gettime( $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 17\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 18\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB12::rpcb_gettime( $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 19\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 20\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB13::rpcb_gettime( $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 21\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 22\n" );

$status = 0;
$t1 = time;
($status, $timep) = XSTEST::RPCB14::rpcb_gettime("localhost");
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 23\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 24\n" );

$status = 0;
$t1 = time;
($status, $timep) = XSTEST::RPCB15::rpcb_gettime("localhost");
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 25\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 26\n" );

$t1 = time;
$timep = XSTEST::RPCB16::rpcb_gettime("localhost");
$t2 = time;
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 27\n" );

$timep = XSTEST::RPCB16::rpcb_gettime("no_such_host");
print( (( ! $timep )? "ok" : "not ok"), " 28\n" );

$timep = XSTEST::RPCB17::rpcb_gettime("no_such_host");
print( (( ! $timep )? "ok" : "not ok"), " 29\n" );

$t1 = time;
$timep = XSTEST::RPCB18::rpcb_gettime("localhost");
$t2 = time;
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 30\n" );

$timep = XSTEST::RPCB18::rpcb_gettime("no_such_host");
print( (( ! $timep )? "ok" : "not ok"), " 31\n" );

$netconf1 = RPC::getnetconfigent();
print( ((defined $netconf1)? "ok" : "not ok"), " 32\n" );
$t1 = time;
$timep = RPC::rpcb_gettime();
$t2 = time;
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 33\n" );

$netconf2 = RPC::getnetconfigent('tcp');
print( ((defined $netconf2)? "ok" : "not ok"), " 34\n" );
$t1 = time;
$timep = RPC::rpcb_gettime('localhost');
$t2 = time;
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 35\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB19::rpcb_gettime( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 36\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 37\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB20::rpcb_gettime( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 38\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 39\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB21::rpcb_gettime( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 40\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 41\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB22::rpcb_gettime( $timep, 'localhost' );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 42\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 43\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB22::rpcb_gettime( $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 44\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 45\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB23::rpcb_gettime( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 46\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 47\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = FOO::gettime( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 48\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 49\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = BAR::getit( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 50\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 51\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB24::rpcb_gettime( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 52\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 53\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB25::rpcb_gettime( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 54\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 55\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB26::rpcb_gettime( "localhost", $timep );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 56\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 57\n" );

$status = 0;
$t1 = time;
$timep = 0;
$status = XSTEST::RPCB26::x_gettime( $timep, "localhost" );
$t2 = time;
print( (($status == 1)? "ok" : "not ok"), " 58\n" );
print( (($timep >= $t1 and $timep <= $t2)? "ok" : "not ok"), " 59\n" );

BEGIN { $last = 59 }
