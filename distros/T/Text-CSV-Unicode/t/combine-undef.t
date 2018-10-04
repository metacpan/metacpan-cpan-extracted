use strict;
use warnings;
use Test::More tests => 4; 

require_ok( q(Text::CSV::Unicode) );

my $warn = q{};
$SIG{__WARN__} = sub { $warn .= $_[0]; };

my @array;
$array[1] = 'hello'; 
$array[3] = 'world'; 

my $csv = Text::CSV::Unicode->new( { always_quote => 1 } );
ok $csv->combine(@array), "combine with undef values"; 
is $csv->string, q{,"hello",,"world"}, 
	"combine with undef values - output";
is $warn, q{}, "combine with undef values - no warnings";

