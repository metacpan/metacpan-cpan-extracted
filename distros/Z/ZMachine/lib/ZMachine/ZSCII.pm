package ZMachine::ZSCII 0.005;
use 5.14.0;
use warnings;
# ABSTRACT: an encoder/decoder for Z-Machine text

use Carp ();
use charnames ':full';

#pod =head1 OVERVIEW
#pod
#pod ZMachine::ZSCII is a class for objects that are encoders/decoders of Z-Machine
#pod text.  Right now, ZMachine::ZSCII only implements Version 5 (and thus 7 and 8),
#pod and even that partially.  There is no abbreviation support yet.
#pod
#pod =head2 How Z-Machine Text Works
#pod
#pod The Z-Machine's text strings are composed of ZSCII characters.  There are 1024
#pod ZSCII codepoints, although only bottom eight bits worth are ever used.
#pod Codepoints 0x20 through 0x7E are identical with the same codepoints in ASCII or
#pod Unicode.
#pod
#pod ZSCII codepoints are then encoded as strings of five-bit Z-characters.  The
#pod most common ZSCII characters, the lowercase English alphabet, can be encoded
#pod with one Z-character.  Uppercase letters, numbers, and common punctuation
#pod ZSCII characters require two Z-characters each.  Any other ZSCII character can
#pod be encoded with four Z-characters.
#pod
#pod For storage on disk or in memory, the five-bit Z-characters are packed
#pod together, three in a word, and laid out in bytestrings.  The last word in a
#pod string has its top bit set to mark the ending.  When a bytestring would end
#pod with out enough Z-characters to pack a full word, it is padded.
#pod (ZMachine::ZSCII pads with Z-character 0x05, a shift character.)
#pod
#pod Later versions of the Z-Machine allow the mapping of ZSCII codepoints to
#pod Unicode codepoints to be customized.  ZMachine::ZSCII does not yet support this
#pod feature.
#pod
#pod ZMachine::ZSCII I<does> allow conversion between all four relevant
#pod representations:  Unicode text, ZSCII text, Z-character strings, and packed
#pod Z-character bytestrings.  All four forms are represented by Perl strings.
#pod
#pod =cut

my %DEFAULT_ZSCII = (
  chr(0x00) => "\N{NULL}",
  chr(0x08) => "\N{DELETE}",
  chr(0x0D) => "\x0D",
  chr(0x1B) => "\N{ESCAPE}",

  (map {; chr $_ => chr $_ } (0x20 .. 0x7E)), # ASCII maps over

  # 0x09B - 0x0FB are the "extra characters" and need Unicode translation table
  # 0x0FF - 0x3FF are undefined and never (?) used
);

# We can use these characters below because they all (save for the magic A2-C6)
# are the same in Unicode/ASCII/ZSCII. -- rjbs, 2013-01-18
my $DEFAULT_ALPHABET = join(q{},
  'a' .. 'z', # A0
  'A' .. 'Z', # A1
  (           # A2
    "\0", # special: read 2 chars for 10-bit zscii character
    "\x0D",
    (0 .. 9),
    do { no warnings 'qw'; qw[ . , ! ? _ # ' " / \ - : ( ) ] },
  ),
);

my @DEFAULT_EXTRA = map chr hex, qw(
  E4 F6 FC C4 D6 DC DF BB       AB EB EF FF CB CF E1 E9
  ED F3 FA FD C1 C9 CD D3       DA DD E0 E8 EC F2 F9 C0
  C8 CC D2 D9

  E2 EA EE F4 FB C2 CA CE       D4 DB E5 C5 F8 D8 E3 F1
  F5 C3 D1 D5 E6 C6 E7 C7       FE F0 DE D0 A3 153 152 A1
  BF
);

sub _validate_alphabet {
  my (undef, $alphabet) = @_;

  Carp::croak("alphabet table was not 78 entries long")
    unless length $alphabet == 78;

  Carp::carp("alphabet character 52 not set to 0x000")
    unless substr($alphabet, 52, 1) eq chr(0);

  Carp::croak("alphabet table contains characters over 0xFF")
    if grep {; ord > 0xFF } split //, $alphabet;
}

sub _shortcuts_for {
  my ($self, $alphabet) = @_;

  $self->_validate_alphabet($alphabet);

  my %shortcut = (q{ } => chr(0));

  for my $i (0 .. 2) {
    my $offset = $i * 26;
    my $prefix = $i ? chr(0x03 + $i) : '';

    for my $j (0 .. 25) {
      next if $i == 2 and $j == 0; # that guy is magic! -- rjbs, 2013-01-18

      $shortcut{ substr($alphabet, $offset + $j, 1) } = $prefix . chr($j + 6);
    }
  }

  return \%shortcut;
}

#pod =method new
#pod
#pod   my $z = ZMachine::ZSCII->new;
#pod   my $z = ZMachine::ZSCII->new(\%arg);
#pod   my $z = ZMachine::ZSCII->new($version);
#pod
#pod This returns a new codec.  If the only argument is a number, it is treated as a
#pod version specification.  If no arguments are given, a Version 5 codec is made.
#pod
#pod Valid named arguments are:
#pod
#pod =begin :list
#pod
#pod = version
#pod
#pod The number of the Z-Machine targeted; at present, only 5, 7, or 8 are permitted
#pod values.
#pod
#pod = extra_characters
#pod
#pod This is a reference to an array of between 0 and 97 Unicode characters.  These
#pod will be the characters to which ZSCII characters 155 through 251.  They may not
#pod duplicate any characters represented by the default ZSCII set.  No Unicode
#pod codepoint above U+FFFF is permitted, as it would not be representable in the
#pod Z-Machine Unicode substitution table.
#pod
#pod If no extra characters are given, the default table is used.
#pod
#pod = alphabet
#pod
#pod This is a string of 78 characters, representing the three 26-character
#pod alphabets used to encode ZSCII compactly into Z-characters.  The first 26
#pod characters are alphabet 0, for the most common characters.  The rest of the
#pod characters are alphabets 1 and 2.
#pod
#pod No character with a ZSCII value greater than 0xFF may be included in the
#pod alphabet.  Character 52 (A2's first character) should be NUL.
#pod
#pod If no alphabet is given, the default alphabet is used.
#pod
#pod = alphabet_is_unicode
#pod
#pod By default, the values in the C<alphabet> are assumed to be ZSCII characters,
#pod so that the contents of the alphabet table from the Z-Machine's memory can be
#pod used directly.  The C<alphabet_is_unicode> option specifies that the characters
#pod in the alphabet string are Unicode characters.  They will be converted to ZSCII
#pod internally by the C<unicode_to_zscii> method, and if characters appear in the
#pod alphabet that are not in the default ZSCII set or the extra characters, an
#pod exception will be raised.
#pod
#pod =end :list
#pod
#pod =cut

sub new {
  my ($class, $arg) = @_;

  if (! defined $arg) {
    $arg = { version => 5 };
  } if (! ref $arg) {
    $arg = { version => $arg };
  }

  my $guts = { version => $arg->{version} };

  Carp::croak("only Version 5, 7, and 8 ZSCII are supported at present")
    unless $guts->{version} == 5
        or $guts->{version} == 7
        or $guts->{version} == 8;

  $guts->{zscii} = { %DEFAULT_ZSCII };

  # Why is this an arrayref and not, like alphabets, a string?
  # Alphabets are strings because they're guaranteed to fit in bytestrings.
  # You can't put a ZSCII character over 0xFF in the alphabet, because it can't
  # be put in the story file's alphabet table!  By using a string, it's easy to
  # just pass in the alphabet from memory to/from the codec.  On the other
  # hand, the Unicode translation table stores Unicode codepoint values packed
  # into words, and it's not a good fit for use in the codec.  Maybe a
  # ZMachine::Util will be useful for packing/unpacking Unicode translation
  # tables.
  $guts->{extra} = $arg->{extra_characters}
                || \@DEFAULT_EXTRA;

  Carp::confess("Unicode translation table exceeds maximum length of 97")
    if @{ $guts->{extra} } > 97;

  for (0 .. $#{ $guts->{extra} }) {
    Carp::confess("tried to add ambiguous Z->U mapping")
      if exists $guts->{zscii}{ chr(155 + $_) };

    my $u_char = $guts->{extra}[$_];

    # Extra characters must go into the Unicode substitution table, which can
    # only represent characters with codepoints between 0 and 0xFFFF.  See
    # Z-Machine Spec v1.1 § 3.8.4.2.1
    Carp::confess("tried to add Unicode codepoint greater than U+FFFF")
      if ord($u_char) > 0xFFFF;

    $guts->{zscii}{ chr(155 + $_) } = $u_char;
  }

  $guts->{zscii_for} = { };
  for my $zscii_char (sort keys %{ $guts->{zscii} }) {
    my $unicode_char = $guts->{zscii}{$zscii_char};

    Carp::confess("tried to add ambiguous U->Z mapping")
      if exists $guts->{zscii_for}{ $unicode_char };

    $guts->{zscii_for}{ $unicode_char } = $zscii_char;
  }

  my $self = bless $guts => $class;

  # The default alphabet is entirely made up of characters that are the same in
  # Unicode and ZSCII.  If a user wants to put "extra characters" into the
  # alphabet table, though, the alphabet should contain ZSCII values.  When
  # we're building a ZMachine::ZSCII using the contents of the story file's
  # alphabet table, that's easy.  If we're building a codec to *produce* a
  # story file, it's less trivial, because we don't want to think about the
  # specific ZSCII codepoints for the Unicode text we'll encode.
  #
  # We provide alphabet_is_unicode to let the user say "my alphabet is supplied
  # in Unicode, please convert it to ZSCII during construction." -- rjbs,
  # 2013-01-19
  my $alphabet = $arg->{alphabet} || $DEFAULT_ALPHABET;

  # It's okay if the user supplies alphabet_is_unicode but not alphabet,
  # because the default alphabet is all characters with the same value in both
  # character sets! -- rjbs, 2013-01-20
  $alphabet = $self->unicode_to_zscii($alphabet)
    if $arg->{alphabet_is_unicode};

  $self->{alphabet} = $alphabet;
  $self->{shortcut} = $class->_shortcuts_for( $self->{alphabet} );

  return $self;
}

#pod =method encode
#pod
#pod   my $packed_zchars = $z->encode( $unicode_text );
#pod
#pod This method takes a string of text and encodes it to a bytestring of packed
#pod Z-characters.
#pod
#pod Internally, it converts the Unicode text to ZSCII, then to Z-characters, and
#pod then packs them.  Before this processing, any native newline characters (the
#pod value of C<\n>) are converted to C<U+000D> to match the Z-Machine's use of
#pod character 0x00D for newline.
#pod
#pod =cut

sub encode {
  my ($self, $string) = @_;

  $string =~ s/\n/\x0D/g;

  my $zscii  = $self->unicode_to_zscii($string);
  my $zchars = $self->zscii_to_zchars($zscii);

  return $self->pack_zchars($zchars);
}

#pod =method decode
#pod
#pod   my $text = $z->decode( $packed_zchars );
#pod
#pod This method takes a bytestring of packed Z-characters and returns a string of
#pod text.
#pod
#pod Internally, it unpacks the Z-characters, converts them to ZSCII, and then
#pod converts those to Unicode.  Any ZSCII characters 0x00D are converted to the
#pod value of C<\n>.
#pod
#pod =cut

sub decode {
  my ($self, $bytestring) = @_;

  my $zchars  = $self->unpack_zchars( $bytestring );
  my $zscii   = $self->zchars_to_zscii( $zchars );
  my $unicode = $self->zscii_to_unicode( $zscii );

  $unicode =~ s/\x0D/\n/g;

  return $unicode;
}

#pod =method unicode_to_zscii
#pod
#pod   my $zscii_string = $z->unicode_to_zscii( $unicode_string );
#pod
#pod This method converts a Unicode string to a ZSCII string, using the dialect of
#pod ZSCII for the ZMachine::ZSCII's configuration.
#pod
#pod If the Unicode input contains any characters that cannot be mapped to ZSCII, an
#pod exception is raised.
#pod
#pod =cut

sub unicode_to_zscii {
  my ($self, $unicode_text) = @_;

  my $zscii = '';
  for (0 .. length($unicode_text) - 1) {
    my $char = substr $unicode_text, $_, 1;

    Carp::croak(
      sprintf "no ZSCII character available for Unicode U+%v05X <%s>",
        $char,
        charnames::viacode(ord $char),
    ) unless defined( my $zscii_char = $self->{zscii_for}{ $char } );

    $zscii .= $zscii_char;
  }

  return $zscii;
}

#pod =method zscii_to_unicode
#pod
#pod   my $unicode_string = $z->zscii_to_unicode( $zscii_string );
#pod
#pod This method converts a ZSCII string to a Unicode string, using the dialect of
#pod ZSCII for the ZMachine::ZSCII's configuration.
#pod
#pod If the ZSCII input contains any characters that cannot be mapped to Unicode, an
#pod exception is raised.  I<In the future, it may be possible to request a Unicode
#pod replacement character instead.>
#pod
#pod =cut

sub zscii_to_unicode {
  my ($self, $zscii) = @_;

  my $unicode = '';
  for (0 .. length($zscii) - 1) {
    my $char = substr $zscii, $_, 1;

    Carp::croak(
      sprintf "no Unicode character available for ZSCII %#v05x", $char,
    ) unless defined(my $unicode_char = $self->{zscii}{ $char });

    $unicode .= $unicode_char;
  }

  return $unicode;
}

#pod =method zscii_to_zchars
#pod
#pod   my $zchars = $z->zscii_to_zchars( $zscii_string );
#pod
#pod Given a string of ZSCII characters, this method will return a (unpacked) string
#pod of Z-characters.
#pod
#pod It will raise an exception on ZSCII codepoints that cannot be represented as
#pod Z-characters, which should not be possible with legal ZSCII.
#pod
#pod =cut

sub zscii_to_zchars {
  my ($self, $zscii) = @_;

  return '' unless length $zscii;

  my $zchars = '';
  for (0 .. length($zscii) - 1) {
    my $zscii_char = substr($zscii, $_, 1);
    if (defined (my $shortcut = $self->{shortcut}{ $zscii_char })) {
      $zchars .= $shortcut;
      next;
    }

    my $ord = ord $zscii_char;

    if ($ord >= 1024) {
      Carp::croak(
        sprintf "can't encode ZSCII codepoint %#v05x in Z-characters",
          $zscii_char
      );
    }

    my $top = ($ord & 0b1111100000) >> 5;
    my $bot = ($ord & 0b0000011111);

    $zchars .= "\x05\x06"; # The escape code for a ten-bit ZSCII character.
    $zchars .= chr($top) . chr($bot);
  }

  return $zchars;
}

#pod =method zchars_to_zscii
#pod
#pod   my $zscii = $z->zchars_to_zscii( $zchars_string, \%arg );
#pod
#pod Given a string of (unpacked) Z-characters, this method will return a string of
#pod ZSCII characters.
#pod
#pod It will raise an exception when the right thing to do can't be determined.
#pod Right now, that could mean lots of things.
#pod
#pod Valid arguments are:
#pod
#pod =begin :list
#pod
#pod = allow_early_termination
#pod
#pod If C<allow_early_termination> is true, no exception is thrown if the
#pod Z-character string ends in the middle of a four z-character sequence.  This is
#pod useful when dealing with dictionary words.
#pod
#pod =end :list
#pod
#pod =cut

sub zchars_to_zscii {
  my ($self, $zchars, $arg) = @_;
  $arg ||= {};

  my $text = '';
  my $alphabet = 0;

  while (length( my $char = substr $zchars, 0, 1, '')) {
    my $ord = ord $char;

    if ($ord == 0) { $text .= q{ }; next; }

    if    ($ord == 0x04) { $alphabet = 1; next }
    elsif ($ord == 0x05) { $alphabet = 2; next }

    if ($alphabet == 2 && $ord == 0x06) {
      my $next_two = substr $zchars, 0, 2, '';
      if (length $next_two != 2) {
        last if $arg->{allow_early_termination};
        Carp::croak("ten-bit ZSCII encoding segment terminated early")
      }

      my $value = ord(substr $next_two, 0, 1) << 5
                | ord(substr $next_two, 1, 1);

      $text .= chr $value;
      $alphabet = 0;
      next;
    }

    if ($ord >= 0x06 && $ord <= 0x1F) {
      $text .= substr $self->{alphabet}, (26 * $alphabet) + $ord - 6, 1;
      $alphabet = 0;
      next;
    }

    Carp::croak("unknown zchar <$char> encountered in alphabet <$alphabet>");
  }

  return $text;
}

#pod =method make_dict_length
#pod
#pod   my $zchars = $z->make_dict_length( $zchars_string )
#pod
#pod This method returns the Z-character string fit to dictionary length for the
#pod Z-machine version being handled.  It will trim excess characters or pad with
#pod Z-character 5 to be the right length.
#pod
#pod When converting such strings back to ZSCII, you should pass the
#pod C<allow_early_termination> to C<zchars_to_zscii>, as a four-Z-character
#pod sequence may have been terminated early.
#pod
#pod =cut

sub make_dict_length {
  my ($self, $zchars) = @_;

  my $length = $self->{version} >= 5 ? 9 : 6;
  $zchars = substr $zchars, 0, $length;
  $zchars .= "\x05" x ($length - length($zchars));

  return $zchars;
}

#pod =method pack_zchars
#pod
#pod   my $packed_zchars = $z->pack_zchars( $zchars_string );
#pod
#pod This method takes a string of unpacked Z-characters and packs them into a
#pod bytestring with three Z-characters per word.  The final word will have its top
#pod bit set.
#pod
#pod =cut

sub pack_zchars {
  my ($self, $zchars) = @_;

  my $bytestring = '';

  while (my $substr = substr $zchars, 0, 3, '') {
    $substr .= chr(5) until length $substr == 3;

    my $value = ord(substr($substr, 0, 1)) << 10
              | ord(substr($substr, 1, 1)) <<  5
              | ord(substr($substr, 2, 1));

    $value |= (0x8000) if ! length $zchars;

    $bytestring .= pack 'n', $value;
  }

  return $bytestring;
}

#pod =method unpack_zchars
#pod
#pod   my $zchars_string = $z->pack_zchars( $packed_zchars );
#pod
#pod Given a bytestring of packed Z-characters, this method will unpack them into a
#pod string of unpacked Z-characters that aren't packed anymore because they're
#pod unpacked instead of packed.
#pod
#pod Exceptions are raised if the input bytestring isn't made of an even number of
#pod octets, or if the string continues past the first word with its top bit set.
#pod
#pod =cut

sub unpack_zchars {
  my ($self, $bytestring) = @_;

  Carp::croak("bytestring of packed zchars is not an even number of bytes")
    if length($bytestring) % 2;

  my $terminate;
  my $zchars = '';
  while (my $word = substr $bytestring, 0, 2, '') {
    # XXX: Probably allow this to warn and `last` -- rjbs, 2013-01-18
    Carp::croak("input continues after terminating byte") if $terminate;

    my $n = unpack 'n', $word;
    $terminate = $n & 0x8000;

    my $c1 = chr( ($n & 0b0111110000000000) >> 10 );
    my $c2 = chr( ($n & 0b0000001111100000) >>  5 );
    my $c3 = chr( ($n & 0b0000000000011111)       );

    $zchars .= "$c1$c2$c3";
  }

  return $zchars;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZMachine::ZSCII - an encoder/decoder for Z-Machine text

=head1 VERSION

version 0.005

=head1 OVERVIEW

ZMachine::ZSCII is a class for objects that are encoders/decoders of Z-Machine
text.  Right now, ZMachine::ZSCII only implements Version 5 (and thus 7 and 8),
and even that partially.  There is no abbreviation support yet.

=head2 How Z-Machine Text Works

The Z-Machine's text strings are composed of ZSCII characters.  There are 1024
ZSCII codepoints, although only bottom eight bits worth are ever used.
Codepoints 0x20 through 0x7E are identical with the same codepoints in ASCII or
Unicode.

ZSCII codepoints are then encoded as strings of five-bit Z-characters.  The
most common ZSCII characters, the lowercase English alphabet, can be encoded
with one Z-character.  Uppercase letters, numbers, and common punctuation
ZSCII characters require two Z-characters each.  Any other ZSCII character can
be encoded with four Z-characters.

For storage on disk or in memory, the five-bit Z-characters are packed
together, three in a word, and laid out in bytestrings.  The last word in a
string has its top bit set to mark the ending.  When a bytestring would end
with out enough Z-characters to pack a full word, it is padded.
(ZMachine::ZSCII pads with Z-character 0x05, a shift character.)

Later versions of the Z-Machine allow the mapping of ZSCII codepoints to
Unicode codepoints to be customized.  ZMachine::ZSCII does not yet support this
feature.

ZMachine::ZSCII I<does> allow conversion between all four relevant
representations:  Unicode text, ZSCII text, Z-character strings, and packed
Z-character bytestrings.  All four forms are represented by Perl strings.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 new

  my $z = ZMachine::ZSCII->new;
  my $z = ZMachine::ZSCII->new(\%arg);
  my $z = ZMachine::ZSCII->new($version);

This returns a new codec.  If the only argument is a number, it is treated as a
version specification.  If no arguments are given, a Version 5 codec is made.

Valid named arguments are:

=over 4

=item version

The number of the Z-Machine targeted; at present, only 5, 7, or 8 are permitted
values.

=item extra_characters

This is a reference to an array of between 0 and 97 Unicode characters.  These
will be the characters to which ZSCII characters 155 through 251.  They may not
duplicate any characters represented by the default ZSCII set.  No Unicode
codepoint above U+FFFF is permitted, as it would not be representable in the
Z-Machine Unicode substitution table.

If no extra characters are given, the default table is used.

=item alphabet

This is a string of 78 characters, representing the three 26-character
alphabets used to encode ZSCII compactly into Z-characters.  The first 26
characters are alphabet 0, for the most common characters.  The rest of the
characters are alphabets 1 and 2.

No character with a ZSCII value greater than 0xFF may be included in the
alphabet.  Character 52 (A2's first character) should be NUL.

If no alphabet is given, the default alphabet is used.

=item alphabet_is_unicode

By default, the values in the C<alphabet> are assumed to be ZSCII characters,
so that the contents of the alphabet table from the Z-Machine's memory can be
used directly.  The C<alphabet_is_unicode> option specifies that the characters
in the alphabet string are Unicode characters.  They will be converted to ZSCII
internally by the C<unicode_to_zscii> method, and if characters appear in the
alphabet that are not in the default ZSCII set or the extra characters, an
exception will be raised.

=back

=head2 encode

  my $packed_zchars = $z->encode( $unicode_text );

This method takes a string of text and encodes it to a bytestring of packed
Z-characters.

Internally, it converts the Unicode text to ZSCII, then to Z-characters, and
then packs them.  Before this processing, any native newline characters (the
value of C<\n>) are converted to C<U+000D> to match the Z-Machine's use of
character 0x00D for newline.

=head2 decode

  my $text = $z->decode( $packed_zchars );

This method takes a bytestring of packed Z-characters and returns a string of
text.

Internally, it unpacks the Z-characters, converts them to ZSCII, and then
converts those to Unicode.  Any ZSCII characters 0x00D are converted to the
value of C<\n>.

=head2 unicode_to_zscii

  my $zscii_string = $z->unicode_to_zscii( $unicode_string );

This method converts a Unicode string to a ZSCII string, using the dialect of
ZSCII for the ZMachine::ZSCII's configuration.

If the Unicode input contains any characters that cannot be mapped to ZSCII, an
exception is raised.

=head2 zscii_to_unicode

  my $unicode_string = $z->zscii_to_unicode( $zscii_string );

This method converts a ZSCII string to a Unicode string, using the dialect of
ZSCII for the ZMachine::ZSCII's configuration.

If the ZSCII input contains any characters that cannot be mapped to Unicode, an
exception is raised.  I<In the future, it may be possible to request a Unicode
replacement character instead.>

=head2 zscii_to_zchars

  my $zchars = $z->zscii_to_zchars( $zscii_string );

Given a string of ZSCII characters, this method will return a (unpacked) string
of Z-characters.

It will raise an exception on ZSCII codepoints that cannot be represented as
Z-characters, which should not be possible with legal ZSCII.

=head2 zchars_to_zscii

  my $zscii = $z->zchars_to_zscii( $zchars_string, \%arg );

Given a string of (unpacked) Z-characters, this method will return a string of
ZSCII characters.

It will raise an exception when the right thing to do can't be determined.
Right now, that could mean lots of things.

Valid arguments are:

=over 4

=item allow_early_termination

If C<allow_early_termination> is true, no exception is thrown if the
Z-character string ends in the middle of a four z-character sequence.  This is
useful when dealing with dictionary words.

=back

=head2 make_dict_length

  my $zchars = $z->make_dict_length( $zchars_string )

This method returns the Z-character string fit to dictionary length for the
Z-machine version being handled.  It will trim excess characters or pad with
Z-character 5 to be the right length.

When converting such strings back to ZSCII, you should pass the
C<allow_early_termination> to C<zchars_to_zscii>, as a four-Z-character
sequence may have been terminated early.

=head2 pack_zchars

  my $packed_zchars = $z->pack_zchars( $zchars_string );

This method takes a string of unpacked Z-characters and packs them into a
bytestring with three Z-characters per word.  The final word will have its top
bit set.

=head2 unpack_zchars

  my $zchars_string = $z->pack_zchars( $packed_zchars );

Given a bytestring of packed Z-characters, this method will unpack them into a
string of unpacked Z-characters that aren't packed anymore because they're
unpacked instead of packed.

Exceptions are raised if the input bytestring isn't made of an even number of
octets, or if the string continues past the first word with its top bit set.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
