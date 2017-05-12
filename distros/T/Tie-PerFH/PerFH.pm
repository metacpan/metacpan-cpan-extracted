package Tie::PerFH;

$VERSION = '1.00';

my %value;

sub TIESCALAR { bless \my $x, shift }
sub FETCH { $value{select()}{$_[0]} }
sub STORE { $value{select()}{$_[0]} = $_[1] }


1;

__END__

=head1 NAME

Tie::PerFH - creates scalars specific to a filehandle

=head1 SYNOPSIS

  use Tie::PerFH;
  use strict;

  tie my($font), 'Tie::PerFH';

  # $font is 'blue' when STDOUT is select()ed
  $font = "blue";

  select OTHER_FH;

  # $font is 'red' when OTHER_FH is select()ed
  $font = "red";

=head1 DESCRIPTION

This module creates scalars that hold different values depending on which
filehandle is selected (much like the format variables, and the autoflush
variable).

=head1 AUTHOR

  Jeff "japhy" Pinyan
  CPAN ID: PINYAN
  japhy@pobox.com
  http://www.pobox.com/~japhy/

=cut
