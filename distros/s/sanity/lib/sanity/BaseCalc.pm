package  # hide from PAUSE
   sanity::BaseCalc;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.03'; # VERSION
# ABSTRACT: DO NOT USE!

use strict;
use Carp;
use Math::BigInt 1.78;  # 1.78 = round_mode => common
use Math::BigFloat;

# configure some basic big number stuff
Math::BigInt  ->config({
  upgrade    => 'Math::BigFloat',
  round_mode => 'common',
  trap_nan   => 1,
  trap_inf   => 1,
});
Math::BigFloat->config({
  round_mode => 'common',
  trap_nan   => 1,
  trap_inf   => 1,
});

sub new {
  my ($pack, %opts) = @_;
  my $self = bless {}, $pack;
  $self->{neg_char}   = $opts{neg_char}   || '-';
  $self->{radix_char} = $opts{radix_char} || '.';
  $opts{digits} = $_[1] if (@_ == 2);
  $self->digits($opts{digits});
  return $self;
}

sub digits {
  my $self = shift;
  return @{$self->{digits}} unless (@_);

  # Set the value
  if (ref $_[0] eq 'ARRAY') {
    $self->{digits} = [ @{ shift() } ];
    delete $self->{digitset_name};
  } else {
    my $name = shift;
    my %digitsets = $self->_digitsets;
    croak "Unrecognized digit set '$name'" unless exists $digitsets{$name};
    $self->{digits} = $digitsets{$name};
    $self->{digitset_name} = $name;
  }
  $self->{neg_char}   = '' if (grep { $_ eq $self->{neg_char}   } @{$self->{digits}});
  $self->{radix_char} = '' if (grep { $_ eq $self->{radix_char} } @{$self->{digits}});
  $self->{digit_strength} = log(scalar @{$self->{digits}}) / log(10);

  # Build the translation table back to numbers
  delete $self->{trans};
  @{$self->{trans}}{@{$self->{digits}}} = 0..$#{$self->{digits}};

  return @{$self->{digits}};
}


sub _digitsets {
  return (
      'bin' => [0,1],
      'hex' => [0..9,'a'..'f'],
      'HEX' => [0..9,'A'..'F'],
      'oct' => [0..7],
      '64'  => ['A'..'Z','a'..'z',0..9,'+','/'],
      '62'  => [0..9,'a'..'z','A'..'Z'],
     );
}

sub from_base {
  my ($self, $str) = @_;
  my ($nc, $fc) = @$self{qw(neg_char radix_char)};
  return $self->_from_accurate_return( Math::BigFloat->new( $self->from_base($str) )->bneg() )
    if $nc && $str =~ s/^\Q$nc\E//;  # Handle negative numbers

  # number clean up + decimal checks
  my $base = @{$self->{digits}};
  my $zero = $self->{digits}[0];
  my $is_dec = ($fc && $str =~ /\Q$fc\E/);
  $str =~ s/^\Q$zero\E+//;
  $str =~ s/\Q$zero\E+$// if ($is_dec);

  # num of digits + big number support
  my $poten_digits = int(length($str) * $self->{digit_strength}) + 16;
  Math::BigFloat->accuracy($poten_digits + 16);
  my $result = Math::BigFloat->new(0);
  $result = $result->as_int() unless $is_dec;

  # short-circuits
  unless ($is_dec || !$self->{digitset_name}) {
    $result = $result->from_hex(lc "0x$str") if ($self->{digitset_name} =~ /^hex$/i);
    $result = $result->from_bin(   "0b$str") if ($self->{digitset_name} eq 'bin');
    $result = $result->from_oct(lc  "0$str") if ($self->{digitset_name} eq 'oct');
  }

  if ($result == 0) {
    # num of digits (power)
    my $i = 0;
    $i = length($str)- 1;
    # decimal digits (yes, this removes the radix point, but $i captures the "digit location" information.)
    $i = length($1)  - 1 if ($fc && $str =~ s/^(.*)\Q$fc\E(.*)$/$1$2/);

    while ( $str =~ s/^(.)// ) {
      my $v = $self->{trans}{$1};
      croak "Invalid character $1 in string!" unless defined $v;

      my $exp = Math::BigInt->new($base);
      $result = $exp->bpow($i)->bmul($v)->badd($result);
      $i--;  # may go into the negative for non-ints
    }
  }

  return $self->_from_accurate_return($result);
}

sub _from_accurate_return {
  my ($self, $result) = @_;

  # never lose the accuracy
  my $rscalar = $result->numify();
  my $rstring = $result->bstr();
  $rstring =~ s/0+$// if ($rstring =~ /\./);
  $rstring =~ s/\.$//;  # float to whole number
  # (the user can choose to put the string in a Math object if s/he so wishes)
  return $rstring eq ($rscalar + 0 . '') ? $result->numify() : $rstring;
}

sub to_base {
  my ($self, $num) = @_;

  # decimal checks
  my $base = scalar @{$self->{digits}};
  my $is_dec = ($num =~ /\./) ? 1 : 0;
  $is_dec = 0 unless $self->{radix_char};
  my $zero = $self->{digits}[0];

  # num of digits + big number support
  my $poten_digits = length($num);
  Math::BigFloat->accuracy($poten_digits + 16);
  $num = Math::BigFloat->new($num);
  $num = $num->as_int() unless $is_dec && $self->{radix_char};

  # (hold off on this check until after the big number support)
  return $self->{neg_char}.$self->to_base( $num->bneg ) if $num < 0;  # Handle negative numbers

  # short-circuits
  return $zero if ($num == 0);  # this confuses log, so let's just get rid of this quick
  unless ($is_dec || !$self->{digitset_name}) {
     return substr(lc $num->as_hex(), 2) if ($self->{digitset_name} eq 'hex');
     return substr(uc $num->as_hex(), 2) if ($self->{digitset_name} eq 'HEX');
     return substr(   $num->as_bin(), 2) if ($self->{digitset_name} eq 'bin');
     return substr(   $num->as_oct(), 1) if ($self->{digitset_name} eq 'oct');
  }

  # get the largest power of Z (the highest digit)
  my $i = $num->copy()->blog(
    $base,
    int($num->length() / 9) + 2  # (an accuracy that is a little over the potential # of integer digits within log)
  )->bfloor()->numify();

  my $result = '';
  # BigFloat's accuracy should counter this, but the $i check is
  # to make sure we don't get into an irrational/cyclic number loop
  while (($num != 0 || $i >= 0) && $i > -1024) {
    my $exp = Math::BigFloat->new($base);
    $exp    = $i < 0 ? $exp->bpow($i) : $exp->as_int->bpow($i);
    my $v   = $num->copy()->bdiv($exp)->bfloor();
    $num   -= $v * $exp;  # this method is safer for fractionals

    $result .= $self->{radix_char} if ($i == -1);  # decimal point
    $result .= $self->{digits}[$v];

    $i--;  # may go into the negative for non-ints
  }

  # Final cleanup
  return $zero unless length $result;

  $result =~ s/^\Q$zero\E+//;
  $result =~ s/\Q$zero\E+$// if ($is_dec);

  return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

sanity::BaseCalc - DO NOT USE!

=head1 DESCRIPTION

This module is only temporary until Math::BaseCalc is fixed
(L<RT #77198|https://rt.cpan.org/Ticket/Display.html?id=77198> and
L<Pull Request #2|https://github.com/kenahoo/perl-math-basecalc/pull/2>).
Do NOT use for anything else, as it will go away soon.

=head1 SEE ALSO

L<Math::BaseCalc>

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/sanity>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/sanity/>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
