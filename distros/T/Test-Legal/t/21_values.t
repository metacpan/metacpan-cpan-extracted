#use Test::t ;

use Test::More;
use Test::Legal;


*_values = \& Test::Legal::_values ;

my $dir     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';

my $required_keys = [qw/ base dirs meta/];
my @keys = qw/ base dirs meta/;


is_deeply [sort keys %{_values({base=>'.'})}] , $required_keys;
is_deeply [sort keys %{_values({base=>'.', dirs=>'t'})}] , $required_keys;
is_deeply [sort keys %{_values({a=>''})}] , [ 'a',@$required_keys];

my $give={base=>'.',dirs=>'t'} ; 
my $get ={ %$give, meta=> CPAN::Meta->load_file('META.yml') };
is_deeply _values( $give), $get ;

is_deeply [sort keys %{_values({})} ] , $required_keys;
is_deeply [sort keys %{_values()}   ] , $required_keys;

ok ! _values([]);

note 'with collector';
my $h = _values(  {a=>8, b=>9}, {a=>1, b=>2} );
delete @{$h}{qw/dirs meta base/};
is_deeply $h, {a=>8,b=>9} ;

$h = _values(  {a=>8 }, {a=>1, b=>2} );
delete @{$h}{qw/dirs meta base/};
is_deeply $h, {a=>8,b=>2} ;

$h = _values(  { }, {a=>1, b=>2} );
delete @{$h}{qw/dirs meta base/};
is_deeply $h, {a=>1,b=>2} ;

$h = _values(  {a=>8, b=>9 }, {} );
delete @{$h}{qw/dirs meta base/};
is_deeply $h, {a=>8,b=>9} ;

$h = _values(  {a=>8, b=>9 },  );
delete @{$h}{qw/dirs meta base/};
is_deeply $h, {a=>8,b=>9} ;

$h = _values(  {}, {}  );
delete @{$h}{qw/dirs meta base/};
is_deeply $h, {} ;

$h = _values(  );
delete @{$h}{qw/dirs meta base/};
is_deeply $h, {} ;

