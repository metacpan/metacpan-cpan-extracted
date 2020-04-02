#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2015 -- leonerd@leonerd.org.uk

package Tickit::Style::Parser;

use strict;
use warnings;
use base qw( Parser::MGC );

our $VERSION = '0.51';

use Struct::Dumb;

# Identifiers can include hyphens
use constant pattern_ident => qr/[A-Z0-9_-]+/i;

# Allow #-style line comments
use constant pattern_comment => qr/#.*\n/;

sub parse
{
   my $self = shift;
   $self->sequence_of( \&parse_def );
}

sub token_typename
{
   my $self = shift;
   $self->generic_token( typename => qr/(?:${\pattern_ident}::)*${\pattern_ident}/ );
}

struct Definition => [qw( type class tags style )];

sub parse_def
{
   my $self = shift;

   my $type = $self->token_typename;
   $self->commit;

   my $class;
   if( $self->maybe_expect( '.' ) ) {
      $class = $self->token_ident;
   }

   my %tags;
   while( $self->maybe_expect( ':' ) ) {
      $tags{$self->token_ident}++;
   }

   my %style;
   $self->scope_of(
      '{',
      sub { $self->sequence_of( sub {
         $self->any_of(
            sub {
               my $delete = $self->maybe_expect( '!' );
               my $key = $self->token_ident;
               $self->commit;

               $key =~ s/-/_/g;

               if( $delete ) {
                  $style{$key} = undef;
               }
               else {
                  $self->expect( ':' );
                  my $value = $self->any_of(
                     $self->can( "token_int" ),
                     $self->can( "token_string" ),
                     \&token_boolean,
                  );
                  $style{$key} = $value;
               }

            },
            sub {
               $self->expect( '<' ); $self->commit;
               my $key = $self->maybe_expect( '>' ) || $self->substring_before( '>' );
               $self->expect( '>' );

               $self->expect( ':' );

               $style{"<$key>"} = $self->token_ident;
            }
         );
         $self->expect( ';' );
      } ) },
      '}'
   );

   return Definition( $type, $class, \%tags, \%style );
}

sub token_boolean
{
   my $self = shift;
   return $self->token_kw(qw( true false )) eq "true";
}

0x55AA;
