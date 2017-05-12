package WWW::Baseball::NPB;

use strict;
use vars qw($VERSION);
$VERSION = 0.03;

use LWP::Simple;
use WWW::Baseball::NPB::Game;

use vars qw($YahooURL);
$YahooURL = 'http://sports.yahoo.co.jp/baseball/';

sub croak { require Carp; Carp::croak(@_) }

sub new {
    my $class = shift;
    my $self  = bless { games => [] }, $class;
    $self->_parse_body($YahooURL);
    return $self;
}

sub games {
    my($self, $league) = @_;
    unless ($league) {
	return @{$self->{games}};
    }
    return grep { $_->league eq $league } @{$self->{games}};
}

sub _parse_body {
    my($self, $url) = @_;
    my $body = LWP::Simple::get($url) or croak("Can't get content of $url");
    my $re   = $self->_match_pattern;
    while ($body =~ m/$re/g) {
	$self->_add_game($1, $2, $3, $4, $5, $6, $7);
    }
}

my %league = (cl => 'central', pl => 'pacific');

sub _add_game {
    my($self, $home, $home_score, $visitor_score, $league, $status, $visitor, $stadium) = @_;
    for ($home_score, $visitor_score) {
	s,<b>(.*)</b>,$1,;
    }
    push @{$self->{games}}, WWW::Baseball::NPB::Game->new(
	home    => $home,
	visitor => $visitor,
	score   => {
	    $home => $home_score,
	    $visitor => $visitor_score,
	},
	league  => $league{$league},
	status  => $status,
	stadium => $stadium,
    );
}

sub _match_pattern {
    return <<'RE';
<tr valign="top">
<td align="right" width=35%>
<b><a href=".*?">(.*?)</a>
</b>
</td>
<td align="center" width=30%>(\S*) ?- ?(\S*)<br><a href="/baseball/(cl|pl)/scores/.*?">(.*?)</a>
</td>
<td align="left" width=35%><b><a href=".*?">(.*?)</a>
</b>
(?:</td>\n)?</tr>
<tr>(?:<td colspan=3 align=center><small>\[ <a href=".*?">ещеде╓</a> \]</small></td></tr><tr>)?
<td align="center" colspan=3 ?>(.*?)</td>
</tr>
<tr><td height=4 colspan=3></td></tr>
RE
    ;
}

1;
__END__

=head1 NAME

WWW::Baseball::NPB - Fetches Japanese baseball games information

=head1 SYNOPSIS

  use WWW::Baseball::NPB;

  my $baseball = WWW::Baseball::NPB->new;
  my @games  = $baseball->games;
  # or @games = $baseball->games('central');

  for my $game (@games) {
      my $home    = $game->home;
      my $visitor = $game->visitor;
      printf "%s %d - %d %s (%s) [%s]\n",
          $home, $game->score($home), $game->score($visitor), $visitor,
          $game->status, $game->stadium;
  }

=head1 DESCRIPTION

WWW::Baseball::NPB provides you a way to fetch and extract Japanese
baseball games information via Yahoo! Baseball. (NPB = Nippon
Professional Baseball)

=head1 NOTE

=over 4

=item *

Characters like team names, status and stadium are encoded in
EUC-JP. You can convert them to any encoding via Jcode.

=back

=head1 TODO

=over 4

=item *

Separate out Yahoo! Baseball parsing logic, using information provider
architecture (e.g. WWW::Baseball::NPB::Provider::*)

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<LWP::Simple>

=cut
