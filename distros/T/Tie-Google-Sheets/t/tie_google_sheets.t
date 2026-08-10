use Test2::V0 -no_srand => 1;
use v5.42;
use lib 't/lib';
use Local::FakeSheetsUA;
use Tie::Google::Sheets;

sub build_doc (%extra) {
    my $mock = Local::FakeSheetsUA->new;
    tie my %doc, 'Tie::Google::Sheets',
        spreadsheet_id => 'test-spreadsheet',
        access_token   => 'fake-token',
        any_ua         => $mock,
        %extra;
    return (\%doc, $mock);
}

sub batch_update_calls ($mock) {
    return grep { $_->{url} =~ /values:batchUpdate\z/ } $mock->calls;
}

subtest 'cell read/write' => sub {
    my($doc) = build_doc();

    is $doc->{Sheet1}{A1}, undef, 'unset cell reads as undef';
    ok !exists $doc->{Sheet1}{A1}, 'unset cell does not exist';

    $doc->{Sheet1}{A1} = 'hello';
    is $doc->{Sheet1}{A1}, 'hello', 'cell round-trips';
    ok exists $doc->{Sheet1}{A1}, 'set cell exists';

    is delete $doc->{Sheet1}{A1}, 'hello', 'delete returns old value';
    is $doc->{Sheet1}{A1}, undef, 'cell is gone after delete';

    like dies { $doc->{Sheet1}{'not a cell'} }, qr/invalid cell reference/, 'bad cell reference croaks';
};

subtest 'get_formula / get_all_formulas' => sub {
    my($doc, $mock) = build_doc();
    my $client = tied(%$doc)->_client;

    $doc->{Sheet1}{A1} = 3;
    $doc->{Sheet1}{B1} = 4;
    $mock->{sheets}{Sheet1}{formulas}{C1} = '=A1+B1';
    $mock->{sheets}{Sheet1}{cells}{C1}    = 7;

    is $client->get_formula('Sheet1', 'C1'), '=A1+B1', 'get_formula returns the formula, not the computed value';
    is $client->get_formula('Sheet1', 'A1'), 3, 'get_formula falls back to the plain value for a non-formula cell';
    is $client->get_value('Sheet1', 'C1'), 7, 'get_value is unaffected, still returns the computed value';

    is $client->get_all_formulas('Sheet1'), [[3, 4, '=A1+B1']], 'get_all_formulas mixes formulas and plain values';
    is $client->get_all_values('Sheet1'), [[3, 4, 7]], 'get_all_values is unaffected';
};

subtest 'fetch_mode' => sub {
    my($doc, $mock) = build_doc();
    my $ws = tied(%{ $doc->{Sheet1} });

    is $ws->fetch_mode, 'value', 'fetch_mode defaults to value';

    $doc->{Sheet1}{A1} = 3;
    $doc->{Sheet1}{B1} = 4;
    $mock->{sheets}{Sheet1}{formulas}{C1} = '=A1+B1';
    $mock->{sheets}{Sheet1}{cells}{C1}    = 7;

    is $doc->{Sheet1}{C1}, 7, 'fetching a cell in value mode returns the computed value';

    is $ws->fetch_mode('formula'), 'formula', 'fetch_mode returns the new mode when setting';
    is $doc->{Sheet1}{C1}, '=A1+B1', 'fetching a cell in formula mode returns the formula';
    is $doc->{Sheet1}{A1}, 3, 'a non-formula cell still returns its plain value in formula mode';

    is [ sort keys %{ $doc->{Sheet1} } ], [qw( A1 B1 C1 )], 'iteration keys are unaffected by fetch_mode';
    is [ sort values %{ $doc->{Sheet1} } ], ['3', '4', '=A1+B1'], 'iterating values honors fetch_mode too';

    is delete $doc->{Sheet1}{C1}, '=A1+B1', 'delete returns the formula in formula mode';

    $ws->fetch_mode('value');
    is $ws->fetch_mode, 'value', 'fetch_mode can be switched back to value';

    like dies { $ws->fetch_mode('bogus') }, qr/fetch_mode must be 'value' or 'formula'/, 'invalid fetch_mode croaks';
};

subtest 'worksheet iteration' => sub {
    my($doc) = build_doc();

    $doc->{Sheet1}{A1} = 'x';
    $doc->{Sheet1}{B2} = 'y';

    is [ sort keys %{ $doc->{Sheet1} } ], [qw( A1 B2 )], 'keys lists populated cells';

    %{ $doc->{Sheet1} } = ();
    is [ keys %{ $doc->{Sheet1} } ], [], 'CLEAR on a worksheet empties it';
};

subtest 'FETCH on a missing worksheet' => sub {
    my($doc) = build_doc();

    is $doc->{NoSuchSheet}, undef, 'fetching an unknown worksheet directly returns undef';
    is tied(%$doc)->FETCH('NoSuchSheet'), undef, 'FETCH returns undef for an unknown worksheet';
    is $doc->{Sheet1}, D(), 'fetching an existing worksheet still returns something defined';
};

subtest 'worksheet management' => sub {
    my($doc, $mock) = build_doc();

    is [ keys %$doc ], ['Sheet1'], 'starts with one worksheet';
    ok exists $doc->{Sheet1}, 'Sheet1 exists';
    ok !exists $doc->{NoSuchSheet}, 'unknown worksheet does not exist';

    tied(%$doc)->add_worksheet('Report', { A1 => 'Total', B1 => 42 });
    ok exists $doc->{Report}, 'add_worksheet creates the worksheet';
    is $doc->{Report}{A1}, 'Total', 'add_worksheet populates cells (A1)';
    is $doc->{Report}{B1}, 42, 'add_worksheet populates cells (B1)';

    $doc->{Extra} = { A1 => 'direct-store' };
    is $doc->{Extra}{A1}, 'direct-store', 'assigning a hashref to a new key creates + populates a worksheet';

    like dies { $doc->{Sheet1} = { A1 => 'nope' } }, qr/already exists/, 'assigning over an existing worksheet croaks';

    delete $doc->{Report};
    ok !exists $doc->{Report}, 'delete removes the worksheet';

    is [ sort keys %$doc ], [qw( Extra Sheet1 )], 'final worksheet list';

    like dies { %$doc = () }, qr/cannot delete every worksheet/, 'clearing the document croaks';
};

subtest 'worksheet copying' => sub {
    my($doc, $mock) = build_doc();

    $doc->{Sheet1}{A1} = 'hello';

    my $copy = tied(%$doc)->copy_worksheet('Sheet1', 'Sheet1 Copy');
    ok exists $doc->{'Sheet1 Copy'}, 'copy_worksheet creates the destination worksheet';
    is $copy->{A1}, 'hello', 'copy_worksheet returns the new worksheet, with the source data copied';
    is $doc->{'Sheet1 Copy'}{A1}, 'hello', 'copied cell is visible via the tied hash too';

    is $doc->{Sheet1}{A1}, 'hello', 'source worksheet is unaffected';

    like dies { tied(%$doc)->copy_worksheet('NoSuchSheet', 'Whatever') },
        qr/no such worksheet/, 'copying an unknown source worksheet croaks';

    like dies { tied(%$doc)->copy_worksheet('Sheet1', 'Sheet1 Copy') },
        qr/already exists/, 'copying onto an existing destination worksheet croaks';
};

subtest 'write batching' => sub {
    my($doc, $mock) = build_doc(batch_size => 2);

    $doc->{Sheet1}{A1} = 'x';
    is [ grep { $_->{method} eq 'PUT' } $mock->calls ], [], 'queued write is not sent immediately';
    is [ batch_update_calls($mock) ], [], 'no flush yet below batch_size';

    $doc->{Sheet1}{B1} = 'y';
    is scalar(batch_update_calls($mock)), 1, 'reaching batch_size auto-flushes as a single call';
    is $doc->{Sheet1}{A1}, 'x', 'first batched write is visible after auto-flush';
    is $doc->{Sheet1}{B1}, 'y', 'second batched write is visible after auto-flush';

    $doc->{Sheet1}{C1} = 'z';
    is $doc->{Sheet1}{C1}, 'z', 'reading a queued cell flushes it first';
    is scalar(batch_update_calls($mock)), 2, 'the read triggered a flush';

    $doc->{Sheet1}{D1} = 'w';
    tied(%$doc)->flush;
    is scalar(batch_update_calls($mock)), 3, 'explicit flush sends the queued write';
    is $doc->{Sheet1}{D1}, 'w', 'explicitly flushed write round-trips';

    tied(%$doc)->flush;
    is scalar(batch_update_calls($mock)), 3, 'flushing with nothing queued is a no-op';

    $doc->{Sheet1}{E1} = 'v';
    tied(%$doc)->add_worksheet('Extra');
    is scalar(batch_update_calls($mock)), 4, 'adding a worksheet flushes pending writes first';
    is $doc->{Sheet1}{E1}, 'v', 'write queued before add_worksheet still applied';
};

subtest 'write batching flushes when the document falls out of scope' => sub {
    my $mock = Local::FakeSheetsUA->new;
    {
        tie my %doc, 'Tie::Google::Sheets',
            spreadsheet_id => 'test-spreadsheet',
            access_token   => 'fake-token',
            any_ua         => $mock,
            batch_size     => 10;
        $doc{Sheet1}{A1} = 'scoped';
    }
    is scalar(batch_update_calls($mock)), 1, 'pending write is flushed once the tied document is destroyed';
};

subtest 'batch_size validation' => sub {
    my $mock = Local::FakeSheetsUA->new;
    like dies {
        tie my %doc, 'Tie::Google::Sheets',
            spreadsheet_id => 'test-spreadsheet',
            access_token   => 'fake-token',
            any_ua         => $mock,
            batch_size     => 0;
    }, qr/batch_size must be a positive integer/, 'batch_size of 0 croaks';

    like dies {
        tie my %doc, 'Tie::Google::Sheets',
            spreadsheet_id => 'test-spreadsheet',
            access_token   => 'fake-token',
            any_ua         => $mock,
            batch_size     => -1;
    }, qr/batch_size must be a positive integer/, 'negative batch_size croaks';
};

subtest 'API error propagation' => sub {
    my($doc, $mock) = build_doc();

    $mock->fail_next(403, 'The caller does not have permission');
    like dies { $doc->{Sheet1}{A1} }, qr/403.*permission/i, 'API error is surfaced with status and message';
};

subtest 'backoff_retry' => sub {
    my @slept;
    local $Tie::Google::Sheets::Client::SLEEP = sub ($seconds) { push @slept, $seconds };

    subtest 'succeeds after transient rate limiting' => sub {
        @slept = ();
        my($doc, $mock) = build_doc(backoff_retry => 3);

        $mock->fail_next(429, 'Rate limit exceeded', 2);
        is $doc->{Sheet1}{A1}, undef, 'request succeeds once retries exhaust the rate limiting';
        is \@slept, [1, 2], 'backed off twice, doubling each time, before succeeding';
    };

    subtest 'croaks once retries are exhausted' => sub {
        @slept = ();
        my($doc, $mock) = build_doc(backoff_retry => 2);

        $mock->fail_next(429, 'Rate limit exceeded', 100);
        like dies { $doc->{Sheet1}{A1} }, qr/429.*Rate limit exceeded/, 'still croaks after exhausting retries';
        is \@slept, [1, 2], 'backed off for every retry, then gave up';
    };

    subtest 'without backoff_retry, rate limiting fails immediately' => sub {
        @slept = ();
        my($doc, $mock) = build_doc();

        $mock->fail_next(429, 'Rate limit exceeded', 100);
        like dies { $doc->{Sheet1}{A1} }, qr/429.*Rate limit exceeded/, 'croaks on the first rate limited response';
        is \@slept, [], 'never backed off';
    };

    subtest 'non-rate-limit errors are not retried' => sub {
        @slept = ();
        my($doc, $mock) = build_doc(backoff_retry => 3);

        $mock->fail_next(403, 'The caller does not have permission', 100);
        like dies { $doc->{Sheet1}{A1} }, qr/403.*permission/i, 'croaks immediately on a non-429 error';
        is \@slept, [], 'never backed off';
    };
};

done_testing;
