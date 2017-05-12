# @(#) $Id$

use strict;
use warnings;

use Test::More;

my %processors;
BEGIN {
    foreach ( qw( XML::XPath XML::LibXML ) ) {
        eval "use $_";
        $processors{ $_ }++ unless $@;
    }
    plan skip_all => "no available xpath processors" unless %processors;
    plan tests => (4 + 30 * scalar(keys(%processors)));
}

BEGIN {
    use_ok( 'Test::XML::XPath' );
}

eval { like_xpath() };
like( $@, qr/^usage: /, 'like_xpath() no args failure' );
eval { like_xpath( '<foo />' ) };
like( $@, qr/^usage: /, 'like_xpath() 1 args failure' );
eval { like_xpath( undef, '/foo' ) };
like( $@, qr/^usage: /, 'like_xpath() undef first arg failure' );

run_the_tests_with( $_ )
    foreach keys %processors;

sub run_the_tests_with {
    my $class = shift;
    set_xpath_processor( $class );
    # Test everything mentioned in the docs...
    my $silly_xml =
      '<foo attrib="1"><bish><bosh args="42">pub</bosh></bish></foo>';
    my @tests = (
        [ '<foo/>',   '/foo',               1 ],
        [ '<foo/>',   '/bar',               0 ],
        [ '<foo/>',   '/bar',               0 ],
        [ $silly_xml, '/foo[@attrib="1"]',  1 ],
        [ $silly_xml, '//bosh',             1 ],
        [ $silly_xml, '//bosh[@args="42"]', 1 ],
        [ '<foo/>',   '/foo',               1 ],
        [ '<foo/>',   'foo',                1 ],
    );

    foreach my $t ( @tests ) {
        my $func = $t->[2] ? 'like_xpath' : 'unlike_xpath';
        my $name = "$func( $t->[0] => $t->[1] )";
        if ( $t->[2] ) {
            eval { like_xpath( $t->[0], $t->[1], "$name [$class]" ) };
        } else {
            eval { unlike_xpath( $t->[0], $t->[1], "$name [$class]" ) };
        }
        is( $@, '', "$name did not blow up [$class]" );
    }

    my @other_tests = (
        [ '<foo>bar</foo>', '/'                    => 'bar' ],
        [ '<foo>bar</foo>', '/foo'                 => 'bar' ],
        [ $silly_xml,       '/'                    => 'pub' ],
        [ $silly_xml,       '/foo/bish'            => 'pub' ],
        [ $silly_xml,       '/foo/bish/bosh'       => 'pub' ],
        [ $silly_xml,       '/foo/@attrib'         => '1' ],
        [ $silly_xml,       '/foo/bish/bosh/@args' => '42' ],
        # Uncomment this to see a sample failure.
        #[ '<foo>bar</foo>', '/bar'                 => 'foo' ],
    );

    foreach my $t ( @other_tests ) {
        eval { is_xpath( @$t, "is_xpath() $t->[1] is $t->[2] [$class]" ) };
        is( $@, '', "is_xpath() did not blow up [$class]" );
    }
}

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim: set ai et sw=4 syntax=perl :
