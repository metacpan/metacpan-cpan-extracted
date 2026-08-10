use warnings;
use v5.42;

package Tie::Google::Sheets::Client 0.02 {

    # ABSTRACT: Low level client used internally by Tie::Google::Sheets

    use Carp qw( croak );
    use JSON::MaybeXS qw( decode_json encode_json );
    use HTTP::AnyUA;
    use URI;
    use URI::Escape qw( uri_escape );
    use Crypt::JWT qw( encode_jwt );
    use Ref::Util qw( is_ref is_plain_hashref is_plain_coderef );
    use Path::Tiny qw( path );

    our @CARP_NOT = qw( Tie::Google::Sheets Tie::Google::Sheets::Worksheet Class::Tiny::Object );

    use Class::Tiny qw( spreadsheet_id ua access_token service_account ), {
        token         => undef,
        token_expires => 0,
        batch_size    => undef,
        backoff_retry => undef,
        _pending      => sub { [] },
    };

    our $SLEEP = sub ($seconds) { sleep $seconds };

    use constant {
        API_BASE  => 'https://sheets.googleapis.com/v4/spreadsheets',
        TOKEN_URI => 'https://oauth2.googleapis.com/token',
        SCOPE     => 'https://www.googleapis.com/auth/spreadsheets',
    };

    sub BUILDARGS ($class, %args) {
        my $spreadsheet_id  = delete $args{spreadsheet_id};
        my $spreadsheet_url = delete $args{spreadsheet_url};
        if(!defined $spreadsheet_id && defined $spreadsheet_url) {
            ($spreadsheet_id) = $spreadsheet_url =~ m{/d/([a-zA-Z0-9_-]+)};
        }
        croak 'spreadsheet_id (or a recognizable spreadsheet_url) is required'
            unless defined $spreadsheet_id;

        my $service_account = delete $args{service_account};
        my $access_token    = delete $args{access_token};
        croak 'one of service_account or access_token is required'
            unless defined $service_account || defined $access_token;

        my $ua_arg     = delete $args{ua};
        my $any_ua_arg = delete $args{any_ua};
        croak 'only one of ua or any_ua may be given' if defined $ua_arg && defined $any_ua_arg;

        my $batch_size = delete $args{batch_size};
        croak 'batch_size must be a positive integer'
            if defined $batch_size && $batch_size !~ /\A[1-9][0-9]*\z/;

        my $backoff_retry = delete $args{backoff_retry};
        croak 'backoff_retry must be a positive integer'
            if defined $backoff_retry && $backoff_retry !~ /\A[1-9][0-9]*\z/;

        croak "unknown constructor argument(s): @{[ sort keys %args ]}" if %args;

        my $ua = $any_ua_arg // HTTP::AnyUA->new( ua => $ua_arg // do {
            require HTTP::Tiny;
            HTTP::Tiny->new
        });

        return {
            spreadsheet_id  => $spreadsheet_id,
            ua              => $ua,
            access_token    => $access_token,
            service_account => defined $service_account
                ? $class->_load_service_account($service_account)
                : undef,
            batch_size      => $batch_size,
            backoff_retry   => $backoff_retry,
        };
    }

    sub _load_service_account ($class, $val) {
        return $val if is_plain_hashref($val);
        croak 'service_account must be a hashref of the decoded key file, or a path to one'
            unless !is_ref($val) && path($val)->is_file;

        my $json;
        try { $json = path($val)->slurp_raw }
        catch ($e) { croak "unable to open service account key file $val: $!" }

        return decode_json($json);
    }

    sub _access_token ($self) {
        if(defined(my $token = $self->access_token)) {
            return is_plain_coderef($token) ? $token->() : $token;
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
            my $data;
            try {
                $data = decode_json $res->{content};
                $message = $data->{error}{message} if is_plain_hashref($data) && $data->{error}{message};
            } catch ($e) {
                warn "warning decoding JSON: $e";
            }
        }
        croak "Google Sheets API error ($res->{status}): $message";
    }

    sub _request ($self, $method, $url, %opts) {
        my %headers = ( authorization => 'Bearer ' . $self->_access_token, ( $opts{headers} // {} )->%* );
        my %http_opts = ( headers => \%headers );
        if(defined $opts{body}) {
            $headers{'content-type'} = 'application/json';
            $http_opts{content} = encode_json($opts{body});
        }

        my $attempts = ($self->backoff_retry // 0) + 1;
        my $res;
        for my $attempt (1 .. $attempts) {
            $res = $self->ua->request($method, $url, \%http_opts);
            last if $res->{success} || $res->{status} != 429 || $attempt == $attempts;
            $SLEEP->(2 ** ($attempt - 1));
        }
        $self->_croak_on_error($res);

        return undef unless length $res->{content};
        return decode_json($res->{content});
    }

    sub _url ($self, $segments = [], $action = undef, %query) {
        my $uri = URI->new(API_BASE);
        $uri->path_segments($uri->path_segments, $self->spreadsheet_id, $segments->@*);
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
        $self->flush;
        my $data = $self->_request('GET', $self->_url([], undef, fields => 'sheets.properties.title'));
        return [ map { $_->{properties}{title} } ( $data->{sheets} // [] )->@* ];
    }

    sub sheet_id_for_title ($self, $title) {
        $self->flush;
        my $data = $self->_request('GET', $self->_url([], undef, fields => 'sheets.properties'));
        for my $sheet (( $data->{sheets} // [] )->@*) {
            return $sheet->{properties}{sheetId} if $sheet->{properties}{title} eq $title;
        }
        return undef;
    }

    sub get_value ($self, $title, $a1) {
        $self->flush;
        my $data = $self->_request('GET', $self->_url([ 'values', $self->_quote_range($title, $a1) ]));
        my $row  = ($data->{values} // [])->[0] // [];
        return $row->[0];
    }

    sub get_formula ($self, $title, $a1) {
        $self->flush;
        my $data = $self->_request('GET',
            $self->_url([ 'values', $self->_quote_range($title, $a1) ], undef, valueRenderOption => 'FORMULA'));
        my $row = ($data->{values} // [])->[0] // [];
        return $row->[0];
    }

    sub update_value ($self, $title, $a1, $value) {
        my $range = $self->_quote_range($title, $a1);

        if($self->batch_size) {
            push $self->_pending->@*, { range => $range, majorDimension => 'ROWS', values => [[$value]] };
            $self->flush if $self->_pending->@* >= $self->batch_size;
        }
        else {
            $self->_request('PUT', $self->_url([ 'values', $range ], undef, valueInputOption => 'USER_ENTERED'),
                body => { range => $range, majorDimension => 'ROWS', values => [[$value]] },
            );
        }

        return;
    }

    sub flush ($self) {
        return unless $self->_pending->@*;

        my $data = $self->_pending;
        $self->_pending([]);

        $self->_request('POST', $self->_url([ 'values' ], ':batchUpdate'), body => {
            valueInputOption => 'USER_ENTERED',
            data             => $data,
        });

        return;
    }

    sub clear_value ($self, $title, $a1) {
        $self->clear_range($title, $a1);
        return;
    }

    sub clear_range ($self, $title, $a1 = undef) {
        $self->flush;
        $self->_request('POST', $self->_url([ 'values', $self->_quote_range($title, $a1) ], ':clear'), body => {});
        return;
    }

    sub get_all_values ($self, $title) {
        $self->flush;
        my $data = $self->_request('GET', $self->_url([ 'values', $self->_quote_range($title) ]));
        return $data->{values} // [];
    }

    sub get_all_formulas ($self, $title) {
        $self->flush;
        my $data = $self->_request('GET',
            $self->_url([ 'values', $self->_quote_range($title) ], undef, valueRenderOption => 'FORMULA'));
        return $data->{values} // [];
    }

    sub add_sheet ($self, $title) {
        $self->flush;
        $self->_request('POST', $self->_url([], ':batchUpdate'), body => {
            requests => [ { addSheet => { properties => { title => $title } } } ],
        });
        return;
    }

    sub delete_sheet ($self, $title) {
        $self->flush;
        my $sheet_id = $self->sheet_id_for_title($title);
        croak "no such worksheet: $title" unless defined $sheet_id;
        $self->_request('POST', $self->_url([], ':batchUpdate'), body => {
            requests => [ { deleteSheet => { sheetId => $sheet_id } } ],
        });
        return;
    }

    sub copy_worksheet ($self, $from_title, $to_title) {
        $self->flush;
        my $sheet_id = $self->sheet_id_for_title($from_title);
        croak "no such worksheet: $from_title" unless defined $sheet_id;
        $self->_request('POST', $self->_url([], ':batchUpdate'), body => {
            requests => [ { duplicateSheet => {
                sourceSheetId => $sheet_id,
                newSheetName  => $to_title,
            } } ],
        });
        return;
    }

    sub DEMOLISH ($self, $global_destruction) {
        return if $global_destruction;
        return unless $self->{_pending} && $self->{_pending}->@*;
        try {
            $self->flush;
        } catch ($e) {
            warn "warning flushing DEMOLISH: $e";
        }
        return;
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Google::Sheets::Client - Low level client used internally by Tie::Google::Sheets

=head1 VERSION

version 0.02

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

=head2 batch_size

The maximum number of pending cell writes accumulated by L</update_value>
before they are automatically flushed. C<undef> (the default) disables
batching: L</update_value> sends each write immediately.

=head2 backoff_retry

The maximum number of times an API request will be retried, with
exponential backoff, after being rate limited by Google (HTTP status 429).
C<undef> (the default) disables retrying: a rate limited request fails
immediately.

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

=head2 get_formula

 my $formula = $client->get_formula($title, $a1);

Returns the formula of the cell C<$a1> in worksheet C<$title>, as text (for
example C<"=SUM(A1:A10)">), or the same as L</get_value> if the cell
doesn't contain a formula.

=head2 update_value

 $client->update_value($title, $a1, $value);

Sets the value of the cell C<$a1> in worksheet C<$title>. If L</batch_size>
is set, the write is queued rather than sent immediately; see L</flush>.

=head2 flush

 $client->flush;

Sends any cell writes queued by L</update_value> as a single
C<values.batchUpdate> API call. A no-op if nothing is queued. Called
automatically before every other API request (so reads always see
previously queued writes), when the number of queued writes reaches
L</batch_size>, and when the client is garbage collected.

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

=head2 get_all_formulas

 my $rows = $client->get_all_formulas($title);

Like L</get_all_values>, but returns formulas (as text) instead of values,
for every cell in the used range of worksheet C<$title> that has one; cells
without a formula hold the same value L</get_all_values> would return.

=head2 add_sheet

 $client->add_sheet($title);

Adds a new, empty worksheet named C<$title>.

=head2 delete_sheet

 $client->delete_sheet($title);

Deletes the worksheet named C<$title>.

=head2 copy_worksheet

 $client->copy_worksheet($from_title, $to_title);

Copies the worksheet named C<$from_title> to a new worksheet named
C<$to_title>, including its formatting, data validation, and other
properties, not just its cell values.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
