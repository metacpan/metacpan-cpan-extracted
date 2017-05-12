package WWW::KeePassRest;

use 5.006;
use strict;
use warnings FATAL => 'all';
use WWW::JSONAPI;
use File::ShareDir;
use Carp;

=head1 NAME

WWW::KeePassRest - use KeePass for secure local secret storage

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

KeePass is a nifty Windows app (with work-alikes for Linux) that stores passwords and other sensitive
information in an encrypted database on the local hard drive. When open, it can then be used to manage
usernames and passwords, even generating new passwords with crunchy random goodness.

Wouldn't it be nice if you could just use the open KeePass instance for unattended retrieval of usernames
and passwords for your Web-enabled scripts? Well, with the doubly nifty KeePassRest plug-in, you can do
just that!

The KeePassRest plug-in is available at the SmartFTP website: L<https://www.smartftp.com/keepassrest>

KeePassRest exposes a minimal API on localhost:12984, secured by SSL and accessed with a JSON API.
You can't do everything with it (you can't generate passwords, work with groups of entries, etc.) but
for that stuff you've got L<File::KeePass> anyway.

Here's the absolutely simplest possible way to use WWW::KeePassRest:

    use LWP;
    use WWW::KeePassRest;
    use strict;

    my $url = 'http://somesite.com/aa/bb/cc.html';
    my $browser = LWP::UserAgent->new('Mozilla');
    $browser->credentials("somesite.com:80", "Realm", WWW:::KeePassRest->get_by_title('Some site credentials', 'UserName', 'Password'));
    my $response=$browser->get($url);

Seriously. Easy as that. Notice that there is I<absolutely no sensitive information> in this script.
The username and password are stored in KeePass under the title "Some site credentials". The script will
only run when KeePass is running and you've given it your password entirely separately - and that needs
to happen I<once>, after which your scripts can run to your heart's content with no further need to
enter passwords.
If KeePass is not running, the call here will croak with "500 Can't connect", so you can easily trap for that case.

Note that KeePass is actually based on a nifty key/value-oriented database and could be used for any kind
of sensitive information, not just usernames and passwords.

B<Please note:> The first time you use this module to hit the KeePass database, you'll see a security popup.
It provides the thumbprint from the certificate bundled with this distribution. Once you accept it, KeePassRest
saves it to an entry in the KeePass database, and if you subsequently save the database you'll never see
the popup again. However, if you let KeePass shut down due to your laptop hibernating or the like, then it
won't save the database, and you'll see that popup again. So word to the wise: save the database after using
this module the first time.

=head1 ADMINISTRATIVE METHODS

=head2 new

Creates an instance of WWW::KeePassRest, specifying your own certificate/key pair if you want.

=cut

sub new {
   my $self = bless {}, shift;
   my %opts = @_;

   croak "Must provide both cert and key file" if (defined $opts{cert_file} and not defined $opts{key_file})
                                               or (not defined $opts{cert_file} and defined $opts{key_file});
   my $cert_file = $opts{cert_file} || File::ShareDir::module_file('WWW::KeePassRest', 'wwwkprcert.pem');
   my $key_file  = $opts{key_file} || File::ShareDir::module_file('WWW::KeePassRest', 'wwwkprkey.pem');
   croak "Can't find cert file $cert_file" unless -e $cert_file;
   croak "Can't find key file $cert_file" unless -e $key_file;
   
   my $port = $opts{port} || 12984;
   
   $self->{json} = WWW::JSONAPI->new(cert_file => $cert_file,
                                     key_file  => $key_file,
                                     base_url  => "https://localhost:$port/keepass/");

   return $self;
}

=head2 ua, req, res

WWW::KeePassRest is based on WWW::JSONAPI, so it saves the request and response objects from each
call in case you want to do things to them that aren't covered by the API.

=cut

sub ua  { $_[0]->{json}->ua; }
sub res { $_[0]->{json}->res; }
sub req { $_[0]->{json}->req; }


=head1 BASIC API

The basic API functions correspond pretty closely to the API as exposed by the KeePassRest plugin, and
are essentially CRUD for the entries in the database, plus a search function.

=cut 

# -------------------
# Error handler
# -------------------

sub _error {
   my $error = shift;
   croak 'KeePass not running' if $error =~ /^500 /;
   croak 'UUID not found' if $error =~ /^404 /;
   croak $error;
}

=head2 create (group, entry)

C<create> creates an entry containing the information passed in with the entry hashref, optionally
in the group named by C<group> (this group will be created if it doesn't exist). Leave the group name
off if you just want to create an entry in the root of the database. You can also swap the positions
of the group and entry because I'm bad at remembering order and the entry can be assumed to be the hashref.

Returns 1 if the entry was created, 0 if not. Croaks with the status line from the request if KeePassRest
returns anything but a 200.

The fields with special names in the KeePass database are Title, UserName, Password, URL, and Notes; fields
with any other names will be stored perfectly well under those names, which will then appear on the Advanced
tab of the entry dialog. KeePassRest uses this method to store known client certificates, keyed by their
thumbprints.

=cut

sub create {
   my $self = shift;
   my ($group, $entry) = @_;
   ($group, $entry) = ($entry, $group) if ref($group) eq 'HASH';
   croak "Need an entry hash to create entry" unless defined $entry and ref($entry) eq 'HASH';
   
   return 1 if 'true' eq $self->{json}->json_POST_string ('entry', { Entry => $entry, defined $group ? (GroupName => $group) : ()});
   return 0;
}

=head2 get (entry)

C<get> takes the UUID of an entry (a unique identifier within the database) and returns its entry fields in
a hashref. Croaks with "UUID not found" if an unknown UUID is supplied. (This is an underlying 404 Not Found.)

C<get> is special in that it will create its own WWW::KeePassRest object if you call it as a class method.
This makes it quick to integrate simple retrieval in just a line.

If there are fields beyond the "entry" parameter, they will be used to index the hashref returned, and
the method will return a list of the named values instead of the full hashref. Again, this makes it
simpler to integrate calls to C<get> into other function calls without the need to clutter things up
with intermediate variables.  (This is obviously an extension to the vanilla KeePassRest API.)

=cut

sub get {
   my $self = shift;
   my $uuid = shift || croak 'Need UUID in get';
   
   $self = new($self) if ref($self) eq ''; # Special case: get without creating an object.
   
   my $return;
   eval { $return = $self->{json}->GET_json ("entry/$uuid"); };
   _error ($@) if $@;
   
   if (@_) {
      my @return = map { $return->{$_} } @_;
      return @return;
   }
   return $return;
}

=head2 update (uuid, entry)

Given a UUID and an entry hash, updates the entry in the database identified by the UUID with the contents
of the hashref.  Returns 1 if successful, 0 otherwise.

=cut

sub update {
   my $self = shift;
   my $uuid = shift || croak 'Need UUID and entry in update';
   my $entry = shift || croak 'Need UUID and entry in update';
   my $ret = eval { $self->{json}->json_PUT_string ("entry/$uuid", $entry); };
   _error($@) if $@;
   $ret eq 'true';
}

=head2 delete (uuid)

Given a UUID, deletes the entry in the database identified by the UUID.
Returns 1 if successful, 0 otherwise.

=cut

sub delete {
   my $self = shift;
   my $uuid = shift || croak 'Need UUID in delete';
   my $ret = eval { $self->{json}->DELETE_string ("entry/$uuid"); };
   _error($@) if $@;
   $ret eq 'true';
}

=head2 search (search_string, parameters)

Finally comes search, which is a little weird. The first parameter is always the search string; the rest of the parameters
determine where the search will be carried out. Almost all are flags which, if they appear in the parameters, will be set to 'true'.
The only exception is C<ComparisonMode>, which also specifies a number, which is assumed to follow it in the parameter list.
I don't know what this parameter actually I<does>, mind you, but from inspection of the Find dialog in the KeePass
UI, I suspect it's something to do with case-sensitivity.

The other search parameters are: C<ExcludeExpired> flag excludes entries from the
search results which have a date in the past, the C<RegularExpression> flag causes the search string to be treated as a regex,
and the SearchInGroupNames, SearchInNotes, SearchInOther, SearchInPasswords, SearchInTag, SearchInTitles, SearchInUrls,
SearchInUserNames, and SearchInUuids flags all do exactly what they say.

Returns an arrayref containing the UUIDs of the entries that match the search. To get the entries that match, use C<get_all>.

=cut

sub search {
   my $self = shift;
   my $search = {};
   $search->{SearchString} = shift || croak 'Need search string';
   
   while (@_) {
      my $flag = shift;
      if ($flag eq 'ComparisonMode') {
         $search->{$flag} = shift;
      } else {
         $search->{$flag} = 1;
      }
   }
   my $ret = eval { $self->{json}->json_POST_json ('entry/search', $search); };
   _error($@) if $@;
   $ret;
}

=head1 API SUGAR

I threw together a few convenience functions extending the API.

=head2 create_and_return (group, entry)

Works the same as C<create> except that it finds and returns the UUID for the entry just created.
(This is actually the documented behavior of the KeePassRest plug-in, but it doesn't work that way.)

=cut

sub create_and_return {
   my $self = shift;
   my ($group, $entry) = @_;
   ($group, $entry) = ($entry, $group) if ref($group) eq 'HASH';
   croak "Need an entry hash to create entry" unless defined $entry and ref($entry) eq 'HASH';

   my $existing = eval { $self->search($entry->{Title}, 'SearchInTitles'); };
   croak $@ if $@;
   return unless $self->create($group, $entry);
   my $now = $self->search($entry->{Title}, 'SearchInTitles');
   foreach my $check (@$now) {
      return $check unless grep { $_ eq $check } @$existing;
   }
   return;
}

=head2 get_all (search_string, parameters)

Takes the same parameters as the C<search> method above, but instead of returning UUIDs, it
retrieves all the entries in question for you. Returns a hashref of the entries, keyed by the UUID.

=cut

sub get_all {
   my $self = shift;
   my $list = eval { $self->search (@_); };
   croak $@ if $@;
   
   my %returns;
   foreach my $uuid (@$list) {
       $returns{$uuid} = $self->get($uuid);
   }
   return \%returns;
}

=head2 get_by_title, get_by_url

Two quickie search-and-retrieve functions that do what you think. If your title or URL matches
more than one entry, a random one is returned (not really random - whatever comes up first in
the search, probably by date of entry or something).

These do the same trick as C<get> allowing them to be called as class methods.

=cut

sub get_by_title {
   my $self = shift;
   my $title = shift;
   $self = new($self) if ref($self) eq '';
   my $list = eval { $self->search ($title, 'SearchInTitles'); };
   croak $@ if $@;
   return $self->get($list->[0], @_);
}
sub get_by_url {
   my $self = shift;
   my $url = shift;
   $self = new($self) if ref($self) eq '';
   my $list = eval { $self->search ($url, 'SearchInUrls'); };
   croak $@ if $@;
   return $self->get($list->[0], @_);
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-keepassrest at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-KeePassRest>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::KeePassRest


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-KeePassRest>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-KeePassRest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-KeePassRest>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-KeePassRest/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WWW::KeePassRest
