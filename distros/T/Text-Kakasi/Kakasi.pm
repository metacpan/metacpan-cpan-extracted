#
# $Id: Kakasi.pm,v 2.4 2003/05/26 10:42:01 dankogai Exp $

package Text::Kakasi;
use strict;
# use warnings; # 5.00503 does not have one!
use Carp;
require Exporter;
require DynaLoader;

use vars qw($VERSION $DEBUG @ISA @EXPORT_OK %EXPORT_TAGS $HAS_ENCODE);
$VERSION = do { my @r = (q$Revision: 2.4 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(getopt_argv do_kakasi close_kanwadict);
%EXPORT_TAGS = (all => [qw(getopt_argv do_kakasi close_kanwadict)]);

bootstrap Text::Kakasi $VERSION;

$HAS_ENCODE = load_encode();

sub load_encode{
    $INC{Encode} and return 1;
    if ($] >= 5.008){
	eval { require Encode };
	$@ and return 0;
	eval { 
	    Encode->import(qw/find_encoding from_to _utf8_on _utf8_off/)
	};
	return $@ ? 0 : 1;
    }else{
	return 0;
    }
}

sub new{
    my $thingy = shift;
    my $class = ref $thingy ? ref $thingy : $thingy;
    my $self = bless {} => $class;
    @_ and $self->set(@_);
    return $self
}

my %k2p = 
    (
     oldjis => "7bit-jis",
     newjis => "7bit-jis",
     dec    => "euc-jp",
     euc    => "euc-jp",
     sjis   => "shiftjis",
    );

sub set{
    my $self = shift;
    my @argv;
    if ($HAS_ENCODE){
	for (@_){
	    if (/(-[io])\s*(\S+)/){
		my $name = $k2p{lc($2)} || $2;
		my $enc = find_encoding($name);;
		unless (ref $enc){
		    carp "encoding $name is not supported";
		    next;
		}
		$self->{$1} = $enc->name;
		# push @argv, "$1euc";
	    }else{
		push @argv, $_;
	    }
	}
    }else{
	@argv = @_;
    }
    my $error = getopt_argv(@argv);
    $error and 
	carp "Kakasi returned $error for ", join " " => @argv;
    $self->{error} = $error;
    $self->{argv}  = [ @argv ];
    return $self;
}

sub getopt_argv{
    my @argv = @_;
    $argv[0] and $argv[0] eq 'kakasi' or unshift @argv, 'kakasi';
    xs_getopt_argv(@argv);
}

sub error{ shift->{error} };

sub get{
    my $self   = shift; 
    my $str    = shift;
    if ($HAS_ENCODE){
	if ($self->{'-i'}){
	    $self->{'-i'} eq 'utf8' and _utf8_off($str);
	    from_to($str, $self->{'-i'} =>'eucjp');
	}
    }
    $str = do_kakasi($str);
    if (defined $str){
	$self->{error} = 0;
	if ($HAS_ENCODE){
	    if ($self->{'-o'}){
		from_to($str, 'eucjp' => $self->{'-o'});
		$self->{'-o'} eq 'utf8' and _utf8_on($str);
	    }
	}
    }else{
	warn;
	$self->{error} = 1;
    }
    return $str;
}

sub do_kakasi{
    my $str = shift;
    $str =~ tr/\0//d;
    return xs_do_kakasi($str);
}

sub close_kanwadict { xs_close_kanwadict() };

1;
__END__

=head1 NAME

Text::Kakasi - perl frontend to kakasi

=head1 SYNOPSIS

  use Text::Kakasi;
  # functional
  $res = Text::Kakasi::getopt_argv('-JJ', '-c', '-w');
  $str = Text::Kakasi::do_kakasi($japanese_text);
  # object-oriented
  $obj = Text::Kakasi->new('-JJ', '-c', '-w');
  $str = $obj->get($japanese_text);

=head1 DESCRIPTION

This module provides interface to kakasi (kanji kana simple inverter).
kakasi is a set of programs and libraries which does what Japanese
input methods do in reverse order.  You feed Japanese and kakasi
converts it to phonetic representation thereof.  kakasi can also be
used to tokenizing Japanese text. To find more about kakasi, see
L<http://kakasi.namazu.org/> .

Text::Kakasi now features both functional and object-oriented APIs.
functional APIs are 100% compatible with ver. 1.05.  But to take
advantage of L</"Perl 5.8 Features">, you should use OOP APIs instead.

See L<Text::Kakasi::JP> for the Japanese version of this document.

=head1 Functional APIs

Note C<Text::Kakasi::> is omitted.  Text::Kakasi does not export these
functions by default.  You can import these function as follows;

  use Text::Kakasi qw/getopt_argv do_kakasi/;

=over 2

=item $err = getopt_argv($arg1, $arg2, ...)

initializes kakasi with options options are the same as C<kakasi>
command.  Here is the summery as of kakasi 2.3.4.

  -a[jE] -j[aE] -g[ajE] -k[ajKH]
  -E[aj] -K[ajkH] -H[ajkK] -J[ajkKH]
  -i{oldjis,newjis,dec,euc,sjis}
   -o{oldjis,newjis,dec,euc,sjis}
  -r{hepburn,kunrei} -p -s -f -c"chars" 
   [jisyo1, jisyo2,,,]

  Character Sets:
       a: ascii  j: jisroman  g: graphic  k: kana 
       (j,k     defined in jisx0201)
       E: kigou  K: katakana  H: hiragana J: kanji
       (E,K,H,J defined in jisx0208)

  Options:
    -i: input coding system    -o: output coding system
    -r: romaji conversion system
    -p: list all readings (with -J option)
    -s: insert separate characters (with -J option)
    -f: furigana mode (with -J option)
    -c: skip chars within jukugo
        (with -J option: default TAB CR LF BLANK)
    -C: romaji Capitalize (with -Ja or -Jj option)
    -U: romaji Upcase     (with -Ja or -Jj option)
    -u: call fflush() after 1 character output
    -w: wakatigaki mode

Returns 0 on success and nonzero on failure.

Unlike version 1.x where you have to start the first argument with
C<kakasi>, you can omit that in version 2.x (adding C<kakasi> does not
harm so compatibility is preserved).

=item $result_str = do_kakasi($str)

apply kakasi to C<$str> and returns result. If anything goes wrong it
return C<undef>.

=item close_kanwadic()

closes dictionary files which are implicitly opened.  This function is
for backward compatibity only and you should never have to use this
function today.

=back

=head1 Object-Oriented APIs

As of 2.0, Text::Kakasi also offers OOP APIs.

=over 2

=item $k = Text::Kakasi->new($args ...)

Constructs object.  When argument is fed, it is the same as 
C<< Text::Kakasi->new->set($args ...) >>

=item $k->set($args ...)

OOP interface to C<getopt_argv>.

  my $k = Text::Kakasi->new;
  $k->set('-w'); # Text::Kakasi::getopt_argv('-w');

Unlike C<getopt_argv()> which returns the status, C<set> returns the
object itself so you can go like this;

  my $tokenized = $k->set('-w')->get($raw_japanese);

To get the status of C<< $k->set >>, use C<< $k->error >>.

See also L</"Perl 5.8 Features">.

=item $k->error

returns the status of last method.

=item $result = $k->get($raw_japanese);

OOP interface to C<do_kakasi>.  The following codes are equivalent.

  # Functional
  getopt_argv('-w'); $result = do_kakasi($raw_japanese);
  # OOP
  $k->set('-w')->get($raw_japanese);

=back

=head1 Perl 5.8 Features

Perl 5.8 introduces L<Encode> module which transcodes various
encodings.  This module takes advantage of this feature but to keep
backward compatibility with version 1.x, This feature is enabled only
when you use OOP interface (version 1.x only provided functional
APIs).

On Perl 5.8 and up, C<< -iI<encoding> >> and C<< -oI<encoding> >>are
handled by L<Encode> module so you can use encodings Kakasi does not
suppport such as utf8.  In other words,

  $result = $k->set(qw/-iutf8 -outf8 -w/)->get($utf8);

Is analogous to:

  $euc = encode('eucjp' => $utf8);
  getopt_argv('-w');
  $tmp = do_kakasi($euc);
  $result = decode('eucjp' => $tmp);

When you specify C<-outf8>, C<< $k->get >> will return the string with
utf8 flag on.

You can suppress this feature by setting C<$Text::Kakasi::HAS_ENCODE>
to 0 in which case this feature is not used.

=head1 SEE ALSO

L<kakasi(1)>, L<http://kakasi.namazu.org/>,L<Encode>,L<perlunicode>

=head1 COPYRIGHT

  (C) 1998, 1999, 2000 NOKUBI Takatsugu <knok@daionet.gr.jp>
  (C) 2003 Dan Kogai <dankogai@dan.co.jp>

There is no warranty for this free software. Anyone can modify and/or
redistribute this module under GNU GENERAL PUBLIC LICENSE. See COPYING
file that is included in the archive for more details.

=cut
