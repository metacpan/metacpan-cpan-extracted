package WWW::Link::Tester::Simple;
$REVISION=q$Revision: 1.9 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

=head1 NAME

WWW::Link::Tester::Simple - a link tester that uses the LWP head method

=head1 SYNOPSIS

    use WWW::Link::Test::Simple
    $ua=create_a_user_agent();
    $link=get_a_link_object();
    WWW::Link::Test::Simple::test_link($ua, $link);
    WWW::Link::Tester::Simple::Test($url)

=head1 DESCRIPTION

This is a simple Link Testing module which accepts a url and returns a
status based on the result returned by the LWP useragent.

The link is tested and then given information about what was
discovered.  The link then records this information for future use..

=head1 METHODS

=head2 test_link

This function tests a link by going out to the world and checking it
and then telling the associated link object what happened.

=cut

use HTTP::Response;
use HTTP::Request;
use WWW::Link::Tester;
@ISA="WWW::Link::Tester";
use warnings;
use strict;
use Carp;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  $self->{"user_agent"}=shift;
  bless $self, $class;
  $self->config();
  return $self;
}

sub get_response {
  my $self=shift;
  my $link=shift;
  my $user_agent=$self->{"user_agent"};
  my $url=$link->url();
  my $supported;

  my $verbose=$self->{"verbose"};

  my $urlo=new URI($url);
  my $proto=$urlo->scheme();

  eval { $supported = $user_agent->is_protocol_supported($proto) ; };

  #if it get's really upset, is_protocol_supported sometimes dies.  We
  #just treat this as an unsupported link.

  $@ && do {
    warn $@;
    $supported=0;
  };

  $supported or do {
      my $response=new HTTP::Response ( RC_PROTOCOL_UNSUPPORTED,
					MSG_PROTOCOL_UNSUPPORTED );
      return $response;
  };

  my $request=new HTTP::Request ('HEAD',$url);

  print STDERR "sending request\n" if $verbose;
  my $response=$user_agent->simple_request($request);
  print STDERR "got response\n" if $verbose;
  #warn on client error

  if ($self->{warn_access}) { # warn about links where we can't access it
    # but someone might
    print STDERR "didn't have authorisation\n";
  }

  my @redirects;
 REDIRECT:  while ($response->is_redirect()) {
    my $loc = $response->headers->header('Location');
    (defined $loc) || do {
      carp "redirect with no location!";
      $response=new HTTP::Response (RC_REDIRECT_LIMIT_EXCEEDED,
				    MSG_REDIRECT_LIMIT_EXCEEDED);
      last REDIRECT;
    };
    print STDERR "have a redirect: " . $loc . "\n" if $verbose;

    push @redirects, $response;

    (@redirects == $self->{"max_redirects"}) && do {
      $response=new HTTP::Response (RC_REDIRECT_LIMIT_EXCEEDED,
				    MSG_REDIRECT_LIMIT_EXCEEDED);
      last;
    };
    my $request=new HTTP::Request ('HEAD',$loc);
    $response=$user_agent->simple_request($request);
  }
  return $response, @redirects;
}


1; #kEEp rEqUIrE HaPpY.


