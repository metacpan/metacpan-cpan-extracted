package Test::XML::SAX;
# @(#) $Id$

use strict;
use warnings;

use Carp;
use Test::More;
use Test::XML;
use Test::Builder;
use XML::SAX;
use XML::SAX::ParserFactory;
use XML::SAX::Writer;

our $VERSION = '0.01';

sub import {
    my $self   = shift;
    my $caller = caller;

    no strict 'refs';
    *{ $caller . '::test_sax' }             = \&test_sax;
    *{ $caller . '::test_all_sax_parsers' } = \&test_all_sax_parsers;

    my $Test = Test::Builder->new;
    $Test->exported_to( $caller );
    $Test->plan( @_ );
}

sub test_sax {
    my ( $handler, $input, $expected, $test_name ) = @_;
    croak "usage: test_sax(handler,input,expected,[test_name])"
        unless $handler && ref $handler && $input && $expected;

    my $Test = Test::Builder->new;
    my $result = '';
    eval {
        my $w = XML::SAX::Writer->new( Output => \$result );
        $handler->set_handler( $w );
        my $p = XML::SAX::ParserFactory->parser( Handler => $handler );
        $p->parse_string( $input );
    };
    if ( $@ ) {
        $Test->ok( 0, $test_name );
        $Test->diag( "Error during parse: $@" );
    }

    return is_xml( $result, $expected, $test_name );
}

sub test_all_sax_parsers {
    my ( $sub, $numtests ) = @_;
    croak "usage: test_all_sax_parsers(sub,[numtests])"
        unless $sub && ref($sub) eq 'CODE';

    my @parsers = map { $_->{Name} } @{ XML::SAX->parsers };
    plan tests => ($numtests * scalar( @parsers ) )
        if $numtests;

    # NB: Have to sort by shortest parser first so that
    # XML::SAX::ParserFactory
    # loads them all in correctly.
    foreach my $parser ( sort { length $a <=> length $b } @parsers ) {
        local $XML::SAX::ParserPackage = $parser;
        $sub->( $parser, $numtests );
    }
}

1;
__END__

=head1 NAME

Test::XML::SAX - Test XML::SAX handlers

=head1 SYNOPSIS

  use Test::XML::SAX tests => 1;
  use My::XML::Filter;

  my $handler = My::XML::Filter->new;
  test_sax( $handler, '<foo />', '<bar/>', 'translates foo to bar' );

  # ... In Another File ...

  use Test::XML::SAX; use My::XML::Filter;
  
  sub do_tests {
      my $handler = My::XML::Filter->new;
      test_sax( $handler, '<foo />', '<bar/>', 'translates foo to bar' );
  }

  test_all_sax_parsers( \&do_tests, 1 );

=head1 DESCRIPTION

This module is for testing XML::SAX handlers.

=head1 FUNCTIONS

All functions are exported.

=over 4

=item test_sax ( HANDLER, INPUT, EXPECTED [, TESTNAME ] )

This function will process INPUT using HANDLER, and compare the result
with EXPECTED.  TESTNAME can optionally be used to name the test in the
output (a good idea).

=item test_all_sax_parsers ( SUB [, NUMTESTS ] )

This function will repeat a set of tests for all installed SAX parsers.
SUB must be a coderef to run a series of tests.  NUMTESTS is the number
of tests inside SUB.

B<NB>: You must not issue a plan to Test::More if you call this
function!  The plan will be set for you, according to the number of
parsers installed and NUMTESTS.  This also means that you must not have
any tests outside of SUB or you will get an error.

When SUB is called, it will be passed two arguments.  The name of the
parser being used and the number of tests.  It can use this information
to decide whether or not to skip this set of tests.

=back

=head1 SEE ALSO

L<Test::More>, L<Test::XML>, L<XML::SAX>.

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
