package Test::XML::Twig;
# @(#) $Id$

use strict;
use warnings;

use Carp;
use Test::More;
use Test::XML;
use Test::Builder;
use XML::Twig;

our $VERSION = '0.01';

sub import {
    my $self   = shift;
    my $caller = caller;

    no strict 'refs';
    *{ $caller . '::get_twig' }           = \&get_twig;
    *{ $caller . '::test_twig_handler' }  = \&test_twig_handler;
    *{ $caller . '::test_twig_handlers' } = \&test_twig_handlers;

    my $Test = Test::Builder->new;
    $Test->exported_to( $caller );
    $Test->plan( @_ );
}

# Just a useful convenience function.
sub get_twig {
    my ( $input, %args ) = @_;
    croak "get_twig: no input provided"
        unless defined $input;
    my $t = XML::Twig->new( keep_spaces => 1, %args );
    eval { $t->parse( $input ) };
    return $@ ? undef: $t;
}

sub test_twig_handler {
    my ( $handler, $input, $expected, $test_name, $cond ) = @_;
    croak "usage: test_twig_handler(twig_args,input,expected,test_name[,cond])"
        unless $handler
            && ref($handler) eq 'CODE'
            && $input
            && $expected
            && $test_name;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $Test = Test::Builder->new;
    my $t = get_twig( $input );
    if ( $t ) {
        my $el = ( $cond ? $t->root->first_child( $cond ) : $t->root );
        eval { $handler->( $t, $el ) };
        if ( $@ ) {
            $Test->ok( 0, $test_name );
            $Test->diag( "handler said: $@" );
            return 0;
        } elsif ( ref $expected ) {
            return $Test->like( $t->sprint, $expected, $test_name );
        } else {
            return is_xml( $t->sprint, $expected, $test_name );
        }
    } else {
        $Test->ok( 0, $test_name );
        $Test->diag( "during parse of: '$input'$@" );
        return 0;
    }
}

# Test multiple twig handlers in combination.
sub test_twig_handlers {
    my ( $twig_args, $input, $expected, $test_name ) = @_;
    croak "usage: test_twig_handlers(twig_args,input,expected,test_name)"
        unless $twig_args
            && ref($twig_args) eq 'HASH'
            && $input
            && $expected
            && $test_name;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $Test = Test::Builder->new;
    my $t = get_twig( $input, %$twig_args );
    if ( $t ) {
        if (ref $expected) {
            return $Test->like( $t->sprint, $expected, $test_name );
        } else {
            return is_xml( $t->sprint, $expected, $test_name );
        }
    } else {
        $Test->ok( 0, $test_name );
        $Test->diag( "during parse of: '$input'$@" );
        return 0;
    }
}

1;
__END__

=head1 NAME

Test::XML::Twig - Test XML::Twig handlers

=head1 SYNOPSIS

  use Test::XML::Twig tests => 2;
  use My::Twig qw( handler );

  test_twig_handler(
      \&handler,
      '<foo/>', '<bar/>',
      'turns foo to bar',
  );

  test_twig_handlers(
      { twig_handlers => { 'foo' => \&handler } },
      '<foo/>', '<bar/>',
      'turns foo into bar',
  );

=head1 DESCRIPTION

This module is for testing XML::Twig handlers.

=head1 FUNCTIONS

All functions are exported.

=over 4

=item get_twig ( INPUT [, ARGS ] )

Return a parsed twig of INPUT, or undef on parse failure.  Optionally,
ARGS may be supplied as a set of hash-like parameters to be passed into
the twig constructor.

=item test_twig_handler ( HANDLER, INPUT, EXPECTED, TESTNAME [, COND ] )

Parse INPUT, using HANDLER as a I<twig_handler> (i.e: it gets called
after the parse tree has been built).  Tests that the result is the same
as EXPECTED (which can be either a string of XML or a quoted regex).
HANDLER must be a code ref.

Optionally, COND can be supplied.  Instead of the handler being called
with the root element of INPUT, COND will be used with first_child() to
select an alternative element.

Returns true / false depending upon test success.

=item test_twig_handlers ( ARGS, INPUT, EXPECTED, TESTNAME )

This is similiar to test_twig_handler(), but with more flexibility.  The
first argument, ARGS, is a hash reference which can be used to specify
any of the ordinary parameters to twig's constructor.  This lets you
test things like I<start_tag_handlers>, as well as multiple
I<twig_handler>s together.

=back

=head1 SEE ALSO

L<Test::More>, L<Test::XML>, L<XML::Twig>.

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
