#!/usr/local/bin/perl
# FILE %usr/unixonly/hp200lx/ps/getst.pl
#
# VERY simple script which can be used to fetch the Palm Pilot
# edition of "Der Standard"
#
# written:       1998-10-19
# latest update: 1998-10-30 18:14:20
#

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;

use lib '.';
use HP200LX::DB;

%ENT=
(
  'auml' => 'ae',
  'ouml' => 'oe',
  'uuml' => 'ue',
  'Auml' => 'Ae',
  'Ouml' => 'Oe',
  'Uuml' => 'Ue',
  'szlig' => 'ss',
  'nbsp' => ' ',
  'gt' => '>',
  'lt' => '<',
  'amp' => '&',
  'quot' => '"',
);

$ua= new LWP::UserAgent;
# $ua->proxy ('http', 'http://falbala.wu-wien.ac.at');

$BASE= 'http://derstandard.at/Palm';
if (defined ($arg= shift (@ARGV)))
{
  $BASE .= '/'. $arg;
  $WHAT= $BASE .'/Seite1.htm';
}
else
{
  $WHAT= $BASE. '/Titel.htm';
}

@arts= &get_standard ($ua, $WHAT);

$db= HP200LX::DB::openDB ('template/standard.gdb');
tie (@db, HP200LX::DB, $db);

foreach $art (@arts)
{
  # print "\n\n", '-' x 72, "\n", join (':', %$art), "\n";
  $db[$i++]= $art;
}
$today=~ s/-//g;
$db->refresh_viewpt (-1);
$db->saveDB ("ps/$today.gdb");
exit (0);

sub get_standard
{
  my $ua= shift;
  my $URL= shift;

  my %URLS=
  (
    'http://www.comyan.com' => 'ignore',
    'http://derstandard.at/Palm/19981020/standard.htm' => 'ignore',
  );
  my (@rec, $art);

  push (@URLS, $URL);

  while ($url= shift (@URLS))
  {
    next if (defined ($URLS{$url}));
    next unless ($url =~ /^$BASE/);
    next if ($url =~ /Sport\.htm/);

    $URLS{$url}= '1';

    print ">>> $url\n";

    my $req= new HTTP::Request ('GET', $url);
    my $res= $ua->request ($req);
    if ($res->is_success)
    {
      $txt= $res->content;
      push (@URLS, &parse_page ($url, $txt));
      if ($url =~ /(\d{4})(\d{2})(\d{2})\/(\d+)\.htm$/)
      {
        $date= "$1-$2-$3";
        $page= $4;
        $today= $date unless ($today);
        $art= &get_article ($txt);
        $art->{Date}= $date;
        $art->{Page}= sprintf ("%3d", $page);
        $art->{Source}= 'Standard';

        push (@rec, $art);
        # print ">>> txt=$txt\n";
        # last;
      }
    }
    else
    {
      print $res->error_as_HTML;
    }
  }

  @rec;
}

sub ent2txt
{
  my $ent= shift;
  $ENT{$ent} || "&$ent;";
}

sub get_article
{
  my $html= shift;

  if ($html =~ m#<title>([^-]+)-\s*(.+)</title>#) { $Sect= $1; $Title= $2; }
  $html =~ s#[\r\|]##g;
  $html =~ s#<HR NOSHADE>#\|#g;
  $html =~ s#<[Bb]>#*#g;
  $html =~ s#</[Bb]>#*#g;
  $html =~ s#<[^>]*>##g;
  $html =~ s#&([\w\d\.]+);#&ent2txt($1)#ge;
  $Title =~ s#&([\w\d\.]+);#&ent2txt($1)#ge;
  $html =~ s#\[[<>]\]##g;
  $html =~ s#^[^\|]*\|##;
  $html =~ tr#\t \n#  \n#s;
  $html =~ s#\n#\r\n#g; # should be in HP module?

  return { 'Text' => $html, 'Title' => $Title, 'Sect' => $Sect };
}

sub parse_page
{
  my $base= shift;
  my $html= shift;

  my (@p, @pp, @q, @r);
  my ($p, $r);
  my @base= split ('/', $base);

  $html=~ s/<a href="([^"]+)">/push (@p, $1)/gei;
  # print "$html";
  # print "p: ", join ('|', @p), "\n";
  # @p;

  # process each found url
  foreach $p (@p)
  {
    if ($p =~ /^http:/ || $p =~ /^\//)
    {
      push (@q, $p);
      next;
    }

    @pp= split ('/', $p);
    @q= @base;
    pop (@q);

    while (defined ($pp= shift (@pp)))
    {
      if ($pp eq '.' || $pp eq '') { }
      if ($pp eq '..') { pop (@q); }
      else { push (@q, $pp); }
    }
    push (@r, join ('/', @q));
  }

  @r;
}

