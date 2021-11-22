package WWW::KeePassHttp;
use 5.012;  # //, strict, s//r
use warnings;

use MIME::Base64;
use Crypt::Mode::CBC;
use HTTP::Tiny;
use JSON;   # will use JSON::XS when available
use Time::HiRes qw/gettimeofday sleep/;
use MIME::Base64;
use Carp;
use WWW::KeePassHttp::Entry;

our $VERSION = '0.020';  # rrr.mmmsss : rrr is major revision; mmm is minor revision; sss is sub-revision (new feature path or bugfix); optionally use _sss instead, for alpha sub-releases

my $dumpfn;
BEGIN {
    $dumpfn = sub { JSON->new->utf8->pretty->encode($_[0]) } # hidden from podcheckers and external namespace
}

=pod

=head1 NAME

WWW::KeePassHttp - Interface with KeePass PasswordSafe through the KeePassHttp plugin

=head1 SYNOPSIS

    use WWW::KeePassHttp;

    my $kph = WWW::KeePassHttp->new(Key => $key);
    $kph->associate() unless $kph->test_associate();
    my @entries = @${ $kph->get_logins($search_string) };
    print $entry[0]->url;
    print $entry[0]->login;
    print $entry[0]->password;

=head1 DESCRIPTION

Interface with KeePass PasswordSafe through the KeePassHttp plugin.  Allows reading entries based on URL or TITLE, and creating a new entry as well.

=head2 REQUIREMENTS

You need to have KeePass (or compatible) on your system, with the KeePassHttp plugin installed.

=head1 INTERFACE

=head2 CONSTRUCTOR AND CONFIGURATION

=over

=item new

    my $kph = WWW::KeePassHttp->new( Key => $key, %options);
    my $kph = WWW::KeePassHttp->new( Key => $key, keep_alive => 0, %options);

Creates a new KeePassHttp connection, and sets up the AES encryption.

The C<Key =E<gt> $key> is required; pass in a string of 32 octets that
represent a 256-bit key value.  If you have your key as 64 hex nibbles,
then use C<$key = pack 'H*', $hexnibbles;> to convert it to the value.
If you have your key as a Base64 string, use
C<$key = decode_base64($base64string);> to convert it to the value.

There is also a C<keep_alive> option, which will tell the HTTP user
agent to keep the connection alive when the option is set to C<1> (or
when it's not specified); setting the option to a C<0> will disable
that feature of the user agent.

The C<%options> share the same name and purposes with the
configuration methods that follow, and can be individually specified in
the constructor as key/value pairs, or passing in an C<%options> hash.

=cut

sub new
{
    my ($class, %opts) = @_;
    my $self = bless {}, $class;

    # user agent and URL
    $opts{keep_alive} //= 1;                        # default to keep_alive
    $self->{ua} = HTTP::Tiny->new(keep_alive => $opts{keep_alive} );

    $self->{request_base} = $opts{request_base} // 'http://localhost';   # default to localhost
    $self->{request_port} = $opts{request_port} // 19455;               # default to 19455
    $self->{request_url} = $self->{request_base} . ':' . $self->{request_port};

    # encryption object
    $self->{cbc} = Crypt::Mode::CBC->new('AES');
    $self->{key} = $opts{Key};
    for($self->{key}) {
        croak "256-bit AES key is required" unless defined $_;
        last if length($_) == 32;   # a 32-octet string is assumed to be a valid key
        chomp;
        croak "256-bit AES key must be in octets, not hex nibbles"
            if /^(0x)?[[:xdigit:]]{64}$/;
        croak "256-bit AES key must be in octets, not in base64"
            if length($_) == 44;
        croak "Key not recognized as 256-bit AES";
    }
    $self->{key64} = encode_base64($self->{key}, '');

    # appid
    $self->{appid} = $opts{appid} // 'WWW::KeePassHttp';

    return $self;
}

=item appid

    %options = ( ...,  appid => 'name of your app', ... );
        or
    $kph->appid('name of your app');

Changes the appid, which is the name that is used to map your
application with the stored key in the KeePassHttp settings in
KeePass.

If not defined in the initial options or via this method,
the module will use a default appid of C<WWW::KeePassHttp>.

=cut

sub appid
{
    my ($self, $val) = @_;
    $self->{appid} = $val if defined $val;
    return $self->{appid};
}

=item request_base

    %options = ( ...,  request_base => 'localhost', ... );
        or
    $kph->request_base('127.0.0.1');

Changes the protocol and host: the KeePassHttp plugin defaults to C<http://localhost>, but can be configured differently, so you will need to make your object match your plugin settings.

=cut

sub request_base
{
    my ($self, $val) = @_;
    $self->{request_base} = $val if defined $val;
    $self->{request_url} = $self->{request_base} . ':' . $self->{request_port};
    return $self->{request_base};
}

=item request_port

    %options = ( ...,  request_port => 19455, ... );
        or
    $kph->request_port(19455);

Changes the port: the KeePassHttp plugin defaults to port 19455, but can be configured differently, so you will need to make your object match your plugin settings.

=cut

sub request_port
{
    my ($self, $val) = @_;
    $self->{request_port} = $val if defined $val;
    $self->{request_url} = $self->{request_base} . ':' . $self->{request_port};
    return $self->{request_port};
}

=back

=for comment END OF CONSTRUCTOR AND CONFIGURATION

=head2 USER INTERFACE

These methods implement the L<KeePassHttp plugin's commmunication protocol|https://github.com/pfn/keepasshttp/#a-little-deeper-into-protocol>, with one method for each RequestType.

=over

=item test_associate

    $kph->associate unless $kph->test_associate();

Sends the C<test-assocate> request to the KeePassHttp server,
which is used to see whether or not your application has been
associated with the KeePassHttp plugin or not.  Returns a true
value if your application is already associated, or a false
value otherwise.

=cut

sub test_associate
{
    my ($self, %args) = @_;
    my $content = $self->request('test-associate', %args);
    return $content->{Success};
}

=item associate

    $kph->associate unless $kph->test_associate();

Sends the C<assocate> request to the KeePassHttp server,
which is used to give your application's key to the KeePassHttp
plugin.

When this request is received, KeePass will pop up a dialog
asking for a name -- this name should match the C<appid> value
that you defined for the C<$kph> instance.  All requests sent
to the plugin will include this C<appid> so that KeePassHttp can
look up your application's key, so it must match exactly.
As per the C<KeePassHttp plugin docs|https://github.com/pfn/keepasshttp/>,
the server saves your application's key in the C<KeePassHttp Settings>
entry, in the B<Advanced E<gt> String Fields> with a name of
C<AES Key: XXXX>, where C<XXXX> is the name you type in the dialog
box (which needs to match your C<appid>).

B<Please note>: this C<associate> communication is insecure,
since KeePassHttp plugin is not using HTTPS.  Every other
communication between your application and the plugin uses the
key (which both your application and the plugin know) to
encrypt the critical data (usernames, passwords, titles, etc),
and is thus secure;
but the C<associate> interaction, because it happens before
the plugin has your key, by its nature cannot be encrypted by
that key, so it sends the encoded key I<unencrypted>.  If this
worries you, I suggest that you manually insert the key: do an
C<assocate> once with a dummy key, then manually overwrite the
encoded key that it stores with the encoded version of your real
key.  (This limitation is due to the design of the KeePassHttp
plugin and its protocol for the C<associate> command, not due
to the wrapper around that protocol that this module implements.)

=cut

sub associate
{
    my ($self, %args) = @_;
    my $content = $self->request('associate', Key64 => $self->{key64}, %args);
    croak ("Wrong ID: ", $dumpfn->( { wrong_id => $content } )) unless $self->{appid} eq ($content->{Id}//'<undef>');
    return $content;
}

=item get_logins

    my @entries = @${ $kph->get_logins($search_string) };
    print $entry[0]->url;
    print $entry[0]->login;
    print $entry[0]->password;

Sends the C<get-logins> request, which returns the Name,
Login, and Password for each of the matching entries.

C<$entries> is an array reference containing
L<WWW::KeePassHttp::Entry> objects, from which you can
extract the url/name, login, and password for each matched
entry.

The rules for the matching of the search string are defined in the
L<KeePassHttp plugin documentation|https://github.com/pfn/keepasshttp/>.
But, in brief, it will do a fuzzy match on the URL, and an exact match
on the entry title.  (The plugin was designed to be used for browser plugins
to request passwords for URLs from KeePass, hence its focus on URLs.)

=cut

sub get_logins
{
    my ($self, $search_term, %args) = @_;
    $args{Url} = $search_term;
    $args{SubmitUrl} = $self->{appid} unless exists $args{SubmitUrl};   # "SubmitUrl" is actually the name of the requestor; in the browser->keePassHttp interface, the requestor is the website requesting the password; but here, I am using it as the app identifier
    my $content = $self->request('get-logins', Url => $search_term, %args);
    return [] unless $content->{Count};
    my $entries = $content->{Entries};
    for my $entry ( @$entries ) {
        for my $k ( sort keys %$entry ) {
            $entry->{$k} = $self->{cbc}->decrypt( decode_base64($entry->{$k}), $self->{key}, decode_base64($content->{Nonce}));
        }
        $entry->{Url} = $entry->{Name};
        $entry = WWW::KeePassHttp::Entry->new( %$entry );
    }
    #$dumpfn->( { Entries => $entries } );
    return $entries;
}

=item get_logins_count

    my $count = $kph->get_logins_count($search_string);

Sends the C<get-logins> request, which returns a count of
the number of matches for the search string.

The rules for the matching of the search string are defined in the
L<KeePassHttp plugin documentation|https://github.com/pfn/keepasshttp/>.
But, in brief, it will do a fuzzy match on the URL, and an exact match
on the entry title.  (The plugin was designed to be used for browser plugins
to request passwords for URLs from KeePass, hence its focus on URLs.)

This method is useful when the fuzzy-URL-match might match a large
number of entries in the database; if after seeing this count, you
would rather refine your search instead of requesting that many entries,
this method enables knowing that right away, rather than after you
accidentally matched virtually every entry in your database by searching
for C<www>.

=cut

sub get_logins_count
{
    my ($self, $search_term, %args) = @_;
    $args{Url} = $search_term;
    $args{SubmitUrl} = $self->{appid} unless exists $args{SubmitUrl};   # "SubmitUrl" is actually the name of the requestor; in the browser->keePassHttp interface, the requestor is the website requesting the password; but here, I am using it as the app identifier
    my $content = $self->request('get-logins-count', Url => $search_term, %args);
    return $content->{Count};
}


=item set_login

    $kph->set_login( Login => $username, Url => $url_and_title, Password => $password );
    # or
    $kph->set_login( $entry );

Sends the C<set-login> request, which adds a new entry to your
KeePass database, in the "KeePassHttp Passwords" group (folder).

As far as I know, the plugin doesn't allow choosing a different group
for your entry.  The plugin uses the URL that you supply as both the
entry title and the URL field in that entry.  (Once again, the plugin
was designed around browser password needs, and thus is URL-focused).
I don't know if that's a deficiency in the plugin's implementation,
or just its documentation, or my interpretation of that documentation.

The arguments to the method define the C<Login> (username), C<Url> (for
entry title and URL field), and C<Password> (secret value) for the new
entry.  All three of those parameters are required by the protocol, and
thus by this method.  Alernately, you can just pass it a L<WWW::KeePassHttp::Entry>
object as the single argument.

If you would prefer not to give one or more of those parameters a value,
just pass an empty string.  You could afterword then manually access
your KeePass database and edit the entry yourself.

=cut

sub set_login
{
    my ($self, @rest) = @_;
    my %args = UNIVERSAL::isa($rest[0], 'WWW::KeePassHttp::Entry') ? (%{$rest[0]}) : (@rest);
    croak "set_login(): missing Login parameter" unless defined $args{Login};
    croak "set_login(): missing Url parameter" unless defined $args{Url};
    croak "set_login(): missing Password parameter" unless defined $args{Password};
    my $content = $self->request('set-login', %args);
    return $content->{Success};
}


=item request

    my $results = $kph->request( $type, %options );

This is the generic method for making a request of the
KeePassHttp plugin. In general, other methods should handle
most requests.  However, maybe a new method has been exposed
in the plugin but not yet implemented here, so you can use
this method for handling that.

The C<$type> indicates the RequestType, which include
C<test-associate>, C<associate>, C<get-logins>,
C<get-logins-count>, and C<set-login>.

This method automatically fills out the RequestType, TriggerUnlock, Id, Nonce, and Verifier parameters.  If your RequestType requires
any other parameters, add them to the C<%options>.

It then encodes the request into the JSON payload, and
sends that request to the KeePassHttp plugin, and gets the response,
decoding the JSON content back into a Perl hashref.  It verifies that
the response's Nonce and Verifier parameters are appropriate for the
communication channel, to make sure communications from the plugin
are properly encrypted.

Returns the hashref decoded from the JSON

=cut

sub request {
    my ($self, $type, %params) = @_;
    my ($iv, $nonce) = generate_nonce();

    #print STDERR "request($type):\n";

    # these are required in every request
    my %request = (
        RequestType => $type,
        TriggerUnlock => JSON::true, # was intended for TRUE to request that KeePass unlock, but that doesn't actually happen
        Id => $self->{appid},
        Nonce => $nonce,
        Verifier => encode_base64($self->{cbc}->encrypt($nonce, $self->{key}, $iv), ''),
    );

    # don't want to encrypt the key during an association request
    delete $params{Key};    # only allow Key64
    $request{Key} = delete $params{Key64} if( exists $params{Key64} );

    # encrypt all remaining parameter values
    while(my ($k,$v) = each %params) {
        $request{$k} = encode_base64($self->{cbc}->encrypt($v, $self->{key}, $iv), '');
    }
    #$dumpfn->({final_request => \%request});

    # send the request
    my $response = $self->{ua}->get($self->{request_url}, {content=> encode_json \%request});

    # error checking
    croak $dumpfn->( { request_error => $response } ) unless $response->{success};
    croak $dumpfn->( { no_json => $response } ) unless exists $response->{content};

    # get the JSON
    my $content = decode_json $response->{content};
    #$dumpfn->( { their_response => $response, their_content => $content } );

    # verification before returning the content -- if their verifier doesn't match their nonce,
    #   then we don't have secure communication
    #   Don't need to check on test-associate/associate if verifier is missing, because there can
    #   reasonably be no verifier on those (ie, when test-associate returns false, or when the associate fails)
    if(exists $content->{Verifier} or ($type ne 'test-associate' and $type ne 'associate')) {
        croak $dumpfn->(  { missing_verifier => $content } ) unless exists $content->{Nonce} and exists $content->{Verifier};
        my $their_iv = decode_base64($content->{Nonce});
        my $decode_their_verifier = $self->{cbc}->decrypt( decode_base64($content->{Verifier}), $self->{key}, $their_iv );
        if( $decode_their_verifier ne $content->{Nonce} ) {
            croak $dumpfn->( { "Decoded Verifier $decode_their_verifier" => $content } );
        }
    }

    # If it made it to here, it's safe to return the content
    return $content;
}

=back

=for comment END OF USER INTERFACE

=head2 HELPER METHODS

In general, most users won't need these.  But maybe I<you> will.

=over

=item generate_nonce

    my ($iv, $base64) = $kph->generate_nonce();

This is used by the L</request> method to generate the IV nonce
for communication.  I don't think you need to use it yourself, but
it's available to you, if you find a need for it.

The C<$iv> is the string of octets (the actual 128 IV nonce value).

The C<$base64> is the base64 representation of the C<$iv>.

=cut

sub generate_nonce
{
    # generate 10 bytes of random numbers, 2 bytes of microsecond time, and 4 bytes of seconds
    #   this gives randomness from two sources (rand and usecond),
    #   plus a deterministic counter that won't repeat for 2^31 seconds (almost 70 years)
    #   so as long as you aren't using the same key for 70 years, the nonce should be unique
    my $hex = '';
    $hex .= sprintf '%02X', rand(256) for 1..10;
    my ($s,$us) = gettimeofday();
    $hex .= sprintf '%04X%08X', $us&0xFFFF, $s&0xFFFFFFFF;
    my $iv = pack 'H*', $hex;
    my $nonce = encode_base64($iv, '');
    return wantarray ? ($iv, $nonce) : $iv;
}

=back

=for comment END OF HELPER METHODS


=head1 SEE ALSO

=over

=item * L<KeePass Plugins list|https://keepass.info/plugins.html>

=item * L<KeePassHttp Plugin home|https://github.com/pfn/keepasshttp/>

=item * L<WWW::KeePassRest> = A similar interface which uses the KeePassRest plugin to interface with KeePass

=back

=head1 ACKNOWLEDGEMENTS

Thank you to L<KeePass|https://keepass.info/> for providing a free
password manager with plugin capability.

Thank you to the L<KeePassHttp Plugin|https://github.com/pfn/keepasshttp/>
for providing a free and open source plugin which allows for easy
communication between an external application and the KeePass application,
enabling the existence of this module (and the ability for it to give
applications access to the passwords stored in KeePass).

This module and author are not affiliated with either KeePass or KeePassHttp
except as a user of those fine products.

=head1 TODO

The entries should be full-fledged objects, with method-based access to
the underlying Login, Url, and Password values.

=head1 AUTHOR

Peter C. Jones C<E<lt>petercj AT cpan DOT orgE<gt>>

Please report any bugs or feature requests
thru the repository's interface at L<https://github.com/pryrt/WWW-KeePassHttp/issues>.

=begin html

<a href="https://metacpan.org/pod/WWW::KeePassHttp"><img src="https://img.shields.io/cpan/v/WWW-KeePassHttp.svg?colorB=00CC00" alt="" title="metacpan"></a>
<a href="https://matrix.cpantesters.org/?dist=WWW-KeePassHttp"><img src="https://cpants.cpanauthors.org/dist/WWW-KeePassHttp.png" alt="" title="cpan testers"></a>
<a href="https://github.com/pryrt/WWW-KeePassHttp/releases"><img src="https://img.shields.io/github/release/pryrt/WWW-KeePassHttp.svg" alt="" title="github release"></a>
<a href="https://github.com/pryrt/WWW-KeePassHttp/issues"><img src="https://img.shields.io/github/issues/pryrt/WWW-KeePassHttp.svg" alt="" title="issues"></a>
<a href="https://coveralls.io/github/pryrt/WWW-KeePassHttp?branch=main"><img src="https://coveralls.io/repos/github/pryrt/WWW-KeePassHttp/badge.svg?branch=main" alt="Coverage Status" /></a>
<a href="https://github.com/pryrt/WWW-KeePassHttp/actions/"><img src="https://github.com/pryrt/WWW-KeePassHttp/actions/workflows/perl-ci.yml/badge.svg" alt="github perl-ci"></a>

=end html

=head1 COPYRIGHT

Copyright (C) 2021 Peter C. Jones

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
