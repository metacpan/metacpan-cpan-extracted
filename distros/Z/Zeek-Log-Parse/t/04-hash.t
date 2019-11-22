use 5.10.1;
use strict;
use warnings;

use Test::More tests=>8;

BEGIN { use_ok( 'Zeek::Log::Parse' ); }

my $parse = Zeek::Log::Parse->new({ file => 'logs/ssl.log' });
my $line = $parse->getLine();
is(scalar keys %$line, 20, "Number of entries");
is($line->{uid}, 'CXWv6p3arKYeMETxOg', "uid");

open(my $fh, '<', 'logs/ssl.log');
$parse = Zeek::Log::Parse->new({ fh => $fh });
$line = $parse->getLine();
is(scalar keys %$line, 20, "Number of entries");
is($line->{uid}, 'CXWv6p3arKYeMETxOg', "uid");
close($fh);

@ARGV = ( 'logs/ssl.log' );
$parse = Zeek::Log::Parse->new({ diamond => 1 });
$line = $parse->getLine();
is(scalar keys %$line, 20, "Number of entries");
is($line->{uid}, 'CXWv6p3arKYeMETxOg', "uid");

$@ = undef;
eval {
	$parse = Zeek::Log::Parse->new({ });
};
like($@, qr/^No filename given in constructor\./, "No file");
