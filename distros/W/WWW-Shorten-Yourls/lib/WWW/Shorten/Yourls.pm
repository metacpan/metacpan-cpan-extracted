package WWW::Shorten::Yourls;

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

our $VERSION = '1.001';
$VERSION = eval $VERSION;

our @EXPORT = qw(new);

# _attr (private)
sub _attr {
    my $self = shift;
    my $attr = lc(_trim(shift) || '');
    # attribute list is small enough to just grep each time. meh.
    Carp::croak("Invalid attribute") unless grep {$attr eq $_} @{_attrs()};
    return $self->{$attr} unless @_;

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
            qw(username password server signature),
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
    return $json;
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
        my $file = $^O eq 'MSWin32'? '_yourls': '.yourls';
        $file .= '_test' if $ENV{YOURLS_TEST_CONFIG};
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
                $key = 'server' if $key eq 'base';
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
        $lc_key = 'server' if $lc_key eq 'base';
        next unless grep {$lc_key eq $_} @{$attrs};
        $href->{$lc_key} = $args->{$key};
    }
    my $server = $href->{server} ? $href->{server} : 'https://yourls.org/yourls-api.php';
    my $self = bless $href, $class;
    return $self->server($server);
}

sub clicks {
    my $self = shift;
    Carp::croak("You must tell us which server to use.") unless my $server = $self->server();

    my $args = _parse_args(@_);
    my $short_url = $args->{shortUrl} || $args->{single_arg} || $args->{URL} || $args->{url} || '';
    Carp::croak("A shortUrl parameter is required.\n") unless $short_url;

    my $url = $server->clone();
    my $params = {
        shorturl => $short_url,
        format => 'json',
        action => 'url-stats',
    };
    if (my $sig = $self->signature()) {
        $params->{signature} = $sig;
    }
    else {
        my $user = $self->username();
        my $pass = $self->password();
        unless ($user && $pass) {
            Carp::croak("Username and password required when not using a signature");
        }
        $params->{username} = $user;
        $params->{password} = $pass;
    }
    $url->query_form(%$params);
    return _json_request($url);
}

sub expand {
    my $self = shift;
    Carp::croak("You must tell us which server to use.") unless my $server = $self->server();

    my $args = _parse_args(@_);
    my $short_url = $args->{shortUrl} || $args->{single_arg} || $args->{URL} || $args->{url} || '';
    Carp::croak("A shortUrl parameter is required.\n") unless $short_url;

    my $url = $server->clone();
    my $params = {
        shorturl => $short_url,
        format => 'json',
        action => 'expand',
    };
    if (my $sig = $self->signature()) {
        $params->{signature} = $sig;
    }
    else {
        my $user = $self->username();
        my $pass = $self->password();
        unless ($user && $pass) {
            Carp::croak("Username and password required when not using a signature");
        }
        $params->{username} = $user;
        $params->{password} = $pass;
    }
    $url->query_form(%$params);
    return _json_request($url);
}

sub makealongerlink {
    my $self;
    if ($_[0] && blessed($_[0]) && $_[0]->isa('WWW::Shorten::Yourls')) {
        $self = shift;
    }
    my $url = shift or Carp::croak('No URL passed to makealongerlink');
    $self ||= __PACKAGE__->new(@_);
    my $res = $self->expand(shortUrl=>$url);
    return '' unless ref($res) eq 'HASH' and $res->{longurl};
    return $res->{longurl};
}

sub makeashorterlink {
    my $self;
    if ($_[0] && blessed($_[0]) && $_[0]->isa('WWW::Shorten::Yourls')) {
        $self = shift;
    }
    my $url = shift or Carp::croak('No URL passed to makeashorterlink');
    $self ||= __PACKAGE__->new(@_);
    my $res = $self->shorten(longUrl=>$url, @_);
    return $res->{shorturl};
}

sub password { return shift->_attr('password', @_); }

sub server {
    my $self = shift;
    return $self->{server} unless @_;
    my $val = shift;
    if (!defined($val) || $val eq '') {
        $self->{server} = undef;
        return $self;
    }
    elsif (blessed($val) && $val->isa('URI')) {
        $self->{server} = $val->clone();
        return $self;
    }
    elsif ($val && !ref($val)) {
        $self->{server} = URI->new(_trim($val));
        return $self;
    }

    Carp::croak("The server attribute must be set to a URI object");
}

sub shorten {
    my $self = shift;
    Carp::croak("You must tell us which server to use.") unless my $server = $self->server();

    my $args = _parse_args(@_);
    my $long_url = $args->{longUrl} || $args->{single_arg} || $args->{URL} || $args->{url} || '';
    Carp::croak("A longUrl parameter is required.\n") unless $long_url;

    my $url = $server->clone();
    my $params = {
        url => $long_url,
        format => 'json',
        action => 'shorturl',
    };
    if (my $sig = $self->signature()) {
        $params->{signature} = $sig;
    }
    else {
        my $user = $self->username();
        my $pass = $self->password();
        unless ($user && $pass) {
            Carp::croak("Username and password required when not using a signature");
        }
        $params->{username} = $user;
        $params->{password} = $pass;
    }
    $url->query_form(%$params);
    return _json_request($url);
}

sub signature { return shift->_attr('signature', @_); }

sub username { return shift->_attr('username', @_); }

1;   # End of WWW::Shorten::Yourls

__END__

=head1 NAME

WWW::Shorten::Yourls - Interface to shortening URLs using L<http://yourls.org>

=head1 SYNOPSIS

The traditional way, using the L<WWW::Shorten> interface:

    use strict;
    use warnings;

    use WWW::Shorten::Yourls;
    # use WWW::Shorten 'Yourls';  # or, this way

    # if you have a config file with your credentials:
    my $short_url = makeashorterlink('http://www.foo.com/some/long/url');
    my $long_url  = makealongerlink($short_url);
    # otherwise
    my $short = makeashorterlink('http://www.foo.com/some/long/url', {
        username => 'username',
        password => 'password',
        server => 'https://yourls.org/yourls-api.php',
        ...
    });

Or, the Object-Oriented way:

    use strict;
    use warnings;
    use Data::Dumper;
    use Try::Tiny qw(try catch);
    use WWW::Shorten::Yourls;

    my $yourls = WWW::Shorten::Yourls->new(
        username => 'username',
        password => 'password',
        signature => 'adflkdga234252lgka',
        server => 'https://yourls.org/yourls-api.php', # default
    );
    try {
        my $res = $yourls->shorten(longUrl => 'http://google.com/');
        say Dumper $res;
        # {
        #    message => "http://google.com/ added to database",
        #    shorturl => "https://yourls.org/4",
        #    status => "success",
        #    statusCode => 200,
        #    title => "Google",
        #    url => {
        #        date => "2017-02-08 02:34:37",
        #        ip => "192.168.0.1",
        #        keyword => 4,
        #        title => "Google",
        #        url => "http://google.com/"
        #    }
        # }
    }
    catch {
        die("Oh, no! $_");
    };

=head1 DESCRIPTION

A Perl interface to the L<Yourls.org API|http://yourls.org/#API>.

You can either use the traditional (non-OO) interface provided by L<WWW::Shorten>.
Or, you can use the OO interface that provides you with more functionality.

=head1 FUNCTIONS

In the non-OO form, L<WWW::Shorten::Yourls> makes the following functions available.

=head2 makeashorterlink

    my $short_url = makeashorterlink('https://some_long_link.com');
    # OR
    my $short_url = makeashorterlink('https://some_long_link.com', {
        username => 'foo',
        password => 'bar',
        # any other attribute can be set as well.
    });

The function C<makeashorterlink> will call the L<Yourls Server|http://yourls.org> web site,
passing it your long URL and will return the shorter version.

L<http://yourls.org> requires the use of a user account to shorten links.

=head2 makealongerlink

    my $long_url = makealongerlink('http://yourls.org/22');
    # OR
    my $long_url = makealongerlink('http://yourls.org/22', {
        username => 'foo',
        password => 'bar',
        # any other attribute can be set as well.
    });

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full URL or just the identifier.

If anything goes wrong, either function will die.

=head1 ATTRIBUTES

In the OO form, each L<WWW::Shorten::Yourls> instance makes the following
attributes available.

=head2 password

    my $password = $yourls->password;
    $yourls = $yourls->password('some_secret'); # method chaining

Gets or sets the C<password>. This is used along with the
L<WWW::Shorten::Yourls/username> attribute.  Credentials are sent to the server
upon each and every request.

=head2 server

    my $server = $yourls->server;
    $yourls = $yourls->server(
        URI->new('https://yourls.org/yourls-api.php')
    ); # method chaining

Gets or sets the C<server>. This is full and absolute path to the server and
C<yourls-api.php> endpoint.

=head2 signature

    my $signature = $yourls->signature;
    $signature = $yourls->signature('abcdef123'); # method chaining

Gets or sets the C<signature>. If the C<signature> attribute is set, the
L<WWW::Shorten::Yourls/userna,e> and L<WWW::Shorten::Yourls/password> attributes
are ignored on each request and instead the C<signature> is sent.
See the L<Password-less API|https://github.com/YOURLS/YOURLS/wiki/PasswordlessAPI>
documentation for more details.

=head2 username

    my $username = $yourls->username;
    $yourls = $yourls->username('my_username'); # method chaining

Gets or sets the C<username>. This is used along with the
L<WWW::Shorten::Yourls/password> attribute.  Credentials are sent to the server
upon each and every request.

=head1 METHODS

In the OO form, L<WWW::Shorten::Yourls> makes the following methods available.

=head2 new

    my $yourls = WWW::Shorten::Yourls->new(
        username => 'username',
        password => 'password',
        signature => 'adflkdga234252lgka',
        server => 'https://yourls.org/yourls-api.php', # default
    );

The constructor can take any of the attributes above as parameters.

Any or all of the attributes can be set in your configuration file. If you have
a configuration file and you pass parameters to C<new>, the parameters passed
in will take precedence.

=head2 clicks

    my $clicks = $yourls->clicks(shorturl => "https://yourls.org/5");
    say Dumper $clicks;
    # {
    #    link => {
    #        clicks => 0,
    #        ip => "192.168.0.1",
    #        shorturl => "http://yourls.org/5",
    #        timestamp => "2017-02-08 02:37:24",
    #        title => "Google",
    #        url => "http://www.google.com"
    #    },
    #    message => "success",
    #    statusCode => 200
    # }

Get the C<url-stats> or number of C<clicks> for a given URL made shorter using
the L<Yourls API|http://yourls.org/#API>.
Returns a hash reference or dies. Make use of L<Try::Tiny>.

=head2 expand

    my $long = $yourls->expand(shorturl => "https://yourls.org/5");
    say $long->{longurl};
    # http://www.google.com
    say Dumper $long;
    # {
    #    keyword => 4,
    #    longurl => "http://www.google.com",
    #    message => "success",
    #    shorturl => "http://jupiter/yourls/5",
    #    statusCode => 200,
    #    title => "Google"
    # }

Expand a URL using the L<Yourls API|http://yourls.org/#API>.
Returns a hash reference or dies. Make use of L<Try::Tiny>.

=head2 shorten

    my $short = $yourls->shorten(
        url => "http://google.com/", # required.
    );
    say $short->{shorturl};
    # https://yourls.org/4
    say Dumper $short;
    # {
    #    message => "http://google.com/ added to database",
    #    shorturl => "https://yourls.org/4",
    #    status => "success",
    #    statusCode => 200,
    #    title => "Google",
    #    url => {
    #        date => "2017-02-08 02:34:37",
    #        ip => "192.168.0.1",
    #        keyword => 4,
    #        title => "Google",
    #        url => "http://google.com/"
    #    }
    # }

Shorten a URL using the L<Yourls API|http://yourls.org/#API>.
Returns a hash reference or dies. Make use of L<Try::Tiny>.

=head1 CONFIG FILES

C<$HOME/.yourls> or C<_yourls> on Windows Systems.

You may omit C<username> and C<password> in the constructor if you set them in the
C<.yourls> config file on separate lines using the syntax:

  username=username
  password=password
  server=https://yourls.org/yourls-api.php
  signature=foobarbaz123

Set any or all L<WWW::Shorten::Yourls/ATTRIBUTES> in your config file in your
home directory. Each C<key=val> setting should be on its own line. If any
parameters are then passed to the L<WWW::Shorten::Yourls/new> constructor, those
parameter values will take precedence over these.

=head1 AUTHOR

Pankaj Jain, <F<pjain@cpan.org>>

=head1 CONTRIBUTORS

=over

=item *

Chase Whitener <F<capoeirab@cpan.org>>

=item *

Michiel Beijen <F<michielb@cpan.org>>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Pankaj Jain, All Rights Reserved L<http://blog.linosx.com>.

Copyright (c) 2009 Teknatus Solutions LLC, All Rights Reserved L<http://www.teknatus.com>.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
