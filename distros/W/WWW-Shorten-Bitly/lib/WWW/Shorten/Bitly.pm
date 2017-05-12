package WWW::Shorten::Bitly;

use strict;
use warnings;
use Carp ();
use File::HomeDir ();
use File::Spec ();
use JSON::MaybeXS;
use Path::Tiny qw(path);
use Scalar::Util qw(blessed);
use URI ();

use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw(new version);

our $VERSION = '2.001';
$VERSION = eval $VERSION;

use constant BASE_BLY => $ENV{BITLY_API_URL} || 'https://api-ssl.bitly.com';

# _attr (private)
sub _attr {
    my $self = shift;
    my $attr = lc(_trim(shift) || '');
    # attribute list is small enough to just grep each time. meh.
    Carp::croak("Invalid attribute") unless grep {$attr eq $_} @{_attrs()};
    return $self->{$attr} unless @_;
    # unset the access_token if any other field is set
    # this ensures we're always connecting properly.
    $self->{access_token} = undef;
    my $val = shift;
    unless (defined($val)) {
        $self->{$attr} = undef;
        return $self;
    }
    $self->{$attr} = $val;
    return $self;
}

# _attrs (static, private)
{
    my $attrs; # mimic the state keyword
    sub _attrs {
        return [@{$attrs}] if $attrs;
        $attrs = [
            qw(username password access_token client_id client_secret),
        ];
        return [@{$attrs}];
    }
}

# _json_request (static, private)
sub _json_request {
    my $url = shift;
    Carp::croak("Invalid URI object") unless $url && blessed($url) && $url->isa('URI');
    my $ua = __PACKAGE__->ua();
    my $res = $ua->get($url);
    Carp::croak("Invalid response") unless $res;
    unless ($res->is_success) {
        Carp::croak($res->status_line);
    }

    my $content_type = $res->header('Content-Type');
    my $content = $res->decoded_content();
    unless ($content_type && $content_type =~ m{application/json}) {
        Carp::croak("Unexpected response: $content");
    }
    my $json = decode_json($content);
    Carp::croak("Invalid data returned: $content") unless $json;
    return $json->{data};
}

# _parse_args (static, private)
sub _parse_args {
    my $args;
    if ( @_ == 1 && ref $_[0] ) {
        my %copy = eval { %{ $_[0] } }; # try shallow copy
        Carp::croak("Argument to method could not be dereferenced as a hash") if $@;
        $args = \%copy;
    }
    elsif (@_==1 && !ref($_[0])) {
        $args = {single_arg => $_[0]};
    }
    elsif ( @_ % 2 == 0 ) {
        $args = {@_};
    }
    else {
        Carp::croak("Method got an odd number of elements");
    }
    return $args;
}

# _parse_config (static, private)
{
    my $config; # mimic the state keyword
    sub _parse_config {
        # always give back a shallow copy
        return {%{$config}} if $config;
        # only parse the file once, please.
        $config = {};
        my $file = $^O eq 'MSWin32'? '_bitly': '.bitly';
        $file .= '_test' if $ENV{BITLY_TEST_CONFIG};
        my $path = path(File::Spec->catfile(File::HomeDir->my_home(), $file));

        if ($path && $path->is_file) {
            my @lines = $path->lines_utf8({chomp => 1});
            my $attrs = _attrs();

            for my $line (@lines) {
                $line = _trim($line) || '';
                next if $line =~ /^\s*[;#]/; # skip comments
                $line =~ s/\s+[;#].*$//gm; # trim off comments
                next unless $line && $line =~ /=/; # make sure we have a =

                my ($key, $val) = split(/(?<![^\\]\\)=/, $line, 2);
                $key = lc(_trim($key) || '');
                $val = _trim($val);
                next unless $key && $val;
                $key = 'username' if $key eq 'user';
                next unless grep {$key eq $_} @{$attrs};
                $config->{$key} = $val;
            }
        }
        return {%{$config}};
    }
}

# _trim (static, private)
sub _trim {
    my $input = shift;
    return $input unless defined $input && !ref($input) && length($input);
    $input =~ s/\A\s*//;
    $input =~ s/\s*\z//;
    return $input;
}

sub new {
    my $class = shift;
    my $args;
    if ( @_ == 1 && ref $_[0] ) {
        my %copy = eval { %{ $_[0] } }; # try shallow copy
        Carp::croak("Argument to $class->new() could not be dereferenced as a hash") if $@;
        $args = \%copy;
    }
    elsif ( @_ % 2 == 0 ) {
        $args = {@_};
    }
    else {
        Carp::croak("$class->new() got an odd number of elements");
    }

    my $attrs = _attrs();
    # start with what's in our config file (if anything)
    my $href = _parse_config();
    # override with anything passed in
    for my $key (keys %{$args}) {
        my $lc_key = lc($key);
        $lc_key = 'username' if $lc_key eq 'user';
        next unless grep {$lc_key eq $_} @{$attrs};
        $href->{$lc_key} = $args->{$key};
    }
    return bless $href, $class;
}

sub access_token { return shift->_attr('access_token', @_); }

sub bitly_pro_domain {
    my $self = shift;
    $self->login() unless ($self->access_token);

    my $args = _parse_args(@_);
    my $link = $args->{domain} || $args->{url} || $args->{single_arg} || '';
    unless ($link) {
        Carp::croak("A domain parameter is required.\n");
    }

    my $url = URI->new_abs('/v3/bitly_pro_domain', BASE_BLY);
    $url->query_form(
        access_token => $self->access_token(),
        domain => $link,
        format => 'json',
    );
    return _json_request($url);
}

sub client_id { return shift->_attr('client_id', @_); }

sub client_secret { return shift->_attr('client_secret', @_); }

sub clicks {
    my $self = shift;
    $self->login() unless ($self->access_token);

    my $args = _parse_args(@_);
    my $link = $args->{link} || $args->{single_arg} || '';
    unless ($link) {
        Carp::croak("A link parameter is required.\n");
    }

    my $url = URI->new_abs('/v3/link/clicks', BASE_BLY);
    $url->query_form(
        access_token => $self->access_token(),
        link => $link,
        unit => $args->{unit} || 'day',
        units => $args->{units} || '-1',
        rollup => $args->{rollup}? 'true': 'false',
        timezone => $args->{timezone} || 'America/New_York',
        limit => $args->{limit} || 100,
        unit_reference_ts => $args->{unit_reference_ts} || 'now',
        format => 'json',
    );
    return _json_request($url);
}

sub clicks_by_day {
    my $self = shift;
    $self->login() unless ($self->access_token);

    my $args = _parse_args(@_);
    my $link = $args->{link} || $args->{single_arg} || '';
    unless ($link) {
        Carp::croak("A link parameter is required.\n");
    }
    $args->{unit} = 'day';
    $args->{units} = 7;
    $args->{link} = $link;
    return $self->clicks($args);
}

sub countries {
    my $self = shift;
    $self->login() unless ($self->access_token);

    my $args = _parse_args(@_);
    my $link = $args->{link} || $args->{single_arg} || '';
    unless ($link) {
        Carp::croak("A link parameter is required.\n");
    }

    my $url = URI->new_abs('/v3/link/countries', BASE_BLY);
    $url->query_form(
        access_token => $self->access_token(),
        link => $link,
        unit => $args->{unit} || 'day',
        units => $args->{units} || '-1',
        timezone => $args->{timezone} || 'America/New_York',
        limit => $args->{limit} || 100,
        unit_reference_ts => $args->{unit_reference_ts} || 'now',
        format => 'json',
    );
    return _json_request($url);
}

sub expand {
    my $self = shift;
    $self->login() unless ($self->access_token);

    my $args = _parse_args(@_);
    my $short_url = $args->{shortUrl} || $args->{URL} || $args->{url} || $args->{single_arg} || '';
    unless ($short_url) {
        Carp::croak("A shortUrl parameter is required.\n");
    }

    my $url = URI->new_abs('/v3/expand', BASE_BLY);
    $url->query_form(
        access_token => $self->access_token(),
        shortUrl => $short_url,
        hash => $args->{hash},
        format => 'json',
	);
    
    my $res = _json_request($url);
    Carp::croak("Invalid response") unless $res && ref($res->{expand}) eq 'ARRAY';
    return $res->{expand}[0];
}

sub info {
    my $self = shift;
    $self->login() unless ($self->access_token);
    my $args = _parse_args(@_);

    my $link = $args->{shortUrl} || $args->{single_arg} || '';
    unless ($link) {
        Carp::croak("A shortUrl parameter is required.\n");
    }

    my $url = URI->new_abs('/v3/info', BASE_BLY);
    $url->query_form(
        access_token => $self->access_token(),
        shortUrl => $link,
        hash => $args->{hash},
        expand_user => $args->{expand_user}? 'true': 'false',
        format => 'json',
    );
    return _json_request($url);
}

sub login {
    my $self = shift;
    return $self if $self->{access_token};

    my $username = $self->{username};
    my $password = $self->{password};
    my $id = $self->{client_id};
    my $secret = $self->{client_secret};
    my $url = URI->new_abs('/oauth/access_token', BASE_BLY);
    unless ($username && $password) {
        Carp::croak("Can't login without at least a username and password");
    }
    my $req = HTTP::Request->new(POST => $url);
    $req->header(Accept => 'application/json');
    if ($id && $secret) {
        $req->authorization_basic($id,$secret);
        my $content = URI->new();
        $content->query_form(
            grant_type=>'password',
            username=>$username,
            password=>$password,
        );
        $req->content($content->query());
    }
    else {
        $req->authorization_basic($username,$password);
    }
    my $ua = __PACKAGE__->ua();
    my $res = $ua->request($req);
    Carp::croak("Invalid response") unless $res;
    unless ($res->is_success) {
        Carp::croak($res->status_line);
    }

    my $content_type = $res->header('Content-Type');
    my $content = $res->decoded_content();
    if ($content_type && $content_type =~ m{application/json}) {
        my $json = decode_json($res->decoded_content());
        Carp::croak("Invalid data returned") unless $json;
        Carp::croak($content) unless ($json->{access_token});
        $content = $json->{access_token};
    }
    $self->access_token($content);
    return $self;
}

sub lookup {
    my $self = shift;
    $self->login() unless ($self->access_token);
    my $args = _parse_args(@_);

    my $link = $args->{url} || $args->{single_arg} || '';
    unless ($link) {
        Carp::croak("A url parameter is required.\n");
    }

    my $url = URI->new_abs('/v3/link/lookup', BASE_BLY);
    $url->query_form(
        access_token => $self->access_token(),
        link => $link,
        format => 'json',
    );
    return _json_request($url);
}

sub makeashorterlink {
    my $self;
    if ($_[0] && blessed($_[0]) && $_[0]->isa('WWW::Shorten::Bitly')) {
        $self = shift;
    }
    my $url = shift or Carp::croak('No URL passed to makeashorterlink');
    $self ||= __PACKAGE__->new(@_);
    my $res = $self->shorten(longUrl=>$url, @_);
    return $res->{url};
}

sub makealongerlink {
    my $self;
    if ($_[0] && blessed($_[0]) && $_[0]->isa('WWW::Shorten::Bitly')) {
        $self = shift;
    }
    my $url = shift or Carp::croak('No URL passed to makealongerlink');
    $self ||= __PACKAGE__->new(@_);
    my $res = $self->expand(shortUrl=>$url);
    return '' unless ref($res) eq 'HASH' and $res->{long_url};
    return $res->{long_url};
}

sub password { return shift->_attr('password', @_); }

sub referrers {
    my $self = shift;
    $self->login() unless ($self->access_token);
    my $args = _parse_args(@_);

    my $link = $args->{link} || $args->{single_arg} || '';
    unless ($link) {
        Carp::croak("A link parameter is required.\n");
    }

    my $url = URI->new_abs('/v3/link/referrers', BASE_BLY);
    $url->query_form(
        access_token => $self->access_token(),
        link => $link,
        unit => $args->{unit} || 'day',
        units => $args->{units} || -1,
        timezone => $args->{timezone} || 'America/New_York',
        limit => $args->{limit} || 100,
        unit_reference_ts => $args->{unit_reference_ts} || 'now',
        format => 'json',
    );
    return _json_request($url);
}

sub shorten {
    my $self = shift;
    $self->login() unless ($self->access_token);
    my $args = _parse_args(@_);

    my $long_url = $args->{longUrl} || $args->{single_arg} || $args->{URL} || $args->{url} || '';
    my $domain = $args->{domain} || undef;
    unless ($long_url) {
        Carp::croak("A longUrl parameter is required.\n");
    }

    my $url = URI->new_abs('/v3/shorten', BASE_BLY);
    $url->query_form(
        access_token => $self->access_token(),
        longUrl => $long_url,
        domain => $domain,
        format => 'json',
    );
    return _json_request($url);
}

sub username { return shift->_attr('username', @_); }


1; # End of WWW::Shorten::Bitly
__END__

=head1 NAME

WWW::Shorten::Bitly - Interface to shortening URLs using L<http://bitly.com>

=head1 SYNOPSIS

The traditional way, using the L<WWW::Shorten> interface:

    use strict;
    use warnings;

    use WWW::Shorten::Bitly;
    # use WWW::Shorten 'Bitly';  # or, this way

    # if you have a config file with your credentials:
    my $short_url = makeashorterlink('http://www.foo.com/some/long/url');
    my $long_url  = makealongerlink($short_url);

    # otherwise
    my $short = makeashorterlink('http://www.foo.com/some/long/url', {
        username => 'username',
        password => 'password',
        ...
    });

Or, the Object-Oriented way:

    use strict;
    use warnings;
    use Data::Dumper;
    use Try::Tiny qw(try catch);
    use WWW::Shorten::Bitly;

    my $bitly = WWW::Shorten::Bitly->new(
        username => 'username',
        password => 'password',
        client_id => 'adflkdgalgka',
        client_secret => 'sldfkjasdflg',
    );

    try {
        my $res = $bitly->shorten(longUrl => 'http://google.com/');
        say Dumper $res;
        # {
        #   global_hash => "900913",
        #   hash => "ze6poY",
        #   long_url => "http://google.com/",
        #   new_hash => 0,
        #   url => "http://bit.ly/ze6poY"
        # }
    }
    catch {
        die("Oh, no! $_");
    };

=head1 DESCRIPTION

A Perl interface to the L<Bitly.com API|https://dev.bitly.com/api.html>.

You can either use the traditional (non-OO) interface provided by L<WWW::Shorten>.
Or, you can use the OO interface that provides you with more functionality.

=head1 FUNCTIONS

In the non-OO form, L<WWW::Shorten::Bitly> makes the following functions available.

=head2 makeashorterlink

    my $short_url = makeashorterlink('https://some_long_link.com');
    # OR
    my $short_url = makeashorterlink('https://some_long_link.com', {
        username => 'foo',
        password => 'bar',
        # any other attribute can be set as well.
    });

The function C<makeashorterlink> will call the L<http://bitly.com> web site,
passing it your long URL and will return the shorter version.

L<http://bitly.com> requires the use of a user id and API key to shorten links.

=head2 makealongerlink

    my $long_url = makealongerlink('http://bit.ly/ze6poY');
    # OR
    my $long_url = makealongerlink('http://bit.ly/ze6poY', {
        username => 'foo',
        password => 'bar',
        # any other attribute can be set as well.
    });

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full URL or just the identifier.

If anything goes wrong, either function will die.

=head1 ATTRIBUTES

In the OO form, each L<WWW::Shorten::Bitly> instance makes the following
attributes available. Please note that changing any attribute will unset the
L<WWW::Shorten::Bitly/access_token> attribute and effectively log you out.

=head2 access_token

    my $token = $bitly->access_token;
    $bitly = $bitly->access_token('some_access_token'); # method chaining

Gets or sets the C<access_token>. If the token is set, then we won't try to login.
You can set this ahead of time if you like, or it will be set on the first method
call or on L<WWW::Shorten::Bitly/login>.

=head2 client_id

    my $id = $bitly->client_id;
    $bitly = $bitly->client_id('some_client_id'); # method chaining

Gets or sets the C<client_id>. This is used in the
L<Resource Owner Credentials Grants|https://dev.bitly.com/authentication.html#resource_owner_credentials>
login method along with the L<WWW::Shorten::Bitly/client_secret> attribute.

=head2 client_secret

    my $secret = $bitly->client_secret;
    $bitly = $bitly->client_secret('some_secret'); # method chaining

Gets or sets the C<client_secret>. This is used in the
L<Resource Owner Credentials Grants|https://dev.bitly.com/authentication.html#resource_owner_credentials>
login method along with the L<WWW::Shorten::Bitly/client_id> attribute.

=head2 password

    my $password = $bitly->password;
    $bitly = $bitly->password('some_secret'); # method chaining

Gets or sets the C<password>. This is used in both the
L<Resource Owner Credentials Grants|https://dev.bitly.com/authentication.html#resource_owner_credentials>
and the
L<HTTP Basic Authentication|https://dev.bitly.com/authentication.html#basicauth>
login methods.

=head2 username

    my $username = $bitly->username;
    $bitly = $bitly->username('my_username'); # method chaining

Gets or sets the C<username>. This is used in both the
L<Resource Owner Credentials Grants|https://dev.bitly.com/authentication.html#resource_owner_credentials>
and the
L<HTTP Basic Authentication|https://dev.bitly.com/authentication.html#basicauth>
login methods.

=head1 METHODS

In the OO form, L<WWW::Shorten::Bitly> makes the following methods available.

=head2 new

    my $bitly = WWW::Shorten::Bitly->new(
        access_token => 'sometokenIalreadyreceived24123123512451',
        client_id => 'some id here',
        client_secret => 'some super secret thing',
        password => 'my password',
        username => 'my_username@foobar.com'
    );

The constructor can take any of the attributes above as parameters. If you've
logged in using some other form (OAuth2, etc.) then all you need to do is provide
the C<access_token>.

Any or all of the attributes can be set in your configuration file. If you have
a configuration file and you pass parameters to C<new>, the parameters passed
in will take precedence.

=head2 bitly_pro_domain

    my $bpd = $bitly->bitly_pro_domain(domain => 'http://nyti.ms');
    say Dumper $bpd;

    my $bpd2 = $bitly->bitly_pro_domain(domain => 'http://example.com');
    say Dumper $bpd2;

Query whether a given domain is a valid
L<Bitly pro domain| https://dev.bitly.com/domains.html#v3_bitly_pro_domain>.
Returns a hash reference with the information or dies on error.

=head2 clicks

    my $clicks = $bitly->clicks(
        link => "http://bit.ly/1RmnUT",
        unit => 'day',
        units => -1,
        timezone => 'America/New_York',
        rollup => 'false', # or 'true'
        limit => 100, # from 1 to 1000
        unit_reference_ts => 'now', # epoch timestamp
    );
    say Dumper $clicks;

Get the number of L<clicks|https://dev.bitly.com/link_metrics.html#v3_link_clicks> on a
single link. Returns a hash reference of information or dies.

=head2 clicks_by_day

    my $clicks = $bitly->clicks_by_day(
        link => "http://bit.ly/1RmnUT",
        timezone => 'America/New_York',
        rollup => 'false', # or 'true'
        limit => 100, # from 1 to 1000
        unit_reference_ts => 'now', # epoch timestamp
    );
    say Dumper $clicks;

This call used to exist, but now is merely an alias to the L<WWW::Shorten::Bitly/clicks>
method that hard-sets the C<unit> to C<'day'> and the C<units> to C<7>.
Returns a hash reference of information or dies.

=head2 countries

    my $countries = $bitly->countries(
        unit => 'day',
        units => -1,
        timezone => 'America/New_York',
        rollup => 'false', # or 'true'
        limit => 100, # from 1 to 1000
        unit_reference_ts => 'now', # epoch timestamp
    );
    say Dumper $countries;

Returns a hash reference of aggregate metrics about the
L<countries referring click traffic|https://dev.bitly.com/user_metrics.html#v3_user_countries>
to all of the authenticated user's links. Dies on failure.

=head2 expand

    my $long = $bitly->expand(
        shortUrl => "http://bit.ly/1RmnUT", # OR
        hash => '1RmnUT', # or: 'custom-name'
    );
    say $long->{long_url};

Expand a URL using L<https://dev.bitly.com/links.html#v3_expand>. Older versions
of this library required you to pass a C<URL> parameter.  That parameter has
been aliased for your convenience.  However, we urge you to stick with the
parameters in the API.  Returns a hash reference or dies.

=head2 info

    my $info = $bitly->info(
        shortUrl => 'http://bitly.com/jmv6', # OR
        hash => 'jmv6',
        expand_user => 'false', # or 'true'
    );
    say Dumper $info;

Get info about a shorter URL using the L<info method call|https://dev.bitly.com/links.html#v3_info>.
This will return a hash reference full of information about the given short URL or
hash.  It will die on failure.

=head2 login

    use Try::Tiny qw(try catch);

    try {
        $bitly->login();
        say "yay, logged in!";
    }
    catch {
        warn "Crap! Our login failed! $_";
    };

This method will just return your object instance if your C<access_token> is already set.
Otherwise, it will make use of one of the two login methods depending on how
much information you've supplied. On success, the C<access_token> attribute will
be set and your instance will be returned (method-chaining). On failure, an
exception with relevant information will be thrown.

If you would prefer, you can use one of the other two
forms of logging in:

=over

=item *

L<Resource Owner Credentials Grants|https://dev.bitly.com/authentication.html#resource_owner_credentials>

=item *

L<HTTP Basic Authentication|https://dev.bitly.com/authentication.html#basicauth>

=back

These two forms require at least the C<username> and C<password> parameters.

=head2 lookup

    my $info = $bitly->lookup(url => "http://www.google.com/");
    say $info;

Use this L<lookup method call|https://dev.bitly.com/links.html#v3_link_lookup> to
query for a short URL based on a long URL. Returns a hash reference or dies.

=head2 referrers

    my $refs = $bitly->referrers(
        link => "http://bit.ly/1RmnUT",
        unit => 'day',
        units => -1,
        timezone => 'America/New_York',
        rollup => 'false', # or 'true'
        limit => 100, # from 1 to 1000
        unit_reference_ts => 'now', # epoch timestamp
    );
    say Dumper $refs;

Use the L<referrers API call|https://dev.bitly.com/link_metrics.html#v3_link_referrers>
to get metrics about the pages referring click traffic to a single short URL.
Returns a hash reference or dies.

=head2 shorten

    my $short = $bitly->shorten(
        longUrl => "http://www.example.com", # required.
        domain => 'bit.ly', # or: 'j.mp' or 'bitly.com'
    );
    say $short->{url};

Shorten a URL using L<https://dev.bitly.com/links.html#v3_shorten>. Older versions
of this library required you to pass a C<URL> parameter.  That parameter has
been aliased for your convenience.  However, we urge you to stick with the
parameters in the API.  Returns a hash reference or dies.

=head1 CONFIG FILES

C<$HOME/.bitly> or C<_bitly> on Windows Systems.

    username=username
    password=some_password_here
    client_id=foobarbaz
    client_secret=asdlfkjadslkgj34t34talkgjag

Set any or all L<WWW::Shorten::Bitly/ATTRIBUTES> in your config file in your
home directory. Each C<key=val> setting should be on its own line. If any
parameters are then passed to the L<WWW::Shorten::Bitly/new> constructor, those
parameter values will take precedence over these.

=head1 AUTHOR

Pankaj Jain <F<pjain@cpan.org>>

=head1 CONTRIBUTORS

=over

=item *

Chase Whitener <F<capoeirab@cpan.org>>

=item *

Joerg Meltzer <F<joerg@joergmeltzer.de>>

=item *

Mizar <F<mizar.jp@gmail.com>>

=item *

Peter Edwards <F<pedwards@cpan.org>>

=item *

Thai Thanh Nguyen <F<thai@thaiandhien.com>>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Pankaj Jain, All Rights Reserved L<http://blog.pjain.me>.

Copyright (c) 2009 Teknatus Solutions LLC, All Rights Reserved L<http://teknatus.com>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
