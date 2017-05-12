=head1 NAME

WWW::Link - maintain information about the state of links

=head1 SYNOPSIS

       use WWW::Link;
       $::link=new WWW::Link "http://www.bounce.com/";
       $::link->failed_test;
       $::link->is_okay or warn "link not validated";

=head1 DESCRIPTION

WWW::Link is a perl class which accepts and maintains information about
links.  For example, this would include urls which are referenced from
a WWW page.

The link class will be acted on by such programs as link checkers to
give it information and by other programs to convert that information
into something which can be used by humans.

=cut

package WWW::Link;
$REVISION=q$Revision: 1.25 $ ;
$VERSION = '0.036'; #BETA / under development
use Carp;
use strict;
use vars qw($verbose $VERSION);
$verbose=0;
use HTTP::Response;

=head1 METHODS

=head2 new

The constructor for links expects a url as a string.

=cut

sub new {
  my $class=shift;
  my $url=shift;
  die "usage \$link->(<status-flags>)" unless $url;
  $url=$url->as_string() if ref $url;
  my $self={};
  bless $self, $class;
  $self->initialise();
  $self->url($url);
  return $self;
}

=head2 status

The status effectively a bit field.  Some of the options are mutually exculsive

=cut

#Constants
#
#The following are arbitrary constants for use as flags on the status.

#FIXME: in the next version of WWW::Link, these should all be multiplied by two 
#and Link_not_checked should become 1.
#Status 0 should mean undefined... but it doesn't yet.
#plus these should all be subroutines.

sub LINK_NOT_CHECKED () {0;}
sub LINK_VALIDATED () {1<<0;}
sub LINK_DAMAGED () {1<<1;}
sub LINK_BROKEN () {1<<2;}
sub LINK_ABANDONED () {1<<3;}
sub LINK_REDIRECTED () {1<<4;}
sub LINK_CORRECTABLE () {1<<5;}
sub LINK_UNSUPPORTED () {1<<6;}
sub LINK_DISALLOWED () {1<<7;}

#FIXME make more space at the time we upgrade the format.
sub LINK_BANNED_SIMPLE () {1<<8;}
sub LINK_BANNED_COMPLEX () {1<<9;}
sub LINK_CHECK_UNDETERMINED () {1<<10;}
sub LINK_CHECK_OKAY_SIMPLE () {1<<11;}
sub LINK_CHECK_BROKEN_SIMPLE () {1<<11;}
sub LINK_CHECK_INCONSISTENT () {1<<12;}
sub LINK_UNTESTABLE_SIMPLE () {1<<13;}
sub LINK_UNTESTABLE_COMPLEX () {1<<14;}

sub LAST_SIMPLE_OKAY () {1<<8;}

=pod

  guessed similar ; followed link on page ;

   couldnt_test - for some reason the link tester has been unable to
                   check the status of the link

  robot exlusion ; server overload ; known network break

=head2 initialise

Setup each of the variables into a best guess starting state

=cut

sub initialise{
  my $self=shift;
  $self->status(LINK_NOT_CHECKED); #never been link checked.
  $self->check_method(LINK_CHECK_OKAY_SIMPLE | LINK_CHECK_BROKEN_SIMPLE);
  $self->{breakcount}=0;
  $self->{testcount}=0;
  $self->{short_reliability}=0;
  $self->{long_reliability}=0;
}

=head2 status

There are a number of options for checking the status of a link.
These will maintain meaning although the details of how they do their
tests are likely to vary.

=over

=item is_okay

The link is not considered to have been damaged.  N.B. this could just
mean that we haven't checked it yet.  Use validated okay to verify that.

=item is_not_tested

The link has not been examined and the system doesn't know if it is
good or bad.

=item is_abandoned

We've been testing the link and finding it broken for so long we
aren't interested in it any more.

=item is_broken

After repeated attempts (as defined by user) to validate it, no answer
was recieved and the link is considered broken.

=item is_damaged

The link was broken recently, but we still think that it needs more
time before we can consider it broken.

=item is_redirected

The link was examined and an explicit redirect was found.

=item validated_okay

The link has been examined and was definitely okay.

=back

=cut

sub is_okay{
  my $stat=shift()->status();
  return 1 if $stat & LINK_VALIDATED;
#states should now be pure..
#  return 1 if $stat == LINK_NOT_CHECKED;
  return 0;
}

sub is_not_checked{
  return 1 if shift()->{"status"} == LINK_NOT_CHECKED;
  return 0;
}

sub is_abandoned{return shift()->{"status"} & LINK_ABANDONED}
sub is_broken{return shift()->{"status"} & LINK_BROKEN}
sub is_damaged{return shift()->{"status"} & LINK_DAMAGED}
sub is_redirected{return shift()->{"status"} & LINK_REDIRECTED}
sub is_disallowed{return shift()->{"status"} & LINK_DISALLOWED}
sub is_unsupported{return shift()->{"status"} & LINK_UNSUPPORTED}
sub validated_okay{return shift()->{"status"} & LINK_VALIDATED}

sub status {
  my $self=shift;
  return $self->{"status"} unless @_;
  my $status=shift;
  $self->{"status-change-time"}=time
    unless defined $self->{"status"} and $self->{"status"}==$status;
  $self->{"status"}=$status;
}

sub check_method {
  my $self=shift;
  return $self->{"check-method"} unless @_;
  my $status=shift;
  $self->{"check-method-change-time"}=time
    unless defined $self->{"check-method"}
      and $self->{"check-method"}==$status;
  $self->{"check-method"}=$status;
}

#has the link been hardwired by the user to only test one way
sub banned_complex{
  my $self=shift;
  return $self->{"check-method"} & LINK_BANNED_COMPLEX unless @_;
  my $set=shift;
  $self->{"check-method"} ^= LINK_BANNED_COMPLEX unless $set;
  $self->{"check-method"} |= LINK_BANNED_COMPLEX if $set;
  return $self->{"check-method"};
}
sub banned_simple{
  my $self=shift;
  return $self->{"check-method"} & LINK_BANNED_SIMPLE unless @_;
  my $set=shift;
  $self->{"check-method"} ^= LINK_BANNED_SIMPLE unless $set;
  $self->{"check-method"} |= LINK_BANNED_SIMPLE if $set;
  return $self->{"check-method"};
}

sub check_okay_simple {
  my $self=shift;
  return $self->{"check-method"} & LINK_CHECK_OKAY_SIMPLE unless @_;
  my $set=shift;
  $self->{"check-method"} ^= LINK_CHECK_OKAY_SIMPLE unless $set;
  $self->{"check-method"} |= LINK_CHECK_OKAY_SIMPLE if $set;
  return $self->{"check-method"};
}
sub check_broken_simple{
  my $self=shift;
  return $self->{"check-method"} & LINK_CHECK_BROKEN_SIMPLE unless @_;
  my $set=shift;
  $self->{"check-method"} ^= LINK_CHECK_BROKEN_SIMPLE unless $set;
  $self->{"check-method"} |= LINK_CHECK_BROKEN_SIMPLE if $set;
  return $self->{"check-method"};
}
sub check_undetermined{
  my $self=shift;
  return $self->{"check-method"} & LINK_CHECK_UNDETERMINED unless @_;
  my $set=shift;
  $self->{"check-method"} ^= LINK_CHECK_UNDETERMINED unless $set;
  $self->{"check-method"} |= LINK_CHECK_UNDETERMINED if $set;
  return $self->{"check-method"};
}

=head2 add_status

or the given value into the status flags.

=cut

sub add_status {
  my $self=shift;
  my $status=shift;
  die "usage \$link->(<status-flags>)" unless $status;
  $self->{"status-change-time"}=time unless $self->{"status"} & $status;
  $self->{"status"}=$status | $self->{"status"};
}

=head2 remove_status

or the given value into the status flags.

=cut

sub remove_status {
  my $self=shift;
  my $status=shift;
  die "usage \$link->(<status-flags>)" unless $status;
  $self->{"status-change-time"}=time if $self->{"status"} & $status;
  $status = ~$status;
  $self->{"status"}=$status & $self->{"status"};
}

=head2 status_change_time

Return the last time that the status field of the link was changed.

=cut

sub status_change_time {
  my $self=shift;
  return $self->{"status-change-time"}
}

=head2 breakcount

Returns two times the number of times the link has been tested and
found broken.  This could in future turn into a fraction or something
the basic idea is that at around 10 you should start to think that the
link is broken beyond recognition..

With an argument sets the links broken number, but you shouldn't
normally do this so by default it also complains unless you've set the
package I_know_what_im_up_to variable.

=cut

sub breakcount {
  my $self=shift;
  return $self->{"breakcount"} unless @_;
  $self->{"breakcount"}=shift;
}

sub testcount {
  return shift->{"testcount"};
}


########CONFIG##########
# number of times we let it be tested before we consider it broken
sub BROKEN_COUNT () {4;}

# number of times we let it be tested before we decide nobody cares...
sub ABANDONED_COUNT () {10;}

sub HOUR () {60*60;}
sub DAY () {24*60*60;}
sub TIME_BASE () {1.7*DAY;}

sub OKAY_FACTOR () {5;}
sub UNTESTABLE_FACTOR () {7;} #cost of re-examining should be low..
sub ABANDONED_FACTOR () {11;}
sub DAMAGED_FACTOR () {1;}
sub BROKEN_FACTOR  () {2;}

=head1 time_want_test

This tells you the time till the link thinks it should next be tested.
There are three regimes:-

The time which controls the next time we want to be tested is the last
time we were tested.  This function doesn't worry about what the real
time is now and will happily return times in the past.

=over

=item normal testing

In the normal situation we have a time constant for each link and we
do testing on the link at that time +- one day.

=item damaged link

The link has just been detected as damaged.  We retest it repeatedly
spread across a small number of days and then declare it broken.

=item broken link

The link has been declared broken.  Now we test it occasionally just
to verify if it has been repaired in the meantime.

=item abandoned link

We've detected and declared it broken, but noone has come along to
look at it.  It's still possible that outside influences repair the
link in the meantime, so we keep checking it occasionally

=back

Please note, a link doesn't know anything about the present time, or
when it is scheduled to be checked.  The time it want's to be checked
could be some time in the past.

=cut

sub time_want_test {
  my $self=shift;

  #we think we should always have been checked.
  my $test_time=$self->{"last_test"};
  $test_time=1 unless defined ($test_time);
  my $base=$self->{"base_time"};
  $base=TIME_BASE unless defined $base;
  unless ($base =~ m/^[0-9]*[1-9][0-9]*/ ) {
    warn "time base $base invalid using " . TIME_BASE . " instead";
    $base=TIME_BASE;
  }

  my $factor;
 CASE: {
    $self->is_damaged() && do { $factor=DAMAGED_FACTOR; last };
    $self->is_abandoned() && do {$factor=ABANDONED_FACTOR; last };
    $self->is_broken() && do {$factor=BROKEN_FACTOR; last };
    ($self->is_disallowed() || $self->is_unsupported())
      && do {$factor=UNTESTABLE_FACTOR; last};
    $factor=OKAY_FACTOR; last;
  }
  die "didn't set factor" unless $factor;
  $test_time+=$base*$factor;
  my $vary=0.3*$base*$factor;
  return wantarray ?  ($test_time, $vary) : $test_time ;
}

# =head2 time_scheduled

# The scheduled time is the time we have been told (by the link test
# system) that we will next be checked.

# =cut

# sub time_scheduled {
#   my $self=shift;
#   unless ( @_ ) {
#     #die "link is not scheduled" unless ( defined $self->{"time_scheduled"} );
#     # we return undef if we don´t know when we have been scheduled which is
#     # sort of bad
#     return $self->{"time_scheduled"};
#   }
#   my $time=shift;
#   die "$_ not a valid time" unless /^[+-]?\d+$/;
#   die "$_ not in the future" unless $time > time();
#   $self->{"time_scheduled"} = $time;
#   return $time;
# }


sub last_test {
  my $self=shift;
  return $self->{"last_test"} unless @_;
  my $time=shift;
  die "Invalid time value" unless $time =~ /^[+-]?\d+$/;
  return $self->{"last_test"} = $time;
}

=head2 $l->last_refresh([integer-time])

The last refresh is the last time the link was reported as in use by
some users resource.  It B<must> be updated ever time the index to an
infostructure is rebuilt or else the 

=cut

sub last_refresh {
  my $self=shift;
  return $self->{"last_refresh"} unless @_;
  my $time=shift;
  die "Invalid time value" unless $time =~ /^[+-]?\d+$/;
  unless ( defined $self->{"last_refresh"}
	   and $time < $self->{"last_refresh"} ) {
    return $self->{"last_refresh"} = $time;
  } else {
    warn "ignoring refresh time earlier than current"
      if $verbose & 16;
  }
}

=head2 add_redirect

This method adds information about a redirect from a given link.

Redirects can be a chain.

=cut

sub add_redirect {
  my $self=shift;
  my $redirect_url=shift;
  die "usage \$link->add_redirect(<uri>)" unless $redirect_url;
  $self->{"redirects"}=[] unless $self->{"redirects"};
  my $redir_list=$self->{"redirects"};
  my $found=0;
  my $i;
  my @deletions;
  #we delete backwards so that the array length doesn't change on us
  for ($i = $#$redir_list ; $i>=0; $i--) {
    splice @$redir_list, $i, 1 if $redir_list->[$i] = $redirect_url;
  }
  unshift @$redir_list, $redirect_url;
}


=head2 add_suggestion

Add a suggestion to the beginning of the list of suggested replacement
links.  If the same suggestion is later in the list delete it.  We
return 1 if the link is new.

=cut

sub add_suggestion {
  my $self=shift;
  my $suggestion=shift;
  $self->{"fix_suggestions"}=[] unless $self->{"fix_suggestions"};
  my $sugg_list=$self->{"fix_suggestions"};
  my $count=@$sugg_list;
  my $found=0;
  my $i;
  my @deletions;
  #we delete backwards so that the array length doesn't change on us
  for ($i = $#$sugg_list ; $i>=0; $i--) {
    splice @$sugg_list, $i, 1 if $sugg_list->[$i] = $suggestion;
  }
  unshift @$sugg_list, $suggestion;
  return 1 if $count < @$sugg_list;
  return 0;
}

=head2 redirects

Redirects stores or returns a reference to an array of redirects.

=cut

sub redirects {
  my $self=shift;
  my $redirects=shift;
  croak "usage $self->redirects([array-ref])"
    if @_ or (defined $redirects and not ref($redirects) =~ m/ARRAY/ );
  $self->{"redirects"} = $redirects if defined $redirects;
  $self->add_status(LINK_CORRECTABLE);
  return $self->{"redirects"};
}

=head2 redirect_urls

C<redirect_urls> returns redirections on a link in the form of urls
(text strings, not objects).  In a list context it returns the full
chain of urls.  In a scalar context it returns only the last url of
the chain.

=cut

sub redirect_urls {
  my $self=shift;
  croak "usage $self->redirect_urls()"
    if @_;
  wantarray && do {
    my @urls=();
    REDIR: foreach my $redir (@{$self->{"redirects"}} ) {
      $redir = $self->_redirect_url($redir);
      push @urls, $redir if defined $redir;
    }
    return @urls;
  };
  return $self->_redirect_url($self->{"redirects"}[$#{$self->{"redirects"}}]);
}


# _redirect_url hopefully gets the url whether the redirect is stored
# as a string, a HTTP::Response object or a URI object.

sub _redirect_url {
  my $self=shift;
  my $redir=shift;
 CASE: { 
    ref $redir or last;

    my $url;
    eval { $url = $redir->header('location'); };
    $@ && ( not $@ =~ "Can't locate object method.*header") and do {
      die "Failed to get redirect location: $@";
    };

    defined $url && do {
      $redir=$url;
      last;
    };

    $redir = $redir->as_string() if $redir->can('as_string');

    do { warn "don't know how to get url from redirect: " . $redir;
	 return undef; } if ref $redir;
  }

  return $redir;
}

=head2 fix_suggestion

Fix suggestion is an array of suggestions for documents which might
replace a broken link.  These can be derived from all sorts of places
and some are probably not correct.  The aim is that they are in order
from best guess to worst.  You pass a reference to the new array.

=cut

sub fix_suggestions {
  my $self=shift;
  return $self->{"fix_suggestions"} unless @_;
  my $suggestions=shift;
  $self->{"fix_suggestions"} = $suggestions;
  $self->add_status(LINK_CORRECTABLE);
  return $suggestions;
}


=head2 all_suggestion

Returns a list consisting of all of the redirect and fix suggestions
that have been made for that link.

=cut

sub all_suggestions {
  my $self=shift;
  my $return=[];
  push @$return, @{$self->{"fix_suggestions"}} if $self->{"fix_suggestions"};
  push @$return, @{$self->{"redirects"}} if $self->{"redirects"};
  return $return;
}

=head2 url

just say what url is associated with this link 

=cut


sub url {
  my $self=shift;
  return $self->{"url"} unless @_;
  my $url=shift;
  $self->{"url"} = $url;
  return $url;
}


=head2 failed_test

Failed test should says that you have tested a link and think it's
broken.  Sometimes the link won't care (it's been tested recently and
is waiting to give the resource time to come back if it's just
temporarily mislayed); mostly it'll increase it's broken value by two.

This also creates two reliability values.  The long and short.  These
indicate how reliable the link has been over recent tests.  The long
value takes into account approximately the last 30 tests and the short
takes into account approximately the last 7 tests with more weighting
for more recent tests.  A value of 1 means totally reliably working
for all time and a value of -1 means totally broken for all time and
anything in between is a lower value of certainty.

Probably a value less than about 0.5 is one to consider a problem,
depending on how important the Link is to you.


=head2 redirections and failed tests

There are the following possibilities: A redirected link which ends in
success; considered as redirected.  A redirected link which ends in
failure.  This should be considered broken and finally: A failed link
which was previously redirected.  This should be considered broken,
but the redirection should be remembered as a possible solution for
the problem.

=cut

$WWW::Link::inter_test_time=0.5 * TIME_BASE; #one day approx..

sub LONG_FACTOR () {30;}
sub SHORT_FACTOR () {7;}

sub failed_test {
  my $self=shift;
  #filter status values compatible with failed testing..
  my $stat = $self->status() & (LINK_DAMAGED | LINK_BROKEN | LINK_ABANDONED
				| LINK_CORRECTABLE);
  $self->status($stat);
  unless ( $stat & LINK_DAMAGED) {
    $self->first_broken;
  } elsif (   ( ! defined ($self->{"last_fail"}) ) 
      || (( time() - $self->{"last_fail"} )  >$WWW::Link::inter_test_time ) ) {
    $self->more_broken;
  }
  #this implies we have to pass through the abandoned_count and
  #broken_count values
  $self->tested();

  $self->{long_reliability} = -0.2 unless $self->{long_reliability} ;
  $self->{short_reliability} = -0.2 unless $self->{short_reliability} ;
  $self->{long_reliability} *= ( 1 - 1/LONG_FACTOR);
  $self->{long_reliability} -= (1/LONG_FACTOR);
  $self->{short_reliability} *= ( 1 - 1/SHORT_FACTOR);
  $self->{short_reliability} -= (1/SHORT_FACTOR);

  return $self->{"breakcount"}; #they can check if we changed it.
}


sub first_broken {
  my $self=shift;
  print STDERR "Link found broken for first time\n" if $verbose & 4;
  $self->{"last_fail"}=time();
  $self->{"breakcount"}= 2;
  $self->add_status( LINK_DAMAGED );
}

sub more_broken {
  my $self=shift;
  print STDERR "Link found broken again adding to failure count\n" 
    if $verbose & 4;
  $self->{"breakcount"} += 2;
  $self->{"last_fail"}=time();
  $self->{"breakcount"} == ABANDONED_COUNT
    && $self->add_status(LINK_ABANDONED);
  $self->{"breakcount"} == BROKEN_COUNT
    && $self->add_status(LINK_BROKEN);
}

=head2 passed_test

This tells a link that it has been tested and found to be okay.  It's
an internal method generally and may change name.

N.B. this resets all other status flags.  If you want to have a link
which is okay but is redirected you must call C<redirected>
afterwards.

=cut

sub passed_test {
  my $self=shift;
  $self->status(LINK_VALIDATED);
  $self->tested();
  #reliability information?

  $self->{long_reliability} = 0.5 unless $self->{long_reliability} ;
  $self->{short_reliability} = 0.5 unless $self->{short_reliability} ;

  $self->{long_reliability} *= ( 1 - 1/LONG_FACTOR);
  $self->{long_reliability} += (1/LONG_FACTOR);
  $self->{short_reliability} *= ( 1 - 1/SHORT_FACTOR);
  $self->{short_reliability} += (1/SHORT_FACTOR);

}


=head2 found_redirected

tells the link that there is at least one layer of permanent
redirections from its URL to the final object referred to.  The urls
in the source documents should be updated.

=cut

sub found_redirected {
  shift->add_status(LINK_REDIRECTED);
}

=head2 not_redirected

tells the link that there are no redirections from its URL.

=cut

sub not_redirected {
  shift->remove_status(LINK_REDIRECTED);
}

#  =head2 tested

#  Little helper function that should be called each time the link is
#  tested which updates timestamps etc.

#  =cut

sub tested{
  my $self=shift;

#this was in an early version of Link.pm.  This line can be deleted at
#release time for 1.0 at which time everybody should rebuild their
#databases.
  defined $self->{"checkcount"} and delete $self->{"checkcount"};

  $self->{"testcount"}++;
  $self->{"last_test"}=time;
}

=head2 disallowed

Testing the link was attempted but it was disallowed, e.g. due to the
robots exclusion protocol.  The user should examine what's going on
and either ignore it or get in touch with the site for permission to
do link checking.

N.B. disallowed should only be called when we know that testing has
been disallowed.  Failure to access the resource at the end of a link
should normally be seen as an error.

=cut

sub disallowed {
  my $self=shift;
  $self->status(LINK_DISALLOWED);

  $self->tested(); #Hmmm.. or is it??
}


=head2 unsupported

Testing the link was attempted but it turns out that we don't know
how...  We just mark this as unsupported and the user can then think
about sending in a patch to add the needed features to LinkController.

=cut

sub unsupported {
  my $self=shift;
  $self->status(LINK_UNSUPPORTED);

  $self->tested();
}



sub KEEP_RESP () {10;}

=head2 store_response ( <response>, <time_now>, <tester>, ..<tester data>)

This function is for storing the history of testing of the link so
that we can look through it and find out what has been going on.

The <response> argument should be an HTTP response object representing
the status of the tester and possibly synthesised by the tester.  The
time_now is the time the response is considered to have been
processed.

Tester should be an identifier of the tester used to test the link.
Normally this should be the class of the tester.

The tester data can be anything that the tester wants to store with
the response.

N.B. mere storage of a response does not have any affect on a link.

=cut

sub store_response {
  my $self=shift;
  my @resp=@_;
  unshift @{$self->{"test_hist"}}, \@resp;
  pop @{$self->{"test_hist"}} while $#{$self->{"test_hist"}} > KEEP_RESP;
}

=head2 recover_response (<integer>)

This function returns a previous response which has been applied to
the link.  In a scalar context it returns only the response.  In an
array context it will return the arguments which were given to
store_response.  The integer argument is the age of the link (it's
position in the history).

N.B. an age of 0 returns the most recently stored response.

=cut 

sub recover_response {
  my ($self,$age)=@_;
  croak 'usage: $self->recover_response($age)'
    unless defined $age;
  croak 'age must be a natural number' unless $age =~ /^\d+$/;

  return wantarray ?  () : undef unless defined $self->{"test_hist"};

  $age > KEEP_RESP && do {
    warn "response older than could ever be stored requested";
    return undef;
  };
  $age > $#{$self->{"test_hist"}} && return wantarray ?  () : undef ;

  return wantarray ?  @{$self->{"test_hist"}->[$age]}
		   : $self->{"test_hist"}->[$age]->[0] ;
}

=head1 STORING TEST COOKIE

The test cookie is any data which the tester wants to store to have
available next time it tests this link.  Testers should normally be
very careful how they handle this value and expect that another tester
could use the value differently.  The normal way to cope with this is
to be able to work without the cookie and, when storing the cookie,
use an object which can then be idenitfied easily.

If the cookie I<can> support a time_want_test method, then this can be
used to override the time the link should be tested.  It will be
called with a reference to the link.

=cut

sub test_cookie {
  my ($self,$cookie)=@_;
  $self->{"test-cookie"}=$cookie if $cookie;
  return $self->{"test-cookie"};
}

=head1 DECLARING LINKS BROKEN

A link isn't signalled as broken until after it has been checked
several times and found not working.  The reason for this is quite
simple.  There are many WWW servers in the world which aren't reliably
accessable.  If a set of pages are checked at any given time a fair
number of links could seem to be broken, even when they will soon be
repaired.  In fact, in a well maintained set of pages (as I hope this
package will let you have), these pages will outnumber by a large
amount the number of actual broken links.

=head1 LINK AGING

Links can age in two ways.  Firstly, we can recognise them as broken
and get bored of them being checked.  However, in this case, they stay
around in the database, and are just checked very rarely (we never
give up hope.. there may be some reason why WE can't see a link and
the user can't be bothered to solve it yet but does later.)

The second method we use is keeping a refresh time in each link.  This
represents the last time some user told us that this link was in their
infostructure.  If this gets larger than a certain value (e.g. a
month, but this must be site determined depending on the maintainance
patterns of users), the link should no longer be checked.  

If this gets larger than another value (which should be considerably
larger than the first - say 6 months or a year) then the link can be
retired from the database.  Even if someone did turn out to be
interested, the information would be so out of date as to be useless.

=cut


=head1 SEE ALSO

WWW::Link::Reporter WWW::Link::Selector

=cut

