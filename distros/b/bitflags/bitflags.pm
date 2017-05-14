package bitflags;

use strict;

my $i = .5;


sub import {
  my $self = shift;
  my $caller = (caller)[0];

  if ($_[0] =~ /^:start=(\^?)(\d+)$/) {
    if ($1) { $i = 2 ** ($2-1) }
    elsif ($2 & ($2 - 1)) {
      require Carp;
      Carp::croak("$2 is not a power of two");
    }
    else { $i = $2/2 }
    shift;
  }

  no strict 'refs';
  for (@_) {
    my $j = ($i *= 2);
    *{"${caller}::$_"} = sub () { $j };
  }
}


1;

__END__

=head1 NAME

bitflags - Perl module for generating bit flags

=head1 SYNOPSIS

  use bitflags qw( ALPHA BETA GAMMA DELTA );
  use bitflags qw( EPSILON ZETA ETA THETA );
  
  use bitflags qw( :start=2 BEE CEE DEE EEE EFF GEE );
  
  use bitflags qw( :start=^3 EIGHT SIXTEEN THIRTY_TWO );

=head1 DESCRIPTION

The C<bitflags> module allows you to form a set of unique bit flags, for ORing
together.  Think of the C<O_> constants you get from C<Fcntl>... that's the
idea.

Successive calls remember the previous power used, so you don't have to set a
starting number, or declare all the constants on one line.

If you do want to set a starting value, use the C<:start> flag as the first
argument in the import list.  If the flag is C<:start=NNN>, where C<NNN> is
some positive integer, that value is checked to ensure it's a power of two,
and that value is used as the starting value.  If it is not a power of two,
the program will croak.  If the flag is C<:start=^NNN>, where C<NNN> is some
positive integer, that value is the power of two to start with.

=head2 Implementation

The flags are created as C<()>-prototyped functions in the caller's package,
not unlike the C<constant> pragma.

=head1 AUTHOR

Jeff "C<japhy>" Pinyan.

URL: F<http://www.pobox.com/~japhy/>

Email: F<japhy@pobox.com>, F<PINYAN@cpan.org>

CPAN ID: C<PINYAN>

Online at: C<japhy> on C<#perl> on DALnet and EFnet.  C<japhy> at
F<http://www.perlguru.com/>.  C<japhy> at F<http://www.perlmonks.org/>.
"Coding With Style" column at F<http://www.perlmonth.com/>.

=cut
