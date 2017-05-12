use strict;
use warnings;

package WWW::HKP;

# ABSTRACT: Interface to HTTP Keyserver Protocol (HKP)

use AnyEvent;
use AnyEvent::DNS;
use AnyEvent::HTTP qw(http_request);
use Carp;
use URI 1.60;
use URI::Escape 3.31;
use List::MoreUtils qw(natatime);
use URL::Encode qw(url_encode);
use Email::Address;

our $VERSION = '0.041';    # VERSION

sub new {
    my ( $class, %options ) = @_;

    my $uri = URI->new( $options{secure} ? 'https:' : 'http:' );
    $uri->host( $options{host} || 'localhost' );
    $uri->port( $options{port} || ( $options{secure} ? 443 : 11371 ) );

    my $ua = $AnyEvent::HTTP::USERAGENT;
    {
        local $_ = __PACKAGE__ . '/' . $VERSION;
        $ua =~ s{\)$}{ +$_)};
    }

    AE::log debug => "User-Agent: $ua";
    AE::log debug => "Host: $uri";

    my $self = {
        ua  => $ua,
        uri => $uri,
    };

    return bless $self => ( ref $class || $class );
}

sub discover {
    my ( $email, %options ) = @_;
    ($email) = Email::Address->parse($email)
      unless ref $email eq 'Email::Address';
    return unless $email;
    my $cv = AE::cv;
    AE::log debug => "srv query: _hkp._tcp." . $email->host;
    AnyEvent::DNS::srv 'hkp', 'tcp', $email->host, sub {
        foreach my $rr (@_) {
            my ( $prio, $weight, $port, $host ) = @$rr;
            AE::log debug =>
              "srv answer: $host:$port (prio $prio weight $weight)";
            my $hkp = __PACKAGE__->new(
                host   => $host,
                port   => $port,
                secure => ( $port == 443 ? 1 : 0 )
            );
            my $result =
              $hkp->query( index => $email->address, exact => 1, %options );
            $cv->send($result) if $result;
            AE::log debug => "no result, next...";
        }
        AE::log debug => "no success";
        $cv->send(undef);
    };
    $cv->recv;
}

sub _ua  { shift->{ua} }
sub _uri { shift->{uri} }

sub _get {
    my ( $self, %query ) = @_;
    $self->{error} = undef;
    $self->_uri->path('/pks/lookup');
    $self->_uri->query_form(%query);

    my $cv = AE::cv;
    AE::log debug => "GET " . $self->_uri;
    http_request(
        GET => $self->_uri,
        sub {
            my ( $body, $hdr ) = @_;
            if ( $hdr->{Status} ne '200' ) {
                $self->{error} = sprintf 'HTTP %d: %s', $hdr->{Status},
                  $hdr->{Reason};
                AE::log error => $self->{error};
                $cv->send;
            }
            else {
                $cv->send($body);
            }
        }
    );
    $cv->recv;
}

sub _x_www_form_urlencode {
    my $it = natatime 2 => @_;
    my @params;
    while ( my ( $key, $val ) = $it->() ) {
        next unless $key;
        $val ||= '';
        push @params => url_encode($key) . '=' . url_encode($val);
    }
    join '&' => @params;
}

sub _post {
    my ( $self, @query ) = @_;
    $self->{error} = undef;
    $self->_uri->path('/pks/add');
    my $body = _x_www_form_urlencode(@query);
    my $cv   = AE::cv;
    AE::log debug => "POST " . $self->_uri;
    http_request(
        POST    => $self->_uri,
        body    => $body,
        headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
        sub {
            my ( $body, $hdr ) = @_;
            if ( $hdr->{Status} ne '200' ) {
                $self->{error} = sprintf 'HTTP %d: %s', $hdr->{Status},
                  $hdr->{Reason};
                AE::log error => $self->{error};
                $cv->send;
            }
            else {
                $cv->send($body);
            }
        }
    );
    $cv->recv;
}

sub _parse_mr {
    my ( $self, $lines, $filter_ok ) = @_;
    my $keys = {};
    my $key;
    my ( $keyc, $keyn ) = ( 0, 0 );
    foreach my $line ( split /\r?\n/ => $lines ) {
        if ( $line =~ /^info:(\d+):(\d+)$/ ) {
            croak "unsupported hkp version: v$1" unless $1 == 1;
            $keyc = $2;
        }
        elsif ( $line =~
            /^pub:([0-9a-f]{8,40}):(\d*):(\d*):(\d*):(\d*):([der]*)$/i )
        {
            $key = $1;
            $keyn++;
            my ( $algo, $keylen, $created, $expires, $flags, $ok ) =
              ( $2, $3, $4, $5, $6, undef );
            $ok = (
                (
                         ( $created and $created > time )
                      or ( $expires and $expires < time )
                      or ( length $flags )
                ) ? 0 : 1
            );
            if ( $filter_ok and !$ok ) {
                $key = undef;
                next;
            }
            $keys->{$key} = {
                algo    => $algo,
                keylen  => $keylen,
                created => $created || undef,
                expires => $expires || undef,
                revoked => ( $flags =~ /r/ ? 1 : 0 ),
                expired => ( $flags =~ /e/ ? 1 : 0 ),
                deleted => ( $flags =~ /d/ ? 1 : 0 ),
                ok      => $ok,
                uids    => []
            };
        }
        elsif ( $line =~ /^uid:([^:]*):(\d*):(\d*):([der]*)$/i ) {
            next unless defined $key;
            my ( $uid, $created, $expires, $flags, $ok ) =
              ( $1, $2, $3, $4, undef );
            $ok = (
                (
                         ( $created and $created > time )
                      or ( $expires and $expires < time )
                      or ( length $flags )
                ) ? 0 : 1
            );
            next if $filter_ok and !$ok;
            push @{ $keys->{$key}->{uids} } => {
                uid     => uri_unescape($uid),
                created => $created || undef,
                expires => $expires || undef,
                revoked => ( $flags =~ /r/ ? 1 : 0 ),
                expired => ( $flags =~ /e/ ? 1 : 0 ),
                deleted => ( $flags =~ /d/ ? 1 : 0 ),
                ok      => $ok
            };
        }
        else {
            carp "unknown line: $line";
        }
    }
    carp "server said there where $keyc keys, but $keyn keys parsed"
      unless $keyc == $keyn;
    return $keys;
}

sub _filter_result {
    my ( $self, $result, $grep ) = @_;
    return unless $result;
    my $filtered = {};
    foreach my $keyid ( keys %$result ) {
        my @uids =
          map  { $_->[0] }
          grep { $grep->( $_->[1] ) }
          grep { defined $_->[1] }
          map  { [ $_, Email::Address->parse( $_->{uid} ) ] }
          @{ $result->{$keyid}->{uids} };
        next unless @uids;
        $filtered->{$keyid} = { %{ $result->{$keyid} }, uids => \@uids };
    }
    return $filtered;
}

sub query {
    my ( $self, $type, $search, %options ) = @_;

    if ( $type eq 'index' ) {
        my $message = $self->_get(
            op          => 'index',
            options     => 'mr',
            search      => $search,
            exact       => ( $options{exact} ? 'on' : 'off' ),
            fingerprint => ( $options{fingerprint} ? 'on' : 'off' ),
        );
        unless ( defined $message ) {
            return () if wantarray;
            return;
        }
        my $result = $self->_parse_mr( $message, $options{filter_ok} ? 1 : 0 );
        if ( $options{exact} ) {
            $result = $self->_filter_result( $result,
                sub { shift->address eq $search } );
        }
        if (wantarray) {
            return keys %$result;
        }
        else {
            return $result;
        }
    }

    elsif ( $type eq 'get' ) {
        if ( $search !~ /^0x/ ) {
            $search = '0x' . $search;
        }
        my $message =
          $self->_get( op => 'get', options => 'exact', search => $search );
        return unless defined $message;
        return $message;
    }

    else {
        confess "unknown query type '$type'";
    }
}

sub import_keys {
    my ( $self, $gnupg, @subjects ) = @_;
    confess "" unless ref $gnupg eq 'AnyEvent::GnuPG';
    map    { $gnupg->import_key($_) }
      grep { defined }
      map  { $self->query( get => $_ ) } map { keys %$_ } grep { defined } map {
        scalar $self->query(
            index       => $_,
            exact       => 1,
            filter_ok   => 1,
            fingerprint => 1
          )
      } @subjects;
}

sub submit {
    my ( $self, @keys ) = @_;
    return unless @keys;
    if ( ref $keys[0] eq 'AnyEvent::GnuPG' ) {
        my $gnupg = shift @keys;
        my $output;
        $gnupg->export_keys(
            armor => 1,
            ( @keys ? ( keys => \@keys ) : () ), output => \$output
        );
        return !!$self->_post( keytext => $output );
    }
    else {
        return !!$self->_post( map { ( keytext => $_ ) } @keys );
    }
}

sub error { shift->{error} }

1;

__END__

=pod

=head1 NAME

WWW::HKP - Interface to HTTP Keyserver Protocol (HKP)

=head1 VERSION

version 0.041

=head1 SYNOPSIS

    use WWW::HKP;
    
    my $hkp = WWW::HKP->new();
    
    $hkp->query(index => 'foo@bar.baz');
    $hkp->query(get => 'DEADBEEF');

=head1 DESCRIPTION

This module implements the IETF draft of the OpenPGP HTTP Keyserver Protocol.

More information about HKP is available at L<http://tools.ietf.org/html/draft-shaw-openpgp-hkp-00>.

=head1 METHODS

=head2 new([%options])

The C<new()> constructor method instantiates a new C<WWW::HKP> object. The following example shows available options and its default values.

	my $hkp = WWW::HKP->new(
		host => 'localhost',
		port => 11371,
		secure => 0, # if 1, use https on port 443
	);

In most cases you just need to set the I<host> parameter:

	my $hkp = WWW::HKP->new(host => 'pool.sks-keyservers.net');

=head2 query($type => $search [, %options ])

The C<query()> method implements both query operations of HKP: I<index> and I<get>

=head3 I<index> operation

    $hkp->query(index => 'foo@bar.baz');

The first parameter must be I<index>, the secondend parameter an email-address or key-id.

In scalar context, if any keys were found, a hashref is returned. Otherwise C<undef> is returned, an error message can be fetched with C<< $hkp->error() >>.

The returned hashref may look like this:

    {
		'DEADBEEF' => {
			'algo' => '1',
			'keylen' => '2048',
			'created' => '1253025510',
			'expires' => '1399901151',
			'deleted' => 0,
			'expired' => 0,
			'revoked' => 0,
			'ok' => 1,
			'uids' => [
				{
					'uid' => 'Lorem Ipsum (This is an example) <foo@bar.baz>'
					'created' => '1253025510',
					'expires' => '1399901151',
					'deleted' => 0,
					'expired' => 0,
					'revoked' => 0,
					'ok' => 1
				}
			]
		}
    }

The keys of the hashref are key-ids. The meaning of the hash keys in the second level:

=over

=item I<algo>

The algorithm of the key. The values are described in RFC 2440.

=item I<keylen>

The key length in bytes.

=item I<created>

Creation date of the key, in seconds since 1970-01-01 UTC.

=item I<expires>

Expiration date of the key.

=item I<deleted>, I<expired>, I<revoked>

Indication details, whether the key is deleted, expired or revoked. If the flag is that, the value is C<1>, otherwise C<0>.

=item I<ok>

The creation date and expiration date is checked against C<time()>. If it doesn't match or any of the flags above are set, I<ok> will be C<0>, otherwise C<1>.

=item I<uids>

A arrayref of user-ids.

=over

=item I<uid>

The user-id in common format. It can be parsed by L<Email::Address> for example.

=item I<created>, I<expires>, I<deleted>, I<expired>, I<revoked>, I<ok>

This fields have the same meaning as described above. The information is taken from the self-signature, if any. I<created> and I<expired> may be C<undef> if not available (e.g. empty string).

=back

=back

In list context, only the found key-ids are returned or an empty list if none.

=head4 Available options

=over

=item I<exact>

Set the I<exact> parameter to C<1> (or any expression that evaluates to true), if you want an exact match of your search expression.

=item I<filter_ok>

Set the I<filter_ok> parameter to C<1> (or any expression that evaluates to true), if you want only valid results. All keys or user IDs having I<ok>-parameter of C<0> are ignored.

    $hkp->query(index => 'foo@bar.baz', filter_ok => 1);

=item I<fingerprint>

Provide the pull fingerprint in key-id instead of the abbreviated form. Note that not every server supports this keyword.

=back

=head3 I<get> operation

    $hkp->query(get => 'DEADBEEF');

The operation returns the public key of specified key-id or undef, if not found. Any error messages can be fetched with C<< $hkp->error() >>.

=head3 unimplemented operations

A HKP server may implement various other operations. Unimplemented operation cause the module to die with a stack trace.

=head2 import_keys($gnupg, @search)

This methods imports keys to an L<AnyEvent::GnuPG> object. C<@search> is a list of email addresses to search for. The method imports all found and valid public keys to the keyring.

=head2 submit

Submit one or more ASCII-armored version of public keys to the server.

    $pubkey = "-----BEGIN PGP PUBLIC KEY BLOCK-----\n...";
    
    $hkp->submit($pubkey);
    
    @pubkeys = ($pubkey1, $pubkey2, ...);
    
    $hkp->submit(@pubkeys);

In case of success, C<1> is returned. Otherweise C<0> and an error message can be fetched from C<< $hkp->error() >>.

When the first parameter is an L<AnyEvent::GnuPG> object, then public keys from the keyring will be submitted to the keyserver. Further arguments restrict the public keys to be exported.

	# export and sumbit all public keys in the keyring
	$hkp->submit($gnupg);
	
	# export and submit only a subset
	$hkp->submit($gnupg, qw( foo@bar.net baz@baf.org ))

=head2 error

Returns last error message, if any.

    $hkp->error; # "404 Not found", for example.

=head1 FUNCTIONS

=head2 discover($email, %options)

Discover a corresponding HKP server via SRV lookup and query the server for public keys. C<%options> will be passed to in I<index> operation of the L</query> method.

When no server could be discovered, C<undef> will be returned.

	my $result = WWW::HKP::discover('foo@bar', fingerprint => 1);

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libwww-hkp-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
