# $Id: SGF.pm,v 1.2 2009/02/27 19:54:29 drhyde Exp $

use strict;
use warnings;

package WWW::Facebook::Go::SGF;

use vars qw($VERSION @ISA @EXPORT_OK);

require Exporter;

use LWP::Simple;

@ISA = qw(Exporter);
@EXPORT_OK = qw(facebook2sgf); 
$VERSION = '1.0';

=head1 NAME

WWW::Facebook::Go::SGF - convert a game of Go on Facebook into SGF.

=head1 SYNOPSIS

    use WWW::Facebook::Go::SGF qw(facebook2sgf);
    
    my $sgf = facebook2sgf($game_id);

=head1 DESCRIPTION

A simple tool to extract a game record from the GoTheGame application
on Facebook and convert it to SGF so that you can then manipulate it
using other tools.

=head1 FUNCTIONS

=head2 facebook2sgf

This can be exported if you wish.  It takes a game ID as its only
parameter, and returns a scalar representation of an SGF recording
of the game.

You can get game IDs by visiting L<http://apps.facebook.com/gothegame/>
and clicking the "View Full Profile" link.

=cut

sub facebook2sgf {
    my $gameid = shift();
    my @moves = split(/[\n\r]+/, _download($gameid));

    (my $size = (grep { /^var board_size = '(9|13|19)'/ } @moves)[0])
        =~ s/^var board_size = '(9|13|19)'.*/$1/;

    my $handicap = (grep { /HANDICAP/ } @moves)[0];
    my @handicapstones = ();
    if($handicap) {
        $handicap =~ s/.*HANDICAP','([\d_,]+)'.*/$1/;
        @handicapstones = split(',', $handicap);
    }

    @moves = map {
        /new goMove\((\d+),'([BW])','([^']+)'/;
        [$1, $2, _fixcoords($3)];
    } grep { /^moves\[\d+\] = new goMove/ && $_ !~ /START|HANDICAP/ } @moves;
    @moves = @moves[0 .. $#moves - 1]; # lop off last NEGOTIATE

    my $komi = 0.5 + (@handicapstones ? 0 : 6); # 0.5 or 6.5
    my $board = q{(;GM[1]FF[4]AP[}.__PACKAGE__.
                qq{]ST[1]SZ[$size]HA[}.
                (1+$#handicapstones).
                qq{]KM[$komi]PW[White player]PB[Black player]}.
                "\n\n";
    if(@handicapstones) {
        $board .= ';AB';
        foreach my $stone (map { _fixcoords($_) } @handicapstones) {
            $board .= "[$stone]";
        }
        $board .= "\n";
    }

    foreach(@moves) {
        $board .= ';'.$_->[1].'['.$_->[2].']';
    }
    $board .= "\n)\n";

    return $board;
}

sub _fixcoords {
    my $fbcoord = shift;
    $fbcoord =~ s/(\d+)/substr('abcdefghijklmnopqrs', $1, 1)/eg;
    $fbcoord =~ y/_//d;
    $fbcoord =~ s/PASS|NEGOTIATE//;
    $fbcoord;
}

# private function, wraps around LWP::Simple::get so we can mock it in
# testing
sub _download {
    my $url = 'http://facebook3.wx3.com/go/go_iframe_spectate.php?game_id='.shift();
    my $content = get($url) || die("Couldn't fetch $url\n");
    return $content;
}

=head1 BUGS/WARNINGS/LIMITATIONS

This has only been tested on completed games.  I assume that both players
correctly identified all dead groups after passing and that play didn't
have to resume.  Please report any bugs that you find using
L<http://rt.cpan.org/>.  Obviously you will need to include the game id
in your bug report.

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism
and bug reports.  The best bug reports include files that I can add
to the test suite, which fail with the current code in CVS and will
pass once I've fixed the bug.

Feature requests are far more likely to get implemented if you submit
a patch yourself.

=head1 CVS

L<http://drhyde.cvs.sourceforge.net/drhyde/perlmodules/WWW-Facebook-Go-SGF/>

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2009 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
