package Unicode::Property::XS;

use 5.008;
use strict;
use warnings;
use vars qw( $VERSION );

#require Exporter;
#our @ISA = qw(Exporter);
# use Exporter::Lite;
#our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
our $Prefix;
BEGIN {
    $VERSION = '0.81';
}

# This allows declaration   use Unicode::Property::XS ':all';


our @general = (
         'L', 'LC', 'Lu', 'Ll',
         'Lt', 'Lm', 'Lo', 'M',
         'Mn', 'Mc', 'Me', 'N',
         'Nd', 'Nl', 'No', 'P',
         'Pc', 'Pd', 'Ps', 'Pe',
         'Pi', 'Pf', 'Po', 'S',
         'Sm', 'Sc', 'Sk', 'So',
         'Z', 'Zs', 'Zl', 'Zp',
         'C', 'Cc', 'Cf', 'Cs',
         'Co', 'Cn' ); 
our @bidirectional = (
         'BidiL', 'BidiLRE', 'BidiLRO', 'BidiR',
         'BidiAL', 'BidiRLE', 'BidiRLO', 'BidiPDF',
         'BidiEN', 'BidiES', 'BidiET', 'BidiAN',
         'BidiCS', 'BidiNSM', 'BidiBN', 'BidiB',
         'BidiS', 'BidiWS', 'BidiON' ); 
our @scripts = (
         'Arabic', 'Armenian', 'Balinese', 'Bengali',
         'Bopomofo', 'Braille', 'Buginese', 'Buhid',
         'CanadianAboriginal', 'Cherokee', 'Coptic', 'Cuneiform',
         'Cypriot', 'Cyrillic', 'Deseret', 'Devanagari',
         'Ethiopic', 'Georgian', 'Glagolitic', 'Gothic',
         'Greek', 'Gujarati', 'Gurmukhi', 'Han',
         'Hangul', 'Hanunoo', 'Hebrew', 'Hiragana',
         'Inherited', 'Kannada', 'Katakana', 'Kharoshthi',
         'Khmer', 'Lao', 'Latin', 'Limbu',
         'LinearB', 'Malayalam', 'Mongolian', 'Myanmar',
         'NewTaiLue', 'Nko', 'Ogham', 'OldItalic',
         'OldPersian', 'Oriya', 'Osmanya', 'PhagsPa',
         'Phoenician', 'Runic', 'Shavian', 'Sinhala',
         'SylotiNagri', 'Syriac', 'Tagalog', 'Tagbanwa',
         'TaiLe', 'Tamil', 'Telugu', 'Thaana',
         'Thai', 'Tibetan', 'Tifinagh', 'Ugaritic',
         'Yi' ); 
our @extended = (
         'ASCIIHexDigit', 'BidiControl', 'Dash', 'Deprecated',
         'Diacritic', 'Extender', 'HexDigit', 'Hyphen',
         'Ideographic', 'IDSBinaryOperator', 'IDSTrinaryOperator', 'JoinControl',
         'LogicalOrderException', 'NoncharacterCodePoint', 'OtherAlphabetic', 'OtherDefaultIgnorableCodePoint',
         'OtherGraphemeExtend', 'OtherIDStart', 'OtherIDContinue', 'OtherLowercase',
         'OtherMath', 'OtherUppercase', 'PatternSyntax', 'PatternWhiteSpace',
         'QuotationMark', 'Radical', 'SoftDotted', 'STerm',
         'TerminalPunctuation', 'UnifiedIdeograph', 'VariationSelector', 'WhiteSpace' ); 
our @derived = (
         'Alphabetic', 'Lowercase', 'Uppercase', 'Math',
         'IDStart', 'IDContinue', 'Any', 'Assigned',
         'Unassigned', 'ASCII', 'Common' ); 
our @EastAsianWidth = (
         'EaF', 'EaH', 'EaA', 'EaNa',
         'EaW', 'EaN', 'EaFullwidth0', 'EaFullwidth1',
         'EaHalfwidth0', 'EaHalfwidth1' ); 

our %EXPORT_TAGS = ( 
        'all' => [ 'Legal',
        @general,@bidirectional,@scripts,@extended,
        @derived,@EastAsianWidth ],

        'general' => [ @general ],
        'bidirectional' => [ @bidirectional ],
        'scripts' => [ @scripts ],
        'extended' => [ @extended ],
        'derived' => [ @derived ],
        'EastAsianWidth' => [ @EastAsianWidth ],
        );


#    ucs_InEastAsianFullwidth
#    ucs_InEastAsianHalfwidth
#    ucs_InEastAsianAmbiguous
#    ucs_InEastAsianNarrow
#    ucs_InEastAsianWide
#    ucs_InEastAsianNeutral
#    ucs_InFullwidth
#    ucs_InHalfwidth
#      for ucs_InFullwidth see context $Unicode::EastAsianWidth::EastAsian
#      for ucs_InHalfwidth see context $Unicode::EastAsianWidth::EastAsian

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

sub import {
    my ($pkg, @imports) = @_;
    my($caller, $file, $line) = caller;

    $Prefix = defined($Prefix) ? $Prefix : 'ucs_' ;
    $Prefix =~ s/[^A-Za-z0-9_]//g ;                    # strip possible weird chars in prefix 

    # my @tags;
    my @items;

    # adapted from Exporter::Lite
    if ( !@imports ) {        # Default import.
        @imports = @EXPORT;
    }
    my %ok = map { s/^&//; $_ => 1; } @EXPORT_OK, @EXPORT;
    my %ok_tag = map { $_ => 1; } keys %EXPORT_TAGS;
    my $add;

    ITEM:
    foreach my $item (@imports) {
        $add = $item =~ s/^!// ? 1 : 2;

        if ($item eq ':DEFAULT') {
            map { $ok{$_}=$add; } @EXPORT ;
            next ITEM;
        }

        if ($item =~ /^:(.*)/) {
            if (!$ok_tag{$1}) {
                _report_error($1);
                next ITEM;
            };
            map { $ok{$_}=$add; } @{ $EXPORT_TAGS{$1} } ;
        }
        else {
            if (!$ok{$item}) {
                _report_error($item);
                next ITEM;
            };
            $ok{$item}=$add;
        }
    };

    foreach my $item (keys %ok) {
        next if $ok{ $item } != 2 ;

        do { no strict;
            *{ $caller.'::'.$Prefix.$item } = \&{ $item };
        };
    };

};

sub _report_error {
    my $item = shift;
    do { require Carp; Carp::croak("Can't export symbol: $item") };
};

require XSLoader;
XSLoader::load('Unicode::Property::XS', $VERSION);

# Preloaded methods go here.

1;
__END__


=head1 NAME

Unicode::Property::XS - Unicode properties implemented by lookup table in C code.

=head1 SYNOPSIS

  use Unicode::Property::XS qw(:all); # 'ucs_' is the default prefix

  my @property_letters;
  foreach my $ord (0x0000..0x37FF) { 
      push @property_letters, ucs_L($ord);    # /\p{L}/ 
  };
  my @property_list = ucs_EaFullwidth1(0x0000..0x37FF);

  foreach my $ord (0x0000..0x3FFFF) {
      next if !ucs_Legal($ord);
      die "Internal error!" if ucs_M($ord) != ((chr($ord) =~ /\p{M}/) ? 1 : 0);
  }

  my @myChars = q( a b c d e f g 1 2 3 );
  my @property_list2 = ucs_L( ord(@myChars) );

  __END__

  #################################
    
  BEGIN { Unicode::Property::XS::Prefix = 'Is'; }
  use Unicode::Property::XS;
  
  my @property_letters;
  foreach my $ord (0x0000..0x37FF) { 
      push @property_letters, IsL($ord);    # /\p{L}/ 
  };
   
  __END__

   #################################

   use Unicode::Property::XS qw( Legal :EastAsianWidth );
   use Unicode::EastAsianWidth;
   BEGIN { $Unicode::EastAsianWidth::EastAsian = 0; };

   foreach my $ord (0x0000..0xEFFFF) {
       next if !ucs_Legal($ord) ; 
       my $lookup_value = ucs_EaFullwidth0($ord);    # /\p{InFullwidth}
       my $re_value = chr($ord)=~/\p{InFullwidth}/ ;
       die "Error in Unicode::Property::XS!\n" if !($lookup_value == $re_value) ;
   };

   __END__

=head1 DESCRIPTION

Unicode properties for regular expression in perl is handy. 
But it's somehow slow when the times of repetition is sparse for a given word.
So, I made a table lookup XS module for property lookup.
The "Unicoae Character Properties" section of L<perlunicode> 
and properties in L<Unicode::EastAsianWidth> is implemented.

The bundle costs 1.2MB for run time dynamic library, and include all the property class listed below.
please tell me if you module-spliting or space-saving solutions.

All the functions except C<ucs_Legal()> work the same way.
Return  1 if the input character (in numeric value) is in that property class.
Return  0 if not.
Return  0 if the encoding value is illegal (should not happen if the input value is converted by C<ord($ucs_char)>).
Return 15 if in plane 15, a user-defined plane.
Return 16 if in plane 16, a user-defined plane.

And C<ucs_Legal()> returns 1 if perl will not complain C<chr($ucs_ord)>, and 0, otherwise.

The following functions can be exported to the caller's scope.
    C<ucs_Legal()>.

Functions for general properties:
    C<ucs_L()>, C<ucs_LC()>, C<ucs_Lu()>, C<ucs_Ll()>, C<ucs_Lt()>, C<ucs_Lm()>, C<ucs_Lo()>,
    C<ucs_M()>, C<ucs_Mn()>, C<ucs_Mc()>, C<ucs_Me()>,
    C<ucs_N()>, C<ucs_Nd()>, C<ucs_Nl()>, C<ucs_No()>,
    C<ucs_P()>, C<ucs_Pc()>, C<ucs_Pd()>, C<ucs_Ps()>, C<ucs_Pe()>, C<ucs_Pi()>, C<ucs_Pf()> C<ucs_Po()>,
    C<ucs_S()>, C<ucs_Sm()>, C<ucs_Sc()>, C<ucs_Sk()>, C<ucs_So()>,
    C<ucs_Z()>, C<ucs_Zs()>, C<ucs_Zl()>, C<ucs_Zp()>,
    C<ucs_C()>, C<ucs_Cc()>, C<ucs_Cf()>, C<ucs_Cs()>, C<ucs_Co()>, C<ucs_Cn()>,

Functions for bidirectional properties:
    C<ucs_BidiL()>, C<ucs_BidiLRE()>, C<ucs_BidiLRO()>, C<ucs_BidiR()>, 
    C<ucs_BidiAL()>, C<ucs_BidiRLE()>, C<ucs_BidiRLO()>, C<ucs_BidiPDF()>, 
    C<ucs_BidiEN()>, C<ucs_BidiES()>, C<ucs_BidiET()>, C<ucs_BidiAN()>, 
    C<ucs_BidiCS()>, C<ucs_BidiNSM()>, C<ucs_BidiBN()>, C<ucs_BidiB()>, 
    C<ucs_BidiS()>, C<ucs_BidiWS()>, C<ucs_BidiON()>.

Functions for scripts ( properties PhagsPa, Phoenician, are not included 
since they are not implemented in /\p{ }/ form. ):
    C<ucs_Arabic()>, C<ucs_Armenian()>, C<ucs_Balinese()>, 
    C<ucs_Bengali()>, C<ucs_Bopomofo()>, C<ucs_Braille()>, 
    C<ucs_Buginese()>, C<ucs_Buhid()>, C<ucs_CanadianAboriginal()>, 
    C<ucs_Cherokee()>, C<ucs_Coptic()>, C<ucs_Cuneiform()>, 
    C<ucs_Cypriot()>, C<ucs_Cyrillic()>, C<ucs_Deseret()>, 
    C<ucs_Devanagari()>, C<ucs_Ethiopic()>, C<ucs_Georgian()>, 
    C<ucs_Glagolitic()>, C<ucs_Gothic()>, C<ucs_Greek()>, 
    C<ucs_Gujarati()>, C<ucs_Gurmukhi()>, C<ucs_Han()>, C<ucs_Hangul()>, 
    C<ucs_Hanunoo()>, C<ucs_Hebrew()>, C<ucs_Hiragana()>, 
    C<ucs_Inherited()>, C<ucs_Kannada()>, C<ucs_Katakana()>, 
    C<ucs_Kharoshthi()>, C<ucs_Khmer()>, C<ucs_Lao()>, C<ucs_Latin()>, 
    C<ucs_Limbu()>, C<ucs_LinearB()>, C<ucs_Malayalam()>, 
    C<ucs_Mongolian()>, C<ucs_Myanmar()>, C<ucs_NewTaiLue()>, C<ucs_Nko()>, 
    C<ucs_Ogham()>, C<ucs_OldItalic()>, C<ucs_OldPersian()>, 
    C<ucs_Oriya()>, C<ucs_Osmanya()>, C<ucs_PhagsPa()>, 
    C<ucs_Phoenician()>, C<ucs_Runic()>, C<ucs_Shavian()>, 
    C<ucs_Sinhala()>, C<ucs_SylotiNagri()>, C<ucs_Syriac()>, 
    C<ucs_Tagalog()>, C<ucs_Tagbanwa()>, C<ucs_TaiLe()>, C<ucs_Tamil()>, 
    C<ucs_Telugu()>, C<ucs_Thaana()>, C<ucs_Thai()>, C<ucs_Tibetan()>, 
    C<ucs_Tifinagh()>, C<ucs_Ugaritic()>, C<ucs_Yi()>. 

Functions for extended properties:
    C<ucs_ASCIIHexDigit()>, C<ucs_BidiControl()>, C<ucs_Dash()>, 
    C<ucs_Deprecated()>, C<ucs_Diacritic()>, C<ucs_Extender()>, 
    C<ucs_HexDigit()>, C<ucs_Hyphen()>, C<ucs_Ideographic()>, 
    C<ucs_IDSBinaryOperator()>, C<ucs_IDSTrinaryOperator()>, 
    C<ucs_JoinControl()>, C<ucs_LogicalOrderException()>, 
    C<ucs_NoncharacterCodePoint()>, C<ucs_OtherAlphabetic()>, 
    C<ucs_OtherDefaultIgnorableCodePoint()>, 
    C<ucs_OtherGraphemeExtend()>, C<ucs_OtherIDStart()>, 
    C<ucs_OtherIDContinue()>, C<ucs_OtherLowercase()>, 
    C<ucs_OtherMath()>, C<ucs_OtherUppercase()>, C<ucs_PatternSyntax()>, 
    C<ucs_PatternWhiteSpace()>, C<ucs_QuotationMark()>, C<ucs_Radical()>, 
    C<ucs_SoftDotted()>, C<ucs_STerm()>, C<ucs_TerminalPunctuation()>, 
    C<ucs_UnifiedIdeograph()>, C<ucs_VariationSelector()>, 
    C<ucs_WhiteSpace()>.

Functions for derived properties:
    C<ucs_Alphabetic()>, C<ucs_Lowercase()>, C<ucs_Uppercase()>, 
    C<ucs_Math()>, C<ucs_IDStart()>, C<ucs_IDContinue()>, C<ucs_Any()>, 
    C<ucs_Assigned()>, C<ucs_Unassigned()>, C<ucs_ASCII()>, 
    C<ucs_Common()>.

Functions for EastAsianWidth:
    C<ucs_EaF()>, C<ucs_EaH()>,
    C<ucs_EaA()>, C<ucs_EaNa()>,
    C<ucs_EaW()>, C<ucs_EaN()>,
    C<ucs_EaFullwidth0()>, C<ucs_EaHalfwidth0()>,
    C<ucs_EaFullwidth1()>, C<ucs_EaHalfwidth1()>.

While considering about classification of C<InEastAsianAmbiguous> category in C<InFullwidth> and C<InHalfwidth>,
C<ucs_EaFullwidth0()> and C<ucs_EaHalfwidth0()> represent the C<InFullwidth> class and C<InHalfwidth> class 
with C<$Unicode::EastAsianWidth::EastAsian = 0>.
On the contrary, C<ucs_EaFullwidth1()> and C<ucs_EaHalfwidth1()> with C<$Unicode::EastAsianWidth::EastAsian = 1>. 
The actual value of C<$Unicode::EastAsianWidth::EastAsian> is irrelevant to them since the lookup table is premade.

In my line-warping program, the total running time is cut half by using this module, comparing to original regex version, 
i.e. C</\p{ }/> family. At the same time, caching the regex result doesn't help much.
But it shows only 20%-50% performance difference in benchmark module.


=head2 EXPORT


=head1 SEE ALSO

# Mention other useful documentation such as the documentation of
# related modules or operating system documentation (such as man pages
# in UNIX), or any relevant external documentation such as RFCs or
# standards.

# If you have a mailing list set up for your module, mention it here.

# If you have a web site set up for your module, mention it here.

L<perlunicode>, L<Unicode::EastAsianWidth>, 
L<http://www.unicode.org/unicode/reports/tr11/>, 
L<http://unicode.org/Public/UNIDATA/EastAsianWidth.txt>

=head1 AUTHOR

Mindos Cheng, E<lt>mindos@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2009 by Mindos Cheng

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut

