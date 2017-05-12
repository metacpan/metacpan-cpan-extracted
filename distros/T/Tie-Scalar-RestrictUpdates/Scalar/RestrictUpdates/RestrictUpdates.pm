package Tie::Scalar::RestrictUpdates;

use strict;
use vars qw($VERSION);

$VERSION = '0.01';

sub TIESCALAR { 
my $proto = shift;
my $class = ref($proto) || $proto;
my $self = {};
$self->{_COUNTER} = 0; 
$self->{_VAR} = undef;
bless $self, $class; 
$self->{_COUNTER} = shift || 1; 
return $self;
}

sub STORE { 
my $self = shift; 
if ($self->{_COUNTER}) 
 { $self->{_VAR} = shift; $self->{_COUNTER}--; } 
 else { warn "Cannot set variable again!";  }
}

sub FETCH { my $self = shift; return $self->{_VAR}; }

1;
__END__
=head1 NAME

Tie::Scalar::RestrictUpdates - Limit the number of times a value is stored in a scalar.

=head1 SYNOPSIS

  use Tie::Scalar::RestrictUpdates;

  my $foo;
  tie $foo,"Tie::Scalar::RestrictUpdates",5;
  for(1..10) { $foo = $_; print $foo; }
  # This will print 1234555555

=head1 DESCRIPTION

This module limits the number of times a value can be stored in a scalar.

=head1 TODO

Loads probably. This is a very early draft.

=head1 DISCLAIMER

This code is released under GPL (GNU Public License). More information can be 
found on http://www.gnu.org/copyleft/gpl.html

=head1 VERSION

This is Tie::Scalar::RestrictUpdates 0.0.1.

=head1 AUTHOR

Hendrik Van Belleghem (beatnik@quickndirty.org)

=head1 SEE ALSO

GNU & GPL - http://www.gnu.org/copyleft/gpl.html

=cut
