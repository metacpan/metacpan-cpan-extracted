#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Mouse;

BEGIN {
    use_ok( 'WWW::Datafinder' ) || print "Bail out!\n";
}

my $class = 'WWW::Datafinder';
my $obj = new_ok( $class => [{
    api_key => $ENV{DATAFINDER_API_KEY} // 'abc'
   }]);

# attributes
foreach my $attr (qw(api_key cache_time cache_dir retries)) {
    has_attribute_ok( $class, $attr, $attr . ' attribute' );
}

# methods
foreach my $method (qw(append_email append_phone append_demograph error_message)) {
    can_ok( $obj, $method );
}

done_testing;
