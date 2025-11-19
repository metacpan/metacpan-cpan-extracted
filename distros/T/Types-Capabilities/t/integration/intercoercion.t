use Test2::V0;

use lib 't/lib';
use Types::Capabilities -all;

use Local::Example::Eachable;

my $list = Local::Example::Eachable->new( qw/ foo bar baz quux / );

ok ! is_Greppable( $list );

my $list2 = to_Greppable( $list );

ok is_Greppable( $list2 );

is $list2->grep(sub { length($_) == 4 }), ['quux'];

done_testing;
