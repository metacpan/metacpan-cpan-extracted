use strict;
use warnings;
use oo_sub;     # tested module
use Test::More; # testing module, cf. Test Simple w/ just one 'ok' function

isa_ok getpwnam( 'root' ), 'User::pwent'; #	'getpwnam function returns an instance of User::pwent class';
isa_ok getgrgid( 0 ), 'User::grent';      #	'getgrgid function returns an instance of User::grent class';
isa_ok stat( '.' ), 'File::stat';         #	'stat function returns an instance of File::stat class';
isa_ok localtime, 'Time::Piece';
isa_ok getnetbyname( 'loopback' ), 'Net::netent';
isa_ok getprotobyname( 'tcp' ), 'Net::protoent';
isa_ok getservbyname( 'ftp' ), 'Net::servent';
isa_ok gethostbyname( 'localhost' ), 'Net::hostent';

done_testing;


__END__
