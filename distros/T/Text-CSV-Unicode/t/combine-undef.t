use strict;
use Test::More; 

BEGIN{ 
    plan skip_all => 'charnames required' 
	unless eval{ require charnames }; 
    plan tests => 3;
}
use Text::CSV::Base;

my $warn = q{};
$SIG{__WARN__} = sub { $warn .= $_[0]; };

my @array;
$array[1] = 'hello'; 
$array[3] = 'world'; 

my $csv = Text::CSV::Base->new;
ok $csv->combine(@array), "combine with undef values"; 
is $csv->string, q{"","hello","","world"}, 
	"combine with undef values - output";
is $warn, q{}, "combine with undef values - no warnings";

