package WebService::LiveJournal;

use strict;
use warnings;
use v5.10;
use base qw( WebService::LiveJournal::Client );

# ABSTRACT: Interface to the LiveJournal API
our $VERSION = '0.08'; # VERSION

sub _set_error
{
  my($self, $message) = @_;
  $self->SUPER::_set_error($message);
  die $message;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LiveJournal - Interface to the LiveJournal API

=head1 VERSION

version 0.08

=head1 SYNOPSIS

new interface

 use WebService::LiveJournal;
 my $client = WebService::LiveJournal->new( username => 'foo', password => 'bar' );

same thing with the old interface

 use WebService::LiveJournal::Client;
 my $client = WebService::LiveJournal::Client->new( username => 'foo', password => 'bar' );
 die "connection error: $WebService::LiveJournal::Client::error" unless defined $client;

See L<WebService::LiveJournal::Event> for creating/updating LiveJournal events.

See L<WebService::LiveJournal::Friend> for making queries about friends.

See L<WebService::LiveJournal::FriendGroup> for getting your friend groups.

=head1 DESCRIPTION

This is a client class for communicating with LiveJournal using its API.  It is different
from the other LJ modules on CPAN in that it originally used the XML-RPC API.  It now
uses a hybrid of the flat and XML-RPC API to avoid bugs in some LiveJournal deployments.

There are two interfaces:

=over 4

=item L<WebService::LiveJournal>

The new interface, where methods throw an exception on error.

=item L<WebService::LiveJournal::Client>

The legacy interface, where methods return undef on error and
set $WebService::LiveJournal::Client::error

=back

It is recommended that for any new code that you use the new interface.

=head1 CONSTRUCTOR

=head2 new

 my $client = WebService::LiveJournal::Client->new( %options )

Connects to a LiveJournal server using the host and user information
provided by C<%options>.

Signals an error depending on the interface
selected by throwing an exception or returning undef.

=head3 options

=over 4

=item server

The server hostname, defaults to www.livejournal.com

=item port

The server port, defaults to 80

=item username [required]

The username to login as

=item password [required]

The password to login with

=item mode

One of either C<cookie> or C<challenge>, defaults to C<cookie>.

=back

=head1 ATTRIBUTES

These attributes are read-only.

=head2 server

The name of the LiveJournal server

=head2 port

The port used to connect to LiveJournal with

=head2 username

The username used to connect to LiveJournal

=head2 userid

The LiveJournal userid of the user used to connect to LiveJournal.
This is an integer.

=head2 fullname

The fullname of the user used to connect to LiveJournal as LiveJournal understands it

=head2 usejournals

List of shared/news/community journals that the user has permission to post in.

=head2 message

Message that should be displayed to the end user, if present.

=head2 useragent

Instance of L<LWP::UserAgent> used to connect to LiveJournal

=head2 cookie_jar

Instance of L<HTTP::Cookies> used to connect to LiveJournal with

=head2 fastserver

True if you have a paid account and are entitled to use the
fast server mode.

=head1 METHODS

=head2 create_event

 $client->create_event( %options )

Creates a new event and returns it in the form of an instance of
L<WebService::LiveJournal::Event>.  This does not create the 
event on the LiveJournal server itself, until you use the 
C<update> methods on the event.

C<%options> contains a hash of attribute key, value pairs for
the new L<WebService::LiveJournal::Event>.  The only required
attributes are C<subject> and C<event>, though you may set these
values after the event is created as long as you set them
before you try to C<update> the event.  Thus this:

 my $event = $client->create(
   subject => 'a new title',
   event => 'some content',
 );
 $event->update;

is equivalent to this:

 my $event = $client->create;
 $event->subject('a new title');
 $event->event('some content');
 $event->update;

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=head2 get_events

 $client->get_events( $select_type, %query )

Selects events from the LiveJournal server.  The actual C<%query>
parameter requirements depend on the C<$select_type>.

Returns an instance of L<WebService::LiveJournal::EventList>.

Select types:

=over 4

=item syncitems

This query mode can be used to sync all entries with multiple calls.

=over 4

=item lastsync

The date of the last sync in the format of C<yyyy-mm-dd hh:mm:ss>

=back

=item day

This query can be used to fetch all the entries for a particular day.

=over 4

=item year

4 digit integer

=item month

1 or 2 digit integer, 1-31

=item day

integer 1-12 

=back

=item lastn

Fetch the last n events from the LiveJournal server.

=over 4

=item howmany

integer, default = 20, max = 50

=item beforedate

date of the format C<yyyy-mm-dd hh:mm:ss>

=back

=back

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=head2 get_event

 $client->get_event( $itemid )

Given an C<itemid> (the internal LiveJournal identifier for an event).

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=head2 sync_items

 $client->sync_items( $cb )
 $client->sync_items( last_sync => $time, $cb )

Fetch all of the items which have been created/modified since the last sync.
If C<last_sync =E<gt> $time> is not provided then it will fetch all events.
For each item that has been changed it will call the code reference C<$cb>
with three arguments:

 $cb->($action, $type, $id)

=over 4

=item action

One of C<create> or C<update>

=item type

For "events" (journal entries) this is C<L>

=item id

The internal LiveJournal server id for the item.  An integer.
For events, the actual event can be fetched using the C<get_event>
method.

=back

If the callback throws an exception, then no more entries will be processed.
If the callback does not throw an exception, then the next item will be
processed.

This method returns the time of the last entry successfully processed, which
can be passed into C<sync_item> the next time to only get the items that have
changed since the first time.

Here is a broad example:

 # first time:
 my $time = $client->sync_items(sub {
   my($action, $type, $id) = @_;
   if($type eq 'L')
   {
     my $event = $client->get_item($id);
     # ...
     if(error condition)
     {
       die 'error happened';
     }
   }
 });
 
 # if an error happened during the sync
 my $error = $client->error;
 
 # next time:
 $time = $client->sync_items(last_sync => $time, sub {
   ...
 });

Because the C<syncitems> rpc that this method depends on
can make several requests before it completes it can fail
half way through.  If this happens, you can restart where
the last successful item was processed by passing the
return value back into C<sync_items> again.  You can tell
that C<sync_item> completed without error because the 
C<$client-E<gt>error> accessor should return a false value.

=head2 get_friends

 $client->get_friends( %options )

Returns friend information associated with the account with which you are logged in.

=over 4

=item complete

If true returns your friends, stalkers (users who have you as a friend) and friend groups

 # $friends is a WS::LJ::FriendList containing your friends
 # $friend_of is a WS::LJ::FriendList containing your stalkers
 # $groups is a WS::LJ::FriendGroupList containing your friend groups
 my($friends, $friend_of, $groups) = $client-E<gt>get_friends( complete => 1 );

If false (the default) only your friends will be returned

 # $friends is a WS::LJ::FriendList containing your friends
 my $friends = $client-E<gt>get_friends;

=item friendlimit

If set to a numeric value greater than zero, this mode will only return the number of results indicated. 

=back

=head2 get_friends_of

 $client->get_friend_of( %options )

Returns the list of users that are a friend of the logged in account.

Returns an instance of L<WebService::LiveJournal::FriendList>, a list of
L<WebService::LiveJournal::Friend>.

Options:

=over 4

=item friendoflimit

If set to a numeric value greater than zero, this mode will only return the number of results indicated

=back

=head2 get_friend_groups

 $client->get_friend_groups

Returns your friend groups.  This comes as an instance of
L<WebService::LiveJournal::FriendGroupList> that contains
zero or more instances of L<WebService::LiveJournal::FriendGroup>.

=head2 get_user_tags

 $client->get_user_tags;
 $client->get_user_tags( $journal_name );

Fetch the tags associated with the given journal, or the users journal
if not specified.  This method returns a list of zero or more
L<WebService::LiveJournal::Tag> objects.

=head2 console_command

 $client->console_command( $command, @arguments )

Execute the given console command with the given arguments on the
LiveJournal server.  Returns the output as a list reference.
Each element in the list represents a line out output and consists
of a list reference containing the type of output and the text
of the output.  For example:

 my $ret = $client->console_command( 'print', 'hello world' );

returns:

 [
   [ 'info',    "Welcome to 'print'!" ],
   [ 'success', "hello world" ],
 ]

=head2 batch_console_commands

 $client->batch_console_commands( $command1, $callback);
 $client->batch_console_commands( $command1, $callback, [ $command2, $callback, [ ... ] );

Execute a list of commands on the LiveJournal server in one request. Each command is a list reference. Each callback 
associated with each command will be called with the results of that command (in the same format returned by 
C<console_command> mentioned above, except it is passed in as a list instead of a list reference).  Example:

 $client->batch_console_commands(
   [ 'print', 'something to print' ],
   sub {
     my @output = @_;
     ...
   },
   [ 'print', 'something else to print' ],
   sub {
     my @output = @_;
     ...
   },
 );

=head2 set_cookie

 $client->set_cookie( $key => $value )

This method allows you to set a cookie for the appropriate security and expiration information.
You shouldn't need to call it directly, but is available here if necessary.

=head2 send_request

 $client->send_request( $procname, @arguments )

Make a low level request to LiveJournal with the given
C<$procname> (the rpc procedure name) and C<@arguments>
(should be L<RPC::XML> types).

On success returns the appropriate L<RPC::XML> type
(usually RPC::XML::struct).

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=head2 send_flat_request

 $client->send_flat_request( $procname, @arguments )

Sends a low level request to the LiveJournal server using the flat API,
with the given C<$procname> (the rpc procedure name) and C<@arguments>.

On success returns the appropriate response.

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=head2 error

 $client->error

Returns the last error.  This just returns
$WebService::LiveJournal::Client::error, so it
is still a global, but is a slightly safer shortcut.

 my $event = $client->get_event($itemid) || die $client->error;

It is still better to use the newer interface which throws
an exception for any error.

=head1 EXAMPLES

These examples are included with the distribution in its 'example' directory.

Here is a simple example of how you would login/authenticate with a 
LiveJournal server:

 use strict;
 use warnings;
 use WebService::LiveJournal;
 
 print "user: ";
 my $user = <STDIN>;
 chomp $user;
 print "pass: ";
 my $password = <STDIN>;
 chomp $password;
 
 my $client = WebService::LiveJournal->new(
   server => 'www.livejournal.com',
   username => $user,
   password => $password,
 );
 
 print "$client\n";
 
 if($client->fastserver)
 {
   print "fast server\n";
 }
 else
 {
   print "slow server\n";
 }

Here is a simple example showing how you can post an entry to your 
LiveJournal:

 use strict;
 use warnings;
 use WebService::LiveJournal;
 
 print "user: ";
 my $user = <STDIN>;
 chomp $user;
 print "pass: ";
 my $password = <STDIN>;
 chomp $password;
 
 my $client = WebService::LiveJournal->new(
   server => 'www.livejournal.com',
   username => $user,
   password => $password,
 );
 
 print "subject: ";
 my $subject = <STDIN>;
 chomp $subject;
 
 print "content: (^D or EOF when done)\n";
 my @lines = <STDIN>;
 chomp @lines;
 
 my $event = $client->create(
   subject => $subject,
   event => join("\n", @lines),
 );
 
 $event->update;
 
 print "posted $event with $client\n";
 print "itemid = ", $event->itemid, "\n";
 print "url    = ", $event->url, "\n";
 print "anum   = ", $event->anum, "\n";

Here is an example of a script that will remove all entries from a 
LiveJournal.  Be very cautious before using this script, once the 
entries are removed they cannot be brought back from the dead:

 use strict;
 use warnings;
 use WebService::LiveJournal;
 
 print "WARNING WARNING WARNING\n";
 print "this will remove all entries in your LiveJournal account\n";
 print "this probably cannot be undone\n";
 print "WARNING WARNING WARNING\n";
 
 print "user: ";
 my $user = <STDIN>;
 chomp $user;
 print "pass: ";
 my $password = <STDIN>;
 chomp $password;
 
 my $client = WebService::LiveJournal->new(
   server => 'www.livejournal.com',
   username => $user,
   password => $password,
 );
 
 print "$client\n";
 
 my $count = 0;
 while(1)
 {
   my $event_list = $client->get_events('lastn', howmany => 50);
   last unless @{ $event_list } > 0;
   foreach my $event (@{ $event_list })
   {
     print "rm: ", $event->subject, "\n";
     $event->delete;
     $count++;
   }
 }
 
 print "$count entries deleted\n";

Here is a really simple command line interface to the LiveJournal
admin console.  Obvious improvements like better parsing of the commands
and not displaying the password are left as an exercise to the reader.

 use strict;
 use warnings;
 use WebService::LiveJournal;
 
 my $client = WebService::LiveJournal->new(
   server => 'www.livejournal.com',
   username => do {
     print "user: ";
     my $user = <STDIN>;
     chomp $user;
     $user;
   },
   password => do {
     print "pass: ";
     my $pass = <STDIN>;
     chomp $pass;
     $pass;
   },
 );
 
 while(1)
 {
   print "> ";
   my $command = <STDIN>;
   unless(defined $command)
   {
     print "\n";
     last;
   }
   chomp $command;
   $client->batch_console_commands(
     [ split /\s+/, $command ],
     sub {
       foreach my $line (@_)
       {
         my($type, $text) = @$line;
         printf "%8s : %s\n", $type, $text;
       }
     }
   );
 }

=head1 HISTORY

The code in this distribution was written many years ago to sync my website
with my LiveJournal.  It has some ugly warts and its interface was not well 
planned or thought out, it has many omissions and contains much that is apocryphal 
(or at least wildly inaccurate), but it (possibly) scores over the older 
LiveJournal modules on CPAN in that it has been used in production for 
many many years with very little maintenance required, and at the time of 
its original writing the documentation for those modules was sparse or misleading.

=head1 SEE ALSO

=over 4

=item

L<http://www.livejournal.com/doc/server/index.html>,

=item

L<Net::LiveJournal>,

=item

L<LJ::Simple>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut