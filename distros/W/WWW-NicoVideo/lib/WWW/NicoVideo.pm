# -*- mode: perl; coding: utf-8 -*-

package WWW::NicoVideo;
use utf8;
use strict;
use warnings;
use base qw[Class::Accessor];

use Encode;
use Carp;
use LWP::UserAgent;
use HTTP::Cookies;
use URI;
use URI::QueryParam;
use WWW::NicoVideo::Entry;
use WWW::NicoVideo::Scraper;
use WWW::NicoVideo::URL;

__PACKAGE__->mk_accessors(qw[agent retry retryInterval mail passwd]);

our $VERSION = "0.03";
our $AGENT_NAME = "@{[__PACKAGE__]}/$VERSION)";

sub new
{
  my $pkg = shift;
  my %opts = @_;

  my $ua = $opts{agent} || new LWP::UserAgent(agent => $AGENT_NAME,
					      timeout => 30,
					      %{$opts{agentOpts}});
  $ua->cookie_jar($opts{cookies} ||
		  new HTTP::Cookies(%{$opts{cookiesOpts}}));

  bless {agent => $ua,
	 retry => $opts{retry} || 5,
	 retryInterval => $opts{retryInterval} || 30,
	 mail => $opts{mail},
	 passwd => $opts{passwd}}, $pkg;
}

sub login
{
  my $self = shift;
  my $ua = $self->{agent};
  my $cj = $ua->cookie_jar;
  my $has_cookie = 0;

  if(not defined $self->{mail} or
     not defined $self->{passwd}) {
    confess "mail and passwd required";
  }

  $cj->scan(sub {
	      my($key, $val, $domain, $expires) = @_[1, 2, 4, 8];
	      if($domain eq ".nicovideo.jp" and
		 time + 60 < $expires) {
		$has_cookie = 1;
	      }
	    });

  my $login_ok = 0;
  if($has_cookie) {
    my $res = $ua->get(nicoURL("top"));
    if($res->is_success and
       not $res->as_string =~ /<form [^<>]*name="login"/) {
      $login_ok = 1;
    }
  }

  if($login_ok) {
    $self->{loginOk} = 1;
    return 1;
  } else {
    my $res = $ua->post(nicoURL("login"),
			{mail => $self->{mail},
			 password => $self->{passwd}});

    if($res->is_redirect) {
      $self->{loginOk} = 1;
      return 1;
    } else {
      return 0;
    }
  }
}

sub getEntriesByTagNames
{
  my $self = shift;
  $self->getEntries("tag", @_);
}

*getEntriesByTagName = \&getEntriesByTagNames;

sub getEntriesByKeywords
{
  my $self = shift;
  $self->getEntries("search", @_);
}

*getEntriesByKeyword = \&getEntriesByKeywords;

sub getEntries
{
  my $self = shift;
  my $type = shift;
  my %opts = @_;
  my @keys = (@{$opts{keys} || []},
	      (defined $opts{key}? $opts{key}: ()));
  my $page = $opts{page};
  my $sort = $opts{sort};
  my $order = $opts{order};

  my $ua = $self->{agent};

  if(!$self->{loginOk}) {
    return wantarray? (): undef;
  }

  my $url = new URI(nicoURL($type, @keys));
  $url->query_param_append(sort => $sort) if(defined $sort);
  $url->query_param_append(order => $order) if(defined $order);
  $url->query_param_append(page => $page) if(defined $page);

  my $count = 0;
  my $res;
  my $html;

  do {
    if($count) {
      # busy
      sleep($self->{retryInterval} || 30);
    }

    $res = $ua->get($url);

    if($res->is_success) {
      $html = decode_utf8($res->content);
    } elsif($opts{verbose}) {
      carp "Could not get $url (status: ", $res->status_line, ")";
    }

    $count++;
  } while(not $res->is_success and
	  $count < $self->{retry} and
	  $html =~ m{^<p class="TXT12">【ご注意】<br>}m # access blocking
	 );

  my $scraper = scraper_entries();
  my @res = (map { WWW::NicoVideo::Entry->new($_) }
	     @{$scraper->scrape($html)->{entries} || []});
  wantarray? @res: \@res;
}

"Ritsuko";

=encoding utf-8

=head1 NAME

WWW::NicoVideo - Perl interface to Nico Nico Video service

=head1 SYNOPSIS

  use utf8;
  use WWW::NicoVideo;
  binmode STDOUT, ":encoding(euc-jp)";

  my $nv = new WWW::NicoVideo(mail => 'ritsuko@ritsuko.org',
                              passwd => "ritchan-wa-kawaiidesuyo");
  $nv->login or die "Login failed";

  my @entries = $nv->getEntriesByTagNames("律子ソロ") or die "get failed";
  foreach my $e (@entries) {
    print $e->title, "\n";
  }

=head1 DESCRIPTION

This module allows you to get information from
Nico Nico Video service (L<http://www.nicovideo.jp/>)
and also allows you to search from it.

=head1 METHODS

=over 4

=item $nv = new WWW::NicoVideo(%OPTS)

Constructs a new WWW::NicoVideo object and returns it.
Key/value pair options may be provided to set the default value.
Following options are accepted:

=over 4

=item agent / cookies

LWP::UserAgent / HTTP::Cookies object.

=item retry / retryInterval

Retry count / retry interval in second.
As Nico Nico Video rejects mass access,
you have to give appropriate interval between accesses.

=item mail / passwd

Mail address / password to access Nico Nico Video.

=back

All options except "cookies" can be accessed via accessor methods.
(e.g. $nv->agent)
You may access cookies via "agent".
(e.g. $nv->agent->cookie_jar)

=item $nv->login

Login to Nico Nico Video. You have to call this method before
calling getEntries* methods;

=item $nv->getEntriesByTagNames(%OPTS) / $nv->getEntriesByKeywords(%OPTS)

Returns entry list for given tag name(s) / keyword(s).
In scalar context, this method returns a reference to array of
WWW::NicoVideo::Entry or undef on errors.
In list context, this method returns list of WWW::NicoVideo::Entry
or null list on errors.
Following options are accepted:

=over 4

=item key / keys

Tagname(s) or keyword(s).
"key" takes a scalar value, "keys" takes a reference to array.

=item page

Page number.

=item sort

Sort type. "f" for post date, "v" for number of views,
"r" for number of comments, undef for last comment date.

=item order

Sort order. "a" for ASC, "d" or undef for DESC.

=back

=back

=head1 SEE ALSO

L<perl(1)>, L<Web::Scraper>, L<WWW::NicoVideo::Entry>

=head1 AUTHOR

HIRATA Yasuyuki, E<lt>yasu@REMOVE-THIS-PART.asuka.netE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 SUBVERSION REPOSITORY

The latest version of this module is available
from our Subversion repository at:
  L<http://svn.coderepos.org/share/lang/perl/WWW-NicoVideo/>

=cut
