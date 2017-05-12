package Treemap::Simple;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter Treemap);
our @EXPORT_OK = (  );
our @EXPORT = qw( );
our $VERSION = '0.01';


# ------------------------------------------
# Methods:
# ------------------------------------------


# ------------------------------------------
# new() - Create and return new Treemap 
#         object:
# ------------------------------------------
sub new 
{
   my $proto = shift;
   my $class = ref( $proto ) || $proto;
   my $self = {};

   bless $self, $class;
   return $self;
}

1;

__END__

# ------------------------------------------
# Documentation:
# ------------------------------------------

=head1 NAME

Treemap::Simple - Create Treemaps from arbitrary data. 

=head1 SYNOPSIS

  use Treemap;
  $tmap = Treemap->new();

=head1 DESCRIPTION

Create Treemaps from arbitrary data.  

=head2 EXPORT

None by default.

=head1 AUTHOR

 Simon Ditner, <simon@uc.org>
 Eric Maki, <eric@uc.org>

=head1 SEE ALSO

L<perl>.

=cut
