package WWW::Link::Tester;
$REVISION=q$Revision: 1.14 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

=head1 NAME

WWW::Link::Tester - base class for link testers.

=head1 SYNOPSIS

    use WWW::Link::Tester
    $ua=create_a_user_agent();
    my $tester = new WWW::Link::Tester, $ua;
    $link=get_a_link_object();
    $tester->test_link($link);

=head1 DESCRIPTION

This class acts as a base for constructing link testing classes.  It
provides methods that are useful within those classes.

=cut

use URI;
use Carp;
use Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(RC_PROTOCOL_UNSUPPORTED MSG_PROTOCOL_UNSUPPORTED RC_REDIRECT_LIMIT_EXCEEDED MSG_REDIRECT_LIMIT_EXCEEDED);
use strict;
use warnings;
use HTTP::Status;

sub MSG_PROTOCOL_UNSUPPORTED () {"Unsupported protocol";}
sub RC_PROTOCOL_UNSUPPORTED () {498;}
sub MSG_REDIRECT_LIMIT_EXCEEDED () {"Too Many Redirects";}
sub RC_REDIRECT_LIMIT_EXCEEDED () {499;}

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  $self->{"user_agent"}=shift;
  bless $self, $class;
  $self->config();
  return $self;
}

sub test_link {
  my $self=shift;
  my $link=shift;
  my ($response, @redirects) = $self->get_response($link);
  $self->handle_response($link,$response,@redirects);
}

sub get_response {
  confess "get_response must be implemented in the child class";
}

sub verbose {
  my $self=shift;
  my $verb=shift;
  $self->{verbose} = $verb if defined $verb;
  return $self->{verbose};
}


=head2 handle_response

handle_response is normally just the same as apply response.  The
extra level of indirection can be used where some responses aren't
meant to directly affect the link.

=cut

sub handle_response {
  my $self=shift;
  my $link=shift;
  my $response=shift;
  my @redirects=@_;
  $self->apply_response($link, $response, @redirects);
  my $now=time;
  $link->store_response($response,$now, ref $self);
}

=head2 apply_response

We have a response which should be used to affect the state of the
link.  This should only be called at the end of a chain of redirects,
not for each member in the chain.

=cut

sub apply_response {
  my $self=shift;
  my $link=shift;
  my $response=shift;
  my @redirects=@_;

  my $verbose=$self->{"verbose"};

  my $mode=$self->{mode};

  confess "response wasn't an object" unless ref $response;
  confess "non numeric response code" . $response->code() unless
    $response->code() =~ m/[1-9][0-9]+/;
 CASE: {
    robot_lockout($response) && do {
      print STDERR "checking disallowed, signalling link\n"
	if $::verbose;
      $link->disallowed();
      last;
    };
    unsupported($response) && do {
      print STDERR "checking disallowed, signalling link\n"
	if $::verbose;
      $link->unsupported();
      last;
    };
    $response->is_error() && do {
      print STDERR "response was an error, signalling link\n"
	if $::verbose;
      $link->failed_test(); #someone should come look
      last;
    };
    $response->is_success() && do {
      print STDERR "response was success, signalling link\n"
	if $::verbose;
      $link->passed_test();
      last;
    };
    #a redirect should eiter be terminiated with a success or should be
    #treated as a failure if we don't find the end of a chain of
    #redirects.
    $response->is_redirect() &&
      die "Redirects shouldn't get through to here\n";
    $self->ambiguous_test($link);
  }
  @redirects ? $link->found_redirected() : $link->not_redirected();
  $link->redirects( \@redirects ) if @redirects;
}

sub config {
  shift->{"max_redirects"}=15;
}

sub robot_lockout {
    my $response=shift;
    $response->code() == RC_FORBIDDEN or return 0;
    my $message = $response->message();
    #FIXME; this is because the Complex tester looses this informaition!
    defined $message or return 1;
    $message=~ /robots\.txt/ and return 1;
    return 0;
}

sub unsupported {
    my $response=shift;
    $response->code() == RC_PROTOCOL_UNSUPPORTED
      and return 1;

    #I'm not sure I like the following special case.

    $response->code == 400 and
      $response-> message =~ m/Library does not allow method/
	and return 1;

    return 0;
}

1; #kEEp rEqUIrE HaPpY.
