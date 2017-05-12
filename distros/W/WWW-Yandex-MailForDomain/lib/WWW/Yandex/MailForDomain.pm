package WWW::Yandex::MailForDomain;
# coding: UTF-8

use strict;
use warnings;
use utf8;

our $VERSION = '0.2';

use LWP::UserAgent;
use URI::Escape;
use XML::Simple;

use Data::Dumper;

# ==============================================================================

use constant YANDEX_PDD_API_SERVER => 'https://pddimp.yandex.ru/';
use constant YANDEX_PDD_API_MAX_ON_PAGE => 100;

my %TRANSLATE_TO_PDD = (
    login           => 'login',
    password        => 'password',
    nickname        => 'nickname',

    enabled         => 'enabled',
    eula_signed     => 'signed_eula',

    first_name      => 'iname',
    last_name       => 'fname',
    date_of_birth   => 'birth_date',
    sex             => 'sex',

    secret_question => 'hintq',
    secret_answer   => 'hinta',

    #mail_format     => 'mail_format',
    #charset         => 'charset',
);
my %TRANSLATE_FROM_PDD = map { $TRANSLATE_TO_PDD{$_} => $_ } keys(%TRANSLATE_TO_PDD);

my %TRANSLATE_SERVER_TO_PDD = (
    protocol        => 'method',
    host            => 'ext_serv',
    port            => 'ext_port',
    no_ssl          => 'isssl',
    notify          => 'callback',
);

# ==============================================================================
# Constructor
sub new {
    my ($class, %config) = @_;
    %config = () if !(%config);

    if (! $config{token}) {
        return undef;
    }
    else {
        my $self = +{};
        $self = bless $self, ref($class) || $class;

        $self->_init(\%config);
        return $self;
    }
}
# ------------------------------------------------------------------------------
# Set up initial (passed from caller or default) values
sub _init
{
    my $self = shift;
    my ($config) = @_;

    for (qw(ua token on_error)) {
        $self->{$_} = $config->{$_};
    }

    $self->{_xs} = XML::Simple->new(
        KeepRoot        => 1,
    );

    $self->{_errmsg} = '';

    $self->{_cached_domain}     = undef;
    $self->{_cached_status}     = undef;
    $self->{_cached_total}      = undef;
    $self->{_cached_max_number} = undef;
    $self->{_cached_found}      = undef;
}
# ------------------------------------------------------------------------------
sub _throw_error {
    my ($self, $msg) = @_;

    $self->{_errmsg} = $msg;
    if ($self->{on_error}) {
        # Fire callback
        &{$self->{on_error}}($msg);
    }
}
# ------------------------------------------------------------------------------
sub error {
    my $self = shift;
    return $self->{_errmsg} || '';
}
# ------------------------------------------------------------------------------
# Produces full URI for query from sub-uri and server name
sub _uri
{
    my ($self, $cmd) = @_;
    return YANDEX_PDD_API_SERVER . $cmd . '.xml';
}
# ------------------------------------------------------------------------------
# Our User-Agent
sub _ua {
    my $self = shift;

    if (! defined($self->{ua})) {
        $self->{ua} = LWP::UserAgent->new(
            agent       => ref($self) . '/' . $VERSION,
            timeout     => 30
        );
        $self->{ua}->env_proxy;
    }

    return $self->{ua};
}
# ------------------------------------------------------------------------------
# Make request to API
sub _query
{
    my ($self, $cmd, %data) = @_;
    my $r = undef;

    if (! $self->{token}) {
        $self->_throw_error('Token is not defined');
    }
    else {

        $data{token} = $self->{token};
        my $uri = $self->_uri($cmd) . '?' .
            join('&', map { uri_escape_utf8($_) . "=" . uri_escape_utf8($data{$_}) } keys(%data));

        my $response = $self->_ua->get($uri);

        if ($response->is_success) {

            # Fix wrong encoding in header
            my $cont = $response->decoded_content;
            $cont =~ s/windows-1251/UTF-8/;

            my $xml = $self->{_xs}->XMLin($cont);

            # Error reported by API
            if (exists($xml->{page}->{error}->{reason})) {
                $self->_throw_error('PDD error: ' . $xml->{page}->{error}->{reason});
            }
            # All OK, return XML tree
            else {
                $r = $xml;
            }
        }
        else {
            $self->_throw_error('Request failed: ' . $response->status_line);
        }
    }

    return $r;
}
# ==============================================================================
#
sub _query_users
{
    my ($self, $on_page, $page_n) = @_;

    # Something wrong happens, when we set 'page' and 'on_page' parameters,
    # and number of existing mailboxes is a little.

    # Therefore, we don't set default values for undefined parameters,
    # and try to request API without 'page' and 'on_page' fields.
    # In this case, there is more chances to get a correct list of mailboxes.

    my %data = ();

    # Check $page_n
    if (! defined($page_n)) {
        #$page_n = 1;
    }
    else {
        $page_n = int($page_n);
        $page_n = 1 if $page_n < 1;
        $data{page} = $page_n;
    }

    # Check $on_page
    if (! defined($on_page)) {
        #$on_page = 1;
    }
    else {
        $on_page = int($on_page);
        if ($on_page < 1) {
            $on_page = 1;
        }
        elsif ($on_page > YANDEX_PDD_API_MAX_ON_PAGE) {
            $on_page = YANDEX_PDD_API_MAX_ON_PAGE;
        }
        $data{on_page} = $on_page;
    }

    my $r = $self->_query('get_domain_users',
        %data
    );

    # Saving some information
    if (defined($r)) {
        if ($r->{page}->{domains}->{domain}->{name}) {
            $self->{_cached_domain} = $r->{page}->{domains}->{domain}->{name};
        }

        if (exists($r->{page}->{domains}->{domain}->{status})) {
            $self->{_cached_status} = $r->{page}->{domains}->{domain}->{status};
        }

        if (exists($r->{page}->{domains}->{domain}->{'emails-max-count'})) {
            $self->{_cached_max_number} = int($r->{page}->{domains}->{domain}->{'emails-max-count'});
        }

        if (exists($r->{page}->{domains}->{domain}->{emails}->{total})) {
            $self->{_cached_total} = int($r->{page}->{domains}->{domain}->{emails}->{total});
        }

        if (exists($r->{page}->{domains}->{domain}->{emails}->{found})) {
            $self->{_cached_found} = int($r->{page}->{domains}->{domain}->{emails}->{found});
        }
    }

    return $r;
}
# ------------------------------------------------------------------------------
#
sub refresh_counters
{
    my $self = shift;

    my $r = $self->_query_users(1, 1);
    if (defined($r)) {
        $r = 1;
    }

    return $r;
}
# ------------------------------------------------------------------------------
#
sub domain
{
    my $self = shift;

    if (! $self->{_cached_domain}) {
        $self->refresh_counters;
    }

    return $self->{_cached_domain};
}
# ------------------------------------------------------------------------------
#
sub domain_status
{
    my $self = shift;

    if (! $self->{_cached_status}) {
        $self->refresh_counters;
    }

    return $self->{_cached_status};
}
# ------------------------------------------------------------------------------
#
sub users_total
{
    my $self = shift;

    if (! defined($self->{_cached_total})) {
        $self->refresh_counters;
    }

    return $self->{_cached_total};
}
# ------------------------------------------------------------------------------
#
sub users_max_number
{
    my $self = shift;

    if (! defined($self->{_cached_max_number})) {
        $self->refresh_counters;
    }

    return $self->{_cached_max_number};
}
# ------------------------------------------------------------------------------
#
sub get_users_one_page
{
    my ($self, $on_page, $page_n) = @_;

    my $r = $self->_query_users($on_page, $page_n);

    if (defined($r)) {
        if ($r->{page}->{domains}->{domain}->{emails}->{email}) {
            my @boxes = ();

            my $h = $r->{page}->{domains}->{domain}->{emails}->{email};

            # I could not tune the XML::Simple to properly parse emails list,
            # so I applied some untidy logic: get x->{email}->{name} value,
            # if we have only one item

            my @found = keys(%$h);

            if (scalar(@found) == 1) {
                push(@boxes, $h->{name});
            }
            elsif (scalar(@found) > 1) {
                push(@boxes, @found);
            }

            $r = \@boxes;
        }
        else {
            $r = +[];
        }
    }

    return $r;
}
# ------------------------------------------------------------------------------
#
sub get_users
{
    my ($self) = @_;

    # Initially, we try to get list without any parameters
    my $r = $self->get_users_one_page();

    if ($r) {
        # Collect into hash to avoid duplicates. They may occur with
        # annoying Yandex PDD paging process.
        my %boxes = ();
        for (@$r) { $boxes{$_} = 1 }

        my $found = scalar(keys(%boxes));

        if ($found < $self->users_total) {
            # Not complete, needed page by page retrieving

            my $on_page = YANDEX_PDD_API_MAX_ON_PAGE;
            my $start_page = 1;

            if ($found == YANDEX_PDD_API_MAX_ON_PAGE) {
                # First page is filled wholly
                $start_page = 2;
            }
            else {
                # First page is not filled, try again from beginning
                %boxes = ();
                $start_page = 1;
            }

            my $total_pages = int(($self->users_total + YANDEX_PDD_API_MAX_ON_PAGE - 1) / $on_page);
            my $was_error = 0;
            for (my $page_n = $start_page; $page_n <= $total_pages; $page_n++) {

                my $cur = $self->get_users_one_page($on_page, $page_n);

                if (! defined($cur)) {
                    # Something happens
                    $was_error = 1;
                    last;
                }
                else {
                    for (@$cur) { $boxes{$_} = 1 }
                }
            }

            if ($was_error) {
                $r = undef;
            }
            else {
                my @b = keys(%boxes);
                $r = \@b;
            }
        }
        else {
            # Found all by first query
            my @b = keys(%boxes);
            $r = \@b;
        }
    }

    return $r;
}
# ==============================================================================
#
sub check_user
{
    my ($self, $login) = @_;

    my $r = $self->_query('check_user',
        login     => $login,
    );

    if (defined($r) and defined($r->{page}->{result})) {
        my $x = $r->{page}->{result} eq 'exists' ? 1 : 0;
        $r = $x;
    }

    return $r;
}
# ------------------------------------------------------------------------------
#
sub add_user
{
    my ($self, $login, $password) = @_;

    my $r = $self->_query('reg_user_token',
        u_login     => $login,
        u_password  => $password,
    );

    if (defined($r)) {
        $r = $r->{page}->{ok}->{uid} || '';
        $self->refresh_counters; # Don't care about retval
    }

    return $r;
}
# ------------------------------------------------------------------------------
#
sub add_user_encrypted
{
    my ($self, $login, $password) = @_;

    my $r = $self->_query('reg_user_crypto',
        login     => $login,
        password  => $password,
    );

    if (defined($r)) {
        $r = $r->{page}->{ok}->{uid} || '';
        $self->refresh_counters; # Don't care about retval
    }

    return $r;
}
# ------------------------------------------------------------------------------
#
sub delete_user
{
    my ($self, $login) = @_;

    my $r = $self->_query('delete_user',
        login     => $login,
    );

    if (defined($r)) {
        $r = exists($r->{page}->{ok}) ? 1 : undef;
        $self->refresh_counters; # Don't care about retval
    }

    return $r;
}
# ------------------------------------------------------------------------------
#
sub change_password
{
    my ($self, $login, $new_password) = @_;

    my $r = $self->_query('edit_user',
        login     => $login,
        password  => $new_password,
    );

    if (defined($r)) {
        $r = $r->{page}->{ok}->{uid} || '';
    }

    return $r;
}
# ------------------------------------------------------------------------------
#
sub modify_user
{
    my ($self, $login, %data) = @_;

    my %q = ();
    for (qw(first_name last_name sex secret_question secret_answer)) {
        $q{$_} = $data{$_} if defined($data{$_});
    }

    # Field 'sex' must be integer in [0..2] interval
    if (exists($q{sex})) {
        $q{sex} =~ s/\D//g;
        $q{sex} = int($q{sex});
        if (($q{sex} < 0) or ($q{sex} > 2)) {
            delete $q{sex};
        }
    }

    # Translate field names
    my %qt = ();
    for (keys(%q)) {
        $qt{$TRANSLATE_TO_PDD{$_}} = $q{$_};
    }

    print Dumper(\%qt);

    # Execute query
    my $r = $self->_query('edit_user',
        login     => $login,
        %qt
    );

    if (defined($r)) {
        $r = $r->{page}->{ok}->{uid} || '';
    }

    return $r;
}
# ------------------------------------------------------------------------------
#
sub get_user_info
{
    my ($self, $login, %data) = @_;

    my $r = $self->_query('get_user_info',
        login     => $login,
    );

    if (defined($r) and defined($r->{page}->{domain}->{user})) {

        print Dumper($r), "\n\n";

        my $info = $r->{page}->{domain}->{user};
        my $u = +{};

        for my $k (keys(%$info)) {
            if (exists($TRANSLATE_FROM_PDD{$k})) {
                my $key = $TRANSLATE_FROM_PDD{$k};
                my $val = ref($info->{$k}) eq 'HASH' ? undef : $info->{$k};
                $u->{$key} = $val;
            }
        }

        $r = $u;
    }

    return $r;
}
# ------------------------------------------------------------------------------
#
sub get_unread_count
{
    my ($self, $login) = @_;

    my $r = $self->_query('get_mail_info',
        login     => $login,
    );

    if (defined($r)) {
        $r = $r->{page}->{ok}->{new_messages} || 0;
    }

    return $r;
}
# ==============================================================================
#
sub register_source
{
    my ($self, %opt) = @_;
    my $r = undef;

    if ($opt{host}) {

        $opt{protocol} = ($opt{protocol} && (lc($opt{protocol}) eq 'imap')) ? 'imap' : 'pop3';
        $opt{port} = int($opt{port}) if defined $opt{port};
        $opt{no_ssl} = $opt{no_ssl} ? 'no' : undef;

        my %q = ();
        for (keys(%opt)) {
            $q{$TRANSLATE_SERVER_TO_PDD{$_}} = $opt{$_} if defined($opt{$_});
        }

        $r = $self->_query('set_domain', %q);

        if (defined($r)) {
            $r = exists($r->{page}->{ok}) ? 1 : undef;
        }
    }
    else {
        $self->_throw_error('Remote host is not defined');
    }

    return $r;
}
# ------------------------------------------------------------------------------
#
sub start_import
{
    my ($self, $login, %data) = @_;

    my %q = ();

    $q{login}     = $login;
    $q{ext_login} = $data{remote_login}    if defined $data{remote_login};
    $q{password}  = $data{remote_password} if defined $data{remote_password};

    my $r = $self->_query('start_import', %q);

    if (defined($r)) {
        $r = exists($r->{page}->{ok}) ? 1 : undef;
    }

    return $r;
}
# ------------------------------------------------------------------------------
#
sub stop_import
{
    my ($self, $login) = @_;

    my $r = $self->_query('stop_import',
        login     => $login,
    );

    if (defined($r)) {
        $r = exists($r->{page}->{ok}) ? 1 : undef;
    }

    return $r;
}
# ------------------------------------------------------------------------------
#
sub check_import_status
{
    my ($self, $login) = @_;

    my $r = $self->_query('check_import',
        login     => $login,
    );

    if (defined($r)) {
        my $u = +{};
        $u->{time}  = $r->{page}->{ok}->{last_check};
        $u->{state} = $r->{page}->{ok}->{state};
        $r = $u;
    }

    return $r;
}
# ==============================================================================
#
sub set_forwarding
{
    my ($self, $from, $to, $dont_keep) = @_;

    my $copy = $dont_keep ? 'no' : 'yes';

    my $r = $self->_query('set_forward',
        login     => $from,
        address   => $to,
        copy      => $copy,
    );

    if (defined($r)) {
        $r = exists($r->{page}->{ok}) ? 1 : undef;
    }

    return $r;
}
# ==============================================================================
1;
__END__

=head1 NAME

WWW::Yandex::MailForDomain - Yandex Mail for Domain API

=head1 SYNOPSIS

    use WWW::Yandex::MailForDomain;

    my $pdd = WWW::Yandex::MailForDomain->new(
        token       => '2009....a0ab',
        on_error    => sub { die shift }
    );

    # Add new mailbox
    $pdd->add_user('john', 'pass123');
    $pdd->modify_user('john',
        first_name  => 'John',
        last_name   => 'Doe'
    );

    # List all mailboxes and display number of unread messages
    for my $user (sort(@{$pdd->get_users})) {
        my $unread = $pdd->get_unread_count($user);
        print "$user\t$unread\n";
    }


=head1 DESCRIPTION

The C<WWW::Yandex::MailForDomain> module allows you to use
Yandex Mail for Domain service (L<http://pdd.yandex.ru>) via simple interface.

=head2 Authorization token

For using API, you need an authorization token. When you logged in into
your Yandex account (used for domain activation), just get page at
L<https://pddimp.yandex.ru/get_token.xml?domain_name=example.org>,
where C<example.org> is the domain name for your mail. The token
(some hexadecimal value) will be found in page's body in the XML attribute.

You need to get token only once for specific domain name.


=head1 USAGE

Interaction with Yandex Mail for Domain API executes by methods of the
C<WWW::Yandex::MailForDomain> object, which is needed only one to perform all
actions with specific mail domain. This mail domain, as well as the authorization
data, unambiguously identified by the authorization token.

The object provides methods for:

=over

=item * Retrieving information about the mail domain capabilities

=item * Retrieving information about the user mailbox

=item * Manipulating the users' mailboxes: creating, modifying etc.

=item * Setting up, starting and stopping mail import by POP or IMAP protocol

=item * Initiating mail forwarding

=back

=head2 Constructor

=over

=item C<WWW::Yandex::MailForDomain-E<gt>new(%options)>

This method constructs a new C<WWW::Yandex::MailForDomain> object and returns it.
Key/value pair arguments may be provided to set up the initial state.

    token             The authorization token (required)
    ua                Your own LWP::UserAgent object (optional)
    on_error          The callback to invoke error processing (optional)

If C<token> absent, an object will not be created and C<undef> returned.
If C<ua> is not defined, it will be created internally. Example:

    my $pdd = WWW::Yandex::MailForDomain->new(
        token => '2009....a0ab'
    );

=back

=head2 Errors processing

All methods returns C<undef> when an error is detected. Afterwards, method
C<error> returns a message describing last ocurred error.

=over

=item C<error>

Returns last error.

    my $uid = $pdd->add_user('alice', 'pass123');
    if (! defined($uid)) {
        warn($pdd->error);
    }

=item Callback function

Additionally, you can define a callback function in the constructor's option C<on_error>.
This function will be fired when an error will be occurred.

    my $pdd = WWW::Yandex::MailForDomain->new(
        token       => '2009....a0ab',
        on_error    => sub {
            my ($err) = @_;
            log(time, $err) and die $err;
        }
    );

=back

=head2 User Registration Fields

Data, returned by C<get_user_info()> method, consist of following fields:

    login                     Login name

    enabled                   Is the mailbox enabled or blocked
    eula_signed               Was EULA signed by user

    nickname                  User's nickname
    first_name        (*)     First name
    last_name         (*)     Last name
    date_of_birth             Date of Birth, in YYYY-MM-DD format
    sex               (*)     Gender: 1 - male, 2 - female, 0 - uncertain

    secret_question   (*)     Secret question for password recovering
    secret_answer     (*)     Answer to secret question

Fields, marked with asterisk (*), can be changed with C<modify_user()> method.

All values are UTF-8 encoded scalars.

=head2 General information about mail domain

=over

=item C<domain>

Returns the domain name, associated with authorization token.

=item C<domain_status>

Returns the domain activation state. Possible values are
C<domain-activate>, C<mx-activate> and C<added>.

=item C<users_total>

Returns the number of currently existing mailboxes.

=item C<users_max_number>

Returns the maximum number of mailboxes, allowed for your mail domain.

=item C<refresh_counters>

Because both of C<users_total> and C<users_max_number> methods caching
their values for performance reasons, and only several functions
(such as C<add_user()>) automatically updating the cache,
use C<refresh_counters> to force getting the actual numbers.

=item C<get_users_one_page($on_page, $page_n)>

=item C<get_users_one_page>

Returns an arrayref with usernames. This list is splitted by pages,
contains not over than 100 items on page. You can specify the page number
with C<$page_n>, which starting from C<1>, and quantity of items on page
with C<$on_page>.

Also, you can use this methods without any arguments for default behaviour.
See L</"known bugs">.

=item C<get_users>

Proceed page by page retrieving and returns the complete list of users
in arrayref. See L</"known bugs">.

=back

=head2 Mailboxes management methods

In this section described methods for manipulating mailboxes and
for getting information about them. The mailbox's name is the same thing
as login name or user name.

Some of these methods returns a kind of UID value, that is useless in general.

=over

=item C<check_user($login)>

Returns C<1> if mailbox with specified login exists, or C<0> if not exists.

=item C<add_user($login, $password)>

Creates a new mailbox, specified by username and password. Returns UID
if mailbox was successfully created, or undef by various reasons
(bad username, password is too short, mailbox already exists and so on).

=item C<add_user_encrypted($login, $password_digest)>

Same as C<add_user()>, but accepts a MD5-based encrypted password.
You may use a C<unix_md5_crypt()> function, see L<Crypt::PasswdMD5>.
Example:

    use Crypt::PasswdMD5;
    $r = $pdd->add_user_encrypted('alice', unix_md5_crypt('pass123'));

There is no analogous functionality for C<change_password()> method.

=item C<delete_user($login)>

Removes a mailbox.

B<ATTENTION: a mailbox with all messages in it will be dropped without
any additional confirmation!>

Returns C<1> if mailbox was successfully removed.

=item C<modify_user($login, $field_name =E<gt> $value, ...)>

Modifies user data. Possible fields are:

    first_name
    last_name
    sex
    secret_question
    secret_answer

If a value is not defined, or is empty string, the correspondent field
will not be modified. See "L</"User Registration Fields">".

Returns UID.

=item C<change_password($login, $new_password)>

Changes password for the mailbox. Returns UID if password was successfully changed.

=item C<get_user_info($login)>

Returns hashref with user data. See "L</"User Registration Fields">".

=item C<get_unread_count($login)>

Returns total number of new (unread) messages in the mailbox.

=back

=head2 Importing mail from other server

Naturally, Yandex Mail for Domain service is suitable not only for creating new
mailbox sets. If you already have numerous mailboxes on your domain,
you should be want to moving their content, when moving user accounts
to Yandex Mail for Domain.

Yandex API provides special methods for simplifying this procedure.

=over

=item C<register_source($param =E<gt> $value, ...)>

Registers a mail server that holds user mail at present.
Key/value pair arguments must be specified to set up the connection parameters.

    host              The server's hostname (required)
    port              The server's port number, if it is not standard (optional)
    protocol          Name of protocol: 'POP3' (default) or 'IMAP'
    no_ssl            Server doesn't support SSL connection (optional)
    notify            URI for callback (optional)

The C<notify> is an URI, which will be requested when the import session
will be finished. URI will be amplified with query part C<login=imported_mailbox>.
It's supposed that request will receive XML document like this:

    <page><status>moved</status></page>

if import process finished correctly, or something else otherwise. Example:

    $r = $pdd->register_source(
        protocol    => 'pop3',
        host        => 'mail.example.org',
        notify      => 'http://example.org/transfer_finished.cgi',
    );

=item C<start_import($login, $param =E<gt> $value, ...)>

Begins importing process for user C<$login>. The parameters are C<remote_login>
and C<remote_password>, needed for authentication on the source server.
Example:

    $pdd->start_import('alice', remote_login => 'Alice.Smith', remote_password => 'pass123');

The C<remote_login> may be omitted, if it is equal to C<$login>.

=item C<stop_import($login)>

Terminates importing process for specified user.

=item C<check_import_status($login)>

Returns a hashref with two elements:
C<time> - a timestamp when last event took place, and
C<state> - a text message describing current state of importing process.

=back

=head2 Mail forwarding

=over

=item C<set_forwarding($login, $to)>

=item C<set_forwarding($login, $to, $dont_keep)>

Starts mail forwarding from mailbox, specified by C<$login>, to address C<$to>.
If C<$dont_keep> is defined and is a true value, the messages will be erased
after sending.

    # Setup forwarding, but keep original messages
    $r = $pdd->set_forwarding('alice', 'bob@example.org');

    # Setup forwarding and don't save original messages
    $r = $pdd->set_forwarding('carol', 'carol@home.example.org', 1);

Be careful:

=over

=item a) C<$to> address will not be checked for well-formedness.

=item b) You may set more than one address for forwarding. The order of executing
forwarding rules is not determined, so if any of them doesn't keep messages
in mailbox, proceeding the next rules will be uncertain.

=item c) There is no way to cancel forwarding via API.

=back

Returns C<1> on success.

=back


=head1 KNOWN BUGS

When a number of existing mailboxes is a little, the request users list
by C<get_users_one_page()> with specific C<$page_n> may cause a wrong
number of items in the returned list. Compare number of items with
C<users_total> value, or try call C<get_users_one_page()> without
any parameters.

On the other hand, if a number of mailboxes is a large, C<get_users()> method
may return a wrong number of items too.

I hope, the paging of retrieving mailboxes process will be fixed.
A bug report has been sended to Yandex.


=head1 SEE ALSO

Yandex Mail for Domain API Reference (in Russian): L<http://pdd.yandex.ru/help/section72/>


=head1 COPYRIGHT

Copyright (c) 2010 Oleg Alistratov. All rights reserved.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.


=head1 AUTHOR

Oleg Alistratov <zero@cpan.org>

=cut
