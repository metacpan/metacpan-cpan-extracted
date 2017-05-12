#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Mouse;

BEGIN {
    use_ok( 'WWW::KeenIO' ) || print "Bail out!\n";
}

my $class = 'WWW::KeenIO';
my $obj = new_ok( $class => [{
    project => $ENV{KEEN_PROJ_ID} // 1,
    api_key => $ENV{KEEN_API_KEY} // 'abc',
    write_key => $ENV{KEEN_API_WRITE_KEY} // 'xyz'
   }]);

# attributes
foreach my $attr (qw(api_key write_key project base_url)) {
    has_attribute_ok( $class, $attr, $attr . ' attribute' );
}

# methods
foreach my $method (qw(put select error_message filter)) {
    can_ok( $obj, $method );
}

done_testing;
