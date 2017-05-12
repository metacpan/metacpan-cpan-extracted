
=head1 COPYRIGHT

                Copyright (C) 2002-present Martin Thurn
                         All Rights Reserved

=head1 NAME

WWW::Ebay::Session - log in to eBay and access account information

=head1 SYNOPSIS

  use WWW::Ebay::Session;
  my $oSession = new WWW::Ebay::Session('ebay-userid', 'ebay-password');

=head1 DESCRIPTION

Allows you to programatically log in as a particular user and fetch
webpages from the eBay auction website (www.ebay.com).

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=head1 METHODS

=over

=cut

package WWW::Ebay::Session;

use strict;
use warnings;

require 5.006;

use Data::Dumper;  # for debugging only
use Date::Manip;
use File::Spec::Functions;
use HTML::Form;
use HTML::TreeBuilder;
use HTTP::Cookies;
use HTTP::Request::Common qw( GET POST );
use LWP::Simple;
use LWP::UserAgent;
use WWW::Ebay::Listing;
use WWW::Search;
# We need the version whose _parse_enddate() takes a string as arg2:
use WWW::Search::Ebay 2.181;
# We need the version that has the shipping() method:
use WWW::SearchResult 2.070;

use constant DEBUG_EMAIL => 0;
use constant DEBUG_FETCH => 0;
use constant DEBUG_FUNC => 0;
use constant DEBUG_SELLING => 0;
use constant DEBUG_SOLD => 0;
use constant DEBUG_UNSOLD => 0;
use constant DEBUG_WATCH => 0;
use constant DEBUG_READ_LOCAL_FILES => 0;

our
$VERSION = 1.65;

sub _debug
  {
  # return unless $iDEBUGGING;
  print STDERR @_;
  } # _debug

=item new

Creates a new object of this type.

=cut

sub new
  {
  my $class = shift;
  # This is NOT a clone method:
  return undef if ref $class;
  my ($sUserID, $sPassword) = @_;
  my $self = {
              # Create cookie jar and UserAgent not now, but only when
              # needed:
              '_cookie_jar' => undef,
              '_user_agent' => undef,
              '_error' => '',
              '_pass' => $sPassword,
              '_user' => $sUserID,
              '_response' => undef,
              '_selling_page' => '',
              'raoSold' => undef,
              'raoSelling' => undef,
              'raoWatching' => undef,
             };
  bless ($self, $class);
  return $self;
  } # new


=item response

Returns the HTTP::Response object that resulted from the most recent page fetched.

=cut

sub response
  {
  my $self = shift;
  if (@_)
    {
    $self->{_response} = shift;
    } # if
  return $self->{_response};
  } # response

=item signin

This method can be called if you only need the encrypted password.

=cut

my %hssPasswords;

sub signin
  {
  my $self = shift;
  my $sUserID = $self->{_user} || '';
  my $sPassword = $self->{_pass} || '';
  DEBUG_FUNC && print STDERR " DDD Ebay::Session::signin($sUserID)\n";
  print STDERR " DDD signin($sUserID,$sPassword)\n" if DEBUG_FETCH;
  if (! exists($hssPasswords{$sUserID}))
    {
    # Get the sign-in page and parse it:
    print STDERR " DDD   fetching ebay sign-in page...\n" if DEBUG_FETCH;
    # my $sPage = $self->fetch_any_ebay_page('http://cgi.ebay.com/aw-cgi/eBayISAPI.dll?SignIn', 'signin', 'ignore-refresh');
    my $sPage = $self->fetch_any_ebay_page('http://signin.ebay.com/ws/eBayISAPI.dll?SignIn&ssPageName=h:h:sin:US', 'signin', 'ignore-refresh');
    # http://signin.ebay.com/ws/eBayISAPI.dll?SignIn&ssPageName=h:h:sin:US&ru=http%3A//my.ebay.com/ws/ebayISAPI.dll%3FMyeBay%26CurrentPage%3DMyeBayAllSelling
    # NEW: No encrypted password sent, only cookies.  See if the
    # sign-in succeeded:
    $hssPasswords{$sUserID} = ($sPage =~ m!If you are seeing this page,!i) ? 1 : 'FAILED';
    # OLD: Grab a copy of the encrypted password:
    # $hssPasswords{$sUserID} = ($sPage =~ m!(&|;)pass=(.+?)&!) ? $2 : 'FAILED';
    } # if
  return $hssPasswords{$sUserID};
  } # signin


=item fetch_any_ebay_page

=cut

sub fetch_any_ebay_page
  {
  my $self = shift;
  # Required arg1 == HTTP::Request object, or URL as string:
  my $oReq = shift;
  # Optional arg2 == name of this page (for debugging msgs):
  my $sName = shift() || '';
  # Optional arg3 == whether to ignore meta-refresh tags (default is
  # to follow redirects):
  my $iIgnoreRefresh = shift() || 0;
  DEBUG_FUNC && print STDERR " DDD Ebay::Session::fetch_any($sName)\n";
  my $fname = "Pages/$sName.html";
  my $sPage = '';
  if (DEBUG_READ_LOCAL_FILES && ($sName ne '') && -f $fname)
    {
    unless (open DBG, "<$fname")
      {
      print STDERR " --- DEBUG_READ_LOCAL_FILES is on, but can not open $fname for read: $!\n";
      return '';
      } # unless
    local $/ = undef; # slurp entire file
    $sPage = <DBG>;
    close DBG;
    return $sPage;
    } # if
  print STDERR " DDD in fetch_any_ebay_page, oReq is $oReq\n" if DEBUG_FETCH;
  my $ref = ref $oReq;
  unless ((defined $ref) && ($ref =~ m!HTTP::!))
    {
    # Argument is not a Request object; assume it's a string URL, or a
    # URI object:
    $oReq = new HTTP::Request(GET => $oReq);
    } # unless
  my $sURL = $oReq->uri;
 REQUEST_READY:
  $self->cookie_jar->add_cookie_header($oReq);
  my $sReq = $oReq->as_string;
  if ($sName ne '')
    {
    print STDERR " DDD   the HTTP::Request for $sName is $sReq" if DEBUG_FETCH;
    } # if
  $self->response($self->user_agent->request($oReq));
  my $sRes = $self->response->as_string;
  DEBUG_FETCH && print STDERR " DDD   the HTTP::Response for $sName is ==========$sRes==========";
  my $sURLprev = '';
 OBJECT_MOVED:
  while ($self->response->code == 302)
    {
    print STDERR " DDD     server says: Object Moved\n" if DEBUG_FETCH;
    $sReq .= "<!-- 302 object moved -->\n";
    $sURLprev = $sURL;
    $sURL = $self->response->header('Location');
    $oReq = GET $sURL;
    $oReq->referer($sURLprev);
    $self->cookie_jar->add_cookie_header($oReq);
    print STDERR " DDD   the new HTTP::Request for $sName is ", $oReq->as_string if DEBUG_FETCH;
    $sReq .= $oReq->as_string;
    $self->response($self->user_agent->request($oReq));
    } # while
 META_REFRESH:
  while (! $iIgnoreRefresh && ($self->response->content =~ m!<meta\s+http-equiv="Refresh"\s+content="\d+;\s+url\s*=\s*([^"]+)">!i))
    {
    $sURLprev = $sURL;
    $sURL = $1;
    $sURL =~ s!&amp;!&!g;
    print STDERR " DDD     server says: Meta-Refresh to $sURL\n" if DEBUG_FETCH;
    $oReq = GET $sURL;
    $oReq->referer($sURLprev);
    $self->cookie_jar->add_cookie_header($oReq);
    print STDERR " DDD   the new HTTP::Request for $sName is ", $oReq->as_string if DEBUG_FETCH;
    $sReq .= "<!-- 200 meta refresh -->\n";
    $sReq .= $oReq->as_string;
    $self->response($self->user_agent->request($oReq));
    } # while
  $sRes = $self->response->headers_as_string;
  if (! $self->response->is_success)
    {
    my $fname1 = "Pages/$sName-fail.html";
    if (($sName ne '') && (open ERR, ">$fname1"))
      {
      print STDERR " --- eBay $sName failed: can not get page: ", $self->response->status_line, "\n" if DEBUG_FETCH;
      print ERR "<!-- This page came from this request:\n$sReq\n-->\n\n";
      print ERR "<!-- The response headers for this page are:\n$sRes\n-->\n\n";
      print ERR $self->response->content;
      close ERR;
      print STDERR " ---   what we did get back was saved in $fname1\n" if DEBUG_FETCH;
      } # if
    return '';
    } # unless
  $sPage = $self->response->content;
  if ($sPage =~ m!"SignInForm"!)
    {
    # We need to sign-in before we get to see the requested page:
    my $fname1 = "Pages/$sName-signin.html";
    if (DEBUG_FETCH && ($sName ne '') && (open PAGE, '>', $fname1))
      {
      print PAGE "<!-- This page came from this request:\n$sReq\n-->\n\n";
      print PAGE "<!-- The response headers for this page are:\n$sRes\n-->\n\n";
      print PAGE $sPage;
      close PAGE;
      print STDERR " DDD eBay GET $sName saved in $fname1\n" if DEBUG_FETCH;
      } # if
    print STDERR " DDD parsing ebay sign-in page...\n" if DEBUG_FETCH;
    # Parse the <FORM> elements:
    my @aoForm = HTML::Form->parse($sPage, $self->response->base);
    # As of August 2014, the sign-in form is the first one on the page:
    my $oForm = $aoForm[0];
    unless (ref $oForm)
      {
      print STDERR " EEE eBay sign-in page contained no <FORM> element!\n" if DEBUG_FETCH;
      return undef;
      } # unless
    print STDERR " DDD   got a FORM...\n" if DEBUG_FETCH;
    # Insert the user's values:
    $oForm->value('userid', $self->{_user});
    $oForm->value('pass', $self->{_pass});
    # Request a cookie to reduce bandwidth:
    $oForm->value('keepMeSignInOption', 1);
    # Submit the form and get our cookie:
    $oReq = $oForm->click;
    $oReq->referer($sURLprev);
    $sURLprev = $sURL;
    print STDERR " DDD   CLICK is ", Dumper($oReq) if DEBUG_FETCH;
    print STDERR " DDD submitting password to ebay...\n" if DEBUG_FETCH;
    goto REQUEST_READY;
    } # if we got a sign-in page
  elsif (($sPage =~ m!"AdultLogin"!)
         ||
         ($sPage =~ m!Terms of Use: Mature Audiences Category!)
        )
    {
    my $fname1 = "Pages/$sName-adultlogin.html";
    if (DEBUG_FETCH && ($sName ne '') && (open PAGE, '>', $fname1))
      {
      print PAGE "<!-- This page came from this request:\n$sReq\n-->\n\n";
      print PAGE "<!-- The response headers for this page are:\n$sRes\n-->\n\n";
      print PAGE $sPage;
      close PAGE;
      print STDERR " DDD eBay GET $sName saved in $fname1\n" if DEBUG_FETCH;
      } # if
    # We need to accept the "Mature" disclaimer before we get to see
    # the requested page.  Parse the <FORM> elements:
    my @aoForm = HTML::Form->parse($sPage, $self->response->base);
    # The adult-consent form is the last one on the page:
    my $oForm = $aoForm[-1];
    unless (ref $oForm)
      {
      print STDERR " --- eBay adult-consent page's <FORM> was not valid?\n" if DEBUG_FETCH;
      return undef;
      } # unless
    print STDERR " DDD   got a FORM...\n" if DEBUG_FETCH;
    # Submit the form and get our cookie:
    $oReq = $oForm->click;
    $oReq->referer($sURLprev);
    $sURLprev = $sURL;
    print STDERR " DDD giving adult-consent to ebay...\n" if DEBUG_FETCH;
    print STDERR " DDD   CLICK is ", Dumper($oReq) if DEBUG_FETCH;
    goto REQUEST_READY;
    }
  else
    {
    # No special action required, we got the requested page:
    my $sRes = $self->response->headers_as_string;
    if (DEBUG_FETCH && ($sName ne '') && (open PAGE, '>', $fname))
      {
      print PAGE "<!-- This page came from this request:\n$sReq\n-->\n\n";
      print PAGE "<!-- The response headers for this page are:\n$sRes\n-->\n\n";
      print PAGE $sPage;
      close PAGE;
      print STDERR " DDD eBay GET $sName saved in $fname\n" if DEBUG_FETCH;
      } # if
    } # else
  return $sPage;
  } # fetch_any_ebay_page


=item any_error

Returns non-zero if there are any error messages in the object.

=cut

sub any_error
  {
  shift->error ne ''
  } # any_error

sub _add_error
  {
  local $" = "";
  shift->{'_error'} .= "@_";
  } # _add_error

=item error

Returns a string, the most recent error message(s).

=cut

sub error
  {
  shift->{'_error'} || '';
  } # error

=item clear_errors

Removes all error messages from the object.

=cut

sub clear_errors
  {
  shift->{'_error'} = '';
  } # clear_errors


sub _epoch_of_date
  {
  return UnixDate(&ParseDate(shift), '%s');
  } # _epoch_of_date

=item selling_page

Returns the HTML of the "My Selling" page for this user.

=cut

sub selling_page
  {
  my $self = shift;
  if ($self->{_selling_page} ne '')
    {
    DEBUG_SELLING && print STDERR " DDD   short-circuited _selling_page\n";
    return $self->{_selling_page};
    } # if
  my $sUserID = $self->{_user};
  my $sPasswordEncrypted = $self->signin();
  print STDERR " DDD sPasswordEncrypted is ===$sPasswordEncrypted===\n" if DEBUG_FETCH;
  # my $sURL = qq{http://cgi6.ebay.com/aw-cgi/eBayISAPI.dll?MfcISAPICommand=MyeBayItemsSelling&userid=$sUserID&pass=$sPasswordEncrypted&dayssince=30};
  my $sURL = qq{http://cgi6.ebay.com/aw-cgi/ebayISAPI.dll?MyeBayItemsSelling&userid=$sUserID&pass=$sPasswordEncrypted&first=N&sellerSort=3&bidderSort=3&watchSort=3&dayssince=30};
  $sURL = qq{http://my.ebay.com/ws/ebayISAPI.dll?MyeBay&userid=$sUserID&pass=$sPasswordEncrypted&first=N&sellerSort=3&bidderSort=3&watchSort=3&dayssince=30};
  my $sPage = $self->fetch_any_ebay_page($sURL, 'selling');
  $self->{_selling_page} = $sPage;
  return $sPage;
  } # selling_page


=item watchlist_auctions

Returns a list of WWW::Ebay::Listing objects.

Note that any time/dates returned will be U.S. Pacific time zone.

=cut

sub watchlist_auctions
  {
  my $self = shift;
  return @{$self->{raoWatching}} if $self->{raoWatching};
  my $sFname = shift() || '';
  my $sPage = $self->selling_page;
  if (($sFname ne '') && (open PAGE, '>', $sFname))
    {
    print PAGE $sPage;
    close PAGE or warn;
    } # if
  _debug " DDD   start parsing webpage...\n" if DEBUG_WATCH;
  # Date_Init('TZ=US/Pacific');
  # Our return value, a list of WWW::Search::Result objects:
  my @aoWSR;

  my $oTree = $self->{_selling_tree} || HTML::TreeBuilder->new_from_content($sPage);
  unless (ref $oTree)
    {
    _debug " --- can not parse the response from ebay\n";
    return ();
    } # unless
  $self->{_selling_tree} = $oTree;
  my @aoTDtitle = $oTree->look_down(_tag => 'td',
                                    class => 'c_Title',
                                    colspan => 5,
                                   );
 TITLE_TD_TAG:
  foreach my $oTDtitle (@aoTDtitle)
    {
    next TITLE_TD_TAG unless ref $oTDtitle;
    _debug " DDD   got a TDtitle...\n" if DEBUG_WATCH;
    my $oA = $oTDtitle->look_down(_tag => 'a');
    next TITLE_TD_TAG unless ref $oA;
    _debug " DDD     has an A...\n" if DEBUG_WATCH;
    my $sURL = $oA->attr('href');
    my $sTitle = $oA->as_text || next TITLE_TD_TAG;
    _debug " DDD     has a title...\n" if DEBUG_WATCH;
    # Get the parent row:
    my $oTRparent = $oTDtitle->look_up(_tag => 'tr');
    next TITLE_TD_TAG unless ref $oTRparent;
    _debug " DDD     has a parent TR...\n" if DEBUG_WATCH;
    # Get the next row:
    my $oTRaunt = $oTRparent->right;
    next TITLE_TD_TAG unless ref $oTRaunt;
    _debug " DDD     has an aunt TR...\n" if DEBUG_WATCH;
    # Create a new result item:
    my $oWSR = new WWW::Search::Result;
    $oWSR->add_url($sURL);
    $oWSR->title($sTitle);
    push @aoWSR, $oWSR;
    # Get the cells of that row:
    my @aoTD = $oTRaunt->look_down(_tag => 'td');
 COUSIN_TD_TAG:
    foreach my $oTD (@aoTD)
      {
      next COUSIN_TD_TAG unless ref $oTD;
      my $sClass = $oTD->attr('class');
      _debug " DDD       has a $sClass TD...\n" if DEBUG_WATCH;
      if ($sClass =~ m!price!i)
        {
        $oWSR->bid_amount($oTD->as_text);
        _debug " DDD       has a price TD...\n" if DEBUG_WATCH;
        } # if CurrentPrice
      if ($sClass =~ m!shipping!i)
        {
        $oWSR->shipping($oTD->as_text);
        _debug " DDD       has a shipping TD...\n" if DEBUG_WATCH;
        } # if CurrentPrice
      elsif ($sClass =~ m!bids!i)
        {
        my $s = $oTD->as_text;
        $s = 0 if ($s eq '--');
        $oWSR->bid_count(0 + $s);
        _debug " DDD       has a bids TD...\n" if DEBUG_WATCH;
        } # if Bids
      elsif ($sClass =~ m!bidder!i)
        {
        $oWSR->bidder($oTD->as_text);
        _debug " DDD       has a bidder TD...\n" if DEBUG_WATCH;
        } # if Bids
      elsif ($sClass =~ m!seller!i)
        {
        $oWSR->seller($oTD->as_text);
        _debug " DDD       has a seller TD...\n" if DEBUG_WATCH;
        } # if Bids
      elsif ($sClass =~ m!watchers!i)
        {
        $oWSR->watcher_count(0 + $oTD->as_text);
        _debug " DDD       has a watchers TD...\n" if DEBUG_WATCH;
        } # if Watchers
      elsif ($sClass =~ m!questions!i)
        {
        $oWSR->question_count(0 + $oTD->as_text);
        _debug " DDD       has a questions TD...\n" if DEBUG_WATCH;
        } # if Questions
      elsif ($sClass =~ m!timeleft!i)
        {
        my $oWSE = new WWW::Search('Ebay') or next COUSIN_TD_TAG;
        $oWSE->_parse_enddate($oTD->as_text, $oWSR);
        _debug " DDD       has an enddate TD...\n" if DEBUG_WATCH;
        }
      } # foreach COUSIN_TD_TAG
    } # foreach TITLE_TD_TAG
  $self->{raoWatching} = \@aoWSR;
  return @aoWSR;
  } # watchlist_auctions


=item selling_auctions

Returns a list of WWW::Ebay::Listing objects representing the auctions
currently active.

Note that any time/dates returned will be U.S. Pacific time zone.

=cut

sub selling_auctions
  {
  my $self = shift;
  return @{$self->{raoSelling}} if $self->{raoSelling};
  my $sFname = shift() || '';
  my $sPage = $self->selling_page;
  if (($sFname ne '') && (open PAGE, '>', $sFname))
    {
    print PAGE $sPage;
    close PAGE or warn;
    } # if
  _debug " DDD   start parsing webpage...\n" if DEBUG_SELLING;
  # Date_Init('TZ=US/Pacific');
  # Our return value, a list of WWW::Ebay::Listing objects:
  my @aoWEL;

  my $oTree = $self->{_selling_tree} || HTML::TreeBuilder->new_from_content($sPage);
  unless (ref $oTree)
    {
    _debug " --- can not parse the response from ebay\n";
    return ();
    } # unless
  $self->{_selling_tree} = $oTree;
 PARSE_SELLING_SECTION:
  while (1)
    {
    # This is a fake (infinite) loop which allows us to use 'last'
    # rather than 'goto'.
    my $iCount = 0;
    my $oAselling = $oTree->look_down('_tag' => 'span',
                                      class => 'B',
                                      sub { $_[0]->as_text eq q(Items I'm Selling) },
                                     );
    if (ref $oAselling)
      {
      DEBUG_SELLING && _debug(" DDD   found <SPAN> for SELLING section: ", $oAselling->as_HTML, "\n");
      $oAselling = $oAselling->look_up(_tag => 'td');
      last PARSE_SELLING_SECTION if ! ref($oAselling);
      DEBUG_SELLING && _debug(" DDD     parent is ==", $oAselling->as_HTML, "==\n");
      my $s = $oAselling->as_text;
      $s =~ m!\s+\(\s*(\d+)\s+ITEM!i;
      $iCount = $1 || 0;
      print STDERR " DDD   there should be $iCount SELLING auctions\n" if DEBUG_SELLING;
      } # if
    else
      {
      $self->_add_error("Did not find <TD> for SELLING section.  ");
      }
    if ($iCount <= 0)
      {
      last PARSE_SELLING_SECTION;
      } # if
    my $oTable = $oTree->look_down(_tag => 'table',
                                   id => 'Selling',
                                  );
    if (! ref $oTable)
      {
      $self->_add_error("Did not find <TABLE> for SELLING section.  ");
      last PARSE_SELLING_SECTION;
      } # if
    my @asColumns = qw( spacer price bids bidder watchers questions time_left );
    DEBUG_SELLING && _debug(" DDD   selling <TABLE> is ==", $oTable->as_HTML, "==\n");
    my @aoTR = $oTable->look_down('_tag' => 'tr');
    # Throw out the header row:
    shift @aoTR;
 TR:
    while (my $oTR = shift @aoTR)
      {
      my ($oTD, $s);
      next unless ref $oTR;
      # Got a row containing an auction.  Actually they are pairs of
      # rows; one row has the auction title, the next row has all the
      # details.
      DEBUG_SELLING && _debug(" DDD   <TR> containing selling auction title ==", $oTR->as_HTML, "==\n");
      my $oA = $oTR->look_down('_tag' => 'a',
                               sub
                                 {
                                 defined($_[0]->attr('href'))
                                 &&
                                 $_[0]->attr('href') =~ m!ViewItem!
                                 },
                              );
      next TR unless ref $oA;
      # Make sure this is really an auction title/link:
      next TR unless defined($oA->attr('href'));
      my $sURL = $oA->attr('href');
      next TR unless ($sURL =~ m!ViewItem!);
      next TR unless ($sURL =~ m!item=(\d+)!);
      my $iItem = $1;
      # OK, we've got an auction.
      my $oWEL = new WWW::Ebay::Listing;
      my $sTitle = $oA->as_text;
      $sTitle =~ s![\s\t\r\n]+\Z!!;
      $oWEL->title($sTitle);
      $oWEL->id($iItem);
      $oWEL->status->listed('yes');
      print STDERR " DDD     title ==$sTitle==\n" if DEBUG_SELLING;
      # Go to the next row, where we should find the auction details:
      $oTR = $oTR->right; # shift @aoTR;
      if (! ref($oTR))
        {
        $self->_add_error("Did not find slave <TR> for ITEM.  ");
        next TR;
        } # if
      DEBUG_SELLING && _debug(" DDD   <TR> containing selling auction details ==", $oTR->as_HTML, "==\n");
      my @aoTD = $oTR->look_down('_tag' => 'td');
 SELLING_COLUMN:
      foreach my $sCol (@asColumns)
        {
        $oTD = shift @aoTD;
        if (! ref($oTD))
          {
          $self->_add_error("Did not find <TD> for $sCol column.  ");
          next TR;
          } # if
        if ($sCol eq 'price')
          {
          $s = $oTD->as_text;
          # Keep just the numeric portion:
          $s =~ tr!.0123456789!!dc;
          if ($s !~ m!\d!)
            {
            $self->_add_error("ITEM's current bid '$s' is not a number.  ");
            next TR;
            } # if
          # Convert dollars to cents:
          $oWEL->bidmax(int(eval($s) * 100));
          }
        elsif ($sCol eq 'bids')
          {
          # Column 3 = Number of Bids
          $s = $oTD->as_text;
          $s = 0 if $s =~ m!n/a!;
          $oWEL->bidcount($s);
          }
        elsif ($sCol eq 'bidder')
          {
          # Column 4 = current bidder
          }
        elsif ($sCol eq 'watchers')
          {
          # Column 5 = number of watchers
          }
        elsif ($sCol eq 'questions')
          {
          # Column 6 = number of questions
          }
        elsif ($sCol eq 'time_left')
          {
          # Column 7 = Time Left
          my $sDateRaw = my $sDate = $oTD->as_text;
          $sDate =~ s!d! days!;
          $sDate =~ s!h! hours!;
          $sDate =~ s!m! minutes!;
          my $date = DateCalc('now', " + $sDate");
          my $sDateEnd = _epoch_of_date($date);
          $oWEL->dateend($sDateEnd);
          print STDERR " DDD   end date: raw ==$sDateRaw== cooked ==$sDate== date==$date==\n" if DEBUG_SELLING;
          }
        } # foreach SELLING_COLUMN
      push @aoWEL, $oWEL;
      } # while $oTR
    last PARSE_SELLING_SECTION;
    } # end of fake while(1) loop for PARSE_SELLING_SECTION
  $self->{raoSelling} = \@aoWEL;
  return @aoWEL;
  } # selling_auctions


=item sold_auctions

Returns a list of WWW::Ebay::Listing objects representing the auctions
that have ended and received bids.

Note that any time/dates returned will be U.S. Pacific time zone.

=cut

sub sold_auctions
  {
  my $self = shift;
  return @{$self->{raoSold}} if $self->{raoSold};
  my $sFname = shift() || '';
  my $sPage = $self->selling_page;
  if (($sFname ne '') && (open PAGE, '>', $sFname))
    {
    print PAGE $sPage;
    close PAGE or warn;
    } # if
  _debug " DDD   start parsing webpage...\n" if DEBUG_SOLD;
  # Date_Init('TZ=US/Pacific');
  # Our return value, a list of WWW::Ebay::Listing objects:
  my $oTree;
  if (ref $self->{_selling_tree})
    {
    $oTree = $self->{_selling_tree};
    DEBUG_SOLD && print STDERR " DDD   short-circuited _selling_tree\n";
    }
  else
    {
    $oTree = HTML::TreeBuilder->new_from_content($sPage);
    unless (ref $oTree)
      {
      _debug " --- can not parse the response from ebay\n";
      return ();
      } # unless
    $self->{_selling_tree} = $oTree;
    }
  my @aoWEL;
 PARSE_SOLD_SECTION:
  while (1)
    {
    my $iCount = 0;
    my $oA = $oTree->look_down('_tag' => 'span',
                               class => 'B',
                               sub { $_[0]->as_text eq q(Items I've Sold) },
                              );
    if (ref $oA)
      {
      DEBUG_SOLD && _debug(" DDD   found <SPAN> for SOLD section: ", $oA->as_HTML, "\n");
      $oA = $oA->parent;
      my $s = $oA->as_text;
      $iCount = -1;
      if ($s =~ m!\(\s*(\d+)\s+ITEM!i)
        {
        $iCount = $1;
        DEBUG_SOLD && _debug(" DDD   there should be $iCount sold auctions\n");
        } # if
      } # if
    else
      {
      $self->_add_error("Did not find <SPAN> for SOLD section.  ");
      last PARSE_SOLD_SECTION;
      }
    last PARSE_SOLD_SECTION if ($iCount < 0);
    my $oTable = $oTree->look_down(_tag => 'table',
                                   id => 'Sold',
                                  );
    if (! ref $oTable)
      {
      $self->_add_error("Did not find <TABLE> for SOLD section.  ");
      last PARSE_SOLD_SECTION;
      } # if
    # print STDERR " DDD   sold <TABLE> is ==", $oTable->as_HTML, "==\n" if DEBUG_SOLD;
    my @aoTR = $oTable->look_down(_tag => 'tr',
                                  bgcolor => '#f4f4f4',
                                 );
 SOLD_TR:
    while (my $oTR = shift @aoTR)
      {
      my ($oTD, $s);
      next SOLD_TR unless ref $oTR;
      # Got a row containing an auction.  Actually they are groups of
      # rows; one row has the buyer's ID, the next rows have all the
      # auctions that person won.
      _debug(" DDD   <TR> containing seller ==", $oTR->as_HTML, "==\n") if (2 < DEBUG_SOLD);
      my @aoTD = $oTR->look_down(_tag => 'td');
      # Column 1 = checkbox:
      $oTD = shift @aoTD;
      # Column 2 = winner:
      $oTD = shift @aoTD;
      my $oA = $oTD->look_down('_tag' => 'strong');
      next SOLD_TR unless ref $oA;
      my $sWinnerID = $oA->as_text;
      # In case this person won one auction, all the details are in
      # this row:

      my $oWEL = new WWW::Ebay::Listing;
      $oWEL->winnerid($sWinnerID);
      # We know this auction has ended because this is the "sold"
      # section of the page:
      $oWEL->status->listed('yes');
      $oWEL->status->ended('yes');
      # Next column = quantity:
      $oTD = shift @aoTD;
      DEBUG_SOLD && _debug(" DDD   quantity <TD> ==", $oTD->as_HTML, "==\n");
      # next Column = Bid Price
      $oTD = shift @aoTD;
      if (! ref($oTD))
        {
        $self->_add_error("Did not find <TD> for SOLD ITEM end price.  ");
        next SOLD_TR;
        } # if
      DEBUG_SOLD && _debug(" DDD     <TD> containing EndPrice ==", $oTD->as_HTML, "==\n");
      $s = $oTD->as_text;
      print STDERR " DDD     raw End Price is ==$s==\n" if DEBUG_SOLD;
      $s =~ tr!.0123456789!!dc;
      # Convert dollars to cents:
      my $iBidCents = int((0.005 + $s) * 100);
      print STDERR " DDD     Bid Cents is ==$iBidCents==\n" if DEBUG_SOLD;
      $oWEL->bidmax($iBidCents);
      # next Column = Total Price with shipping.  If the buyer has not
      # done checkout (and the seller has not sent an invoice), this
      # will be '--'.
      $oTD = shift @aoTD;
      DEBUG_SOLD && _debug(" DDD   <TD> of total price ==", $oTD->as_HTML, "==\n");
      $s = $oTD->as_text || '';
      print STDERR " DDD     raw Total Price is ==$s==\n" if DEBUG_SOLD;
      if ($s eq '--')
        {
        $oWEL->shipping('unknown');
        }
      else
        {
        $s =~ tr!.0123456789!!dc;
        if ($s !~ m!\d!)
          {
          $self->_add_error("sold item's total price is not a number.  ");
          next SOLD_TR;
          } # if
        # Convert dollars to cents:
        my $iTotalCents = int((0.005 + $s) * 100);
        print STDERR " DDD     Total Cents is ==$iTotalCents==\n" if DEBUG_SOLD;
        my $iShippingCents = $iTotalCents - $iBidCents;
        $oWEL->shipping($iShippingCents);
        } # else
      # Go to the next row:
      $oTR = $oTR->left;
      if (! ref $oTR)
        {
        next SOLD_TR;
        } # if
      DEBUG_SOLD && _debug(" DDD   <TR> of next row ==", $oTR->as_HTML, "==\n");
      $oA = $oTR->look_down(_tag => 'a');
      next SOLD_TR unless ref $oA;
      DEBUG_SOLD && _debug(" DDD   <A> of title ==", $oA->as_HTML, "==\n");
      my $sTitle = $oA->as_text;
      $sTitle =~ s![\s\t\r\n]+\Z!!;
      $oWEL->title($sTitle);
      my $sURL = $oA->attr('href');
      next SOLD_TR unless ($sURL =~ m!ViewItem!);
      next SOLD_TR unless ($sURL =~ m!item=(\d+)!);
      my $iItem = $1;
      $oWEL->id($iItem);
      push @aoWEL, $oWEL;
      } # while
    last PARSE_SOLD_SECTION;
    } # end of fake while(1) loop for PARSE_SOLD_SECTION
  $self->{raoSold} = \@aoWEL;
  return @aoWEL;
  } # sold_auctions


=item unsold_auctions

Returns a list of WWW::Ebay::Listing objects representing the auctions
that have ended but received no bids.

Note that any time/dates returned will be U.S. Pacific time zone.

=cut

sub unsold_auctions
  {
  my $self = shift;
  return @{$self->{raoUnsold}} if $self->{raoUnsold};
  my $sFname = shift() || '';
  my $sPage = $self->selling_page;
  if (($sFname ne '') && (open PAGE, '>', $sFname))
    {
    print PAGE $sPage;
    close PAGE or warn;
    } # if
  _debug " DDD   start parsing webpage...\n" if DEBUG_UNSOLD;
  # Date_Init('TZ=US/Pacific');
  # Our return value, a list of WWW::Ebay::Listing objects:
  my @aoWEL;

  my $oTree = $self->{_selling_tree} || HTML::TreeBuilder->new_from_content($sPage);
  unless (ref $oTree)
    {
    _debug " --- can not parse the response from ebay\n";
    return ();
    } # unless
  $self->{_selling_tree} = $oTree;
 PARSE_UNSOLD_SECTION:
  while (1)
    {
    # This is a fake (infinite) loop which allows us to use 'last'
    # rather than 'goto'.
    my $iCount = 0;
    my $oAunsold = $oTree->look_down('_tag' => 'a',
                                      'name' => 'unsold',
                                     );
    if (ref $oAunsold)
      {
      print STDERR " DDD   found <A> for UNSOLD section: ", $oAunsold->as_HTML, "\n" if DEBUG_UNSOLD;
      my $s = $oAunsold->as_text;
      $s =~ m!\(\s*(\d+)\s+Items?!;
      $iCount = $1 || 0;
      print STDERR " DDD   there should be $iCount UNSOLD auctions\n" if DEBUG_UNSOLD;
      } # if
    if ($iCount <= 0)
      {
      last PARSE_UNSOLD_SECTION;
      } # if
    my $oTable = $oAunsold->look_up('_tag' => 'table');
    if (! ref $oTable)
      {
      $self->_add_error("Did not find master <TABLE> for UNSOLD section.  ");
      last PARSE_UNSOLD_SECTION;
      } # if
    print STDERR " DDD   ancestor <TABLE> is ==", $oTable->as_HTML, "==\n" if DEBUG_UNSOLD;
    # The heart of the matter is in the n-th table over from this one:
    my $iTable = 2;
    do
      {
      $oTable = $oTable->right;
      if (ref $oTable)
        {
        $iTable-- if ($oTable->tag eq 'table');
        } # if
      else
        {
        # bail!
        $oTable = 0;
        }
      } until ($iTable < 1);
    if (! ref $oTable)
      {
      $self->_add_error("Did not find slave <TABLE> for UNSOLD section.  ");
      last PARSE_UNSOLD_SECTION;
      } # if
    print STDERR " DDD   n-th TABLE sibling of ancestor <TABLE> is ==", $oTable->as_HTML, "==\n" if DEBUG_UNSOLD;
    my @aoTR = $oTable->look_down('_tag' => 'tr');
 TR:
    while (my $oTR = shift @aoTR)
      {
      my ($oTD, $s);
      next unless ref $oTR;
      # Got a row containing an auction.  Actually they are pairs of
      # rows; one row has the auction title, the next row has all the
      # details.
      print STDERR " DDD   <TR> containing unsold auction title ==", $oTR->as_HTML, "==\n" if DEBUG_UNSOLD;
      my $oA = $oTR->look_down('_tag' => 'a');
      next TR unless ref $oA;
      # Make sure this is really an auction title/link:
      next TR unless defined($oA->attr('href'));
      next TR unless ($oA->attr('href') =~ m!ViewItem!);
      # OK, we've got an auction.
      my $oWEL = new WWW::Ebay::Listing;
      my $sTitle = $oA->as_text;
      $sTitle =~ s![\s\t\r\n]+\Z!!;
      $oWEL->title($sTitle);
      print STDERR " DDD     title ==$sTitle==\n" if DEBUG_UNSOLD;
      $oTD = $oA->look_up('_tag' => 'td');
      next TR unless ref $oTD;
      $oTD = $oTD->left;
      next TR unless ref $oTD;
      print STDERR " DDD     <TD> containing Item# ==", $oTD->as_HTML, "==\n" if DEBUG_UNSOLD;
      $s = $oTD->as_text;
      # Delete all but numbers:
      $s =~ tr!0123456789!!dc;
      $oWEL->id($s);
      $oWEL->status->listed('yes');
      $oWEL->status->ended('yes');
      push @aoWEL, $oWEL;
      } # while $oTR
    last PARSE_UNSOLD_SECTION;
    } # end of fake while(1) loop for PARSE_UNSOLD_SECTION
  $self->{raoUnsold} = \@aoWEL;
  return @aoWEL;
  } # unsold_auctions

# =item get_user_email

# Takes two arguments: the eBay userid of the person whose email you seek;
# and an auction ID in which you and that person were involved together.

# Returns that user's email address.
# If an error occurs, prints an error message to STDOUT and returns empty string.

# =cut

# eBay does not allow users to obtain other user's email.  We have to
# use ebay's interface to send an email message to another user.

sub _get_user_email_OLD
  {
  my $self = shift;
  my ($sUserID, $iAuctionID) = @_;
  DEBUG_EMAIL && _debug(" DDD get_user_email($sUserID,$iAuctionID)\n");

  # <form name="contactmember" method="post" style="margin: 0;" action="http://contact.ebay.com/ws1/eBayISAPI.dll"><input type="hidden" name="MfcISAPICommand" value="ReturnUserEmail"><input type="hidden" name="requested" value="watto2000"><input type="hidden" name="frm" value="284"><input type="hidden" name="iid" value="2993844956"><input type="hidden" name="de" value="off"><input type="hidden" name="redirect" value="0"><input type="submit" name="contactsubmit" value="Contact Member"></form>
  my $sURL = 'http://contact.ebay.com/ws1/eBayISAPI.dll?MfcISAPICommand=ReturnUserEmail&requested=__USER__&frm=284&iid=__AUCTION__&de=off&redirect=0';
  $sURL =~ s!__USER__!$sUserID!e;
  $sURL =~ s!__AUCTION__!$iAuctionID!e;
  DEBUG_EMAIL && _debug(" DDD   url ==$sURL==\n");
  my $sPage = $self->fetch_any_ebay_page($sURL, 'contact');
  if ($sPage =~ m!\shref="mailto:(.+?)"!)
    {
    return $1;
    } # if
  DEBUG_EMAIL && _debug(" --- parse error: can not parse user-email page\n");
  return '';
  } # _get_user_email_OLD


=item cookie_jar

=cut

sub cookie_jar
  {
  my $self = shift;
  my $arg = shift() || 0;
  DEBUG_FUNC && _debug(" DDD Ebay::Session::c_jar($arg)\n");
  if ($arg)
    {
    # If argument is given, replace current jar:
    $self->{_cookie_jar} = $arg;
    } # if
  # If jar is still not defined, create one:
  $self->{_cookie_jar} ||= new HTTP::Cookies;
  # Return the jar:
  $self->{_cookie_jar};
  } # cookie_jar


=item user_agent

Returns a user_agent suitable for requesting Ebay webpages.
If you need special processing on your network, you can override this method.
You need to set the cookie_jar to $self->cookie_jar.

=cut

sub user_agent
  {
  my $self = shift;
  DEBUG_FUNC && _debug(" DDD Ebay::Session::user_agent()\n");
  if (! ref $self->{_user_agent})
    {
    my $ua = WWW::Search::_load_env_useragent();
    if (! ref $ua)
      {
      # print STDERR " XXX WWW::Search::_load_env_useragent() failed\n";
      $ua = new LWP::UserAgent;
      $ua->env_proxy('yes');
      } # if
    $ua->cookie_jar($self->cookie_jar);
    # print STDERR " III ua is $ua\n";
    $self->{_user_agent} = $ua;
    } # if
  $self->{_user_agent};
  } # user_agent

=back

=cut

sub _send_email_form
  {
  return <<ENDEMAILFORM
<form action="http://contact.ebay.com/ws1/eBayISAPI.dll?HandleContacteBayMember" name="contactform" method="post" onSubmit="isDefaultMessage(this);doValidate(this);return false;"><input type="hidden" name="MfcISAPICommand" value="HandleContactEbayMember"><input type="hidden" name="requestor" value="__FROM_USERID__"><input type="hidden" name="reqpass" value=""><table border="0" cellpadding="0" cellspacing="0">
<tr>
<td colspan="2">
<table width="775" border="0" cellpadding="0" cellspacing="0">
<tr>
<td>
<table width="100%" border="0" cellpadding="2" cellspacing="0">
<tr valign="top">
<td colspan="2">
													Enter your message below. eBay will send an email to the member.
													<br><br></td>
</tr>
</table>
<table width="100%" border="1" cellpadding="0" cellspacing="0">
<tr>
<td>
<table width="100%" border="0" cellpadding="2" cellspacing="2" bgcolor="#efefef">
<tr>
<td rowspan="4" width="5"><img src="http://pics.ebaystatic.com/aw/pics/spacer.gif" width="5" height="1"></td>
<td colspan="2"><img src="http://pics.ebaystatic.com/aw/pics/spacer.gif" width="1" height="5"></td>
</tr>
<tr>
<td width="10%"><b>To:</b></td>
<td>watto2000</td>
<td valign="top" width="35%" rowspan="3"><b>Marketplace Safety Tips</b><br><br>eBay rules prohibit use of this Contact eBay Member feature to offer to buy or sell directly without bidding on and winning the item on eBay. We strongly advise recipients of these email offers to report them to eBay. Participants in these 'off eBay' transactions lose their ability to use eBay Feedback and our buyer protection programs. <a href="http://pages.ebay.com/securitycenter">Learn more</a> about trading safely.</td>
</tr>
<tr>
<td width="10%"><b>Subject:</b></td>
<td><input name="subject" type="text" size="60" maxlength="100" value="__SUBJECT__"></td>
</tr>
<tr>
<td valign="top" colspan="2"><textarea name="message" cols="55" rows="7" wrap="physical" onclick="clearText()" onFocus="clearText()" onChange="checkMaxLength(this,1000)" onKeyDown="checkMaxLength(this,1000)" onKeyUp="checkMaxLength(this,1000)">Type your message here.</textarea><span class="help"><br>Enter up to 1000 characters. HTML cannot be displayed.</span></td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td><img src="http://pics.ebaystatic.com/aw/pics/spacer.gif" width="1" height="1"></td>
<td><input name="sendcopy" type="checkbox" value="ON">Send a copy of this email to myself.
						</td>
</tr>
<tr>
<td><img src="http://pics.ebaystatic.com/aw/pics/spacer.gif" width="1" height="1"></td>
<td><input name="hideemail" type="checkbox" value="1">Hide my email address for privacy purposes.
								</td>
</tr>
<tr>
<td colspan="2">
								Å†
					             </td>
</tr>
<tr>
<td><img src="http://pics.ebaystatic.com/aw/pics/spacer.gif" width="1" height="1"></td>
<td><input type="submit" name="Submit" value="Send message">Å†Å†
								<script language="Javascript">
						var cf_text = "Clear form";
						<!--
							document.write("<a href=\"#\" onclick=\"clearTextAlways();return false;\">"+cf_text+"</a>");
						//--></script></td>
</tr>
</table>
<table>
<tr>
<td colspan="3" valign="top" align="top"><img src="http://pics.ebaystatic.com/aw/pics/x.gif" height="22" width="1"></td>
</tr>
</table><input type="hidden" name="defaultText" value="Type your message here."><input type="hidden" name="defmessage"><input type="hidden" name="requested" value="__TO_USERID__"></form>
ENDEMAILFORM
  } # _send_email_form

1;

__END__

