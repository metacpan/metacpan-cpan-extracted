package Text::Morse;

use utf8;
use warnings;
use strict;

$Text::Morse::VERSION = '0.07';

no warnings 'qw';

our %ENGLISH = qw(
A .-
B -...
C -.-.
D -..
E .
F ..-.
G --.
H ....
I ..
J .---
K -.-
L .-..
M --
N -.
O ---
P .--.
Q --.-
R .-.
S ...
T -
U ..-
V ...-
W .--
X -..-
Y -.--
Z --..
. .-.-.-
, --..--
/ -...-
: ---...
' .----.
- -....-
? ..--..
! ..--.
@ ...-.-
+ .-.-.
0 -----
1 .----
2 ..---
3 ...--
4 ....-
5 .....
6 -....
7 --...
8 ---..
9 ----.
);

our %SWEDISH = (%ENGLISH, qw(
Å  .--.-
Ä .-.-
Ö ---.
å  .--.-
ä .-.-
ö ---.
));

our %LATIN = (%ENGLISH, qw(
Á .--.-
Ä .-.-
Ö ---.
á .--.-
ä .-.-
ö ---.
É ..-..
é ..-..
Ñ --.--
ñ --.--
Ü ..--
ü ..--
));

our %COMMON_CYR = qw(
А .-
Б -...
В .--
Г --.
Д -..
Е .
Ж ...-
З --..
И ..
Й .---
К -.-
Л .-..
М --
Н -.
О ---
П .--.
Р .-.
С ...
Т -
У ..-
Ф ..-.
Х ....
Ц -.-.
Ч ---.
Ш ----
Щ --.-
Ю ..--
Я .-.-
. .-.-.-
, --..--
/ -...-
: ---...
' .----.
- -....-
? ..--..
! ..--.
@ ...-.-
+ .-.-.
0 -----
1 .----
2 ..---
3 ...--
4 ....-
5 .....
6 -....
7 --...
8 ---..
9 ----.
);

our %BULGARIAN = (%COMMON_CYR, qw(
Ъ -..-
Ь -.--
));

our %RUSSIAN = (%COMMON_CYR, qw(
Ь -..-
Ы -.--
Э ..-..
));

sub new {
        my $class = shift @_;
        my $lang  = shift @_;

        my $hash = \%ENGLISH;
        $hash = \%SWEDISH if defined $lang and $lang =~ /^(SWEDISH|SVENSKA)$/i;
        $hash = \%LATIN if defined $lang and $lang =~ /^LATIN$/i;
	$hash = \%BULGARIAN if defined $lang and $lang =~ /^(BULGARIAN|БЪЛГАРСКИ)$/i;
	$hash = \%RUSSIAN if defined $lang and $lang =~ /^(RUSSIAN|РУССКИЙ)$/i;
        
        my $rev = {reverse %$hash};
        my $self = {'enc' => $hash, 'dec' => $rev, 'lang' => $lang};
        bless $self, $class;
}

sub Encode {
        my ($self, $text) = @_;
        my $enc = $self->{'enc'};
        my @words = split(/\s+/, $text);
        my $sub = sub { $_ = $enc->{shift()}; $_ ? "$_ " : ""; };
        foreach (@words) {
                s/(\S)/&$sub(uc($1))/ge;
        }
        wantarray ? @words : join("\n", @words);
}

sub Decode {
        my ($self, @codes) = @_;
        my @words = @codes;
        my $dec = $self->{'dec'};
        my $sub = sub { $_ = $dec->{shift()}; defined($_) ? $_ : "<scrambled>"; }; 
        foreach (@words) {
                s/([\.-]+)\s*/&$sub($1)/ge;
        }
        wantarray ? @words : join(" ", @words);
}

1;
__END__
=head1 NAME

Text::Morse - Encoding and decoding Morse code

=head1 SYNOPSIS

  use Text::Morse;

  my $morse = new Text::Morse;
  print scalar($morse->Decode("... --- ..."));
  print scalar($morse->Encode("Adam Bertil"));

=head1 DESCRIPTION

Useless but fun.

=head1 SEE ALSO

	/usr/games/morse

=head1 REQUESTS

I need the morse codes for Hebrew, Arabic, Greek and Russian. Please send in 
universal high ASCII (UNIX or Windows, not DOS) :-)

=head1 BUGS AND SOURCE

	Bug tracking for this module: https://rt.cpan.org/Dist/Display.html?Name=Text-Morse

	Source hosting: http://www.github.com/bennie/perl-Text-Morse

=head1 VERSION

	Text::Morse v0.07 (2015/06/09)

=head1 COPYRIGHT

	(c) 2014-2015, Phillip Pollard <bennie@cpan.org>
	(c) 2001, Ariel Brosh

=head1 LICENSE

This source code is released under the "Perl Artistic License 2.0," the text of
which is included in the LICENSE file of this distribution. It may also be
reviewed here: http://opensource.org/licenses/artistic-license-2.0

=head1 AUTHORSHIP

This module was originally authored in 2001 by Ariel Brosh. (schop@cpan.org) 

It was adopted (via the CPAN "adoptme" account) by Phillip Pollard in 2014.

Additional Contributions:
- Bulgarian and Russian language support by svetoslav.chingov@gmail.com 

=cut
