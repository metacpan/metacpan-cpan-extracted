use warnings;
use v5.42;

package Tie::Google::Sheets::Client 0.01 {

    # ABSTRACT: Low level client used internally by Tie::Google::Sheets

    use Carp qw( croak );
    use JSON::MaybeXS qw( decode_json encode_json );
    use HTTP::AnyUA;
    use URI;
    use URI::Escape qw( uri_escape );
    use Crypt::JWT qw( encode_jwt );
    use Class::Tiny qw( spreadsheet_id ua access_token service_account ), {
        token         => undef,
        token_expires => 0,
    };

    use constant {
        API_BASE  => 'https://sheets.googleapis.com/v4/spreadsheets',
        TOKEN_URI => 'https://oauth2.googleapis.com/token',
        SCOPE     => 'https://www.googleapis.com/auth/spreadsheets',
    };

    sub BUILDARGS ($class, %args) {
        my $spreadsheet_id = $args{spreadsheet_id};
        if(!defined $spreadsheet_id && defined $args{spreadsheet_url}) {
            ($spreadsheet_id) = $args{spreadsheet_url} =~ m{/d/([a-zA-Z0-9_-]+)};
        }
        croak 'spreadsheet_id (or a recognizable spreadsheet_url) is required'
            unless defined $spreadsheet_id;

        croak 'one of service_account or access_token is required'
            unless defined $args{service_account} || defined $args{access_token};

        croak 'only one of ua or any_ua may be given' if defined $args{ua} && defined $args{any_ua};

        my $ua = $args{any_ua} // HTTP::AnyUA->new( ua => $args{ua} // do {
            require HTTP::Tiny;
            HTTP::Tiny->new
        });

        return {
            spreadsheet_id  => $spreadsheet_id,
            ua              => $ua,
            access_token    => $args{access_token},
            service_account => defined $args{service_account}
                ? $class->_load_service_account($args{service_account})
                : undef,
        };
    }

    sub _load_service_account ($class, $val) {
        return $val if ref($val) eq 'HASH';
        croak 'service_account must be a hashref of the decoded key file, or a path to one'
            unless !ref($val) && -f $val;
        open my $fh, '<:raw', $val
            or croak "unable to open service account key file $val: $!";
        my $json = do { local $/; <$fh> };
        close $fh;
        return decode_json($json);
    }

    sub _access_token ($self) {
        if(defined(my $token = $self->access_token)) {
            return ref($token) eq 'CODE' ? $token->() : $token;
        }

        return $self->token if $self->token && time() < $self->token_expires - 30;

        my $sa  = $self->service_account;
        my $now = time();
        my $jwt = encode_jwt(
            payload => {
                iss   => $sa->{client_email},
                scope => SCOPE,
                aud   => $sa->{token_uri} // TOKEN_URI,
                iat   => $now,
                exp   => $now + 3600,
            },
            key => \$sa->{private_key},
            alg => 'RS256',
        );

        my $body = join '&',
            'grant_type=' . uri_escape('urn:ietf:params:oauth:grant-type:jwt-bearer'),
            'assertion=' . uri_escape($jwt);

        my $res = $self->ua->request( 'POST', $sa->{token_uri} // TOKEN_URI, {
            headers => { 'content-type' => 'application/x-www-form-urlencoded' },
            content => $body,
        });
        $self->_croak_on_error($res);

        my $data = decode_json($res->{content});
        $self->token($data->{access_token});
        $self->token_expires($now + ($data->{expires_in} // 3600));

        return $self->token;
    }

    sub _croak_on_error ($self, $res) {
        return if $res->{success};

        my $message = $res->{reason} // 'unknown error';
        if($res->{content}) {
            my $data = eval { decode_json($res->{content}) };
            $message = $data->{error}{message} if ref($data) eq 'HASH' && $data->{error}{message};
        }
        croak "Google Sheets API error ($res->{status}): $message";
    }

    sub _request ($self, $method, $url, %opts) {
        my %headers = ( authorization => 'Bearer ' . $self->_access_token, %{ $opts{headers} // {} } );
        my %http_opts = ( headers => \%headers );
        if(defined $opts{body}) {
            $headers{'content-type'} = 'application/json';
            $http_opts{content} = encode_json($opts{body});
        }

        my $res = $self->ua->request($method, $url, \%http_opts);
        $self->_croak_on_error($res);

        return undef unless length $res->{content};
        return decode_json($res->{content});
    }

    sub _url ($self, $segments = [], $action = undef, %query) {
        my $uri = URI->new(API_BASE);
        $uri->path_segments($uri->path_segments, $self->spreadsheet_id, @$segments);
        $uri->path($uri->path . $action) if defined $action;
        $uri->query_form(%query) if %query;
        return $uri;
    }

    sub _quote_range ($self, $title, $a1 = undef) {
        (my $quoted = $title) =~ s/'/''/g;
        my $range = "'$quoted'";
        $range .= "!$a1" if defined $a1;
        return $range;
    }

    sub sheet_titles ($self) {
        my $data = $self->_request('GET', $self->_url([], undef, fields => 'sheets.properties.title'));
        return [ map { $_->{properties}{title} } @{ $data->{sheets} // [] } ];
    }

    sub sheet_id_for_title ($self, $title) {
        my $data = $self->_request('GET', $self->_url([], undef, fields => 'sheets.properties'));
        for my $sheet (@{ $data->{sheets} // [] }) {
            return $sheet->{properties}{sheetId} if $sheet->{properties}{title} eq $title;
        }
        return undef;
    }

    sub get_value ($self, $title, $a1) {
        my $data = $self->_request('GET', $self->_url([ 'values', $self->_quote_range($title, $a1) ]));
        my $row  = ($data->{values} // [])->[0] // [];
        return $row->[0];
    }

    sub update_value ($self, $title, $a1, $value) {
        $self->_request('PUT', $self->_url([ 'values', $self->_quote_range($title, $a1) ], undef, valueInputOption => 'USER_ENTERED'),
            body => { range => $self->_quote_range($title, $a1), majorDimension => 'ROWS', values => [[$value]] },
        );
        return;
    }

    sub clear_value ($self, $title, $a1) {
        $self->clear_range($title, $a1);
        return;
    }

    sub clear_range ($self, $title, $a1 = undef) {
        $self->_request('POST', $self->_url([ 'values', $self->_quote_range($title, $a1) ], ':clear'), body => {});
        return;
    }

    sub get_all_values ($self, $title) {
        my $data = $self->_request('GET', $self->_url([ 'values', $self->_quote_range($title) ]));
        return $data->{values} // [];
    }

    sub add_sheet ($self, $title) {
        $self->_request('POST', $self->_url([], ':batchUpdate'), body => {
            requests => [ { addSheet => { properties => { title => $title } } } ],
        });
        return;
    }

    sub delete_sheet ($self, $title) {
        my $sheet_id = $self->sheet_id_for_title($title);
        croak "no such worksheet: $title" unless defined $sheet_id;
        $self->_request('POST', $self->_url([], ':batchUpdate'), body => {
            requests => [ { deleteSheet => { sheetId => $sheet_id } } ],
        });
        return;
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Google::Sheets::Client - Low level client used internally by Tie::Google::Sheets

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This is a low level class used internally by L<Tie::Google::Sheets> to talk to
the Google Sheets API. It is not part of the public interface and may change
without notice; do not use it directly.

=head1 ATTRIBUTES

=head2 spreadsheet_id

The id of the spreadsheet being accessed.

=head2 ua

The L<HTTP::AnyUA> instance used to make requests.

=head2 access_token

The OAuth2 bearer token (or code reference) given to L</new>, if any.

=head2 service_account

The decoded service account key, if a service account was given to
L</new>.

=head2 token

The most recently obtained OAuth2 access token, when authenticating via
L</service_account>.

=head2 token_expires

The epoch time at which L</token> expires.

=head1 CONSTRUCTOR

=head2 new

 my $client = Tie::Google::Sheets::Client->new(%options);

Constructor. C<%options> are the same as documented in
L<Tie::Google::Sheets/CONSTRUCTOR>.

=head1 METHODS

=head2 sheet_titles

 my $titles = $client->sheet_titles;

Returns an array reference of worksheet titles.

=head2 sheet_id_for_title

 my $sheet_id = $client->sheet_id_for_title($title);

Returns the numeric sheet id for the worksheet named C<$title>, or C<undef>
if there is no such worksheet.

=head2 get_value

 my $value = $client->get_value($title, $a1);

Returns the value of the cell C<$a1> (for example C<"A1">) in worksheet
C<$title>.

=head2 update_value

 $client->update_value($title, $a1, $value);

Sets the value of the cell C<$a1> in worksheet C<$title>.

=head2 clear_value

 $client->clear_value($title, $a1);

Clears the value of the cell C<$a1> in worksheet C<$title>.

=head2 clear_range

 $client->clear_range($title, $a1);
 $client->clear_range($title);

Clears the value of the cell C<$a1> in worksheet C<$title>, or, if C<$a1>
is omitted, clears every cell in the worksheet.

=head2 get_all_values

 my $rows = $client->get_all_values($title);

Returns an array reference of array references holding every value in the
used range of worksheet C<$title>.

=head2 add_sheet

 $client->add_sheet($title);

Adds a new, empty worksheet named C<$title>.

=head2 delete_sheet

 $client->delete_sheet($title);

Deletes the worksheet named C<$title>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
