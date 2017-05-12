package Test::XML;
# @(#) $Id$

use strict;
use warnings;

use Carp;
use Test::Builder;
use XML::SemanticDiff;
use XML::Parser;

our $VERSION = '0.08';

#---------------------------------------------------------------------
# Import shenanigans.  Copied from Test::Pod...
#---------------------------------------------------------------------

sub import {
    my $self   = shift;
    my $caller = caller;

    no strict 'refs';
    *{ $caller . '::is_xml' }             = \&is_xml;
    *{ $caller . '::isnt_xml' }           = \&isnt_xml;
    *{ $caller . '::is_well_formed_xml' } = \&is_well_formed_xml;
    *{ $caller . '::is_good_xml' }        = \&is_well_formed_xml;

    my $Test = Test::Builder->new;
    $Test->exported_to( $caller );
    $Test->plan( @_ );
}

#---------------------------------------------------------------------
# Tool.
#---------------------------------------------------------------------

sub is_xml {
    my ($input, $expected, $test_name) = @_;
    croak "usage: is_xml(input,expected,test_name)"
        unless defined $input && defined $expected;

    my $Test = Test::Builder->new;
    my $differ = XML::SemanticDiff->new;
    my @diffs = eval { $differ->compare( $expected, $input ) };
    if ( @diffs ) {
        $Test->ok( 0, $test_name );
        $Test->diag( "Found " . scalar(@diffs) . " differences with expected:" );
        $Test->diag( "  $_->{message}" ) foreach @diffs;
        $Test->diag( "in processed XML:\n  $input" );
	return 0;
    } elsif ( $@ ) {
        $Test->ok( 0, $test_name );
        # Make the output a bit more testable.
        $@ =~ s/ at \/.*//;
        $Test->diag( "During compare:$@" );
        return 0;
    } else {
        $Test->ok( 1, $test_name );
	return 1;
    }
}

sub isnt_xml {
    my ($input, $mustnotbe, $test_name) = @_;
    croak "usage: isnt_xml(input,mustnotbe,test_name)"
        unless defined $input && defined $mustnotbe;

    my $Test = Test::Builder->new;
    my $differ = XML::SemanticDiff->new;
    my @diffs = eval { $differ->compare( $mustnotbe, $input ) };
    if ( $@ ) {
        $Test->ok( 0, $test_name );
        # Make the output a bit more testable.
        $@ =~ s/ at \/.*//;
        $Test->diag( "During compare:$@" );
        return 0;
    } elsif ( @diffs == 0 ) {
        $Test->ok( 0, $test_name );
        $Test->diag( "Found no differences in processed XML:\n  $input" );
	return 0;
    } else {
        $Test->ok( 1, $test_name );
	return 1;
    }
}

sub is_well_formed_xml {
    my ($input, $test_name) = @_;
    croak "usage: is_well_formed_xml(input,test_name)"
        unless defined $input;

    my $Test = Test::Builder->new;
    my $parser = XML::Parser->new;
    eval { $parser->parse($input) };
    if ( $@ ) {
        $Test->ok( 0, $test_name );
        # Make the output a bit more testable.
        $@ =~ s/ at \/.*//;
        $Test->diag( "During parse: $@" );
        return 0;
    } else {
        $Test->ok( 1, $test_name );
        return 1;
    }
}

1;
__END__

=head1 NAME

Test::XML - Compare XML in perl tests

=head1 SYNOPSIS

  use Test::XML tests => 3;
  is_xml( '<foo />', '<foo></foo>' );   # PASS
  is_xml( '<foo />', '<bar />' );       # FAIL
  isnt_xml( '<foo />', '<bar />' );     # PASS
  is_well_formed_xml('<foo/>');               # PASS
  is_well_formed_xml('<foo>');                # FAIL

=head1 DESCRIPTION

This module contains generic XML testing tools.  See below for a list of
other modules with functions relating to specific XML modules.

=head1 FUNCTIONS

=over 4

=item is_xml ( GOT, EXPECTED [, TESTNAME ] )

This function compares GOT and EXPECTED, both of which are strings of
XML.  The comparison works semantically and will ignore differences in
syntax which are meaningless in xml, such as different quote characters
for attributes, order of attributes or empty tag styles.

Returns true or false, depending upon test success.

=item isnt_xml( GOT, MUST_NOT_BE [, TESTNAME ] )

This function is similiar to is_xml(), except that it will fail if GOT
and MUST_NOT_BE are identical.

=item is_well_formed_xml( XML [, TESTNAME ] )

This function determines whether or not a given XML string is parseable
as XML.

=item is_good_xml ( XML [, TESTNAME ] )

This is an alias for is_well_formed_xml().

=back

=head1 NOTES

There are several features of XML::SemanticDiff that may suprise you
if you are not aware of them.  In particular:

=over 4

=item *

Leading and trailing whitespace is always stripped, even in elements
with character content.

=item *

Whitespace inside character content is always stripped down to a single
space.

=item *

In mixed content elements (ie: an element with both text and elements
beneath it), all text is treated as a single value.

=item *

The order of elements is ignored.

=back

=head1 SEE ALSO

L<Test::XML::SAX>, L<Test::XML::Twig>.

L<Test::More>, L<XML::SemanticDiff>.

=head1 AUTHOR

Dominic Mitchell, E<lt>cpan2 (at) semantico.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by semantico

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim: set ai et sw=4 :
