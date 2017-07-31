
package WWW::Amazon::Wishlist;

use warnings;
use strict;

our
$VERSION = 2.018;

use vars qw( @ISA @EXPORT @EXPORT_OK );

use Carp;
use Data::Dumper;
use HTML::TreeBuilder;
use LWP::UserAgent;

use constant COM => 0;
use constant UK  => 1;

use constant DEBUG => 0;
use constant DEBUG_HTML => 0;
use constant DEBUG_NEXT => 0;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
);
@EXPORT_OK = qw(
        get_list
        UK
        COM
);

=pod

=head1 NAME

WWW::Amazon::Wishlist - grab all the details from your Amazon wishlist

=head1 SYNOPSIS

  use WWW::Amazon::Wishlist qw(get_list COM UK);

  my @wishlist;

  @wishlist = get_list($my_amazon_com_id);       # gets it from amazon.com
  @wishlist = get_list($my_amazon_com_id,  COM); # same, explicitly
  @wishlist = get_list($my_amazon_couk_id, UK);  # gets it from amazon.co.uk

  # Or, if you didn't import the COM and UK constants:
  @wishlist = get_list ($my_amazon_couk_id, WWW::Amazon::Wishlist::UK);

  # The elements of @wishlist are hashrefs that contain the following elements:
  foreach my $book (@wishlist)
    {
    print $book->{title}, # the, err, title
    $book->{author},      # and the author(s) 
    $book->{asin},        # the asin number, its unique id on Amazon
    $book->{price},       # how much it will set you back
    $book->{quantity},    # how many you said you want
    $book->{priority},    # how urgently you said you want it (1-5)
    $book->{type};        # Hardcover/Paperback/CD/DVD etc (not available in the US)
    } # foreach

=head1 DESCRIPTION

Goes to amazon.(com|co.uk), scrapes your wishlist, and returns it
in a array of hashrefs so that you can fiddle with it to your heart's
content.

=head1 GETTING YOUR AMAZON ID

The best way to do this is to search for your own wishlist in the search
tools.

Searching for mine (simon@twoshortplanks.com) on amazon.com takes me to
the URL something like

   http://www.amazon.com/exec/obidos/wishlist/2EAJG83WS7YZM/...

there's some more cruft after that last string of numbers and letters
but it's the

   2EAJG83WS7YZM

bit that's important.

Doing the same for amazon.co.uk is just as easy.

Apparently, some people have had problems getting to their wishlist right
after it gets set up.  You may have to wait a while for it to become
browseable.

=head1 SHOWING YOUR APPRECIATION

There was a thread on london.pm mailing list about working in a vacuum -
that it was a bit depressing to keep writing modules but never get any
feedback.  So, if you use and like this module then please send me an
email and make my day.

All it takes is a few little bytes.


=head1 BUGS

B<IMPORTANT>

C<WWW::Amazon::Wishlist> is a screen scraper and is there for
is vulnerable to any changes that Amazon make to their HTML.

If it starts returning no items then this is very likely the reason
and I will get around to fixing it as soon as possible.

You might want to look at the C<Net::Amazon> module instead.

It doesn't cope with anything apart from the UK and USA versions of Amazon.

I don't think it likes unavailable items - trying to work around this
breaks UK compatability.

The code has accumulated lots of cruft.

Lack of testing.  It works for the pages I've tried it for but that's
no guarantee.

=head1 LICENSE

Copyright (c) 2003 Simon Wistow

Distributed under the same terms as Perl itself.

This software is under no warranty and will probably destroy your wish
list, kill your friends, burn your house and bring about the apocalypse

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>
Currently maintained by Martin Thurn <mthurn@cpan.org>

=head1 SEE ALSO

L<perl>, L<LWP::UserAgent>, L<amazonwish>

=cut

my $USER_AGENT = 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)';

sub get_list {
  # Required arg = wishlist ID:
  my $id = shift || croak "No ID given to get_list() function\n";
  # Optional arg = whether we're accessing the UK site.  Default is "no":
  my $uk = shift || 0;
  # Optional arg = turn on debugging:
  my $test = shift || DEBUG;
  # Note to self ... should we UC the id? Nahhhh. Not yet.
  # fairly self explanatory
  my $domain = ($uk) ? "co.uk" : "com";
  my $sBase = qq'http://www.amazon.$domain';
  # set up some variables
  my $iPage = 1;
  my @items;
  my $url;
  # and awaaaaaaaaaaaaay we go ....
 INFINITE:
  while (1)
    {
    $url ||= $uk ? "$sBase/gp/registry/wishlist/ref=cm_wl_search_1?page=$iPage&cid=$id" :
    "$sBase/gp/registry/wishlist/$id";
    # This is a typical complete .com URL as of 2008-12:
    # http://www.amazon.com/gp/registry/wishlist/2O4B95NPM1W3L
    DEBUG_HTML && warn " DDD fetching wishlist for $id, page $iPage...\n";
    # Don't overwhelm the server:
    sleep(3) if (1 < $iPage);
    my $content = _fetch_page($url, $domain);
    if (DEBUG_HTML == 88)
      {
      warn $content;
      exit 88;
      } # if
    # As of 2009-08, Amazon returns HTML with MISSING BRACKETS:
    $content =~ s/(<tbody\s[^>\r\n]+)(\s+<)/$1>\n$2/g;
    # There seems to be a bug in HTML::TreeBuilder that causes
    # abutting tags to be skpped!?!
    $content =~ s!><!> <!g;
    if (9 < $test)
      {
      eval "use File::Slurp";
      my $sFname = qq'Pages/fetched-$domain.html';
      write_file($sFname, $content);
      warn " DDD wrote HTML to $sFname\n";
      exit 88;
      } # if
    my $iLen = length($content);
    # warn " DDD fetched $iLen bytes.\n";

    my $result = _extract($uk, $content, $test);
    # print Dumper($result);
    # exit 88;
    if (! defined $result)
      {
      DEBUG && warn " WWW _extract() returned nothing\n";
      last INFINITE;
      } # if
    if (! ref $result->{items})
      {
      # Probably an empty wish list
      DEBUG && warn " WWW _extract() returned no items\n";
      last INFINITE;
      } # if
    # Clean up the parsed items and add them to our local @items
    # array:
 ITEM:
    foreach my $item (@{$result->{items}})
      {
      $item->{'author'} =~ s!\n!!g;
      $item->{'author'} =~ s!^\s*by\s+!!g;
      $item->{'author'} =~ s!</span></b><br />\n*!!s;
      $item->{'quantity'} = $1 if ($item->{'priority'} =~ m!Desired:\s*</b>\s*(\d+)!i);
      $item->{'priority'} = $1 if ($item->{'priority'} =~ m!Priority:\s*</b>\s*(\d)!i);
      if (
          $uk
          &&
          $item->{image}
          &&
          ($item->{image} !~ m!^http:!)
         )
        {
        $item->{image} = q"http://images-eu.amazon.com/images/P/". $item->{image};
        } # if
      push @items, $item;
      DEBUG_HTML && warn " DDD added one item to \@items\n";
      } # foreach ITEM
    # Assumes an absolute path without hostname:
    if ( ! defined $result->{next})
      {
      DEBUG_NEXT && warn " WWW did not find next url\n";
      DEBUG_NEXT && write_file(qq'Pages/no-next.html', $content);
      last INFINITE;
      } # if
    $url = $sBase . $result->{next};
    $iPage++;
    } # while INFINITE
  return @items;
  } # get_list

sub _fetch_page {
  my ($url, $domain) = @_;
  if (0)
    {
    eval "use File::Slurp";
    # For debugging UK site:
    return read_file('Pages/uk-2008-12-page1.html');
    # For debugging USA site:
    return read_file('Pages/2008-12.html');
    } # if 0
  # Set up the UA:
  my $ua = new LWP::UserAgent(
                              keep_alive => 1,
                              timeout => 30,
                              agent => $USER_AGENT,
                             );
  # Setting it in the 'new' seems not to work sometimes
  $ua->agent($USER_AGENT);
  # For some reason, this makes stuff work:
  # $ua->max_redirect( 0 );
  # Make a full set of headers:
  my $h = new HTTP::Headers(
                            'Host'            => "www.amazon.$domain",
                            'Referer'         => $url,
                            'User-Agent'      => $USER_AGENT,
                            'Accept'          => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,video/x-mng,image/png,image/jpeg,image/gif;q=0.2,*/*;q=0.1',
                            'Accept-Language' => 'en-us,en;q=0.5',
                            'Accept-Charset'  => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
                            #'Accept-Encoding' => 'gzip,deflate',
                            'Keep-Alive'      =>  '300',
                            'Connection'      =>  'keep-alive',
                           );
  $h->referer("$url");
  my $request  =  HTTP::Request->new ( 'GET', $url, $h );
  my $response;
  my $times = 0;
  # LWP should be able to do this but seemingly fails sometimes
  while ($times++<3)
    {
    $response =  $ua->request($request);
    last if $response->is_success;
    if ($response->is_redirect)
      {
      $url = $response->header("Location");
      #$h->header("Referer", $url); 
      $h->referer("$url");
      $request  =  HTTP::Request->new ( 'GET', $url, $h );
      } # if
    } # while
  if (!$response->is_success)
    {
    croak "Failed to retrieve $url";
    return undef;
    } # if
  my $s = $response->content;
  # Clean the CRAP off the page:
  $s =~ s!<script>.+?</script>!!gs;
  return $s;
  } # _fetch_page

# This is the HTML parsing version written by Martin Thurn:

sub _extract {
  # Required arg1 = whether we are parsing the UK site or not (Boolean):
  my $iUK = shift || 0;
  # Required arg2 = the HTML contents of the webpage:
  my $s = shift || '';
  # Optional arg = debugging level:
  my $iDebug = shift || 0;
  DEBUG_HTML && warn " DDD start _extract()\n";
  my $rh = {};
  my $oTree = new HTML::TreeBuilder;
  $oTree->parse($s);
  $oTree->eof;
  my $sTag = q/div/;
  my $sClass = q/a-fixed-left-grid a-spacing-none/;
  $sClass = q/a-text-left a-fixed-left-grid-col a-col-right/ if $iUK;
  # $sClass = q/a-fixed-left-grid   a-spacing-large/ if $iUK;

  my @aoSPAN = $oTree->look_down(_tag => $sTag,
				 class => $sClass,
      );
  my $iCountSPAN = scalar(@aoSPAN);
  DEBUG_HTML && warn " DDD _extract() found $iCountSPAN $sTag tags of class '$sClass'\n";
 SPAN_TAG:
  foreach my $oSPAN (@aoSPAN)
    {
    next SPAN_TAG unless ref $oSPAN;
    DEBUG_HTML && warn " DDD _extract() found toplevel item tagset\n";
    if (9 < DEBUG_HTML)
      {
      my $s = $oSPAN->as_HTML;
      warn " DDD ==$s==\n";
      } # if
    my $sASIN = q{};
    my $sName = q{};
    my $sTitle = q{};
    my @aoA = $oSPAN->look_down(_tag => 'a');
    DEBUG_HTML && warn sprintf(" DDD _extract(): oSPAN contains %d <A> tags\n", scalar(@aoA));
 A_TAG:
    foreach my $oA (@aoA)
      {
      next A_TAG if ! ref $oA;
      my $sA = $oA->as_HTML;
      DEBUG_HTML && warn " DDD _extract(): try A\n";
      if (9 < DEBUG_HTML)
        {
        warn " DDD ==$sA==\n";
        } # if
      $sTitle = $oA->attr('title') || $oA->as_text;
      # Strip leading whitespace:
      $sTitle =~ s!\A\s+!!;
      # Strip trailing whitespace:
      $sTitle =~ s!\s+\Z!!;
      # Ignore empty (image-only) tags:
      next A_TAG if ($sTitle !~ m/\S/);
      # Strip out zero-width spaces scattered about randomly in item titles
      $sTitle =~ s/\x{200b}//g;
      DEBUG_HTML && warn " DDD _extract(): found item named '$sTitle'\n";
      next A_TAG if ($sTitle eq 'Universal Wish List Button');
      next A_TAG if ($sTitle eq 'Buying this gift elsewhere?');
      my $sURL = $oA->attr('href');
      DEBUG_HTML && warn " DDD _extract(): URL ==$sURL==\n";
      if (
          ($sURL =~ m!/detail(?:/offer-listing)?/-/(.+?)/ref!)
          ||
          ($sURL =~ m!/gp/product/(.+?)/ref!)
          ||
          ($sURL =~ m!/dp/(.+?)/(_encoding|ref)!)
         )
        {
        # It's a match!
        $sASIN = $1;
        last A_TAG;
        } # if
      else
        {
        DEBUG_HTML && warn " EEE   url does not contain asin\n";
        }
      } # foreach A_TAG
    DEBUG_HTML && warn " DDD _extract(): ASIN ==$sASIN==\n";
    if ($sASIN eq q{})
      {
      next SPAN_TAG;
      } # if
    # Grab the smallest-containing ancestor of this item:
    my $oParent = $iUK
                ? $oSPAN->look_up(_tag => 'tbody',
                                  class => 'itemWrapper',
                                 )
                : $oSPAN;
    $oParent = $oSPAN;
    if (! ref $oParent)
      {
      DEBUG_HTML && warn " WWW did not find ancestor TBODY\n";
      next SPAN_TAG;
      } # if
    my $sParentHTML = $oParent->as_HTML;
    DEBUG_HTML && warn " DDD _extract(): parent HTML ==$sParentHTML==\n";
    my $sParent = $oParent->as_text;
    # Manual text clean-up:
    $sParent =~ s/(DESIRED|RECEIVED|PRIORITY)/;  $1: /g;
    DEBUG_HTML && warn " DDD _extract(): parent text ==$sParent==\n";
    my $iDesired = _match_desired($sParent);
    DEBUG_HTML && warn " DDD _extract():     desired set to =$iDesired=\n";
    my $sPriority = _match_priority($sParent);
    DEBUG_HTML && warn " DDD _extract():     priority set to =$sPriority=\n";
    my @aoTDtiny = $oParent->look_down(_tag => 'td',
                                       class => 'tiny',
                                      );
 QUANT_TAG:
    foreach my $oSPAN (@aoTDtiny)
      {
      next QUANT_TAG unless ref $oSPAN;
      my $sSpan = $oSPAN->as_text;
      DEBUG_HTML && warn " DDD _extract():   TDtiny=$sSpan=\n";
      $sPriority ||= _match_priority($sSpan);
      DEBUG_HTML && warn " DDD _extract():     priority set to =$sPriority=\n";
      $iDesired ||= _match_desired($sSpan);
      DEBUG_HTML && warn " DDD _extract():     desired set to =$iDesired=\n";
      } # foreach QUANT_TAG
    if (! $iDesired || ! $sPriority)
      {
      # See if they are encoded in a FORM:
      # Find the priority:
      if ($sParentHTML =~ m!<option selected="yes" value=([-0-9]+)>!)
        {
        $sPriority = $1;
        DEBUG_HTML && warn " DDD _extract():     priority set to =$sPriority=\n";
        } # if
      else
        {
        DEBUG_HTML && warn " WWW   did not find <option> for priority\n";
        }
      # Find the quantity desired:
      if ($sParentHTML =~ m!<input class="tiny" name="requestedQty.+?" size=\d+ type="text" value=(\d+)>!)
        {
        $iDesired = $1;
        DEBUG_HTML && warn " DDD _extract():     desired set to =$iDesired=\n";
        } # if
      else
        {
        DEBUG_HTML && warn " WWW   did not find <input> for desired-quantity\n";
        }
      } # if
    # Put in default values if we never found them:
    $sPriority ||= 'medium';
    DEBUG_HTML && warn " DDD _extract():     priority set to =$sPriority=\n";
    $iDesired ||= 1;
    # Find the date added:
    my $sDate = '';
    if ($sParentHTML =~ m!>added\s+(.+?)<!)
      {
      $sDate = $1;
      DEBUG_HTML && warn " DDD _extract():   date=$sDate=\n";
      } # if
    else
      {
      DEBUG_HTML && warn " WWW   did not find text for date-added\n";
      }

    # Find the "author" of this item:
    my @aoTDauthor;
    if ($iUK)
      {
      @aoTDauthor = $oParent->look_down(_tag => 'td',
                                        class => 'small',
                                       );
      }
    else
      {
      @aoTDauthor = $oParent->look_down(_tag => 'span',
                                        sub
                                          {
                                          my $sHtml = $_[0]->as_HTML;
                                          # DEBUG_HTML && warn " DDD _extract():   try oTDauthor span==$sHtml==\n";
                                          my $s = $_[0]->attr('class') || q{};
                                          $s =~ m'BYLINE'i;
                                          },
                                       );
      } # else
    my $sAuthor = '';
 AUTHOR_TAG:
    foreach my $oTD (@aoTDauthor)
      {
      next AUTHOR_TAG unless ref $oTD;
      my $s = $oTD->as_HTML;
      DEBUG_HTML && warn " DDD _extract():   try oTDauthor==$s==\n";
      $s = $oTD->as_text;
      if ($s =~ s!\A\s*(by|~)\s+!!)
        {
        $sAuthor = $s;
        last AUTHOR_TAG;
        } # if
      } # foreach AUTHOR_TAG
    DEBUG_HTML && warn " DDD _extract():   author=$sAuthor=\n";
    # Find the price of this item:
    my $sPrice = '';
    my $oTDprice = $oParent->look_down(_tag => 'span',
                                       sub
                                         {
                                         my $s = $_[0]->attr('class') || q{};
                                         $s =~ m'PRICE'i;
                                         },
                                      );
    if (! ref $oTDprice)
      {
      DEBUG_HTML && warn " WWW did not find TD for price\n";
      # warn $oParent->as_HTML;
      # exit 88;
      # next SPAN_TAG;
      } # if
    else
      {
      $sPrice = $oTDprice->as_text;
      if ($sPrice =~ m!Price:\s+(.+)\Z!)
        {
        $sPrice = $1;
        } # if
      $sPrice =~ s!\A\s+!!;
      $sPrice =~ s!\s+\Z!!;
      DEBUG_HTML && warn " DDD _extract():   price=$sPrice=\n";
      } # else
    # Add this item to the result set:
    my %hsItem = (
                  asin => $sASIN,
                  author => $sAuthor,
                  # image => $sImageURL,
                  price => $sPrice,
                  priority => $sPriority,
                  quantity => $iDesired,
                  title => $sTitle,
                  # type => $sType,
                 );
    DEBUG_HTML && warn Dumper(\%hsItem);
    # warn " DDD   _extract() added one item to \$rh->{items}\n";
    push @{$rh->{items}}, \%hsItem;
    # All done with this item:
    $oParent->detach;
    $oParent->delete;
    } # foreach SPAN_TAG
  # Look for the next-page link:
  my @aoA = $oTree->look_down(_tag => 'a',
			      role => 'link',
                              sub {
                                return 0 if (length($_[0]->attr('href')) < 55);
                                # my $s = $_[0]->as_text || q{};
                                # DEBUG_NEXT && warn " DDD _extract():   try next <A> ==$s==\n";
                                # $s =~ m/\A\s*(NEXT|SEE\s+MORE)\s*\z/i;
				my $s = $_[0]->attr('class');
				DEBUG_NEXT && warn " DDD _extract():   try next <A> ==$s==\n";
				$s =~ m/wl-see-more/
                                },
                             );
  my $iCountA = scalar(@aoA);
  DEBUG_NEXT && warn " DDD _extract():   found $iCountA <A> tags that match 'next'\n";
  my $oA = shift @aoA;
  if (ref $oA)
    {
    $rh->{next} = $oA->attr('href');
    DEBUG_NEXT && warn " DDD _extract(): raw next URL is ==$rh->{next}==\n";
    } # if
  else
    {
    DEBUG_NEXT && warn " DDD _extract(): did not find next URL\n";
    }
  return $rh;
  } # _extract

sub _match_priority {
  my $s = shift || return;
  if ($s =~ m'PRIORITY:?\s*(\w+?)(\s|\z)'i)
    {
    return lc $1;
    } # if
  return;
  } # _match_priority

sub _match_desired {
  my $s = shift || return;
  if ($s =~ m'(?:DESIRED|WANTS):?\s*(\d+)'i)
    {
    return lc $1;
    } # if
  return;
  } # _match_desired

1;

__END__
