package Unicode::Indic::Kannada;
use strict;
use Unicode::Indic::Phonetic;
our $VERSION = 0.01;
our @ISA = qw (Unicode::Indic::Phonetic);
use constant U => 0x0c80;
my $Map = {
  A	=>	chr(U+0x3e),
  B	=>	chr(U+0x2d),
  C	=>	chr(U+0x1b),
  Ch	=>	chr(U+0x1b),
  D	=>	chr(U+0x21),
  Dh	=>	chr(U+0x22),
  E	=>	chr(U+0x47),
  G	=>	chr(U+0x18),
  H	=>	chr(U+0x3),
  I	=>	chr(U+0x40),
  J	=>	chr(U+0x1d),
  K	=>	chr(U+0x16),
  L	=>	chr(U+0x33),
  M	=>	chr(U+0x2),
  N	=>	chr(U+0x23),
  O	=>	chr(U+0x4b),
  P	=>	chr(U+0x2b),
  R	=>	chr(U+0x43),
  Ri	=>	chr(U+0x43),
  Ru	=>	chr(U+0x43),
  RR	=>	chr(U+0x44),
  RI	=>	chr(U+0x44),
  RU	=>	chr(U+0x44),
  S	=>	chr(U+0x36),
  T	=>	chr(U+0x1f),
  Th	=>	chr(U+0x20),
  U	=>	chr(U+0x42),
  _A	=>	chr(U+0x6),
  _E	=>	chr(U+0xf),
  _I	=>	chr(U+0x8),
  _O	=>	chr(U+0x13),
  _R	=>	chr(U+0xb),
  _Ri	=>	chr(U+0xb),
  _Ru	=>	chr(U+0xb),
  _RR	=>	chr(U+0x60),
  _RI	=>	chr(U+0x60),
  _RU	=>	chr(U+0x60),
  _U	=>	chr(U+0xa),
  _a	=>	chr(U+0x5),
  _aa	=>	chr(U+0x6),
  _ai	=>	chr(U+0x10),
  _au	=>	chr(U+0x14),
  _e	=>	chr(U+0xe),
  _ee	=>	chr(U+0x8),
  _i	=>	chr(U+0x7),
  _ii	=>	chr(U+0x8),
  _o	=>	chr(U+0x12),
  _oo	=>	chr(U+0xa),
  _u	=>	chr(U+0x9),
  _uu	=>	chr(U+0xa),
  _ue   =>	chr(U+0xc),
  _ui   =>	chr(U+0x61),
  a	=>	0,
  aa	=>	chr(U+0x3e),
  ai	=>	chr(U+0x48),
  au    =>      chr(U+0x4c),
  b	=>	chr(U+0x2c),
  bh	=>	chr(U+0x2d),
  c	=>	chr(U+0x1a),
  ch	=>	chr(U+0x1a),
  d	=>	chr(U+0x26),
  dh	=>	chr(U+0x27),
  e	=>	chr(U+0x46),
  ee	=>	chr(U+0x40),
  f	=>	chr(U+0x28),
  g	=>	chr(U+0x17),
  gh	=>	chr(U+0x18),
  h	=>	chr(U+0x39),
  i	=>	chr(U+0x3f),
  ii	=>	chr(U+0x40),
  j	=>	chr(U+0x1c),
  jh	=>	chr(U+0x1d),
  k	=>	chr(U+0x15),
  kh	=>	chr(U+0x16),
  l	=>	chr(U+0x32),
  m	=>	chr(U+0x2e),
  n	=>	chr(U+0x28),
  o	=>	chr(U+0x4a),
  oo	=>	chr(U+0x42),
  p	=>	chr(U+0x2a),
  ph	=>	chr(U+0x2b),
  r	=>	chr(U+0x30),
  s	=>	chr(U+0x38),
  sh	=>	chr(U+0x37),
  t	=>	chr(U+0x24),
  th	=>	chr(U+0x25),
  u	=>	chr(U+0x41),
  uu	=>	chr(U+0x42),
  v	=>	chr(U+0x35),
  ue   =>	chr(U+0x4d).chr(U+0x32).chr(U+0x41), #chr(U+0x62)
  ui   =>	chr(U+0x4d).chr(U+0x32).chr(U+0x42), #chr(U+0x63)
  w	=>	chr(U+0x35),
  y	=>	chr(U+0x2f),
  '~L'	=>	chr(U+0x33), # Sane as L which is same as l.
  '~N'	=>	chr(U+0x23), # Same as N
  '~d'	=>	chr(U+0x21), # Same as D
  '~D'	=>	chr(U+0x22), # Same as Dh
  '~f'	=>	chr(U+0x28), # Sane as f
  '~g'	=>	chr(U+0x17), # Sane as g
  '~j'	=>	chr(U+0x1c), # Same as j
  '~k'	=>	chr(U+0x15), # Same as k
  '~K'	=>	chr(U+0x16), # Same as K
  '~y'	=>	chr(U+0x2f), # Same as y
  '~m'	=>	chr(U+0x19),
  '~n'	=>	chr(U+0x1e),
  '~r'	=>	chr(U+0x31),
  virama=>	chr(U+0x4d),
  base  =>      chr(U),
};

sub new{
  my $proto = shift;
  my $class = ref($proto)||$proto;

  my $self = { Map => $Map };
  bless $self, $class;
}
1;


__END__

=head1	NAME

	Unicode::Indic::Kannada -Perl module for the Kannada language.

=head1	SYNOPSIS

	use Unicode::Indic::Kannada;

=head1	DESCRIPTION

	This perl module is used for transliteration of text from qwerty keyboard characters to Unicode Kannada font characters and versa.

=head1	DIAGNOSTICS

	None!

head1  AUTHOR

	Syamala Tadigadapa
	
=head1  COPYRIGHT

	Copyright (c) 2003, Syamala Tadigadapa. All Rights Reserved.
 This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
     (see http://www.perl.com/perl/misc/Artistic.html)		
