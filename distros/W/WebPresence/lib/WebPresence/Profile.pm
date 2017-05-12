package WebPresence::Profile;

use strict;
use Carp;

our $VERSION = '1.0';

our $AUTOLOAD;

sub new {
    my $pkg = shift or return undef;
    my $obj = {};
    while (@_) {
        my $k = shift;
	if (@_) {
	    my $v = shift;
	    $obj->{$k} = $v;
	}
	else {
	    $obj->{$k} = undef;
	}
    }
    bless $obj, ref $pkg || $pkg;
    $obj->SetInfo($obj->{user}) if $obj->{'user'};
    return $obj;
}

sub SetInfo {
    my $obj = shift;
    my $user = shift;
    $obj->{profile}->{user} = $user;
}

sub Get {
    my $obj = shift;
    my $prop = shift;
    return $obj->{profile}->{$prop};
}

sub Set {
    my $obj = shift;
    my $prop = shift;
    my $val = shift;
    my $oldval = $obj->{profile}->{$prop};
    $obj->{profile}->{$prop} = $val;
    return $oldval || '0E0';
}

sub AUTOLOAD {
    my $obj = shift;
    my $type = ref $obj or croak "$obj is not an object.";
    my $prop = $AUTOLOAD;
    if (@_) {
        return $obj->Set($prop, shift);
    }
    else {
        return $obj->Get($prop);
    }
}

1;

__END__

=head1 NAME

Model3D::WavefrontObject - Perl extension for reading, manipulating and writing polygonal Alias Wavefront 3D models

WebPresence::Profile - Perl extension for retrieving arbitrary user profile
or other similar data. This is a base class and is essentially useless on its
own. The individual subclasses should be called, instead.

=head1 SYNOPSIS

    my $wp = new WebPresence::Profile::SomeSubclass(user => $id);
    for my $k (keys %{$wp->{profile}}) {
        if (ref $wp->{profile}->{$k} eq 'ARRAY') {
	    print "$k: ", join(', ', @{$wp->{profile}->{$k}), "\n";
        }
        else {
            print $k: $wp->{profile}->{$k}\n";
        }
    }

=head1 DESCRIPTION

WebPresence::Profile is a base class intended for retriving user profile
data from various sources no the web. This can be used to prefill profile
data on your own site or for data collation and data mining purposes.

WebPresence::Profile does almost nothing on its own (it sets the 'user'
key to whatever you passed in and that's it). However, it sets up basic
access and constructor methods for subclasses which are intended to work
as plugins.

Instead, use WebPresence::Profile::X where X is a defined 'plugin'
module that inherits from WebPresence::Profile.

=head1 METHODS

=head2 Constructor

    new()

The C<new()> method returns a new WebPresence::Profile::X object where X
is the subclass called (for instance, ICQ, LJ, Tribe, etc). If the
subclass X has defined and thus overriden the SetInfo() method, and if
said method works (in exactly the way it doesn't in the intended AOL module),
then it will return a hashref containing key-value pairs referring to
delectable tidbits from that user's profile -- in theory, anything relevant
and useful and distinct to the user, but in reality whatever the coder of
module X has bothered to parse for.

At the very least you'll need to pass new() a user ID. It's recommended that
developers of module X (still whatever that may be) remain consistent in
their handling of this name for compatibility's sake, and call it 'user',
as this is the bit of data the constructor is going to pass to the SetInfo()
method. However, if what you're retriving requires additional data and 'user'
doesn't make sense, you can always override new(), too, I guess. Just try
not to get too confusing and keep the interface nice and standardised. Thanks.

In some cases Module X (whatever it may be) will require additional
parametres to be passed in. For instance, the LJ (LiveJournal) module would
like you to pass in a 'wp_admin_email' parametre, and wouldn't mind if you
sent it a 'wp_user_agent' parametre. See below for why.

=head2 Public Access Methods

=head4 Get(profile_key)

Use the C<Get()> method to retrieve a named profile property that the
subclass parses for.

=head4 Set(profile_key, new_value)

Use the C<Set()> method to set a names profile property that the subclass
parses for.

=head4 AUTOLOADed methods by profile property name

You should be able to call any profile property by its right name as a
method and retieve that value just like calling C<Get()>. Additionally, if
you supply a value the property will be set to that, just like calling
C<Set()>.

=head2 Sort-of Private Methods, and making plugins

Each subclass X should have at the very least a method called C<SetInfo(user)>.
The purpose of this method is to retrieve and set the info. This may be done
in tons of different ways. In general, LWP is expected to be used, though
if you're grabbing information frmo a tn3270 screen, it might not.

Any which way, this method, C<SetInfo(user)> is where the screen-scraping magick
should generally happen. This method should return undef on fail, but it
doesn't really care. Extremely friendly programmers will set some sort of
error or errstr property in the object that calls the method, and I've been
friendly in one case anyway.

=head2 Included subclasses and nasty things to say about them

The included subclasses all have a chance of returning multiple values for one
key. When this is the case, the value will be an arrayref. However, multiple
instances of a single value will not be included, so if the value contains ten
of the same thing, only a scalar will be stored (of that one thing).

Because of this, multi-value key values will not come out in any particular
order, as they are being filtered through a hash to remove duplicates.

=head3 AOL:

Doesn't work. Don't bother with it. The code is all there and SHOULD
work it seems, but it just doesn't. If it worked, you'd have to pass it a valid
AOL or AIM screen name and password to access the info. Maybe someday it will
work, but not today. I give up for now.

=head3 ICQ:

All you need to pass in is the ICQ UIN as user to the constructor. Schweet,
huh? It's up to the user how much data they have made available online.

=head3 Yahoo:

Again, just pass in the Yahoo ID as the user to the constructor to get Yahoo
user profile info. It's up to the user how much stuff they have in here (and
most Yahoo users have woefully little I've noticed).

=head3 Tribe

Pass in a tribe.net username and get back their Tribe.net profile info,
complete with a list of tribes they belong to that was unusually a pain in the
butt to parse out, but I did it somehow.

Usernames with a - or _ in them are homogenised to the version the module needs
to get the data back, but you won't see this.

=head3 LJ

Pass in a LiveJournal username and get back their full LJ user info. LiveJournal
is nice about this sort of thing compared to many sites and acknowledges that
people would want to do this. They prefer that you use their RSS feeds, but this
doesn't because the data's not all there (and they stated it as a preference,
not a hard and fast rule). The two rules they do insist on are:

  1: Send a UserAgent string with your email and, if applicable, URL.
  2: Cache, where possible.

Number two is up to you. As for number 1, you're strongly encouraged to pass
in a 'wp_admin_email' property to the constructor method, as it will use this
to set your email address in the useragent string. If you don't, the script will
try to guess by using your apache SERVER_ADMIN email, or sticking your LOGNAME
or USER together with the results of `dnsdomainname` or `hostname`. This has a
mild chance of being right, but may tell their logs things you don't want to
know, so set it.

Optionally, you can just pass in a 'wp_user_agent' parametre and set the
UserAgent to whatever you like. If you don't, it should come out well formed
sort of like so:

    your.script (URL-to-your-script-or-just-name-if-not-CGI; email:your_email) WebPresence/1.0 LWP/lwp-version Perl/perl-version CGI/cgi-version

(the CGI part on the end will only appear when called from a browser unless you set the GATEWAY_INTERFACE environment variable yourself).

=head2

How to roll your own extension:

In simplest form, you want to do something like so:

package WebPresence::Profile::X; # Don't use X. Use something that makes sense.
use WebPresence::Profile;
@ISA = ('WebPresence::Profile');

use strict;

sub SetInfo {
    my $obj = shift;
    my $user = shift;

    # fetch the data from somewhere
    # Parse the data as necessary

}

1;

=head1 AUTHOR

Sean 'Dodger' Cannon  qbqtre@ksk3q.arg =~ tr/a-mn-z/n-za-m/
L<http://www.xfx3d.net>

=head1 BUGS

=over

=item * AOL profile retrival doesn't work.

=item * Author consideres this AOL's fault

=item * Author has many rude names for AOL

=item * Most other people do, too

=back

=head1 GOOD INTENTIONS

=over

=item * Make AOL work

=item * Make more subclasses, like MySpace and DevArt and things

=item * Realise that this thing works for all sorts of things other than profiles and ajust thoughts accordingly.

=item * Do more work on the Model3D::WavefrontObject module

=item * Feed the cat, cause she's yelling at me again

=back

=head1 SEE ALSO

perl(1)

=cut

