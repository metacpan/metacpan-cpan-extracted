package WebService::ChangesXml;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use Carp;
use LWP::UserAgent;
use HTTP::Date;
use HTTP::Request;
use HTTP::Status;
use XML::Simple;

sub new {
    my($class, $url) = @_;
    defined($url) or croak "Usage: new(\$url)";
    my $self = bless { url => $url }, $class;
    $self->_init_ua();
    return $self;
}

sub _init_ua {
    my $self = shift;
    $self->{ua} = LWP::UserAgent->new();
    $self->{ua}->agent("WebService::ChangesXml/$VERSION");
}

sub user_agent { shift->{ua} }
sub url        { shift->{url} }
sub count      { shift->{count} }

sub updated {
    my $self = shift;
    $self->{updated} = shift if @_;
    $self->{updated};
}

sub add_handler {
    my($self, $sub) = @_;
    defined($sub) and ref($sub) eq 'CODE' or croak "Usage: add_handler(\$subref);";
    push @{$self->{handlers}}, $sub;
}

sub find_new_pings {
    my $self = shift;

    my $simple_api;
    if (@_) {
	$simple_api = 1;

	# set updated with $interval
	my $interval = shift;
	$self->{updated} = time - $interval;
    }

    # HTTP/GET changes.xml 
    my $request  = HTTP::Request->new(GET => $self->url);
    if (defined($self->{updated})) {
	$request->header('If-Modified-Since' => HTTP::Date::time2str($self->{updated}));
    }
    my $response = $self->user_agent->request($request);
    die "Got error in fetching changes.xml: ", $response->code unless $response->is_success;

    # do nothing if changes.xml is not modified 
    if ($response->code == RC_NOT_MODIFIED) {
	return $simple_api ? [] : 1;
    }

    my $xml = $response->content();
    my $p   = XML::Simple->new();
    my $updates = $p->XMLin($xml, KeyAttr => 'weblog', ForceArray => 1);

    # set updated and count
    my $old = $self->{updated} || 0;
    $self->{updated} = HTTP::Date::str2time($updates->{updated})
	or croak "weird updated format: $updates->{updated}";
    $self->{count}   = $updates->{count};

    my @pings;
    for my $weblog (@{$updates->{weblog}}) {
	# calculate "when" to Unix time
	my $when = $self->{updated} - $weblog->{when};

	# no more new blogs
	last if $old >= $self->{updated} - $weblog->{when};

	if ($simple_api) {
	    push @pings, { name => $weblog->{name},
			   url  => $weblog->{url},
			   when => $when };
	} else {
	    for my $handler (@{$self->{handlers}}) {
		$handler->($weblog->{name}, $weblog->{url}, $when);
	    }
	}
    }

    return $simple_api ? \@pings : 1;
}

1;
__END__

=head1 NAME

WebService::ChangesXml - Do something with updated blogs on Weblogs.Com

=head1 SYNOPSIS

  use WebService::ChangesXml;

  # Simple API
  my $changes = WebService::ChangesXml->new("http://www.weblogs.com/changes.xml");
  my $pings   = $changes->find_new_pings(600); # find new blogs updated in 600 seconds

  for my $ping (@$pings) {
      do_something($ping->{url});
  }

  # Event based API
  # do something with new blogs with 300 seconds interval

  my $changes = WebService::ChangesXml->new("http://www.weblogs.com/changes.xml");
  $changes->add_handler(\&found_new_ping);

  while (1) {
      $changes->find_new_pings();
      sleep 300;
  }

  sub found_new_ping {
      my($blog_name, $blog_url, $when) = @_;
      do_something($blog_url);
  }

=head1 DESCRIPTION

WebService::ChangesXml is a event-driven module to build your
application that does something with newly updated blogs displayed on
Weblogs.Com (or other services that provides compatible
C<changes.xml>).

=head1 METHODS

=over 4

=item new

  $changes = WebService::ChangesXml->new($changes_xml);

Creates new object. Takes URL for C<changes.xml>.

=item url

  $url = $changes->url();

Returns URL for C<changes.xml>, that should be set on C<new>.

=item add_handler

Registers new subroutine that is invoked when this module finds newly
updated blogs. Registerd subroutine will be given 3 paarameters: Blog
name, Blog URL and when its updated (epoch time).

=item find_new_pings

  $changes->find_new_pings($seconds);
  $changes->find_new_pings();

Fetches C<changes.xml> and returns newly updated blogs as hashref in
simple API, or invokes registered handlers when it found new blogs in
event based API.

=item updated

  my $updated = $changes->updated();
  $changes->updated($updated);

Gets/sets last updated time of C<changes.xml>. If you call C<find_new_pings>
method once in a script, and saves updated timestamp in file or
database. Use this method to restore last updated time. For example:

  # restore updated time from $timestamp_file's mtime
  my $last_invoked = (stat($timestamp_file))[8];
  $changes->updated($updated);

  # now find new Blogs
  $changes->find_new_pings();

  # equivalent to Unix "touch"
  my $updated = $changes->updated;
  utime $updated, $updated, $timestamp_file;

Last updated time is set internally when you call C<find_new_pings> methods.

=item count

  my $count = $changes->count();

Returns how many times C<changes.xml> is updated.

=item user_agent

  my $ua = $changes->user_agent();

Returns LWP::UserAgent object used internally. If you wanna override
User-Agent: header, timeout setting or other LWP setting,  use this method.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Thanks to Naoya Ito for teaching me C<KeyAttr> usage of XML::Simple ;-)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WebService::weblogUpdates>

http://newhome.weblogs.com/changesXml

http://www.weblogs.com/changes.xml


=cut
