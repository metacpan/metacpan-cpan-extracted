#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk

package Test::Identity;

use strict;
use warnings;
use base qw( Test::Builder::Module );

use Scalar::Util qw( refaddr blessed );

our $VERSION = '0.01';

our @EXPORT = qw(
   identical
);

=head1 NAME

C<Test::Identity> - assert the referential identity of a reference

=head1 SYNOPSIS

 use Test::More tests => 2;
 use Test::Identity;

 use Thingy;

 {
    my $thingy;

    sub get_thingy { return $thingy }
    sub set_thingy { $thingy = shift; }
 }

 identical( get_thingy, undef, 'get_thingy is undef' );

 my $test_thingy = Thingy->new;
 set_thingy $test_thingy;

 identical( get_thingy, $thingy, 'get_thingy is now $test_thingy' );

=head1 DESCRIPTION

This module provides a single testing function, C<identical>. It asserts that
a given reference is as expected; that is, it either refers to the same object
or is C<undef>. It is similar to C<Test::More::is> except that it uses
C<refaddr>, ensuring that it behaves correctly even if the references under
test are objects that overload stringification or numification.

It also provides better diagnostics if the test fails:

 $ perl -MTest::More=tests,1 -MTest::Identity -e'identical [], {}'
 1..1
 not ok 1
 #   Failed test at -e line 1.
 # Expected an anonymous HASH ref, got an anonymous ARRAY ref
 # Looks like you failed 1 test of 1.

 $ perl -MTest::More=tests,1 -MTest::Identity -e'identical [], []'
 1..1
 not ok 1
 #   Failed test at -e line 1.
 # Expected an anonymous ARRAY ref to the correct object
 # Looks like you failed 1 test of 1.

=cut

=head1 FUNCTIONS

=cut

sub _describe
{
   my ( $ref ) = @_;

   if( !defined $ref ) {
      return "undef";
   }
   elsif( !refaddr $ref ) {
      return "a non-reference";
   }
   elsif( blessed $ref ) {
      return "a reference to a " . ref( $ref );
   }
   else {
      return "an anonymous " . ref( $ref ) . " ref";
   }
}

=head2 identical( $got, $expected, $name )

Asserts that $got refers to the same object as $expected.

=cut

sub identical($$;$)
{
   my ( $got, $expected, $name ) = @_;

   my $tb = __PACKAGE__->builder;

   my $got_desc = _describe $got;
   my $exp_desc = _describe $expected;

   # TODO: Consider if undef/undef ought to do this...
   if( $got_desc ne $exp_desc ) {
      $tb->ok( 0, $name );
      $tb->diag( "Expected $exp_desc, got $got_desc" );
      return 0;
   }

   if( !defined $got ) {
      # Two undefs
      $tb->ok( 1, $name );
      return 1;
   }

   my $got_addr = refaddr $got;
   my $exp_addr = refaddr $expected;

   if( $got_addr != $exp_addr ) {
      $tb->ok( 0, $name );
      $tb->diag( "Expected $exp_desc to the correct object" );
      return 0;
   }

   $tb->ok( 1, $name );
   return 1;
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
