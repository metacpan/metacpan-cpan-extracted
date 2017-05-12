package WWW::Link::Test;
$REVISION=q$Revision: 1.6 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

=head1 NAME

WWW::Link::Test - functions for testing links.

=head1 SYNOPSIS

    use WWW::Link::Test
    $ua=create_a_user_agent();
    $link=get_a_link_object();
    WWW::Link::Test::test_link($ua, $link);

=head1 DESCRIPTION

At present this package only implements a single function which acts
as the glue between a link object and a robot user agent to use the
user agent to test a link.

The link is tested and then given information about what was
discovered.  The link then records this information for future use..

=head1 METHODS

Only one method currently impemented.  The others were done
differently but may come back later..

=head2 test_link

This function tests a link by going out to the world and checking it
and then telling the associated link object what happened.

=cut

use strict;
use URI;
use WWW::Link;
use HTTP::Request

use vars qw($warn_access);

sub test_link ($@) {
  my $user_agent=shift;
  my $link;
  foreach $link (@_) {
    my $url=URI->new($link->url);
    my $request=new HTTP::Request ('HEAD',$url);
    print STDERR "sending request\n";
    my $response=$user_agent->simple_request($request);
    print STDERR "got response\n";
    #warn on client error

    if ($warn_access) { # warn about links where we can't access it
                        # but someone might
      print STDERR "didn't have authorisation\n";
    }


    #examine server errror
    $link->got_simple_response($response); #how much space is this?
    if ($response->is_redirect()) {
      print STDERR "have a redirect: " .  $response->header('Location') . "\n";
      $response=$user_agent->request($request);
      $link->got_end_response($response);
    }
  }
}

=head2

Unconditionally tests all links.  NOT IMPLEMENTED

=cut

sub test_all_links ($) {
  my $link_database=shift;
  while (%$link_database) {
    die "test_all_links unimplemented";
  } 
}

=head1 

Tests links which need it. NOT IMPLEMENTED

=cut

sub test_all_needed ($) {
  my $link_database=shift;
  #remember you can't alter the contents of the database while going
  #through it
  while (%$link_database) {
    die "test_all_needed unimplemented";
  }
}

1; #kEEp rEqUIrE HaPpY.


