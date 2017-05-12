# @(#) $Id$

use strict;
use warnings;

use Test::More;

BEGIN {
    foreach ( qw( XML::SAX::Base XML::SAX::Writer ) ) {
        eval "use $_";
        plan skip_all => "$_ not present" if $@;
    }
}

use Test::XML::SAX;

# A Dummy SAX Filter.
{
    package My::XML::Filter;
    @My::XML::Filter::ISA = 'XML::SAX::Base';
    sub start_element {
        my ($self, $data) = @_;
        $data->{ Name }      =~ s/\bfoo\b/bar/;
        $data->{ LocalName } =~ s/\bfoo\b/bar/;
        $self->SUPER::start_element( $data );
    }
    sub end_element {
        my ($self, $data) = @_;
        $data->{ Name }      =~ s/\bfoo\b/bar/;
        $data->{ LocalName } =~ s/\bfoo\b/bar/;
        $self->SUPER::end_element( $data );
    }
}

test_all_sax_parsers( \&do_tests, 6 );

sub do_tests {
    my ($p, $numtests) = @_;
    my $handler = My::XML::Filter->new;

    # XXX These should really come seperately as they are not parser
    # specific...
    eval { test_sax() };
    like( $@, qr/^usage: /, 'test_sax() no args failure' );
    eval { test_sax( $handler ) };
    like( $@, qr/^usage: /, 'test_sax() 1 args failure' );
    eval { test_sax( $handler, '<foo/>' ) };
    like( $@, qr/^usage: /, 'test_sax() 2 args failure' );
    eval { test_sax( 'handler', '<foo/>', '<bar/>' ) };
    like( $@, qr/^usage: /, 'test_sax() 1st arg type failure' );

    test_sax( $handler, '<foo />', '<bar/>', "translates foo to bar ($p)" );
    test_sax( $handler, '<moo />', '<moo/>', "leaves moo alone ($p)" );
}

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim: set ai et sw=4 syntax=perl :
