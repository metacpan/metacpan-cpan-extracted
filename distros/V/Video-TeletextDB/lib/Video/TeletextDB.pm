package Video::TeletextDB;
use 5.006001;
use strict;
use warnings;
use Carp;
use Video::TeletextDB::Access;

our $VERSION = "0.02";
use base qw(Video::TeletextDB::Parameters);

our @CARP_NOT = qw(File::Path
                   Video::TeletextDB::Access Video::TeletextDB::Options
                   Video::TeletextDB::Parameters);

sub init {
    my ($tele, $params) = @_;

    $tele->{access_class} = "Video::TeletextDB::Access" unless
        defined($tele->{access_class} = delete $params->{DbClass});

    $tele->SUPER::init($params);
    $tele->{access_class}->prepare($tele, $params);
}

# It's important that you cannot change the cache_dir.
# That would make upgrade/downgrade in Video::TeletextDB::Access.pm buggy
sub cache_dir {
    croak 'Too many arguments for cache_dir method' if @_ > 1;
    return shift->{cache_dir} ||
        croak "Current access class doesn't support a cache_dir concept";
}

sub access_class {
    croak 'Too many arguments for cache_dir method' if @_ > 1;
    return shift->{access_class};
}

sub access : method {
    my $tele = shift;
    return $tele->access_class->new(parent => $tele, @_);
}

my %delete_params = map { $_ => 1 } qw(channel umask);
sub delete : method {
    # Abuse the access method to collect properties
    my ($tele, %params) = @_;
    my @bad = grep !exists $delete_params{$_}, keys %params;
    croak("Unknown parameters ", join(", ", @bad)) if @bad;
    shift->access(%params, acquire => 0, creat => 1)->delete;
}

1;
__END__

=head1 NAME

Video::TeletextDB - Perl extension to manage a telextext database

=head1 SYNOPSIS

  use Video::TeletextDB;

  $tele_db	= Video::TeletextDB->new(%options);
  # Possible options are:
  # cache_dir	=> $directory
  # mkpath	=> $boolean
  # umask	=> $mask
  # creat	=> $boolean
  # RW		=> $boolean
  # page_versions => $number
  # channel	=> $string
  # stale_period  => $seconds
  # expire_period => $seconds

  $access	= $tele_db->access(%options);
  # Possible options are:
  # umask	=> $mask
  # creat	=> $boolean
  # RW		=> $boolean
  # page_versions => $number
  # channel	=> $string
  # stale_period  => $seconds
  # expire_period => $seconds

  $cache_dir	= $tele_db->cache_dir;
  $channel	= $tele_db->channel;
  $old_channel	= $tele_db->channel($new_channel);
  @channels	= $tele_db->channels;
  $nr_channels	= $tele_db->channels;
  $boolean	= $tele_db->has_channel(?$channel?);
  $db_file	= $tele_db->db_file;
  $lock_file	= $tele_db->lock_file;
  $tele_db->lock;
  $page_versions= $tele_db->page_versions;
  $umask	= $tele_db->umask;
  $old_umask	= $tele_db->umask($new_umask);
  $RW		= $tele_db->RW;
  $old_RW	= $tele_db->RW($new_RW);
  $stale_period		= $tele_db->stale_period;
  $old_stale_period	= $tele_db->stale_period($new_stale_period);
  $expire_period	= $tele_db->expire_period;
  $old_expire_period	= $tele_db->expire_period($new_expire_period);
  $user_data	= $tele_db->user_data;
  $old_user_data= $tele_db->user_data($new_user_data);

  $tele_db->delete(%options);

=head1 DESCRIPTION

The idea behind a teletext database is to separate the process of collecting
teletext pages from the process of presentation. This makes programs both
shorter (you don't have to implement the side your're not interested in) and
more flexible (you can read teletext pages long after the collector stopped
running and you don't have to be tuned in to the channel you want to read).

In fact, the simple script L<TeleCollect|TeleCollect> coming with this package
will be good enough for most teletext collection purposes, so that you can
concentrate on the page processing.

This modules provides you with methods to both store and retrieve pages into
a database and some rudimentary support to manage a set of databases
(typically one for each channel). The pages will be stored in raw form
so that a client can decide for itself how to handle things like transmission
errors (there are of suggested methods provided in the module though, so
you don't have to reinvent the wheel every time).

It (currently) use a Berkeley DB with an external lockfile for the actual
storage. It only uses the version 1.85 features, so it should work almost
everywhere. There will be one database and lockfile for each channel and all
channel databases and locks will normally be collected in one directory.

=head1 EXAMPLE

  # Show Casema teletext page 100/01 as text.
  # (Casema is a dutch cable channel which for me sits on channel E5)
  # Won't show much until I run a collector like TeleCollect while being
  # tuned in to channel E5 (Casema).

  use Video::TeletextDB;

  my $tele_db = Video::TeletextDB->new;
  my $access = $tele_db->access(channel => "E5");
  # Notice the use of hexadecimal notation for the page and subpage argument
  my $page = $access->fetch_page(0x100, 0x01) ||
      die "Could not fetch teletext page 100/01\n";
  print $page->text;

=head1 METHODS

All methods throw an exception in case of failure unless mentioned otherwise.

=over

=item X<new>$tele_db = Video::TeletextDB->new(%options)

Creates a new Video::TeletextDB object, basically representing a set of
teletext channel databases and some defaults.

%options a sequence of name/value pairs modifying the meaning of the new.
Recognized names are:

=over

=item X<new_cache_dir>cache_dir => $directory

Gives the name of the directory with databases and lockfiles. The given
directory name will be ~-expanded (see the
L<tilde function in Video::TeletextDB::Access|Video::TeletextDB::Access/tilde>)
and prefixed with the current directory if it isn't absolute.

The directory is then checked for existence, and created if the
L<mkpath option|"new_mkpath"> is true. An exception is raised otherwise.

Defaults to ~/.TeletextDB/cache if not given (which also causes
L<mkpath|"new_mkpath"> to default to true if not given).

Also defaults to ~/.TeletextDB/cache if given an undef argument, but
mkpath defaults to false if not given in that case.

=item X<new_mkpath>mkpath => $boolean

If true the requested L<new_cache_dir|"cache_dir"> is created if it doesn't
already exist.
If false, an exception will be raised if it isn't already a directory.

Defaults to false, unless the L<cache_dir option|"new_cache_dir"> is also
absent, in which case it will be true.

=item X<new_umask>umask => $mask

Gives the umask that will be used whenever a file or directory is created by
this module. Defaults to undef if not given, which means to use the global
umask at the time that file or directory gets created.

Remember that an umask is a number, usually given in octal. It is not a string
of octal digits.  See L<oct|perlfunc/oct> to convert an octal string to a
number.

All L<new|"new"> parameters mentioned after this point don't actually do
anything, but are just defaults for L<access objects|"access"> you may create.

=item X<new_creat>creat => $boolean

When a method needs a certain file (database or lock) and the file doesn't
exist yet, something must be done. If this option is true, the file will be
created, if false an exception will be throws (which also happens if the
creation fails).

This module doesn't normally create anything, so it's main role is as a default
for L<access objects|"access"> you might create.

See the L<umask option|"new_umask"> if  you want control over the
permissions used on creation.

=item X<new_RW>RW => $boolean

If given a true value, any database open will by default be done in
readwrite mode. The open database can later be switched to readonly by a
L<downgrade|Video::TeletextDB/downgrade>.

If given undef the state of the database isn't fixed. It will start out as
readonly, but whenever the system needs write access, it will internally do an
L<upgrade|Video::TeletextDB/upgrade>.

All other false values (C<0> and C<""> normally) mean that you only want
readonly access to the database. You won't even be able to
L<upgrade|Video::TeletextDB/upgrade> unless you change the RW flag of the
L<Video::TeletextDB::Access object|Video::TeletextDB::Access/RW>.

The database needs some initialization on create though. So whatever value
you give to this flag, there can be a little bit of write activity if you
also gave the L<creat flag|"new_creat"> (this can happen even if the
database already existed if it somehow was missing its initial state).
The database will then be reopened readonly if you wanted pure readonly access.

=item X<new_page_versions>page_versions => $number

This determines how many versions of a certain page can be stored in the
database. Once this number is reached and a new page comes in, the oldest page
is bumped and replaced by the new one.

If not given or undefined it will read the current value from the database.
If that doesn't have an entry for it (a newly created database typically), it
will use some default value (normally 5).

Otherwise it should be some integer in the range [1..255].

Keeping more than one version of a page allows for some intelligent recovery
in case a page is damaged by using some information from older pages that are
hopefully not damaged in that spot. Using a higher number increases the chances
of a recovery, but also increases the chances of accidentally using stale data
and of course almost linearly increases the database size.

=item X<new_channel>channel => $string

This determines the name of the database and lockfiles that will be used.
The meaning is normally some channel indicator, but any string will do really.
There are however a few basic sanity checks applied to the string so that
you can't use it to confuse the database directory management.

If you leave this parameter undefined you will have to provide it on
L<database access|"access">.

=item X<new_stale_period>stale_period  => $seconds

Each channel database has an idea of when the last major update happened
(see the L<write_pages|Video::TeletextDB::Access/write_pages> method in
L<Video::TeletextDB::Access|Video::TeletextDB::Access>). If a page is older
than that time minus the stale period, it is considered stale and will not
be returned by any of the query methods.

The actual cutoff time is calculated at the moment you open an
L<access object|Video::TeletextDB::Access> and will not change for its lifetime
so that you will get a consistent view of the database even if updates are
still going on (however, if you release the database other clients can start
making changes).

Currently defaults to 1200 if not given (20 minutes).

=item X<new_expire_period>expire_period => $seconds

Each channel database has an idea of when the last major update happened
(see the L<write_pages|Video::TeletextDB::Access/write_pages> method in
L<Video::TeletextDB::Access|Video::TeletextDB::Access>). If a page is older
than that time minus the expire period, it is considered expired and will
get removed if its seen by any the query methods (only if the database is
L<upgradable|Video::TeletextDB::Access/upgrade> to writability). And pages
are not expired at all unless there was a certain minimum amount of stores.

The actual cutoff time is calculated at the moment you open an
L<access object|Video::TeletextDB::Access> and will not change for its lifetime
so that you will get a consistent view of the database, even if updates are
still going on (however, if you release the database other clients can start
making changes).

Currently defaults to 172800 if not given (2 days).

=back

=item X<access>$access = $tele_db->access(%options)

This method will create a new
L<Video::TeletextDB::Access object|Video::TeletextDB::Access> for some
channel. It will then take a blocking lock on the lockfile for that channel
and once it gets that open the corresponding database. You can then start using
the database through the methods the $access object provides.

You will have the database lock and therefore control over the database itself
for as long as this object exists (or until you explicitely give up control
using the L<release method|Video::TeletextDB::Access/release>). So only keep
control for shortish periods of time, unless you don't mind excluding any
other users of that channel database.

The options are again a sequence of name/value pairs and mainly repeat
the options of the L<new method|"new">. Any that are not given are taken over
from $tele_db object (an undef value B<is> giving a parameter, and explicitely
sets that attribute to undef without inheriting from $teledb). All these
values are then remembered inside the $access object so they won't pick up any
later changes to the $tele_db object.

Recognized names are:

=over

=item X<access_umask>umask => $mask

Like the L<umask option|"new_umask"> to L<new|"new">, except that now it
obviously only controls lockfiles and database files since the cache directory
will already have been created at this point.

=item X<access_creat>creat => $boolean

Has the same meaning as the L<corresponding option|"new_creat"> to
L<new|"new">.

=item X<access_RW>RW => $boolean

Has the same meaning as the L<corresponding option|"new_RW"> to
L<new|"new">.

=item X<access_page_versions>page_versions => $number

Has the same meaning as the L<corresponding option|"new_page_versions"> to
L<new|"new">. However if it's undefined it will be read from the database
which is now obviously available. If defined it will be compared to the value
in the database and an exception will be thrown if the two don't match.

=item X<access_channel>channel => $string

Again has the same meaning as the L<corresponding option|"new_page_versions">
to L<new|"new">. But this time you can't leave the value unspecified, since
the database has to be explicitely opend. So an exception is thrown if you
don't give a defined value and there is no default to inherit from the
calling $tele_db.

=item X<access_stale_period>stale_period => $seconds

Has the same meaning as the L<corresponding option|"new_stale_period"> to
L<new|"new">.

=item X<access_expire_period>expire_period => $seconds

Has the same meaning as the L<corresponding option|"new_expire_period"> to
L<new|"new">.

=back

=item X<dir>$cache_dir = $tele_db->cache_dir

Returns the name of the cache directory with databases and lockfiles.
Is guaranteed to be absolute and ends on a C</>. Apart from that it's not
normalized in any way.

=item X<channel>$channel = $tele_db->channel

Returns the current channel value (default name for databases and lockfiles)

=item $old_channel = $tele_db->channel($new_channel)

Sets the current channel to $new_channel. Returns the previous value.

=item X<channels>@channels = $tele_db->channels

=item $nr_channels = $tele_db->channels

Returns the list of channels in no particular order. Basically just returns a
list of readable database files without bothering to check if they actually
contain anything (or are even valid).

Returns the number of channels in scalar context.

=item X<has_channel>$boolean = $tele_db->has_channel(?$channel?)

Returns true if the given channel exists, false otherwise. Uses the current
channel if no argument is given.

=item X<db_file>$db_file = $tele_db->db_file

Returns the name of the database file that would be used for the current
channel. Throws an exception if there is no current channel.

=item X<lock_file>$lock_file = $tele_db->lock_file

Returns the name of the lockfile that would be used for the current
channel. Throws an exception if there is no current channel.

=item X<lock>$fh = $tele_db->lock

Takes a blocking lock on $tele_db->lock_file and truncates it to one
line containing the process id (L<$$|perlvar/$$>. Returns an open filehandle
for that lockfile, which is the last reference, none is kept internally.
So you'll have the lock for as long as you keep this handle alive, or until
you do an explicit unlock.

You normally don't use this method since all locking is taken care of
automatically by L<access|"access">,
L<acquire|Video::TeletextDB::Access/acquire> and
L<release|Video::TeletextDB::Access/release>.

=item X<page_versions>$page_versions = $tele_db->page_versions;

Returns the current setting for L<page_versions|"new_page_versions"> or undef
if there is none.

=item X<umask>$umask = $tele_db->umask

Returns the current logical umask setting (see the
L<umask parameter|"umask"> to L<new|"new">).

=item $old_umask = $tele_db->umask($new_umask)

Sets the logical umask to $new_umask and returns the old value.

=item X<RW>$RW = $tele_db->RW

Returns the current RW setting (see the L<RW parameter|"RW"> to L<new|"new">).

=item $old_RW = $tele_db->RW($new_RW)

Sets the RW flag to $new_RW and returns the old value.

=item X<stale_period>$stale_period = $tele_db->stale_period

Returns the current stale period.

=item $old_stale_period	= $tele_db->stale_period($new_stale_period)

Sets the stale period to $new_stale_period and returns the old value.

=item X<expire_period>$expire_period = $tele_db->expire_period

Returns the current expire period.

=item $old_expire_period = $tele_db->expire_period($new_expire_period)

Sets the expire period to $new_expire_period and returns the old value.

=item X<user_data>$user_data = $tele_db->user_data

With every TeletextDB object you can associate one scalar of user data
(default undef). This method returns that user data.

=item X<user_data>$old_user_data = $tele_db->user_data($new_user_data)

Set new user data, returning the old value.

=item $tele_db->delete(%options)

Used to delete a channel database and its locks. It will however try to take a
lock on the database before doing that, so it can block until the lock becomes
free. Taking a lock may also involve (temporarily) creating a lockfile in the
first place.

Options are a list of name/value pairs. The following names are recognized:

=over

=item X<delete_channel>channel => $string

Determines which channel gets deleted. If not given, it will use the current
channel setting. Raises an exception if undefined.

=item X<delete_umask>umask => $mask

Has the same semantics as L<the corresponding option|"new_umask"> for
L<new|"new">, though you likely don't care too much since most likely a new
lockfile will be deleted almost immediately after it got created.

=back

=head1 EXPORT

None.

=head1 SEE ALSO

L<alevtd(1)>,
L<Video::TeletextDB::Access>,
L<Video::TeletextDB::Page>,
L<TeleCollect>,
L<TeleFcgi>

=head1 AUTHOR

Ton Hospel, E<lt>Video-TeletextDB@ton.iguana.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
