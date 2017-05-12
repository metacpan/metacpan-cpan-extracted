package Treemap::Simple;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw( Exporter );
our @EXPORT_OK = (  );
our @EXPORT = qw( );
our $VERSION = '0.01';


# ------------------------------------------
# Methods:
# ------------------------------------------


# ------------------------------------------
# new() - Create and return new Treemap object:
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

Goes here.
