package Unicode::Stringprep;

require 5.008_003;

use strict;
use utf8;
use warnings;

our $VERSION = "1.105";
$VERSION = eval $VERSION;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(stringprep);

use Carp;

use Unicode::Normalize();

use Unicode::Stringprep::Unassigned;
use Unicode::Stringprep::Mapping;
use Unicode::Stringprep::Prohibited;
use Unicode::Stringprep::BiDi;

sub new {
  my $self  = shift;
  my $class = ref($self) || $self;
  return bless _compile(@_), $class;
}

## Here be eval dragons

sub _compile {
  my $unicode_version = shift;
  my $mapping_tables = shift;
  my $unicode_normalization = uc shift;
  my $prohibited_tables = shift;
  my $bidi_check = shift;
  my $unassigned_check = shift;

  croak 'Unsupported Unicode version '.$unicode_version.'.' 
    if $unicode_version != 3.2;

  my $mapping_sub = _compile_mapping($mapping_tables);
  my $normalization_sub = _compile_normalization($unicode_normalization);
  my $prohibited_sub = _compile_prohibited($prohibited_tables);
  my $bidi_sub = $bidi_check ? '_check_bidi($string)' : undef;
  my $unassigned_sub = $unassigned_check ? '_check_unassigned($string)' : undef;
  my $pr29_sub = (defined $normalization_sub) ? '_check_pr29($string)' : undef;

  my $code = "sub { no warnings 'utf8';".
   'my $string = shift;';

  $code .= '$string .= pack("U0");' if $] < 5.008;

  $code .= join('', map { $_ ? "{$_}\n" : ''} 
    grep { defined $_ }
      $mapping_sub,
      $normalization_sub,
      $prohibited_sub,
      $bidi_sub,
      $unassigned_sub,
      $pr29_sub ).
      'return $string;'.
    '}';

  return eval $code || die $@;
}

## generic compilation functions for matching/mapping characters
##

sub _compile_mapping {
  my %map = ();
  sub _mapping_tables {
    my $map = shift;
    while(@_) {
      my $data = shift;
      if(ref($data) eq 'HASH') { %{$map} = (%{$map},%{$data}) }
      elsif(ref($data) eq 'ARRAY') { _mapping_tables($map,@{$data}) }
      elsif(defined $data){ $map->{$data} = shift };
    }
  }
  _mapping_tables(\%map,@_);

  return '' if !%map;

  sub _compile_mapping_r { 
     my $map = shift;
     if($#_ <= 7) {
       return (join '', (map { '$char == '.$_.
        ' ? "'.(join '', map { quotemeta($_); } ( $$map{$_} )).'"'.
        '   : ' } @_)).' die';
     } else {
      my @a = splice @_, 0, int($#_/2);
      return '$char < '.$_[0].' ? ('.
        _compile_mapping_r($map,@a).
	') : ('.
        _compile_mapping_r($map,@_).
	')';
     }
  };

  my @from = sort { $a <=> $b } keys %map;

  return undef if !@from;

  return '$string =~ s/('._compile_set( map { $_ => $_ } @from).')/my $char = ord($1); '.
      _compile_mapping_r(\%map, @from).'/ge;',
}

sub _compile_set {
  my @collect = ();
  sub _set_tables {
    my $set = shift;
    while(@_) {
      my $data = shift;
      if(ref($data) eq 'HASH') { _set_tables($set, %{$data}); }
      elsif(ref($data) eq 'ARRAY') { _set_tables($set, @{$data}); }
      elsif(defined $data){ push @{$set}, [$data,shift || $data] };
    }
  }
  _set_tables(\@collect,@_);

  # NB: This destroys @collect as it modifies the anonymous ARRAYs
  # referenced in @collect.
  # This is harmless as it only modifies ARRAYs after they've been
  # inspected.

  my @set = ();
  foreach my $d (sort { $a->[0]<=>$b->[0] } @collect) {
    if(!@set || $set[$#set]->[1]+1 < $d->[0]) {
      push @set, $d;
    } elsif($set[$#set]->[1] < $d->[1]) {
      $set[$#set]->[1] = $d->[1];
    }
  }

  return undef if !@set;

  return '['.join('', map {
    $_->[0] >= $_->[1]
        ? sprintf("\\x{%X}", $_->[0])
        : sprintf("\\x{%X}-\\x{%X}", @{$_}[0,1])
    } @set ).']';
}

## specific functions for individual stringprep steps
##

sub _compile_normalization {
  my $unicode_normalization = uc shift;
  $unicode_normalization =~ s/^NF//;

  return '$string = _NFKC_3_2($string)' if $unicode_normalization eq 'KC';
  return undef if !$unicode_normalization;

  croak 'Unsupported Unicode normalization (NF)'.$unicode_normalization.'.';
}

my $is_Unassigned = _compile_set(@Unicode::Stringprep::Unassigned::A1);

sub _NFKC_3_2 {
  my $string = shift;

  ## pre-map characters corrected in Corrigendum #4
  ##
  no warnings 'utf8';
  $string =~ tr/\x{2F868}\x{2F874}\x{2F91F}\x{2F95F}\x{2F9BF}/\x{2136A}\x{5F33}\x{43AB}\x{7AAE}\x{4D57}/;

  ## only normalize runs of assigned characters
  ##
  my @s = split m/($is_Unassigned+)/o, $string;

  for( my $i = 0; $i <= $#s ; $i+=2 ) { # skips delimiters == is_Unassigned
    no warnings 'utf8';
    $s[$i] = Unicode::Normalize::NFKC($s[$i]);
  }
  return join '', @s;
}

sub _check_unassigned {
  if( shift =~ m/($is_Unassigned)/os ) {
    die sprintf("unassigned character U+%04X",ord($1));
  }
}

sub _compile_prohibited {
  my $prohibited = _compile_set(@_);

  if($prohibited) {
    return 
      'if($string =~ m/('.$prohibited.')/os) {'.
          'die sprintf("prohibited character U+%04X",ord($1))'.
      '}';
  }
}

my $is_RandAL = _compile_set(@Unicode::Stringprep::BiDi::D1);
my $is_L = _compile_set(@Unicode::Stringprep::BiDi::D2);

sub _check_bidi {
  my $string = shift;

  if($string =~ m/$is_RandAL/os) {
    if($string =~ m/$is_L/os) {
      die "string contains both RandALCat and LCat characters"
    } elsif($string !~ m/^(?:$is_RandAL)/os) {
      die "string contains RandALCat character but does not start with one"
    } elsif($string !~ m/(?:$is_RandAL)$/os) {
      die "string contains RandALCat character but does not end with one"
    }
  }
}

my $is_Combining = _compile_set(  0x0300,0x0314, 0x0316,0x0319, 0x031C,0x0320,
    0x0321,0x0322, 0x0323,0x0326, 0x0327,0x0328, 0x0329,0x0333, 0x0334,0x0338,
    0x0339,0x033C, 0x033D,0x0344, 0x0347,0x0349, 0x034A,0x034C, 0x034D,0x034E,
    0x0360,0x0361, 0x0363,0x036F, 0x0483,0x0486, 0x0592,0x0595, 0x0597,0x0599,
    0x059C,0x05A1, 0x05A3,0x05A7, 0x05A8,0x05A9, 0x05AB,0x05AC, 0x0653,0x0654,
    0x06D6,0x06DC, 0x06DF,0x06E2, 0x06E7,0x06E8, 0x06EB,0x06EC, 0x0732,0x0733,
    0x0735,0x0736, 0x0737,0x0739, 0x073B,0x073C, 0x073F,0x0741, 0x0749,0x074A,
    0x0953,0x0954, 0x0E38,0x0E39, 0x0E48,0x0E4B, 0x0EB8,0x0EB9, 0x0EC8,0x0ECB,
    0x0F18,0x0F19, 0x0F7A,0x0F7D, 0x0F82,0x0F83, 0x0F86,0x0F87, 0x20D0,0x20D1,
    0x20D2,0x20D3, 0x20D4,0x20D7, 0x20D8,0x20DA, 0x20DB,0x20DC, 0x20E5,0x20E6,
    0x302E,0x302F, 0x3099,0x309A, 0xFE20,0xFE23,
    0x1D165,0x1D166, 0x1D167,0x1D169, 0x1D16E,0x1D172, 0x1D17B,0x1D182,
    0x1D185,0x1D189, 0x1D18A,0x1D18B, 0x1D1AA,0x1D1AD, 
    map { ($_,$_) } 0x0315, 0x031A, 0x031B, 0x0345, 0x0346, 0x0362, 0x0591,
    0x0596, 0x059A, 0x059B, 0x05AA, 0x05AD, 0x05AE, 0x05AF, 0x05B0, 0x05B1,
    0x05B2, 0x05B3, 0x05B4, 0x05B5, 0x05B6, 0x05B7, 0x05B8, 0x05B9, 0x05BB,
    0x05BC, 0x05BD, 0x05BF, 0x05C1, 0x05C2, 0x05C4, 0x064B, 0x064C, 0x064D,
    0x064E, 0x064F, 0x0650, 0x0651, 0x0652, 0x0655, 0x0670, 0x06E3, 0x06E4,
    0x06EA, 0x06ED, 0x0711, 0x0730, 0x0731, 0x0734, 0x073A, 0x073D, 0x073E,
    0x0742, 0x0743, 0x0744, 0x0745, 0x0746, 0x0747, 0x0748, 0x093C, 0x094D,
    0x0951, 0x0952, 0x09BC, 0x09CD, 0x0A3C, 0x0A4D, 0x0ABC, 0x0ACD, 0x0B3C,
    0x0B4D, 0x0BCD, 0x0C4D, 0x0C55, 0x0C56, 0x0CCD, 0x0D4D, 0x0DCA, 0x0E3A,
    0x0F35, 0x0F37, 0x0F39, 0x0F71, 0x0F72, 0x0F74, 0x0F80, 0x0F84, 0x0FC6,
    0x1037, 0x1039, 0x1714, 0x1734, 0x17D2, 0x18A9, 0x20E1, 0x20E7, 0x20E8,
    0x20E9, 0x20EA, 0x302A, 0x302B, 0x302C, 0x302D, 0xFB1E, 0x1D16D,         );

my $is_HangulLV = _compile_set( map { ($_,$_) }     0xAC00, 0xAC1C, 0xAC38,
    0xAC54, 0xAC70, 0xAC8C, 0xACA8, 0xACC4, 0xACE0, 0xACFC, 0xAD18, 0xAD34,
    0xAD50, 0xAD6C, 0xAD88, 0xADA4, 0xADC0, 0xADDC, 0xADF8, 0xAE14, 0xAE30,
    0xAE4C, 0xAE68, 0xAE84, 0xAEA0, 0xAEBC, 0xAED8, 0xAEF4, 0xAF10, 0xAF2C,
    0xAF48, 0xAF64, 0xAF80, 0xAF9C, 0xAFB8, 0xAFD4, 0xAFF0, 0xB00C, 0xB028,
    0xB044, 0xB060, 0xB07C, 0xB098, 0xB0B4, 0xB0D0, 0xB0EC, 0xB108, 0xB124,
    0xB140, 0xB15C, 0xB178, 0xB194, 0xB1B0, 0xB1CC, 0xB1E8, 0xB204, 0xB220,
    0xB23C, 0xB258, 0xB274, 0xB290, 0xB2AC, 0xB2C8, 0xB2E4, 0xB300, 0xB31C,
    0xB338, 0xB354, 0xB370, 0xB38C, 0xB3A8, 0xB3C4, 0xB3E0, 0xB3FC, 0xB418,
    0xB434, 0xB450, 0xB46C, 0xB488, 0xB4A4, 0xB4C0, 0xB4DC, 0xB4F8, 0xB514,
    0xB530, 0xB54C, 0xB568, 0xB584, 0xB5A0, 0xB5BC, 0xB5D8, 0xB5F4, 0xB610,
    0xB62C, 0xB648, 0xB664, 0xB680, 0xB69C, 0xB6B8, 0xB6D4, 0xB6F0, 0xB70C,
    0xB728, 0xB744, 0xB760, 0xB77C, 0xB798, 0xB7B4, 0xB7D0, 0xB7EC, 0xB808,
    0xB824, 0xB840, 0xB85C, 0xB878, 0xB894, 0xB8B0, 0xB8CC, 0xB8E8, 0xB904,
    0xB920, 0xB93C, 0xB958, 0xB974, 0xB990, 0xB9AC, 0xB9C8, 0xB9E4, 0xBA00,
    0xBA1C, 0xBA38, 0xBA54, 0xBA70, 0xBA8C, 0xBAA8, 0xBAC4, 0xBAE0, 0xBAFC,
    0xBB18, 0xBB34, 0xBB50, 0xBB6C, 0xBB88, 0xBBA4, 0xBBC0, 0xBBDC, 0xBBF8,
    0xBC14, 0xBC30, 0xBC4C, 0xBC68, 0xBC84, 0xBCA0, 0xBCBC, 0xBCD8, 0xBCF4,
    0xBD10, 0xBD2C, 0xBD48, 0xBD64, 0xBD80, 0xBD9C, 0xBDB8, 0xBDD4, 0xBDF0,
    0xBE0C, 0xBE28, 0xBE44, 0xBE60, 0xBE7C, 0xBE98, 0xBEB4, 0xBED0, 0xBEEC,
    0xBF08, 0xBF24, 0xBF40, 0xBF5C, 0xBF78, 0xBF94, 0xBFB0, 0xBFCC, 0xBFE8,
    0xC004, 0xC020, 0xC03C, 0xC058, 0xC074, 0xC090, 0xC0AC, 0xC0C8, 0xC0E4,
    0xC100, 0xC11C, 0xC138, 0xC154, 0xC170, 0xC18C, 0xC1A8, 0xC1C4, 0xC1E0,
    0xC1FC, 0xC218, 0xC234, 0xC250, 0xC26C, 0xC288, 0xC2A4, 0xC2C0, 0xC2DC,
    0xC2F8, 0xC314, 0xC330, 0xC34C, 0xC368, 0xC384, 0xC3A0, 0xC3BC, 0xC3D8,
    0xC3F4, 0xC410, 0xC42C, 0xC448, 0xC464, 0xC480, 0xC49C, 0xC4B8, 0xC4D4,
    0xC4F0, 0xC50C, 0xC528, 0xC544, 0xC560, 0xC57C, 0xC598, 0xC5B4, 0xC5D0,
    0xC5EC, 0xC608, 0xC624, 0xC640, 0xC65C, 0xC678, 0xC694, 0xC6B0, 0xC6CC,
    0xC6E8, 0xC704, 0xC720, 0xC73C, 0xC758, 0xC774, 0xC790, 0xC7AC, 0xC7C8,
    0xC7E4, 0xC800, 0xC81C, 0xC838, 0xC854, 0xC870, 0xC88C, 0xC8A8, 0xC8C4,
    0xC8E0, 0xC8FC, 0xC918, 0xC934, 0xC950, 0xC96C, 0xC988, 0xC9A4, 0xC9C0,
    0xC9DC, 0xC9F8, 0xCA14, 0xCA30, 0xCA4C, 0xCA68, 0xCA84, 0xCAA0, 0xCABC,
    0xCAD8, 0xCAF4, 0xCB10, 0xCB2C, 0xCB48, 0xCB64, 0xCB80, 0xCB9C, 0xCBB8,
    0xCBD4, 0xCBF0, 0xCC0C, 0xCC28, 0xCC44, 0xCC60, 0xCC7C, 0xCC98, 0xCCB4,
    0xCCD0, 0xCCEC, 0xCD08, 0xCD24, 0xCD40, 0xCD5C, 0xCD78, 0xCD94, 0xCDB0,
    0xCDCC, 0xCDE8, 0xCE04, 0xCE20, 0xCE3C, 0xCE58, 0xCE74, 0xCE90, 0xCEAC,
    0xCEC8, 0xCEE4, 0xCF00, 0xCF1C, 0xCF38, 0xCF54, 0xCF70, 0xCF8C, 0xCFA8,
    0xCFC4, 0xCFE0, 0xCFFC, 0xD018, 0xD034, 0xD050, 0xD06C, 0xD088, 0xD0A4,
    0xD0C0, 0xD0DC, 0xD0F8, 0xD114, 0xD130, 0xD14C, 0xD168, 0xD184, 0xD1A0,
    0xD1BC, 0xD1D8, 0xD1F4, 0xD210, 0xD22C, 0xD248, 0xD264, 0xD280, 0xD29C,
    0xD2B8, 0xD2D4, 0xD2F0, 0xD30C, 0xD328, 0xD344, 0xD360, 0xD37C, 0xD398,
    0xD3B4, 0xD3D0, 0xD3EC, 0xD408, 0xD424, 0xD440, 0xD45C, 0xD478, 0xD494,
    0xD4B0, 0xD4CC, 0xD4E8, 0xD504, 0xD520, 0xD53C, 0xD558, 0xD574, 0xD590,
    0xD5AC, 0xD5C8, 0xD5E4, 0xD600, 0xD61C, 0xD638, 0xD654, 0xD670, 0xD68C,
    0xD6A8, 0xD6C4, 0xD6E0, 0xD6FC, 0xD718, 0xD734, 0xD750, 0xD76C, 0xD788, );

sub _check_pr29 {
  die "String contains Unicode Corrigendum #5 problem sequences" if shift =~ m/
    \x{09C7}$is_Combining+[\x{09BE}\x{09D7}]		| # BENGALI VOWEL SIGN E
    \x{0B47}$is_Combining+[\x{0B3E}\x{0B56}\x{0B57}]	| # ORIYA VOWEL SIGN E
    \x{0BC6}$is_Combining+[\x{0BBE}\x{0BD7}]		| # TAMIL VOWEL SIGN E
    \x{0BC7}$is_Combining+\x{0BBE}			| # TAMIL VOWEL SIGN EE
    \x{0B92}$is_Combining+\x{0BD7}			| # TAMIL LETTER O
    \x{0CC6}$is_Combining+[\x{0CC2}\x{0CD5}\x{0CD6}]	| # KANNADA VOWEL SIGN E
    [\x{0CBF}\x{0CCA}]$is_Combining\x{0CD5}		| # KANNADA VOWEL SIGN I or KANNADA VOWEL SIGN O
    \x{0D47}$is_Combining+\x{0D3E}			| # MALAYALAM VOWEL SIGN EE
    \x{0D46}$is_Combining+[\x{0D3E}\x{0D57}]		| # MALAYALAM VOWEL SIGN E
    \x{1025}$is_Combining+\x{102E}			| # MYANMAR LETTER U
    \x{0DD9}$is_Combining+[\x{0DCF}\x{0DDF}]		| # SINHALA VOWEL SIGN KOMBUVA
    [\x{1100}-\x{1112}]$is_Combining[\x{1161}-\x{1175} ] | # HANGUL CHOSEONG KIYEOK..HIEUH
    ($is_HangulLV|[\x{1100}-\x{1112}][\x{1161}-\x{1175}])($is_Combining)([\x{11A8}-\x{11C2}]) # HANGUL SyllableType=LV
  /osx;
}

1;
__END__

=head1 NAME

Unicode::Stringprep - Preparation of Internationalized Strings (S<RFC 3454>)

=head1 SYNOPSIS

  use Unicode::Stringprep;
  use Unicode::Stringprep::Mapping;
  use Unicode::Stringprep::Prohibited;

  my $prepper = Unicode::Stringprep->new(
    3.2,
    [ { 32 => '<SPACE>'},  ],
    'KC',
    [ @Unicode::Stringprep::Prohibited::C12, @Unicode::Stringprep::Prohibited::C22,
      @Unicode::Stringprep::Prohibited::C3, @Unicode::Stringprep::Prohibited::C4,
      @Unicode::Stringprep::Prohibited::C5, @Unicode::Stringprep::Prohibited::C6,
      @Unicode::Stringprep::Prohibited::C7, @Unicode::Stringprep::Prohibited::C8,
      @Unicode::Stringprep::Prohibited::C9 ],
    1, 0 );
  $output = $prepper->($input)

=head1 DESCRIPTION

This module implements the I<stringprep> framework for preparing
Unicode text strings in order to increase the likelihood that
string input and string comparison work in ways that make sense
for typical users throughout the world.  The I<stringprep>
protocol is useful for protocol identifier values, company and
personal names, internationalized domain names, and other text
strings.

The I<stringprep> framework does not specify how protocols should
prepare text strings. Protocols must create profiles of
stringprep in order to fully specify the processing options.

=head1 FUNCTIONS

This module provides a single function, C<new>, that creates a
perl function implementing a I<stringprep> profile.

This module exports nothing.

=over 4

=item B<new($unicode_version, $mapping_tables, $unicode_normalization, $prohibited_tables, $bidi_check, $unassigned_check)>

Creates a C<bless>ed function reference that implements a stringprep profile.

This function takes the following parameters:

=over

=item $unicode_version

The Unicode version specified by the stringprep profile.

Currently, this parameter must be C<3.2> (numeric).

=item $mapping_tables

The mapping tables used for stringprep.  

The parameter may be a reference to a hash or an array, or C<undef>. A hash
must map Unicode codepoints (as integers, S<e. g.> C<0x0020> for U+0020) to
replacement strings (as perl strings).  An array may contain pairs of Unicode
codepoints and replacement strings as well as references to nested hashes and
arrays.

L<Unicode::Stringprep::Mapping> provides the tables from S<RFC 3454>,
S<Appendix B>.

For further information on the mapping step, see S<RFC 3454>, S<section 3>.

=item $unicode_normalization 

The Unicode normalization to be used.

Currently, C<undef>/C<''> (no normalization) and C<'KC'> (compatibility
composed) are specified for I<stringprep>.

For further information on the normalization step, see S<RFC 3454>,
S<section 4>.

Normalization form KC will also enable checks for some problem sequences for
which the normalization can't be implemented in an interoperable way.

For more information, see L</CAVEATS> below.

=item $prohibited_tables 

The list of prohibited output characters for stringprep. 

The parameter may be a reference to an array, or C<undef>. The
array contains B<pairs> of codepoints, which define the B<start>
and B<end> of a Unicode character range (as integers). The end
character may be C<undef>, specifying a single-character range.
The array may also contain references to nested arrays.

L<Unicode::Stringprep::Prohibited> provides the tables from S<RFC 3454>,
S<Appendix C>.

For further information on the prohibition checking step, see 
S<RFC 3454>, S<section 5>.

=item $bidi_check

Whether to employ checks for confusing bidirectional text. A boolean value.

For further information on the bidi checking step, see S<RFC 3454>,
S<section 6>.

=item $unassigned_check

Whether to check for and prohibit unassigned characters. A boolean value.

The check must be used when creating I<stored> strings. It should not be used
for I<query> strings, increasing the chance that newly assigned characters work
as expected.

For further information on I<stored> and I<query> strings, see S<RFC 3454>, 
S<section 7>.

=back

The function returned can be called with a single parameter, the string to be
prepared, and returns the prepared string. It will die if the input string
cannot be successfully prepared because it would contain invalid output (so use
C<eval> if necessary).

For performance reasons, it is strongly recommended to call the
C<new> function as few times as possible, S<i. e.> exactly once per
I<stringprep> profile. It might also be better not to use this
module directly but to use (or write) a module implementing a
profile, such as L<Authen::SASL::SASLprep>.

=back

=head1 IMPLEMENTING PROFILES

You can easily implement a I<stringprep> profile without subclassing:

  package ACME::ExamplePrep;

  use Unicode::Stringprep;

  use Unicode::Stringprep::Mapping;
  use Unicode::Stringprep::Prohibited;

  *exampleprep = Unicode::Stringprep->new(
    3.2,
    [ \@Unicode::Stringprep::Mapping::B1, ],
    '',
    [ \@Unicode::Stringprep::Prohibited::C12,
      \@Unicode::Stringprep::Prohibited::C22, ],
    1,
  );

This binds C<ACME::ExamplePrep::exampleprep> to the function
created by C<Unicode::Stringprep-E<gt>new>.

Usually, it is not necessary to subclass this module. Sublassing
this module is not recommended.

=head1 DATA TABLES

The following modules contain the data tables from S<RFC 3454>.
These modules are automatically loaded when loading
C<Unicode::Stringprep>.

=over 4

=item * L<Unicode::Stringprep::Unassigned>

  @Unicode::Stringprep::Unassigned::A1	# Appendix A.1

=item * L<Unicode::Stringprep::Mapping>

  @Unicode::Stringprep::Mapping::B1	# Appendix B.1
  @Unicode::Stringprep::Mapping::B2	# Appendix B.2
  @Unicode::Stringprep::Mapping::B2	# Appendix B.3

=item * L<Unicode::Stringprep::Prohibited>

  @Unicode::Stringprep::Prohibited::C11	# Appendix C.1.1
  @Unicode::Stringprep::Prohibited::C12	# Appendix C.1.2
  @Unicode::Stringprep::Prohibited::C21	# Appendix C.2.1
  @Unicode::Stringprep::Prohibited::C22	# Appendix C.2.2
  @Unicode::Stringprep::Prohibited::C3	# Appendix C.3
  @Unicode::Stringprep::Prohibited::C4	# Appendix C.4
  @Unicode::Stringprep::Prohibited::C5	# Appendix C.5
  @Unicode::Stringprep::Prohibited::C6	# Appendix C.6
  @Unicode::Stringprep::Prohibited::C7	# Appendix C.7
  @Unicode::Stringprep::Prohibited::C8	# Appendix C.8
  @Unicode::Stringprep::Prohibited::C9	# Appendix C.9

=item * L<Unicode::Stringprep::BiDi>

  @Unicode::Stringprep::BiDi::D1	# Appendix D.1
  @Unicode::Stringprep::BiDi::D2	# Appendix D.2

=back

=head1 CAVEATS

In Unicode 3.2 to 4.0.1, the specification of UAX #15: Unicode Normalization
Forms for forms NFC and NFKC is not logically self-consistent.  This has been
fixed in Corrigendum #5 (L<http://unicode.org/versions/corrigendum5.html>).

Unfortunately, this yields two ways to implement NFC and NFKC in Unicode 3.2,
on which the Stringprep standard is based: one based on a literal
interpretation of the original specification and one based on the corrected
specification. The output of these implementations differs for a small class of
strings, all of which can't appear in meaningful text. See UAX #15, section 19
L<http://unicode.org/reports/tr15/#Stability_Prior_to_Unicode41> for details.

This module will check for these strings and, if normalization is done,
prohibit them in output as it is not possible to interoperate under these
circumstandes. 

Please note that due to this, the I<normalization> step may cause the
preparation to fail. That is, the preparation function may die even if there
are no prohibited characters and no checks for bidi sequences and unassigned
characters, which may be surprising.

=head1 AUTHOR

Claus FE<auml>rber <CFAERBER@cpan.org>

=head1 LICENSE

Copyright 2007-2009 Claus FE<auml>rber.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Unicode::Normalize>, S<RFC 3454> (L<http://www.ietf.org/rfc/rfc3454.txt>)

=cut
