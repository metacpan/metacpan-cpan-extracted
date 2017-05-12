package WWW::Google::PageRank;

# -*- perl -*-

use strict;
use warnings;

use vars qw($VERSION);

use LWP::UserAgent;
use URI::Escape;

$VERSION = '0.19';

sub new {
  my $class = shift;
  my %par = @_;
  my $self;
  $self->{ua} = LWP::UserAgent->new(agent => $par{agent} ||
				    'Mozilla/4.0 (compatible; GoogleToolbar 2.0.111-big; Windows XP 5.1)')
    or return;
  $self->{ua}->env_proxy if $par{env_proxy};
  $self->{ua}->proxy('http', $par{proxy}) if $par{proxy};
  $self->{ua}->timeout($par{timeout}) if $par{timeout};
  $self->{host} = $par{host} || 'toolbarqueries.google.com';
  bless($self, $class);
}

sub get {
  my ($self, $url) = @_;
  return unless defined $url and $url =~ m[^https?://]i;

  my $ch = '6' . _compute_ch_new('info:' . $url);
  my $query = 'http://' . $self->{host} . '/tbr?client=navclient-auto&ch=' . $ch .
    '&ie=UTF-8&oe=UTF-8&features=Rank&q=info:' . uri_escape($url);

  my $resp = $self->{ua}->get($query);
  if ($resp->is_success && $resp->content =~ /Rank_\d+:\d+:(\d+)/) {
    if (wantarray) {
      return ($1, $resp);
    } else {
      return $1;
    }
  } else {
    if (wantarray) {
      return (undef, $resp);
    } else {
      return;
    }
  }
}

sub _compute_ch_new {
  my $url = shift;

  my $ch = _compute_ch($url);
  $ch = (($ch % 0x0d) & 7) | (($ch / 7) << 2);

  return _compute_ch(pack("V20", map {my $t = $ch; _wsub($t, $_*9); $t} 0..19));
}

sub _compute_ch {
  my $url = shift;

  my @url = unpack("C*", $url);
  my ($a, $b, $c, $k) = (0x9e3779b9, 0x9e3779b9, 0xe6359a60, 0);
  my $len = scalar @url;

  while ($len >= 12) {
    _wadd($a, $url[$k+0] | ($url[$k+1] << 8) | ($url[$k+2] << 16) | ($url[$k+3] << 24));
    _wadd($b, $url[$k+4] | ($url[$k+5] << 8) | ($url[$k+6] << 16) | ($url[$k+7] << 24));
    _wadd($c, $url[$k+8] | ($url[$k+9] << 8) | ($url[$k+10] << 16) | ($url[$k+11] << 24));

    _mix($a, $b, $c);

    $k += 12;
    $len -= 12;
  }

  _wadd($c, scalar @url);

  _wadd($c, $url[$k+10] << 24) if $len > 10;
  _wadd($c, $url[$k+9] << 16) if $len > 9;
  _wadd($c, $url[$k+8] << 8) if $len > 8;
  _wadd($b, $url[$k+7] << 24) if $len > 7;
  _wadd($b, $url[$k+6] << 16) if $len > 6;
  _wadd($b, $url[$k+5] << 8) if $len > 5;
  _wadd($b, $url[$k+4]) if $len > 4;
  _wadd($a, $url[$k+3] << 24) if $len > 3;
  _wadd($a, $url[$k+2] << 16) if $len > 2;
  _wadd($a, $url[$k+1] << 8) if $len > 1;
  _wadd($a, $url[$k]) if $len > 0;

  _mix($a, $b, $c);

  return $c; # integer is positive always
}

sub _mix {
  my ($a, $b, $c) = @_;

  _wsub($a, $b); _wsub($a, $c); $a ^= $c >> 13;
  _wsub($b, $c); _wsub($b, $a); $b ^= ($a << 8) % 4294967296;
  _wsub($c, $a); _wsub($c, $b); $c ^= $b >>13;
  _wsub($a, $b); _wsub($a, $c); $a ^= $c >> 12;
  _wsub($b, $c); _wsub($b, $a); $b ^= ($a << 16) % 4294967296;
  _wsub($c, $a); _wsub($c, $b); $c ^= $b >> 5;
  _wsub($a, $b); _wsub($a, $c); $a ^= $c >> 3;
  _wsub($b, $c); _wsub($b, $a); $b ^= ($a << 10) % 4294967296;
  _wsub($c, $a); _wsub($c, $b); $c ^= $b >> 15;

  @_[0 .. $#_] = ($a, $b, $c);
}

sub _wadd { $_[0] = int(($_[0] + $_[1]) % 4294967296);}
sub _wsub { $_[0] = int(($_[0] - $_[1]) % 4294967296);}

1;


__END__

=head1 NAME

WWW::Google::PageRank - Query google pagerank of page

=head1 SYNOPSIS

 use WWW::Google::PageRank;
 my $pr = WWW::Google::PageRank->new;
 print scalar($pr->get('http://www.yahoo.com/')), "\n";

=head1 DESCRIPTION

The C<WWW::Google::PageRank> is a class implementing a interface for
querying google pagerank.

To use it, you should create C<WWW::Google::PageRank> object and use its
method get(), to query page rank of URL.

It uses C<LWP::UserAgent> for making request to Google.

=head1 CONSTRUCTOR METHOD

=over 4

=item  $gpr = WWW::Google::PageRank->new(%options);

This method constructs a new C<WWW::Google::PageRank> object and returns it.
Key/value pair arguments may be provided to set up the initial state.
The following options correspond to attribute methods described below:

   KEY                     DEFAULT
   -----------             --------------------
   agent                   "Mozilla/4.0 (compatible; GoogleToolbar 2.0.111-big; Windows XP 5.1)"
   proxy                   undef
   timeout                 undef
   env_proxy               undef
   host                    "toolbarqueries.google.com"

C<agent> specifies the header 'User-Agent' when querying Google.  If
the C<proxy> option is passed in, requests will be made through
specified poxy. C<proxy> is the host which serve requests from Googlebar.

If the C<env_proxy> option is passed in with a TRUE value, then proxy
settings are read from environment variables (see
C<LWP::UserAgent::env_proxy>)

=back

=head1 QUERY METHOD

=over 4

=item  $pr = $gpr->get('http://www.yahoo.com');

Queries Google for a specified pagerank URL and returns pagerank. If
query successfull, integer value from 0 to 10 returned. If query fails
for some reason (google unreachable, url does not begin from
'http://', undefined url passed) it return C<undef>.

In list context this function returns list from two elements where
first is the result as in scalar context and the second is the
C<HTTP::Response> object (returned by C<LWP::UserAgent::get>). This
can be usefull for debugging purposes and for querying failure
details.

=back

=head1 BUGS

If you find any, please report ;)

=head1 AUTHOR

Yuri Karaban F<E<lt>ykar@cpan.orgE<gt>>.

Algorithm of computing checksum taken from mozilla module
pagerankstatus F<http://pagerankstatus.mozdev.org> by
Stephane Queraud F<E<lt>squeraud@toteme.comE<gt>>.

Algorithm was modified (15-09-2004) according to new algorithm of
computingchecksum in googlebar.

=head1 COPYRIGHT

Copyright 2004-2011, Yuri Karaban, All Rights Reserved.

You may use, modify, and distribute this package under the
same terms as Perl itself.
