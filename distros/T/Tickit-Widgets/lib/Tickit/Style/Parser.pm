#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2015 -- leonerd@leonerd.org.uk

use Object::Pad 0.09;

package Tickit::Style::Parser 0.51;
class Tickit::Style::Parser
   extends Parser::MGC;

use Struct::Dumb;

# Identifiers can include hyphens
use constant pattern_ident => qr/[A-Z0-9_-]+/i;

# Allow #-style line comments
use constant pattern_comment => qr/#.*\n/;

method parse
{
   $self->sequence_of( \&parse_def );
}

method token_typename
{
   # Also accept the generic "*" wildcard
   $self->generic_token( typename => qr/(?:${\pattern_ident}::)*${\pattern_ident}|\*/ );
}

struct Definition => [qw( type class tags style )];

method parse_def
{
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

method token_boolean
{
   return $self->token_kw(qw( true false )) eq "true";
}

0x55AA;
