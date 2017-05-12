package WWW::Link::Tester::Adaptive;
$REVISION=q$Revision: 1.12 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

=head1 NAME

WWW::Link::Test - adaptive functions for testing links.

=head1 SYNOPSIS

    use WWW::Link::Test
    $ua=create_a_user_agent();
    $link=get_a_link_object();
    WWW::Link::Test::test_link($ua, $link);

=head1 DESCRIPTION

The adaptive tester uses either a simple or a complex tester depending
on which one has been working correctly.

=cut

#  Only one method currently impemented.  The others were done
#  differently but may come back later..

=head1 METHODS

=head2 test_link

This function tests a link by going out to the world and checking it
and then telling the associated link object what happened.

=cut

use WWW::Link::Tester;
use WWW::Link::Tester::Simple;
use WWW::Link::Tester::Complex;

@ISA=qw(WWW::Link::Tester);

use strict;
use warnings;
use vars qw($mode);

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  my $ua=shift;
  $self->{"complex"}=new WWW::Link::Tester::Complex $ua;
  $self->{"simple"}=new WWW::Link::Tester::Simple $ua;
  bless $self, $class;
}

sub test_link {
  my $self=shift;
  my $link=shift;
  my $simple=undef;
  my $verbose=$self->{"verbose"};

  my $cookie=$self->check_cookie($link);

  my $url=$link->url();

  my($mode, undef)=$cookie->calculate_test_state($link);

    my ($response, @redirects);
 CASE: {
    ($mode==WWW::Link::Tester::Adaptive::Cookie::MODE_SIMPLE() ) and do {
      ($response, @redirects) = $self->{"simple"}->get_response($link);
      last CASE;
    };
    ($mode==WWW::Link::Tester::Adaptive::Cookie::MODE_COMPLEX() ) and do {
      ($response, @redirects) = $self->{"complex"}->get_response($link);
      last CASE;
    };
    die "unknown testing mode $mode";
  }

  $self->handle_response($link,$mode,$response,@redirects);

  return;
}

=head2 handle_response

The link tester has recieved a response, now the question is what do
we do with it.   It depends on our testing mode.

=cut

sub handle_response {
  my $self=shift;
  my $link=shift;
  my $mode=shift;
  my $response=shift;
  my @redirects=@_;

  my $cookie=$self->check_cookie($link);

  my $apply=$cookie->consider_test($link,$response,$mode);


  if ( $apply ) {
    print STDERR "applying response\n" if $self->{verbose};
    $self->apply_response($link,$response,@redirects);
  } else {
    print STDERR "not applying response\n" if $self->{verbose};
  }

  $link->store_response($response, time, ref $self, $mode);
  $link->test_cookie($cookie);
}

=head1 check_cookie

This verifies that the given link has a useful test cookie, and gives
it an appropriate one if it doesn't.

=cut

sub check_cookie {
  my $self=shift;
  my $link=shift;
  my $cookie=$link->test_cookie();

 CASE: {
    defined $cookie && ref($cookie) =~ m/WWW::Link::Tester::Adaptive::Cookie/
      and last;
    defined $cookie and warn "replacing old cookie type: " . ref $cookie;
    $cookie=WWW::Link::Tester::Adaptive::Cookie->new();
  }
  return $cookie;
}


package WWW::Link::Tester::Adaptive::Cookie;

use warnings;
use WWW::Link::Tester;

our ( $verbose );

=head1 TESTING MODES

We have two different ways of testing.  One us network efficient, but
is less likely to give a fully correct answer.  The other is less
network efficient, but more tests more carefully.

We assume that the complex testing system is correct.  We will allow
the simple testing system to be used only as long as we have no
reason to suspect inaccuracy we will test with the simple tester.

=head2 verifying testing..

Every now and then (after 20 tests) we will verify that our method of
testing is consistent.  We do this by trying simple then complex
testing in order.  If they are inconsistent then we finally try simple
testing one more time then mark the simple testing as wrong.

=head2 testing at status changes.

If a link changes status then we will try to verify it sooner..

=head2 statuses

There are two flags that can be set.

OKAY_SIMPLE_WORKING - link tests correctly with both complex and
simple testers when it is working.

OKAY_SIMPLE_BROKEN- link tests correctly with both complex and
simple testers when it is broken.

As long as these are both set then most of our testing should be done
in simple mode.

=cut

#  Occasionally we try complex mode.  We see if this gives a different
#  result.  If it does then we switch over to complex testing.  This
#  means that we will be somewhat delayed in finding link problems that
#  only complex mode discovers

#  =cut


sub BANNED_SIMPLE () {1<<1;}
sub BANNED_COMPLEX () {1<<2;}

#sub CHECK_UNDETERMINED () {1<<3;}

sub CHECK_VERIFY_WORKING_SIMPLE () {1<<6;}
sub CHECK_VERIFY_BROKEN_SIMPLE () {1<<6;}

sub UNTESTABLE_SIMPLE () {1<<7;}
sub UNTESTABLE_COMPLEX () {1<<8;}

sub LAST_SIMPLE_WORKING () {1<<8;}

#testing modes to return
sub MODE_SIMPLE {1;}
sub MODE_COMPLEX {2;}

sub TIME_SHORT {1;}
sub TIME_NORMAL {2;}

sub UPDATE_LINK {1;}
sub TRY_ONLY {2;}

#switch over triggers.  We mostly want to test complex
sub TRY_COMPLEX_EVERY_SIMPLE () {11;}
sub TRY_SIMPLE_EVERY_COMPLEX () {5;}

#how many inconsistent tests before we decide it's a sure problem
sub STABLE_INCONSISTENT () {3;}
sub PART_INCONSISTENT () {1;}

sub new {
    my $s=shift;
    my $class = ref($s) || $s;
    my $self={};
    $self->{settings}=0 ;
    bless $self, $class;
}

#fixme: special cases
#link is suspicious (others on server look broken)
#link has just changed status?

sub calculate_test_state {
  my $self=shift;
  my $link=shift;

  defined $self->{'simple'} && do {
    warn 'deleting $self->{simple} from cookie';
    delete $self->{'simple'};
  };

  defined $self->{'complex'} && do {
    warn 'deleting $self->{complex} from cookie';
    delete $self->{'complex'};
  };

  defined $self->{settings} or $self->{settings}=0;
  my $settings=$self->{settings};

  #user controlled cases
  $settings & BANNED_SIMPLE && $settings & BANNED_COMPLEX and
    die "banned from both simple and complex testing";
  $settings & BANNED_SIMPLE && return MODE_SIMPLE;
  $settings & BANNED_COMPLEX && return MODE_COMPLEX;

  my $url=$link->url();
  my $count=$link->testcount();

  #now look at history..
  my @responses=@_;

  for (my $i=0; @responses < 4; $i++) {
    my @resp=$link->recover_response($i);
    @resp or last;
    defined $resp[2] or do {
      warn "last tester not recorded";
      last;
    };
    last unless $resp[2] eq "WWW::Link::Tester::Adaptive";
    push @responses, \@resp;
  }
  my $inconsistency = 0;
  foreach (@{$self->{test_consistency}}) {
    next unless defined $_;
    $inconsistency = $_ if $_ > $inconsistency;
  }

  print STDERR "link inconsistency $inconsistency\n"
    if $verbose;

 CASE: {

    $inconsistency <= 0 && do {
      ( $count % TRY_COMPLEX_EVERY_SIMPLE )
	== ( TRY_COMPLEX_EVERY_SIMPLE - 1 )
	  and return MODE_COMPLEX, TIME_NORMAL;
      print STDERR "returning simple for normal testing\n"
	if $verbose;
      return MODE_SIMPLE, TIME_NORMAL;
    };

    $inconsistency < STABLE_INCONSISTENT && do {
      if ( $responses[0][3] == MODE_COMPLEX){
	print STDERR "returning simple for instability testing\n"
	  if $verbose;
	return MODE_SIMPLE, TIME_SHORT;
      } else {
	print STDERR "returning complex for instability testing\n"
	  if $verbose;
	return MODE_COMPLEX, TIME_NORMAL;
      }
    };

    $inconsistency >= STABLE_INCONSISTENT && do {
      ( $count % TRY_SIMPLE_EVERY_COMPLEX )
	== ( TRY_SIMPLE_EVERY_COMPLEX  - 1 )
	  and do {
	    print STDERR "returning simple incase it's working again\n"
	      if $verbose;
	    return MODE_SIMPLE, TIME_SHORT;
	  };
      print STDERR "returning complex for careful testing\n"
	if $verbose;
      return MODE_COMPLEX, TIME_NORMAL;
    };
    die "no inconsistency value";
  }

  die "shouldn't get here";
}

#  =comment

#  we've just done a test
#  we aren't going to apply it to the link.
#  we should see if it changes anything about our opionion

#  we return 1 if we think that this response is good for applying to the link.

#  =cut

sub consider_test {
  my $self=shift;
  my $link=shift;

  my $response=shift;
  my $mode=shift;

  my ($old_response,$old_time,$old_tester,$old_mode)
    = $link->recover_response(0);

  defined $old_response or return 1;
  defined $old_mode or do {
    warn "old mode not defined; treating as first test";
    return 1;
  };

#  ($old_response,$old_time,$old_tester,$old_mode)
#      = ($self->{try_response}, $self->{try_time}, undef, $self->{try_mode})
#        if defined $self->{try_response} and  $self->{try_time} > $old_time;

  my $apply=0;

  die "mode not defined" unless defined $mode;

  $self->{test_consistency} = [] unless defined $self->{test_consistency};

  print STDERR "mode is $mode and old mode is $old_mode\n"
      if $verbose;
  print STDERR "simple is ". MODE_SIMPLE
    . " and complex is " . MODE_COMPLEX . "\n" if $verbose;


  #unsupported protocols should always be handled by simple by
  #default.  It's also possible for simple to handle some protocols
  #that complex doesn't although this is not a good situation.

  ( $mode == MODE_COMPLEX and $response->code == RC_PROTOCOL_UNSUPPORTED )
    and do {
      $self->{test_consistency} = [];
      return 1;
    };

  ( $mode == MODE_SIMPLE and $old_mode == MODE_COMPLEX )
    || ( $mode == MODE_COMPLEX and $old_mode == MODE_SIMPLE ) and do {
      print STDERR "considering consistency of last two tests\n"
	  if $verbose;
      my $scode = short_code( ($mode == MODE_SIMPLE)
			      ? $old_response->code
			      : $old_response->code );
      $self->{test_consistency}[$scode]=0
	unless defined $self->{test_consistency}[$scode];
      if ( $self->responses_are_equivalent( $response, $old_response) ) {
	if ( $self->{test_consistency}[$scode]  > STABLE_INCONSISTENT) {
	  $self->{test_consistency}[$scode] = PART_INCONSISTENT;
	} else {
	  $self->{test_consistency}[$scode] = 0;
	}
      } else {
	$self->{test_consistency}[short_code($old_response->code)]++;
	# inconsistent test so we don't want to reduce consistency of other
	# codes; return now
	return $mode == MODE_COMPLEX ;
      }
    };


  # inconsistency can be caused by intermittent network problems...
  # we decay it away if it isn't confirmed.

  # FIXME: maybe we shouldn't do this when we have a known
  # inconsistent link?

    foreach my $inconsistency (@{$self->{test_consistency}}) {
      next unless defined $inconsistency;
      $inconsistency -= 0.3 if $inconsistency < STABLE_INCONSISTENT;
      $inconsistency = 0 if $inconsistency < 0;
    }

  return 1;
}

sub INTER_TEST_DELAY() {60 * 60 * 1};

sub time_want_test {
    my ($self, $link)=@_;
    die 'usage $cookie->time_want_test($link)' unless ref $link;
    my (undef, $time)=$self->calculate_test_state;
    return INTER_TEST_DELAY if $time &  TIME_SHORT;
    return undef;
}

#  =scode

#  short code - returns the first digit of a response code.  The first
#  digit represents the class.

#  =cut

sub short_code {
  my $code=shift;
  die "invalid code $code" unless
    $code =~ m/^[1-9][0-9][0-9]$/;
  $code =~ s/^([1-9])[0-9][0-9]$/$1/;
  return $code;
}

#  =comment

#  responses_are_equivalent - returns true if two responses can be
#  considered equivalent from the point of view of testing.

#  =cut

sub responses_are_equivalent {
  my ($self, $resp_a, $resp_b)=@_;

  my $scode_a=short_code($resp_a->code);
  my $scode_b=short_code($resp_b->code);

  return $scode_a == $scode_b;

}


1; #kEEp rEqUIrE HaPpY.
