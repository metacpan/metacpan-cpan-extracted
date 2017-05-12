package WWW::Mediawiki::Client;

use warnings;
use strict;
use File::Spec;
use File::Find;
use LWP::UserAgent;
use HTML::TokeParser;
use HTTP::Request;
use HTTP::Request::Common;
use HTTP::Cookies;
use URI::Escape;
use VCS::Lite;
use Data::Dumper;
use WWW::Mediawiki::Client::Exceptions;
use XML::LibXML ();
use HTML::Entities qw(encode_entities);
use File::Temp ();
use Encode;
use Encode::Guess;
use utf8;

BEGIN {
    # If we tell LWP it's dealing with UTF-8 then URI::Escape will munge the text
    # So either we put up with warnings or do this:
    for (0x100 .. 0xd7ff, 0xf000 .. 0xfdcf) {
        $URI::Escape::escapes{chr($_)} =
        &URI::Escape::uri_escape_utf8(chr($_));
    }
}

use base 'Exporter';
our %EXPORT_TAGS = (
	options => [qw(OPT_YES OPT_NO OPT_DEFAULT OPT_KEEP)],
);
our @EXPORT_OK = map { @{$EXPORT_TAGS{$_}} } keys %EXPORT_TAGS;

=head1 NAME

WWW::Mediawiki::Client

=cut

=head1 SYNOPSIS
  
  use WWW::Mediawiki::Client;

  my $filename = 'Subject.wiki';
  my $mvs = WWW::Mediawiki::Client->new(
      host => 'www.wikitravel.org'
  );

  # like cvs update
  $mvs->do_update($filename);

  # like cvs commit
  $mvs->do_commit($filename, $message);

  #aliases
  $mvs->do_up($filename);
  $mvs->do_com($filename, $message);

=cut

=head1 DESCRIPTION

WWW::Mediawiki::Client provides a very simple cvs-like interface for
Mediawiki driven WikiWiki websites, such as
L<http://www.wikitravel.org|Wikitravel> or
L<http://www.wikipedia.org|Wikipedia.>  
The interface mimics the two most basic cvs commands: update and commit
with similarly named methods.  Each of these has a shorter alias, as in
cvs.  

=cut

=head1 CONSTANTS

=cut

use constant ACTION => 'action';

use constant TITLE => 'title';

use constant SUBMIT => 'submit';

use constant LOGIN => 'submitlogin';

use constant LOGIN_TITLE => 'Special:Userlogin';

use constant EDIT => 'edit';

# defaults for various known Mediawiki installations
my %DEFAULTS;

$DEFAULTS{'www.wikitravel.org'} =
    {
        'host'              => 'wikitravel.org',
        'protocol'          => 'http',
        'space_substitute'  => '_',
        'wiki_path'         => 'wiki/__LANG__/index.php',
    };
$DEFAULTS{'wikitravel.org'} = $DEFAULTS{'www.wikitravel.org'};

$DEFAULTS{'www.wikipedia.org'} =
    {
        'host'              => '__LANG__.wikipedia.org',
        'protocol'          => 'http',
        'space_substitute'  => '+',
        'wiki_path'         => 'w/wiki.phtml',
    };
$DEFAULTS{'wikipedia.org'} = $DEFAULTS{'www.wikipedia.org'};

$DEFAULTS{'www.wiktionary.org'} = 
    {
        'host'              => '__LANG__.wiktionary.org',
        'protocol'          => 'http',
        'space_substitute'  => '_',
        'wiki_path'         => 'w/wiki.phtml',
    };
$DEFAULTS{'wiktionary.org'} = $DEFAULTS{'www.wiktionary.org'};

$DEFAULTS{'www.wikibooks.org'} = 
    {
        'host'              => '__LANG__.wikibooks.org',
        'protocol'          => 'http',
        'space_substitute'  => '_',
        'wiki_path'         => 'w/wiki.phtml',
    };
$DEFAULTS{'wikibooks.org'} = $DEFAULTS{'www.wikibooks.org'};

sub DEFAULTS { \%DEFAULTS };

use constant SPACE_SUBSTITUTE => '_';
use constant WIKI_PATH => 'wiki/index.php';
use constant LANGUAGE_CODE => 'en';
use constant PROTOCOL => 'http';

use constant SPECIAL_EXPORT => 'Special:Export';
use constant SPECIAL_VERSION => 'Special:Version';


=head3 $VERSION 

=cut 

our $VERSION = 0.31;

=head2 Update Status

=head3 STATUS_UNKNOWN

Indicates that C<WWW::Mediawiki::Client> has no information about the file.

=head3 STATUS_UNCHANGED

Indicates that niether the file nor the server page have changed.

=head3 STATUS_LOCAL_ADDED

Indicates that the file is new locally, and does not exist on the server.

=head3 STATUS_LOCAL_MODIFIED

Indicates that the file has been modified locally.

=head3 STATUS_SERVER_MODIFIED

Indicates that the server page was modified, and that the modifications
have been successfully merged into the local file.

=head3 STATUS_CONFLICT

Indicates that there are conflicts in the local file resulting from a
failed merge between the server page and the local file.

=cut

use constant STATUS_UNKNOWN         => '?';
use constant STATUS_UNCHANGED       => '=';
use constant STATUS_LOCAL_ADDED     => 'A';
use constant STATUS_LOCAL_MODIFIED  => 'M';
use constant STATUS_SERVER_MODIFIED => 'U';
use constant STATUS_CONFLICT        => 'C';

=head2 Option Settings

=head3 OPT_YES

Indicates that the setting should always be applied.

=head3 OPT_NO

Indicates that the setting should never be applied.

=head3 OPT_DEFAULT

Indicates that the setting should be applied based on the user profile
default on the Wikimedia server.

=head3 OPT_KEEP

Four-state options only.  Indicates that the setting should not be
changed from its current value on the server.

=cut

# Option values:
use constant OPT_YES     =>  1;
use constant OPT_NO      =>  0;
use constant OPT_DEFAULT => -1;
use constant OPT_KEEP    => -2; # Only for watch.

# Reverse lookup:
use constant OPTION_SETTINGS => (
	OPT_YES,     'OPT_YES', 
	OPT_NO,      'OPT_NO', 
	OPT_DEFAULT, 'OPT_DEFAULT',
	OPT_KEEP,    'OPT_KEEP',
);

# Option defaults:
use constant MINOR_DEFAULT => OPT_DEFAULT;
use constant WATCH_DEFAULT => OPT_DEFAULT;

=head2 Mediawiki form widgets

=head3 TEXTAREA_NAME

=head3 COMMENT_NAME

=head3 EDIT_SUBMIT_NAME

=head3 EDIT_SUBMIT_VALUE

=head3 EDIT_PREVIEW_NAME

=head3 EDIT_PREVIEW_VALUE

=head3 EDIT_TIME_NAME

=head3 EDIT_TOKEN_NAME

=head3 EDIT_WATCH_NAME

=head3 EDIT_MINOR_NAME

=head3 CHECKED

=head3 UNCHECKED

=head3 USERNAME_NAME

=head3 PASSWORD_NAME

=head3 REMEMBER_NAME

=head3 LOGIN_SUBMIT_NAME

=head3 LOGIN_SUBMIT_VALUE

=cut

use constant TEXTAREA_NAME      => 'wpTextbox1';
use constant COMMENT_NAME       => 'wpSummary';
use constant EDIT_SUBMIT_NAME   => 'wpSave';
use constant EDIT_SUBMIT_VALUE  => 'Save Page';
use constant EDIT_PREVIEW_NAME  => 'wpPreview';
use constant EDIT_PREVIEW_VALUE => 'Show preview';
use constant EDIT_TIME_NAME     => 'wpEdittime';
use constant EDIT_TOKEN_NAME    => 'wpEditToken';
use constant EDIT_WATCH_NAME    => 'wpWatchthis';
use constant EDIT_MINOR_NAME    => 'wpMinoredit';
use constant CHECKED            => 1;
use constant UNCHECKED          => 0;
use constant USERNAME_NAME      => 'wpName';
use constant PASSWORD_NAME      => 'wpPassword';
use constant REMEMBER_NAME      => 'wpRemember';
use constant LOGIN_SUBMIT_NAME  => 'wpLoginattempt';
use constant LOGIN_SUBMIT_VALUE => 'Log In';

=head2 Files

=head3 CONFIG_FILE

  .mediawiki

=head3 COOKIE_FILE

  .mediawiki.cookies

=head3 SAVED_ATTRIBUTES

Controls which attributes get saved out to the config file.

=cut

use constant CONFIG_FILE => '.mediawiki';
use constant COOKIE_FILE => '.mediawiki_cookies.dat';
use constant SAVED_ATTRIBUTES => (
    qw(site_url host protocol language_code space_substitute username
       password wiki_path watch encoding minor_edit escape_filenames)
);  # It's important that host goes first since it has side effects


=head1 CONSTRUCTORS

=cut

=head2 new

  my $mvs = WWW::Mediawiki::Client->new(host = 'www.wikitravel.org');

Accepts name-value pairs which will be used as initial values for any of
the fields which have accessors below.  Throws the same execptions as the
accessor for any field named.

=cut

sub new {
    my $pkg = shift;
    my %init = @_;
    my $self = bless {};
    $self->load_state;
    foreach my $attr (SAVED_ATTRIBUTES) {
        next unless $init{$attr};
        $self->$attr($init{$attr});
    }
    $self->{ua} = LWP::UserAgent->new();
    push @{ $self->{ua}->requests_redirectable }, 'POST';
    my $agent = 'WWW::Mediawiki::Client/' . $VERSION;
    $self->{ua}->agent($agent);
    $self->{ua}->env_proxy;
    my $cookie_jar = HTTP::Cookies->new(
        file => COOKIE_FILE,
        autosave => 1,
    );
    $self->{ua}->cookie_jar($cookie_jar);
    return $self;
}

=head1 ACCESSORS

=cut

=head2 host

  my $url = $mvs->host('www.wikipediea.org');

  my $url = $mvs->host('www.wikitravel.org');

The C<host> is the name of the Mediawiki server from which you want to
obtain content, and to which your submissions will be made.  There is no
default.  This has to be set before attempting to use any of the methods
which attempt to access the server.

B<Side Effects:>

=over 4

=item Server defaults

If WWW::Mediawiki::Client knows about the path settings for the Mediawiki
installation you are trying to use then the various path fields will also
be set as a side-effect.

=item Trailing slashes

Any trailing slashes are deleted I<before> the value of C<host> is set.

=back

=cut

sub host {
    my ($self, $host) = @_;
    if ($host) {
        $host =~ s{/*$}{}; # remove any trailing /s
        $self->{host} = $host;
        my $defaults = $DEFAULTS{$host};
        foreach my $k (keys %$defaults) {
            $self->{$k} = $defaults->{$k};
        }
    }
    return $self->{host};
}

=head2 protocol

  my $url = $mvs->protocol('www.wikipediea.org');

  my $url = $mvs->protocol('www.wikitravel.org');

The C<protocol> is the protocol used by the Mediawiki server from which you
want to obtain content, and to which your submissions will be made.  It can
be one of C<http> or C<https> with the default value being http.

B<Side Effects:>

=over 4

=item Server defaults

If WWW::Mediawiki::Client knows about the settings for the Mediawiki
installation you are trying to use then the various path fields will also
be set as a side-effect.

=back

=cut

sub protocol {
    my ($self, $protocol) = @_;
    if ($protocol) {
        WWW::Mediawiki::Client::URLConstructionException->throw(
                "The protocol must be either 'http' or 'https'."
                . "You specified $protocol." )
            unless $protocol =~ m/^http(s){0,1}$/;
        $self->{protocol} = $protocol;
    } 
    return $self->{protocol} || PROTOCOL;
}

=head2 language_code

  my $lang = $mvs->language_code($lang);

Most Mediawiki projects have multiple language versions.  This field can be
set to target a particular language version of the project the client is
set up to address.  When the C<filename_to_url> and C<pagename_to_url> methods
encounter the text '__LANG__' in any part of their constructed URL the
C<language_code> will be substituted.

C<language_code> defaults to 'en'.

=cut

sub language_code {
    my ($self, $char) = @_;
    $self->{language_code} = $char if $char;
    $self->{language_code} = LANGUAGE_CODE 
            unless $self->{language_code};
    return $self->{language_code};
}

=head2 space_substitute

  my $char = $mvs->space_substitute($char);

Mediawiki allows article names to have spaces, for instance the default
Meidawiki main page is called "Main Page".  The spaces need to be converted
for the URL, and to avoid the normal but somewhat difficult to read URL
escape the Mediawiki software substitutes some other character.  Wikipedia
uses a '+', as in "Main+Page" and Wikitravel uses a '_' as in "Main_page".
WWW::Mediawiki::Client always writes wiki files using the '_', but converts
them to whatever the C<space_substitute> is set to for the URL.

B<Throws:>

=over

=item WWW::Mediawiki::Client::URLConstructionException

=back

=cut

sub space_substitute {
    my ($self, $char) = @_;
    if ($char) {
        WWW::Mediawiki::Client::URLConstructionException->throw(
                "Illegal Character in space_substitute $char" )
            if $char =~ /[\&\?\=\\\/]/;
        $self->{space_substitute} = $char;
    }
    $self->{space_substitute} = SPACE_SUBSTITUTE 
            unless $self->{space_substitute};
    return $self->{space_substitute};
}

=head2 escape_filenames

  my $char = $mvs->escape_filenames($do_escape);

Mediawiki allows article names to be in UTF-8 and most international
Wikipedias use this feature. That leads us to UTF-8 encoded file names
and not all filesystems can handle them. So you can set this option to
some true value to make all your local file names with wiki articles
URL-escaped.

=cut

sub escape_filenames {
    my ($self, $do_escape) = @_;
    if ($do_escape) {
        $self->{escape_filenames} = $do_escape;
    } elsif (!defined $self->{escape_filenames}) {
        $self->{escape_filenames} = 0;
    }

    return $self->{escape_filenames};
}

=head2 wiki_path

  my $path = $mvs->wiki_path($path);

C<wiki_path> is the path to the php page which handles all request to
edit or submit a page, or to login.  If you are using a Mediawiki site
which WWW::Mediawiki::Client knows about this will be set for you when you
set the C<host>.  Otherwise it defaults to the 'wiki/wiki.phtml' which is
what you'll get if you follow the installation instructions that some with
Mediawiki.

B<Side effects>

=over

=item Leading slashes

Leading slashes in any incoming value will be stripped.

=back

=cut

sub wiki_path {
    my ($self, $wiki_path) = @_;
    if ($wiki_path) {
        $wiki_path =~ s{^/*}{}; # strip leading slashes
        $self->{wiki_path} = $wiki_path;
    }
    $self->{wiki_path} = WIKI_PATH 
            unless $self->{wiki_path};
    return $self->{wiki_path};
}

=head2 encoding

  my $encoding = $mvs->encoding($encoding);

C<encoding> is the charset in which the Mediawiki server expects uploaded
content to be encoded.  This should be set the first time you use do_login.

=cut

sub encoding {
    my ($self, $encoding) = @_;
    $self->{encoding} = $encoding if $encoding;
    return $self->{encoding};
}

=head2 username

  my $url = $mvs->username($url);

The username to use if WWW::Mediawiki::Client is to log in to the Mediawiki server as a given
user.

=cut

sub username {
    my ($self, $username) = @_;
    $self->{username} = $username if $username;
    return $self->{username};
}

=head2 password

  my $url = $mvs->password($url);

The password to use if WWW::Mediawiki::Client is to log in to the Mediawiki server as a given
user.  Note that this password is sent I<en clair>, so it's probably not a
good idea to use an important one.

=cut

sub password {
    my ($self, $password) = @_;
    $self->{password} = $password if $password;
    return $self->{password};
}

=head2 commit_message

  my $msg = $mvs->commit_message($msg);

A C<commit_message> must be specified before C<do_commit> can be run.  This
will be used as the comment when submitting pages to the Mediawiki server.

=cut

sub commit_message {
    my ($self, $msg) = @_;
    $self->{commit_message} = $msg if $msg;
    return $self->{commit_message};
}

=head2 watch

  my $watch = $mvs->watch($watch);

Mediawiki allows users to add a page to thier watchlist at submit time
using using the "Watch this page" checkbox.  The field C<watch> allows
commits from this library to add or remove the page in question to/from
your watchlist.

This is a four-state option:

=over

=item C<OPT_YES>

Always add pages to the watchlist.

=item C<OPT_NO>

Remove pages from the watchlist.

=item C<OPT_KEEP>

Maintain current watched state.

=item C<OPT_DEFAULT> (default)

Adhere to user profile default on the server.  Watched pages will
always remain watched, and all other pages will be watched if the
"watch all pages by default" option is enabled in the user profile.

=back

B<Throws:>

=over

=item WWW::Mediawiki::Client::InvalidOptionException

=back

=cut

sub watch {
    my ($self, $watch) = @_;
    if (defined($watch)) {
	$self->_option_verify('watch', $watch, 
		[OPT_YES, OPT_NO, OPT_KEEP, OPT_DEFAULT]);
	$self->{watch} = $watch;
    }
    $self->{watch} = WATCH_DEFAULT unless defined $self->{watch};
    return $self->{watch};
}

=head2 minor_edit

  my $minor = $mvs->minor_edit($minor);

Mediawiki allows users to mark some of their edits as minor using the "This
is a minor edit" checkbox.  The field C<minor_edit> allows a commit from
the mediawiki client to be marked as a minor edit.

This is a three-state option:

=over

=item C<OPT_YES>

Always declare change as minor.

=item C<OPT_NO>

Never declare change as minor.

=item C<OPT_DEFAULT> (default)

Adhere to user profile default on the server.  Edits will be marked
as minor if the "minor changes by default" option is enabled in the
user profile.

=back

B<Throws:>

=over

=item WWW::Mediawiki::Client::InvalidOptionException

=back

=cut

sub minor_edit {
    my ($self, $minor) = @_;
    if (defined($minor)) {
	$self->_option_verify('minor_edit', $minor, 
		[OPT_YES, OPT_NO, OPT_DEFAULT]);
	$self->{minor_edit} = $minor;
    }
    $self->{minor_edit} = MINOR_DEFAULT unless defined $self->{minor_edit};
    return $self->{minor_edit};
}

=head2 status

  my %status = $mvs->status;

This field will be empty until do_update has been called, after which it
will be set to a hash of C<filename> => C<status> pairs.  Each C<status> 
will be one of the following (see CONSTANTS for discriptions):

=item WWW::Mediawiki::Client::STATUS_UNKNOWN;

=item WWW::Mediawiki::Client::STATUS_UNCHANGED;

=item WWW::Mediawiki::Client::STATUS_LOCAL_ADDED;

=item WWW::Mediawiki::Client::STATUS_LOCAL_MODIFIED;

=item WWW::Mediawiki::Client::STATUS_SERVER_MODIFIED;

=item WWW::Mediawiki::Client::STATUS_CONFLICT;

=cut

sub status {
    my ($self, $arg) = @_;
    WWW::Mediawiki::Client::ReadOnlyFieldException->throw(
            "Tried to set read-only field 'status' to $arg.") if $arg;
    return unless defined($self->{status});
    return $self->{status};
}

=head2 site_url DEPRICATED

  my $url = $mvs->site_url($url);

The site URL is the base url for reaching the Mediawiki server who's
content you wish to edit.  This field is now depricated in favor of the
C<host> field which is basically the same thing without the protocol
string.


B<Side Effects:>

=over 4

=item Server defaults

If WWW::Mediawiki::Client knows about the path settings for the Mediawiki
installation you are trying to use then the various path fields will also
be set as a side-effect.

=item Trailing slashes

Any trailing slashes are deleted I<before> the value of C<site_url> is set.

=back

=cut

sub site_url {
    my ($self, $host) = @_;
    my ($pkg, $caller, $line) = caller;
    warn "Using depricated method 'site_url' at $caller line $line."
            unless $pkg =~ "WWW::Mediawiki::Client";
    my $protocol = $self->protocol;
    $host =~ s{^$protocol://}{} if $host;
    $host = $self->host($host);
    return "$protocol://" . $host if $host;
}

=head1 Instance Methods

=cut

=head2 do_login

  $mvs->do_login;

The C<do_login> method operates like the cvs login command.  The
C<host>, C<username>, and C<password> attributes must be set before
attempting to login.  Once C<do_login> has been called successfully any
successful commit from the same directory will be logged in the Mediawiki
server as having been done by C<username>.

B<Throws:>

=over

=item WWW::Mediawiki::Client::AuthException

=item WWW::Mediawiki::Client::CookieJarException

=item WWW::Mediawiki::Client::LoginException

=item WWW::Mediawiki::Client::URLConstructionException

=back

=cut

sub do_login {
    my $self = shift;
    WWW::Mediawiki::Client::URLConstructionException->throw(
            "No Mediawiki host specified.")
            unless $self->host;
    WWW::Mediawiki::Client::URLConstructionException->throw(
            "No wiki_path specified.")
            unless $self->wiki_path;
    WWW::Mediawiki::Client::AuthException->throw(
        "Must have username and password to login.")
            unless $self->username && $self->password;
    my $host = $self->host;
    my $path = $self->wiki_path;
    my $lang = $self->language_code;
    $host =~ s/__LANG__/$lang/;
    $path =~ s/__LANG__/$lang/;
    my $protocol = $self->protocol;
    my $url = "$protocol://$host/$path"
            . "?" . ACTION . "=" . LOGIN
            . "&" . TITLE  . "=" . LOGIN_TITLE;
    $self->{ua}->cookie_jar->clear;
    $self->{ua}->cookie_jar->save
            or WWW::Mediawiki::Client::CookieJarException->throw(
            "Could not save cookie jar.");
    my $res = $self->{ua}->request(POST $url,
        [ 
            &USERNAME_NAME      => $self->username,
            &PASSWORD_NAME      => $self->password,
            &REMEMBER_NAME      => 1,
            &LOGIN_SUBMIT_NAME  => &LOGIN_SUBMIT_VALUE,
        ]
    );
    # success == Mediawiki gave us a Password cookie
    if ($self->{ua}->cookie_jar->as_string =~ /UserID=/) {
        $self->encoding($self->_get_server_encoding);
        $self->save_state;
        $self->{ua}->cookie_jar->save
                or WWW::Mediawiki::Client::CookieJarException->throw(
                "Could not save cookie jar.");
        return $self;
    } elsif ($res->is_success) {  # got a page, but not what we wanted
        WWW::Mediawiki::Client::LoginException->throw(
                error => "Login did not work, please check username and password.\n",
                res => $res,
                cookie_jar => $self->{ua}->cookie_jar,
            );
    } else { # something else went wrong, send all the data in exception
        my $err = "Login to $url failed.";
        WWW::Mediawiki::Client::LoginException->throw(
                error => $err, 
                res => $res,
                cookie_jar => $self->{ua}->cookie_jar,
            );
    }
}

=head2 do_li
  
  $mvs->do_li;

An alias for C<do_login>.

=cut

sub do_li {
    do_login(@_);
}

=head2 do_update
  
  $self->do_update($filename, ...);

The C<do_update> method operates like a much-simplified version of the cvs
update command.  The argument is a list of filenames, whose contents will
be compared to the version on the WikiMedia server and to a locally stored
reference copy.  Lines which have changed only in the server version will
be merged into the local version, while lines which have changed in both
the server and local version will be flagged as possible conflicts, and
marked as such, somewhate in the manner of cvs (actually this syntax comes
from the default conflict behavior of VCS::Lite):

  ********************Start of conflict 1  Insert to Primary, Insert to Secondary ************************************************************

  The line as it appears on the server

  ****************************************************************************************************

  The line as it appears locally
  ********************End of conflict 1********************************************************************************

After the merging, and conflict marking is complete the server version will
be copied into the reference version.

If either the reference version or the local version are empty, or if
either file does not exist they will both be created as a copy of the
current server version.

B<Throws:>

=over

=item WWW::Mediawiki::Client::URLConstructionException

=item WWW::Mediawiki::Client::FileAccessException

=item WWW::Mediawiki::Client::FileTypeException

=item WWW::Mediawiki::Client::ServerPageException

=item WWW::Mediawiki::Client::AbsoluteFileNameException

=back

=cut

sub do_update {
	my ($self, @files) = @_;
        @files = $self->list_wiki_files unless @files;
	WWW::Mediawiki::Client::URLConstructionException->throw(
		"No server URL specified.") unless $self->{host};
	my %pages;
	my %dirs;
	foreach my $filename (@files) {
		my ($vol, $dirs, $fn) = $self->_check_path($filename);
		my $pagename = $self->filename_to_pagename($filename);
		$pages{$filename} = $pagename;
		$dirs{$filename}  = $dirs;
	}
	$self->_get_exported_pages(values %pages);
	foreach my $filename (@files) {
		my $pagename = $pages{$filename};
		my $dirs     = $dirs{$filename};
		my $status = $self->_update_core($filename, $pagename, $dirs);
		$self->{status}->{$filename} = $status;
	}
        return $self->status;
}

sub _update_core {
    my ($self, $filename, $pagename, $dirs) = @_;
    my $sv = $self->get_server_page($pagename);
    my $lv = $self->get_local_page($filename);
    my $rv = $self->_get_reference_page($filename);
    my $nv = $self->_merge($filename, $rv, $sv, $lv);
    my $status = $self->_get_update_status($rv, $sv, $lv, $nv);
    return unless $status;  # nothing changes, nothing to do
    return $status
            if $status eq STATUS_LOCAL_ADDED
                or $status eq STATUS_UNKNOWN
                or $status eq STATUS_UNCHANGED;
    # save the newly retrieved and/or merged version as our local copy
    my @dirs = split '/', $dirs;
    for my $d (@dirs) {
        mkdir $d;
        chdir $d;
    }
    for (@dirs) {
        chdir '..';
    }
    open OUT, ">:utf8", $filename or WWW::Mediawiki::Client::FileAccessException->throw(
            "Cannot open $filename for writing.");
    print OUT $nv;
    # save the server version out as the reference file
    $filename = $self->_get_ref_filename($filename);
    open OUT, ">:utf8", $filename or WWW::Mediawiki::Client::FileAccessException->throw(
            "Cannot open $filename for writing.");
    print OUT $sv;
    close OUT;
    return $status;
}

=head2 do_up

An alias for C<do_update>.

=cut

sub do_up {
    do_update(@_);
}

=head2 do_commit
  
  $self->do_commit($filename);

As with C<do_update> the C<do_commit> method operates like a much
simplified version of the cvs commit command.  Again, the argument is a
filename.  In keeping with the operation of cvs, C<do_commit> does not
automatically do an update, but does check the server version against the
local reference copy, throwing an error if the server version has changed,
thus forcing the user to do an update.  A different error is thrown if the
conflict pattern sometimes created by C<do_update> is found.

After the error checking is done the local copy is submitted to the server,
and, if all goes well, copied to the local reference version.

B<Throws:>

=over

=item WWW::Mediawiki::Client::CommitMessageException

=item WWW::Mediawiki::Client::ConflictsPresentException

=item WWW::Mediawiki::Client::FileAccessException

=item WWW::Mediawiki::Client::FileTypeException

=item WWW::Mediawiki::Client::URLConstructionException

=item WWW::Mediawiki::Client::UpdateNeededException

=item WWW::Mediawiki::Client::InvalidOptionException

=back

=cut

sub do_commit {
    my ($self, $filename) = @_;
    WWW::Mediawiki::Client::CommitMessageException->throw(
            "No commit message specified")
        unless $self->{commit_message};
    # Perform the actual upload:
    my ($res, $text) = $self->_upload_file($filename, 1);
    # save the local version as the reference version
    my $refname = $self->_get_ref_filename($filename);
    open OUT, ">:utf8", $refname 
            or WWW::Mediawiki::Client::FileAccessException->throw(
            "Cannot open $refname for writing.");
    print OUT $text;
    close OUT;
}

=head2 do_com

This is an alias for C<do_commit>.

=cut

sub do_com {
    do_commit(@_);
}

=head2 do_preview
  
  $self->do_preview($filename);

The C<do_preview> method is a non-writing version of the C<do_commit>
method.  It uploads the given filename to test its formatting.  Its
behaviour and arguments are identical to C<do_commit>.

The behaviour of C<do_preview> is currently based on the environment.
If C<MVS_BROWSER> is set, this program (typically a web browser) will
be launched on a temporary file.  Otherwise, the preview will be saved
to the file specified by the C<MVS_PREVIEW> variable, or preview.html
if this is unset.  This behaviour is considered a prototype for future
functionality, and is C<subject to change> in the near future.

Returns the name of the preview file, or undef if the file was sent to
a web browser.

B<Throws:>

=over

=item WWW::Mediawiki::Client::ConflictsPresentException

=item WWW::Mediawiki::Client::FileAccessException

=item WWW::Mediawiki::Client::FileTypeException

=item WWW::Mediawiki::Client::URLConstructionException

=item WWW::Mediawiki::Client::UpdateNeededException

=back

=cut

sub do_preview {
	my ($self, $filename) = @_;
	my ($response) = $self->_upload_file($filename, 0);
	my $url = encode_entities($response->request->uri);
	my $content = $response->decoded_content;
	$content =~ s#<head>#$&<base href="$url"/>#;
	my $browser = $ENV{MVS_BROWSER};
	if (defined($browser)) {
            my $fh = new File::Temp(UNLINK => 1, SUFFIX => '.html');
            print $fh Encode::encode_utf8($content);
            $fh->close;
            system($browser, $fh->filename);
            return undef;
	}
	my $preview = $ENV{MVS_PREVIEW};
	$preview = 'preview.html' unless defined($preview);
	open(PREVIEW, '>', $preview) 
		or WWW::Mediawiki::Client::FileAccessException->throw(
			"Cannot open $preview for writing.");
	print PREVIEW $content;
	close(PREVIEW) or WWW::Mediawiki::Client::FileAccessException->throw(
			"Cannot close $preview.");
	print STDERR "Saved preview: $preview\n";
	return $preview;
}

=head2 do_clean

  $self->do_clean;

Removes all reference files under the current directory that have no
corresponding Wiki files.

B<Throws:>

=over

=item WWW::Mediawiki::Client::FileAccessException

=back

=cut

sub do_clean {
	my ($self) = @_;

	my $dir = File::Spec->curdir();
	find(sub { 
		return unless m/^\..*\.ref\.wiki\z/s;

		my $name = $File::Find::name;
		$name = File::Spec->abs2rel($name);

		my $wiki = $self->_ref_to_filename($name);
		return if -e $wiki;

		warn "Deleting: $name\n";
		unlink($name) 
		    or WWW::Mediawiki::Client::FileAccessException->throw(
			"Cannot delete reference file $name");
	}, $dir);
}

=head2 save_state
  
  $mvs->save_state;

Saves the current state of the wmc object in the current working directory.

B<Throws:>

=over

=item WWW::Mediawiki::Client::FileAccessException

=back

=cut

sub save_state {
    my $self = shift;
    my $conf = CONFIG_FILE;
    my %init;
    foreach my $attr (SAVED_ATTRIBUTES) {
        $init{$attr} = $self->$attr;
    }
    open OUT, ">:utf8", $conf or WWW::Mediawiki::Client::FileAccessException->throw(
            "Cannot write to config file, $conf.");
    print OUT Dumper(\%init);
    close OUT;
}

=head2 load_state

  $mvs = $mvs->load_state;

Loads the state of the wmc object from that saved in the current working
directory.

B<Throws:>

=over

=item WWW::Mediawiki::Client::CorruptedConfigFileException

=back

=cut

sub load_state {
    my $self = shift;
    my $config = CONFIG_FILE;
    return $self unless -e $config;
    our $VAR1;
    do $config or 
            WWW::Mediawiki::Client::CorruptedConfigFileException->throw(
            "Could not read config file: $config.");
    my %init = %$VAR1;
    foreach my $attr (SAVED_ATTRIBUTES) {
        $self->$attr($init{$attr});
    }
    return $self;
}

=head2 get_server_page

  my $wikitext = $mvs->get_server_page($pagename);

Returns the wikitext of the given Mediawiki page name.

B<Throws:>

=over

=item WWW::Mediawiki::Client::ServerPageException

=back

=cut

sub get_server_page {
    my ($self, $pagename) = @_;

    my $export = delete $self->{export}->{$pagename};
    return $export if defined($export);

    my $url = $self->pagename_to_url($pagename, EDIT);
    my $res = $self->{ua}->get($url);
    WWW::Mediawiki::Client::ServerPageException->throw(
            error => "Couldn't fetch \"$pagename\" from the server.",
            res => $res,
        ) unless $res->is_success;
    my $doc = $res->decoded_content;
    my $text = $self->_get_wiki_text($doc);
    $self->{edit}->{date} = $self->_get_edit_date($doc);
    $self->{edit}->{token} = $self->_get_edit_token($doc);
    $self->{edit}->{watch_now} = $self->_get_edit_is_watching($doc);
    $self->{edit}->{def_watch} = $self->_get_edit_watch_default($doc);
    $self->{edit}->{def_minor} = $self->_get_edit_minor_default($doc);
    my $headline = Encode::encode("utf8", $self->_get_page_headline($doc));
    my $expected = lc $pagename;
    unless (lc($headline) =~ /\Q$expected\E$/) {
        WWW::Mediawiki::Client::ServerPageException->throw(
	        error => "The server could not resolve the page name
                        '$pagename', but responded that it was '$headline'.",
                res   => $res,
            ) if ($headline && $headline =~ /^Editing /);
        WWW::Mediawiki::Client::ServerPageException->throw(
	        error => "Error message from the server: '$headline'.",
                res   => $res,
            ) if ($headline);
        WWW::Mediawiki::Client::ServerPageException->throw(
                error => "Could not identify the error in this context.",
                res   => $res,
            );
    }
    chomp $text;
    return $text;
}

=head2 get_local_page

  my $wikitext = $mvs->get_local_page($filename);

Returns the wikitext from the given local file;

B<Throws:>

=over

=item WWW::Mediawiki::Client::FileAccessException

=item WWW::Mediawiki::Client::FileTypeException

=item WWW::Mediawiki::Client::AbsoluteFileNameException 

=back

=cut

sub get_local_page {
    my ($self, $filename) = @_;
    $self->_check_path($filename);
    return '' unless -e $filename;
    open IN, "<:utf8", $filename or 
            WWW::Mediawiki::Client::FileAccessException->throw(
            "Cannot open $filename.");
    local $/;
    my $text = <IN>;
    close IN;
    return $text;
}

=head2 pagename_to_url

  my $url = $mvs->pagename_to_url($pagename);

Returns the url at which a given pagename will be found on the Mediawiki
server to which this instance of points.

B<Throws:>

=over

=item WWW::Mediawiki::Client::URLConstructionException;

=back

=cut

sub pagename_to_url {
    my ($self, $name, $action) = @_;
    WWW::Mediawiki::Client::URLConstructionException->throw(
            error => 'No action supplied.',
        ) unless $action;
    WWW::Mediawiki::Client::URLConstructionException->throw(
            error => "Page name $name ends with '.wiki'.",
        ) if $name =~ /.wiki$/;
    my $char = $self->space_substitute;
    $name =~ s/ /$char/;
    my $lang = $self->language_code;
    my $host = $self->host;
    $host =~ s/__LANG__/$lang/g;
    my $wiki_path = $self->wiki_path;
    $wiki_path =~ s/__LANG__/$lang/g;
    my $protocol = $self->protocol;
    return "$protocol://$host/$wiki_path?" . ACTION . "=$action&" . TITLE . "=$name";
}

=head2 filename_to_pagename

  my $pagename = $mvs->filname_to_pagename($filename);

Returns the cooresponding server page name given a filename.

B<Throws:>

=over

=item WWW::Mediawiki::Client::AbsoluteFileNameException

=item WWW::Mediawiki::Client::FileTypeException 

=back

=cut

sub filename_to_pagename {
    my ($self, $name) = @_;
    $self->_check_path($name);
    $name =~ s/.wiki$//;

    $self->{escape_filenames} and $name = decode('UTF-8', URI::Escape::uri_unescape($name));

    $name =~ s/_/ /g;
    return ucfirst $name;
}

=head2 filename_to_url

  my $pagename = $mvs->filname_to_url($filename);

Returns the cooresponding server URL given a filename.

B<Throws:>

=over

=item WWW::Mediawiki::Client::AbsoluteFileNameException

=item WWW::Mediawiki::Client::FileTypeException 

=back

=cut

sub filename_to_url {
    my ($self, $name, $action) = @_;
    $name = $self->filename_to_pagename($name);
    return $self->pagename_to_url($name, $action);
}

=head2 pagename_to_filename

  my $filename = $mvs->pagename_to_filename($pagename);

Returns a local filename which cooresponds to the given Mediawiki page
name.

=cut

sub pagename_to_filename {
    my ($self, $name) = @_;
    $name =~ s/ /_/;

    $self->{escape_filenames} and $name = URI::Escape::uri_escape_utf8($name);
    
    $name .= '.wiki';
    return $name;
}

=head2 url_to_filename
  
  my $filename = $mvs->url_to_filename($url);

Returns the local filename which cooresponds to a given URL.

=cut

sub url_to_filename {
    my ($self, $url) = @_;
    my $char = '\\' . $self->space_substitute;
    $url =~ s/$char/_/g;
    my $title = TITLE;
    $url =~ m/&$title=([^&]*)/;
    return "$1.wiki";
}

=head2 list_wiki_files

  @filenames = $mvs->list_wiki_files;

Returns a recursive list of all wikitext files in the local repository.

=cut

sub list_wiki_files {
    my $self = shift;
    my @files;
    my $dir = File::Spec->curdir();
    find(sub { 
        return unless /^[^.].*\.wiki\z/s;
        my $name = $File::Find::name;
        $name = File::Spec->abs2rel($name);
        push @files, $name;
    }, $dir);
    return @files;
}

=begin comment

=head1 Private Methods

=cut

sub _merge {
    my ($self, $filename, $ref, $server, $local) = @_;
    my $control = {
            in => $\,
            out => $/,
            chomp => 1
        };
    $ref = VCS::Lite->new('ref', "\n", "$ref\n");
    $server = VCS::Lite->new('server', "\n", "$server\n");
    $local = VCS::Lite->new('local', "\n", "$local\n");
    my $merge = $ref->merge($server, $local);
    return scalar $merge->text();
}

sub _get_wiki_text {
    my ($self, $doc) = @_;
    my $p = HTML::TokeParser->new(\$doc);
    $p->get_tag("textarea");
    my $text = $p->get_text;
    $text =~ s///gs;                      # convert endlines
    return $text;
}

sub _get_server_encoding {
    my ($self) = @_;
    my $url = $self->_get_version_url;
    my $res = $self->{ua}->get($url);
    my $doc = $res->decoded_content;
    my $p = HTML::TokeParser->new(\$doc);
    while ( my $t = $p->get_tag("meta") ) {
        next unless defined $t->[1]->{'http-equiv'}
     and ($t->[1]->{'http-equiv'} eq 'Content-Type'
     or $t->[1]->{'http-equiv'} eq 'Content-type');
        my $cont = $t->[1]->{'content'};
        $cont =~ m/charset=(.*)/;
        return $1;
    }
}

sub _get_page_headline {
    my ($self, $doc) = @_;
    my $p = HTML::TokeParser->new(\$doc);
    $p->get_tag("h1");
    my $text = $p->get_text;
    $text =~ s///gs;                      # convert endlines
    return $text;
}

sub _get_edit_date {
    my ($self, $doc) = @_;
    my $p = HTML::TokeParser->new(\$doc);
    my $date;
    while (my $tag = $p->get_tag('input')) {
        next unless $tag->[1]->{type} eq 'hidden';
        next unless $tag->[1]->{name} eq EDIT_TIME_NAME;
        $date = $tag->[1]->{value};
    }
    return $date;
}

sub _get_edit_token {
    my ($self, $doc) = @_;
    my $p = HTML::TokeParser->new(\$doc);
    my $token;
    while (my $tag = $p->get_tag('input')) {
        next unless $tag->[1]->{type} eq 'hidden';
        next unless $tag->[1]->{name} eq 'wpEditToken';
        $token = $tag->[1]->{value};
    }
    return $token;
}

sub _get_edit_is_watching {
    my ($self, $doc, $name) = @_;
    my $p = HTML::TokeParser->new(\$doc);
    my $status;
    while (my $tag = $p->get_tag('a')) {
        next unless $tag->[1]->{href} 
                && $tag->[1]->{href} =~ m/&action=((?:un)?watch)/;
	# If 'un'watch, then it's watched; otherwise, it's not.
        $status = ($1 eq 'unwatch' ? 1 : 0);
    }
    return $status;
}

sub _get_edit_checkbox {
    my ($self, $doc, $name) = @_;
    my $p = HTML::TokeParser->new(\$doc);
    my $status;
    while (my $tag = $p->get_tag('input')) {
        next unless $tag->[1]->{type} eq 'checkbox';
        next unless $tag->[1]->{name} eq $name;
        $status = ($tag->[1]->{checked} ? 1 : 0);
    }
    return $status;
}

sub _get_edit_watch_default {
	my ($self, $doc) = @_;
	return $self->_get_edit_checkbox($doc, EDIT_WATCH_NAME);
}

sub _get_edit_minor_default {
	my ($self, $doc) = @_;
	return $self->_get_edit_checkbox($doc, EDIT_MINOR_NAME);
}

sub _check_path {
    my ($self, $filename) = @_;
    WWW::Mediawiki::Client::FileTypeException->throw(
            "'$filename' doesn't appear to be a wiki file.")
            unless $filename =~ /\.wiki$/;
    WWW::Mediawiki::Client::AbsoluteFileNameException->throw(
            "No absolute filenames allowed!")
            if File::Spec->file_name_is_absolute($filename);
    return File::Spec->splitpath($filename);
}

sub _get_reference_page {
    my ($self, $filename) = @_;
    return '' unless -e $filename;
    $filename = $self->_get_ref_filename($filename);
    my $ref = $self->get_local_page($filename);
    return $ref;
}

sub _get_ref_filename {
    my ($self, $filename) = @_;
    WWW::Mediawiki::Client::FileTypeException->throw(
            "Not a .wiki file.") unless $filename =~ /\.wiki$/;
    my ($vol, $dirs, $fn) = File::Spec->splitpath($filename);
    $fn =~ s/(.*)\.wiki/.$1.ref.wiki/;
    return File::Spec->catfile('.', $dirs, $fn);
}

sub _ref_to_filename {
    my ($self, $ref) = @_;
    my ($vol, $dirs, $fn) = File::Spec->splitpath($ref);
    $fn =~ s/^\.(.*)\.ref\.wiki$/$1.wiki/
        or WWW::Mediawiki::Client::FileTypeException->throw(
            "Not a .ref.wiki file.");
    return File::Spec->catpath($vol, $dirs, $fn);
}

sub _conflicts_found_in {
    my ($self, $text) = @_;
    return 1 if $text =~ /Start of conflict 1/m;
    return 0;
}

sub _get_update_status {
    my ($self, $rv, $sv, $lv, $nv) = @_;
    chomp ($rv, $sv, $lv, $nv); # double chomp
    chomp ($rv, $sv, $lv, $nv); # it's a nasty hack, but necessary until we re-write
    return STATUS_CONFLICT if $self->_conflicts_found_in($nv);
    return STATUS_UNKNOWN unless $sv or $lv;
    return STATUS_LOCAL_ADDED unless $sv;
    return STATUS_UNCHANGED if $sv eq $lv;
    return STATUS_LOCAL_MODIFIED if $lv ne $rv;
    return STATUS_SERVER_MODIFIED if $rv ne $sv;
    return STATUS_UNKNOWN;
}

sub _get_host_url {
	my ($self) = @_;
	my $lang = $self->language_code;
	my $host = $self->host;
	$host =~ s/__LANG__/$lang/g;
        my $protocol = $self->protocol;
	return "$protocol://$host/";
}

sub _get_version_url {
    my ($self) = @_;
    my $lang = $self->language_code;
    my $path = $self->wiki_path;
    $path =~ s/__LANG__/$lang/g;
    return $self->_get_host_url 
         . $path . '?' . TITLE . '=' . SPECIAL_VERSION;
}

sub _get_export_url {
    my ($self) = @_;
    my $lang = $self->language_code;
    my $path = $self->wiki_path;
    $path =~ s/__LANG__/$lang/g;
    return $self->_get_host_url 
         . $path . '?' . TITLE . '=' . SPECIAL_EXPORT;
}

sub _get_exported_pages {
    my ($self, @pages) = @_;
    my $count = scalar @pages;
    my $url = $self->_get_export_url;
    my $response = $self->{ua}->request(POST $url, [ 
            pages => join("\n", @pages),
            action => 'submit',
            curonly => 'true',
    ]);
    WWW::Mediawiki::Client::ServerPageException->throw(
            error => "Couldn't fetch $count pages from the server.",
            res => $response,
        ) unless $response->is_success;
    my $parser = XML::LibXML->new;
    my $doc = $parser->parse_string($response->decoded_content);
    my %expecting = map {$_ => 1} @pages;
    my %export = ();
    my %timestamp = ();
    foreach my $node ($doc->findnodes('/mediawiki/page')) {
        my $page = $node->findvalue(TITLE);
        my $text = $node->findvalue('revision/text');
        my $time = $node->findvalue('revision/timestamp');
        WWW::Mediawiki::Client::ServerPageException->throw(
            error => "Server returned unexpected page '$page'.",
            res => $response) unless $expecting{$page};
        $export{$page} = $text;
        $timestamp{$page} = $time;
    }
    $self->{export} = \%export;
    $self->{timestamp} = \%timestamp;
}

sub _upload_file {
    my ($self, $filename, $commit) = @_;
    WWW::Mediawiki::Client::URLConstructionException->throw(
            "No server URL specified.") unless $self->{host};
    WWW::Mediawiki::Client::FileAccessException->throw("No such file!") 
        unless -e $filename;
    WWW::Mediawiki::Client::CommitException->throw(
            'Could not determine charset for uploading to this server.'
        ) unless $self->encoding;
    my $text = $self->get_local_page($filename);
    my $pagename = $self->filename_to_pagename($filename);
    my $sp = $self->get_server_page($pagename);
    if ($self->{edit}->{date}) {
        my $ref = $self->_get_reference_page($filename);
        chomp ($sp, $ref);
        WWW::Mediawiki::Client::UpdateNeededException->throw(
                error => $self->filename_to_pagename($filename) 
                       . " has changed on the server.",
            ) unless $sp eq $ref;
    }
    chomp ($text);
    WWW::Mediawiki::Client::ConflictsPresentException->throw(
            "$filename appears to have unresolved conflicts")
        if $self->_conflicts_found_in($text);
    my @params;
    push(@params, EDIT_MINOR_NAME, CHECKED) if $self->_option_check(
        'minor_edit', $self->{minor_edit}, 
	$self->{edit}->{def_minor});
    push(@params, EDIT_WATCH_NAME, CHECKED) if $self->_option_check(
	'watch', $self->{watch}, 
	$self->{edit}->{def_watch}, $self->{edit}->{watch_now});
    my $act_name  = ($commit ? EDIT_SUBMIT_NAME  : EDIT_PREVIEW_NAME );
    my $act_value = ($commit ? EDIT_SUBMIT_VALUE : EDIT_PREVIEW_VALUE);
    my $url = $self->filename_to_url($filename, SUBMIT);
    my $octets = Encode::encode($self->encoding, $text);
    my $res = $self->{ua}->post($url,
        [ 
            $act_name           => $act_value,
            &TEXTAREA_NAME      => $octets,
            &COMMENT_NAME       => $self->{commit_message},
            &EDIT_TIME_NAME     => $self->{edit}->{date},
            &EDIT_TOKEN_NAME    => $self->{edit}->{token},
	    @params,
        ],
    );
    my $doc = $res->decoded_content;
    my $headline = $self->_get_page_headline($doc);
    my $expect = ($commit ? $pagename : "Editing $pagename");
    unless (lc($headline) eq lc($expect)) {
        WWW::Mediawiki::Client::CommitException->throw(
	        error => "The page you are trying to commit appears to contain a link which is associated with Wikispam.",
                res   => $res,
            ) if ($headline eq 'Spam protection filter');
        WWW::Mediawiki::Client::CommitException->throw(
	        error => "When we tried to commit '$pagename' the server responded with '$headline'.",
                res   => $res,
            ) if ($headline);
    }
    return ($res, $text);
}

sub _option_verify {
	my ($self, $name, $value, $r_accept) = @_;

	foreach my $acc (@{$r_accept}) {
		return 1 if $acc == $value;
	}

	my %opts = OPTION_SETTINGS;
	my $valstr = $opts{$value};
	$valstr = "value '$value'" unless defined($valstr);

        WWW::Mediawiki::Client::InvalidOptionException->throw(
	        error  => "Cannot set field $name to $valstr.",
		field  => $name,
                option => $opts{$value},
		value  => $value,
	);
}

sub _option_check {
	my ($self, $name, $value, $default, $current) = @_;

	return 1 if $value == OPT_YES;
	return 0 if $value == OPT_NO;

	if ($value == OPT_DEFAULT) {
		return $default if defined($default);
		WWW::Mediawiki::Client::InvalidOptionException->throw(
			error  => "Field '$name' cannot use OPT_DEFAULT:"
			    . " Default information could not be determined.",
			field  => $name,
			option => 'OPT_DEFAULT',
			value  => $value,
		);
	}

	if ($value == OPT_KEEP) {
		return $current if defined($current);
		WWW::Mediawiki::Client::InvalidOptionException->throw(
			error  => "Field '$name' cannot use OPT_KEEP:"
			    . " Current information could not be determined.",
			field  => $name,
			option => 'OPT_DEFAULT',
			value  => $value,
		);
	}

	# Should never happen; these are verified at assignment time.
	my %opts = OPTION_SETTINGS;
        WWW::Mediawiki::Client::InvalidOptionException->throw(
	        error  => "Field '$name' is in unknown state '$value'.",
		field  => $name,
                option => $opts{$value},
		value  => $value
	);
}

1;

__END__

=end comment

=head1 BUGS

Please submit bug reports to the CPAN bug tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mediawiki-Client>.

=head1 DISCUSSION

There is a discussion list.  You can subscribe or read the archives at:
L<http://www.geekhive.net/cgi-bin/mailman/listinfo/www-mediawiki-client-l>

=head1 AUTHORS

=over

=item Mark Jaroski <mark@geekhive.net> 

Original author, maintainer

=item Mike Wesemann <mike@fhi-berlin.mpg.de>

Added support for Mediawiki 1.3.10+ edit tokens

=item Bernhard Kaindl <bkaindl@ffii.org>

Improved error messages.

=item Oleg Alexandrov <aoleg@math.ucla.edu>, Thomas Widmann <twid@bibulus.org>

Bug reports and feedback.

=item Adrian Irving-Beer <wisq@wisq.net>

Preview support, export support for multi-page update, more 'minor'
and 'watch' settings, and bug reports.

=item Nicolas Brouard <nicolas.brouard@libertysurf.fr>

Fixed content-type bug.

=item Alex Kapranoff <alex@kapranoff.ru>

Added C<escape_filename> in order to support UTF-8 filenames on filesystems
lacking UTF-8 support.

=back

=head1 LICENSE

Copyright (c) 2004-2006 Mark Jaroski. 

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

