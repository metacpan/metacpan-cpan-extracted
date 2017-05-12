package Text::Guess::Script;

use strict;
use warnings;

our $VERSION = '0.03';

use Unicode::Normalize;

our @codes;

sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub guess {
  my ($self, $text) = @_;

  my $text_NFC = NFC($text);

  my @tokens = $text_NFC =~ m/(.)/xmsg;

  my $chars = {};
  for my $token (@tokens) {
    $chars->{$token}++;
  }

  my $guesses = {};
  my @other_codes = @codes;
  my @seen_codes;

  CHAR: for my $char (keys %$chars) {
    for my $code (@seen_codes) {
      if ($char =~ m/\p{$code}/xms) {
        $guesses->{$code} += $chars->{$char};
        next CHAR;
      }
    }
    OTHER: for my $code (@other_codes) {
      eval {local $SIG{'__DIE__'}; $char =~ m/\p{$code}/xms};
      if ($@) { next OTHER }
      if ($char =~ m/\p{$code}/xms) {
        $guesses->{$code} += $chars->{$char};
        push @seen_codes,$code;
        next CHAR;
      }
    }
  }

  my ($guess) = sort { $guesses->{$b} <=> $guesses->{$a} } keys(%$guesses);
  return $guess;
}

BEGIN {
@codes = qw(
Adlm
Afak
Aghb
Ahom
Arab
Aran
Armi
Armn
Avst
Bali
Bamu
Bass
Batk
Beng
Bhks
Blis
Bopo
Brah
Brai
Bugi
Buhd
Cakm
Cans
Cari
Cham
Cher
Cirt
Copt
Cprt
Cyrl
Cyrs
Deva
Dsrt
Dupl
Egyd
Egyh
Egyp
Elba
Ethi
Geok
Geor
Glag
Goth
Gran
Grek
Gujr
Guru
Hanb
Hang
Hani
Hano
Hans
Hant
Hatr
Hebr
Hira
Hluw
Hmng
Hrkt
Hung
Inds
Ital
Jamo
Java
Jpan
Jurc
Kali
Kana
Khar
Khmr
Khoj
Kitl
Kits
Knda
Kore
Kpel
Kthi
Lana
Laoo
Latf
Latg
Latn
Leke
Lepc
Limb
Lina
Linb
Lisu
Loma
Lyci
Lydi
Mahj
Mand
Mani
Marc
Maya
Mend
Merc
Mero
Mlym
Modi
Mong
Moon
Mroo
Mtei
Mult
Mymr
Narb
Nbat
Newa
Nkgb
Nkoo
Nshu
Ogam
Olck
Orkh
Orya
Osge
Osma
Palm
Pauc
Perm
Phag
Phli
Phlp
Phlv
Phnx
Piqd
Plrd
Prti
Qaaa
Qabx
Rjng
Roro
Runr
Samr
Sara
Sarb
Saur
Sgnw
Shaw
Shrd
Sidd
Sind
Sinh
Sora
Sund
Sylo
Syrc
Syre
Syrj
Syrn
Tagb
Takr
Tale
Talu
Taml
Tang
Tavt
Telu
Teng
Tfng
Tglg
Thaa
Thai
Tibt
Tirh
Ugar
Vaii
Visp
Wara
Wole
Xpeo
Xsux
Yiii
Zinh
Zmth
Zsye
Zsym
Zxxx
Zyyy
Zzzz
);
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::Guess::Script - Guess script from text using ISO-15924 codes

=begin html

<a href="https://travis-ci.org/wollmers/Text-Guess-Script"><img src="https://travis-ci.org/wollmers/Text-Guess-Script.png" alt="Text-Guess-Script"></a>
<a href='https://coveralls.io/r/wollmers/Text-Guess-Script?branch=master'><img src='https://coveralls.io/repos/wollmers/Text-Guess-Script/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/Text-Guess-Script'><img src='http://cpants.cpanauthors.org/dist/Text-Guess-Script.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Text-Guess-Script"><img src="https://badge.fury.io/pl/Text-Guess-Script.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

  use Text::Guess::Script;
  my $guessed_script = Text::Guess::Script->guess($text);


=head1 DESCRIPTION

Text::Guess::Script matches the characters in the text against the script property
and returns the code of script with most characters.

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the Text::Guess::Script computation.  Use one of these per concurrent
Text::Guess::Script->guess() call.

=back

=head2 METHODS

=over 4


=item guess($text)

Returns the script code with the most characters.

=back

=head2 EXPORT

None by design.

=head1 STABILITY

Until release of version 1.00 the included methods, names of methods and their
interfaces are subject to change.

Beginning with version 1.00 the specification will be stable, i.e. not changed between
major versions.


=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Text-Guess-Script>

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT

Copyright 2016- Helmut Wollmersdorfer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Locale::Codes::Script

=cut

