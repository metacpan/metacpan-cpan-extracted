use warnings;
use v5.42;

package Local::FakeSheetsUA {

    # ABSTRACT: In memory fake of the Google Sheets + OAuth2 HTTP APIs for testing

    use JSON::MaybeXS qw( decode_json encode_json );
    use URI::Escape qw( uri_unescape );

    sub new ($class, %args) {
        return bless {
            id      => $args{spreadsheet_id} // 'test-spreadsheet',
            sheets  => { Sheet1 => { id => 0, cells => {} } },
            order   => ['Sheet1'],
            next_id => 1,
            calls   => [],
            fail    => undef,
        }, $class;
    }

    sub calls ($self) { return @{ $self->{calls} } }

    sub fail_next ($self, $status, $message) {
        $self->{fail} = { status => $status, message => $message };
        return;
    }

    sub request ($self, $method, $url, $opts = undef) {
        push @{ $self->{calls} }, { method => $method, url => $url, opts => $opts // {} };

        if(my $fail = delete $self->{fail}) {
            return $self->_json_response($fail->{status}, 0, { error => { message => $fail->{message} } });
        }

        return $self->_token_response if $url eq 'https://oauth2.googleapis.com/token';

        my($path) = split /\?/, $url, 2;
        $path =~ s{^https://sheets\.googleapis\.com/v4/spreadsheets/}{}
            or return $self->_json_response(404, 0, { error => { message => "unrecognized url $url" } });

        if($path =~ /\A([^:\/]+):batchUpdate\z/) {
            return $self->_batch_update($opts);
        }
        elsif($path =~ m{\A[^/]+/values/(.+):clear\z}) {
            return $self->_clear($1);
        }
        elsif($path =~ m{\A[^/]+/values/(.+)\z}) {
            my $range_enc = $1;
            return $method eq 'GET' ? $self->_get_values($range_enc) : $self->_update_values($range_enc, $opts);
        }
        elsif($path =~ m{\A[^/]+\z}) {
            return $self->_metadata;
        }

        return $self->_json_response(404, 0, { error => { message => "unrecognized url $url" } });
    }

    sub _token_response ($self) {
        return $self->_json_response(200, 1, { access_token => 'fake-service-account-token', expires_in => 3600, token_type => 'Bearer' });
    }

    sub _metadata ($self) {
        return $self->_json_response(200, 1, {
            sheets => [ map { +{ properties => { sheetId => $self->{sheets}{$_}{id}, title => $_ } } } @{ $self->{order} } ],
        });
    }

    sub _parse_range ($range_enc) {
        my $range = uri_unescape($range_enc);
        my($quoted_title, $a1) = $range =~ /\A'((?:[^']|'')*)'(?:!(.+))?\z/;
        (my $title = $quoted_title) =~ s/''/'/g;
        return ($title, $a1);
    }

    sub _get_values ($self, $range_enc) {
        my($title, $a1) = _parse_range($range_enc);
        return $self->_json_response(400, 0, { error => { message => "Unable to parse range: no such sheet $title" } })
            unless exists $self->{sheets}{$title};

        my $cells = $self->{sheets}{$title}{cells};

        if(defined $a1) {
            my $val = $cells->{ uc $a1 };
            return $self->_json_response(200, 1, defined($val) ? { values => [[$val]] } : {});
        }

        my($max_c, $max_r) = (0, 0);
        for my $key (keys %$cells) {
            my($c, $r) = _a1_to_rc($key);
            $max_c = $c if $c > $max_c;
            $max_r = $r if $r > $max_r;
        }
        my @grid;
        for my $r (1 .. $max_r) {
            push @grid, [ map { $cells->{ _rc_to_a1($_, $r) } // '' } 1 .. $max_c ];
        }
        return $self->_json_response(200, 1, @grid ? { values => \@grid } : {});
    }

    sub _update_values ($self, $range_enc, $opts) {
        my($title, $a1) = _parse_range($range_enc);
        return $self->_json_response(400, 0, { error => { message => "Unable to parse range: no such sheet $title" } })
            unless exists $self->{sheets}{$title};

        my $body  = decode_json($opts->{content});
        my $value = $body->{values}[0][0];
        $self->{sheets}{$title}{cells}{ uc $a1 } = $value;

        return $self->_json_response(200, 1, { spreadsheetId => $self->{id}, updatedRange => $range_enc });
    }

    sub _clear ($self, $range_enc) {
        my($title, $a1) = _parse_range($range_enc);
        return $self->_json_response(400, 0, { error => { message => "Unable to parse range: no such sheet $title" } })
            unless exists $self->{sheets}{$title};

        if(defined $a1) {
            delete $self->{sheets}{$title}{cells}{ uc $a1 };
        }
        else {
            $self->{sheets}{$title}{cells} = {};
        }

        return $self->_json_response(200, 1, { spreadsheetId => $self->{id}, clearedRange => $range_enc });
    }

    sub _batch_update ($self, $opts) {
        my $body = decode_json($opts->{content});

        for my $req (@{ $body->{requests} // [] }) {
            if(my $add = $req->{addSheet}) {
                my $title = $add->{properties}{title};
                return $self->_json_response(400, 0, { error => { message => "sheet already exists: $title" } })
                    if exists $self->{sheets}{$title};
                $self->{sheets}{$title} = { id => $self->{next_id}++, cells => {} };
                push @{ $self->{order} }, $title;
            }
            elsif(my $del = $req->{deleteSheet}) {
                my $sheet_id = $del->{sheetId};
                my($title) = grep { $self->{sheets}{$_}{id} == $sheet_id } @{ $self->{order} };
                return $self->_json_response(400, 0, { error => { message => "no such sheetId: $sheet_id" } })
                    unless defined $title;
                delete $self->{sheets}{$title};
                $self->{order} = [ grep { $_ ne $title } @{ $self->{order} } ];
            }
        }

        return $self->_json_response(200, 1, { spreadsheetId => $self->{id}, replies => [{}] });
    }

    sub _json_response ($self, $status, $success, $data) {
        return {
            success => !!$success,
            status  => $status,
            reason  => $success ? 'OK' : 'Error',
            content => encode_json($data),
            headers => {},
        };
    }

    sub _a1_to_rc ($a1) {
        my($letters, $row) = $a1 =~ /\A([A-Za-z]+)([0-9]+)\z/;
        my $col = 0;
        $col = $col * 26 + (ord(uc $_) - ord('A') + 1) for split //, $letters;
        return ($col, $row);
    }

    sub _rc_to_a1 ($col, $row) {
        my $letters = '';
        my $n = $col;
        while($n > 0) {
            my $rem = ($n - 1) % 26;
            $letters = chr(65 + $rem) . $letters;
            $n = int(($n - 1) / 26);
        }
        return "$letters$row";
    }

}

=head1 DESCRIPTION

Test-only fake of the Google Sheets and OAuth2 token HTTP APIs, implementing
the same C<request($method, $url, \%opts)> contract as L<HTTP::AnyUA>, for
use as the C<any_ua> constructor argument in tests.

=cut
