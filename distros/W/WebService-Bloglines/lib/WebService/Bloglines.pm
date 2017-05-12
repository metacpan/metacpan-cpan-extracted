package WebService::Bloglines;

use strict;
use 5.8.1;
our $VERSION = '0.12';

use LWP::UserAgent;
use URI;

use WebService::Bloglines::Entries;
use WebService::Bloglines::Subscriptions;

sub new {
    my($class, %p) = @_;
    my $ua  = LWP::UserAgent->new();
    $ua->env_proxy;
    $ua->agent("WebService::Bloglines/$VERSION");
    $ua->credentials("rpc.bloglines.com:80", "Bloglines RPC",
		     $p{username}, $p{password});
    bless { %p, ua => $ua }, $class;
}

sub username    { shift->_var('username', @_) }
sub password    { shift->_var('password', @_) }
sub use_liberal { shift->_var('use_liberal', @_) }

sub _var {
    my $self = shift;
    my $key  = shift;
    $self->{$key} = shift if @_;
    $self->{$key};
}

sub _die {
    my($self, $message) = @_;
    require Carp;
    Carp::croak($message);
}

sub _request {
    my($self, $url, %param) = @_;
    my $uri = URI->new($url);
    $uri->query_form(%param);

    my $request = HTTP::Request->new(GET => $uri);
    return $self->{ua}->request($request);
}

# http://www.bloglines.com/services/api/notifier
sub notify {
    my $self = shift;
    my $res  = $self->_request("http://rpc.bloglines.com/update",
			       user => $self->{username},
			       ver  => 1);
    my $content = $res->content;

    # |A|B| where A is the number of unread items
    $content =~ /\|([\-\d]+)|(.*)|/
	or $self->_die("Bad Response: $content");

    my($unread, $url) = ($1, $2);

    # A is -1 if the user email address is wrong.
    if ($unread == -1) {
	$self->_die("Bad username: $self->{username}");
    }

    # XXX should check $url?

    return $unread;
}

# http://www.bloglines.com/services/api/listsubs
sub listsubs {
    my $self = shift;
    my $res  = $self->_request("http://rpc.bloglines.com/listsubs");

    if ($res->code == 401) {
	$self->_die($res->status_line);
    }

    return WebService::Bloglines::Subscriptions->new($res->content);
}

# http://www.bloglines.com/services/api/getitems
sub getitems {
    my($self, $subid, $mark_read, $time) = @_;
    my %param = (s => $subid, n => $mark_read, d => $time);

    # normalize to defined parameters
    %param = map { defined($param{$_}) ? ($_ => $param{$_}) : () } keys %param;

    my $res  = $self->_request("http://rpc.bloglines.com/getitems", %param);

    # 304 means no updates
    return if $res->code == 304;

    # otherwise, something bad is happened
    unless ($res->code == 200) {
	$self->_die($res->status_line);
    }

    return WebService::Bloglines::Entries->parse($res->content, $self->use_liberal);
}

1;
__END__

=head1 NAME

WebService::Bloglines - Easy-to-use Interface for Bloglines Web Services

=head1 SYNOPSIS

  use WebService::Bloglines;

  my $bloglines = WebService::Bloglines->new(
      username => $username,
      password => $password, # password is optional for notify()
      use_liberal => 1,
  );

  # get the number of unread items using Notifer API
  my $notifier = $bloglines->notify();

  # list subscriptions using Sync API
  my $subscription = $bloglines->listsubs();

  # list all feeds
  my @feeds = $subscription->feeds();
  for my $feed (@feeds) {
      my $title  = $feed->{title};            # title of the feed
      my $url    = $feed->{htmlUrl};          # URL for HTML
      my $type   = $feed->{type};             # "rss"
      my $xml    = $feed->{xmlUrl};           # URL for XML
      my $subid  = $feed->{BloglinesSubId};   # Blogines SubId
      my $unread = $feed->{BloglinesUnread};  # number of unread items
      my $ignore = $feed->{BloglinesIgnore};  # flag to ignore update
  }

  # list folders
  my @folders = $subscription->folders();
  for my $folder (@folders) {
      my $title  = $folder->{title};  # title of the folder
      my $unread = $folder->{BloglinesUnread}; # number of unread items
      my $subid  = $folder->{BloglinesSubId};  # Bloglines SubId
      my $ignore = $folder->{BloglinesIgnore}; # flag to ignore update
      my @feeds  = $subscription->feeds_in_folder($subid);
  }

  # list feeds in root folder
  my @root_feeds = $subscription->feeds_in_folder(); # no args or just use $subId = 0

  # get new items using Sync API
  my $update = $bloglines->getitems($subId);
  #  $update = $bloglines->getitems($subId, 1);            # mark unread items as read
  #  $update = $bloglines->getitems($subId, 1, $unixtime); # items from $unixtime

  # get channel information
  my $feed = $update->feed();
  $feed->{title};       # channel/title
  $feed->{link};        # channel/link
  $feed->{description}; # channel/description
  $feed->{bloglines}->{siteid};      # bloglines::siteid
  $feed->{language};    # language

  for my $item ($update->items) {
      my $title       = $item->{title};
      my $creator     = $item->{dc}->{creator};
      my $link        = $item->{link};
      my $guid        = $item->{guid};
      my $description = $item->{description};
      my $pubDate     = $item->{pubDate}; # "Mon, 27 Sep 2004 8:04:17 GMT"
      my $itemid      = $item->{bloglines}->{itemid};
  }

  # get all unread items in a single call
  my @updates = $bloglines->getitems(0);
  for my $update (@updates) {
      my $feed = $update->feed();
      for my $item ($update->items) {
          ...
      }
  }

=head1 DESCRIPTION

WebService::Bloglines priovides you an Object Oriented interface for
Bloglines Web Services (BWS). It currently supports Notifier API and
Sync API. See http://www.bloglines.com/services/api/ for details.

=head1 METHODS

TBD.

=head1 TODO

=over 4

=item *

Cleaner API to make users free from the difference between OPML and RSS stuff

=item *

Use LibXML to parse OPML?

=back

=head1 WARNING

This module is in beta version. Object interface it provides may be changed later.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.bloglines.com/

http://www.bloglines.com/services/api/

Blog Hacks: http://hacks.bloghackers.net/ (in Japanese)

=cut
