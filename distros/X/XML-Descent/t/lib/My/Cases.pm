package My::Cases;

use strict;
use warnings;

use Carp;
use XML::Descent;

use base qw( Exporter );
our @EXPORT = our @EXPORT_OK = qw( load_cases );

=head1 NAME

My::Cases - Load test cases from a chunk of data

=head2 C<load_cases>

Load cases from a filehandle.

=cut

sub load_cases {
  my $fh    = shift || \*main::DATA;
  my $cases = {};
  my $p     = XML::Descent->new( { Input => $fh } );
  $p->on(
    cases => sub {
      $p->on(
        case => sub {
          my ( $el, $at ) = @_;
          croak "Missing name on case"
           unless exists $at->{name};
          $cases->{ $at->{name} } = $p->xml;
        }
      )->walk;
    }
  )->walk;
  return $cases;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl
