use Test2::V0 -no_srand => 1;
use v5.42;
use lib 't/lib';
use Local::FakeSheetsUA;
use Tie::Google::Sheets;

sub build_doc {
    my $mock = Local::FakeSheetsUA->new;
    tie my %doc, 'Tie::Google::Sheets',
        spreadsheet_id => 'test-spreadsheet',
        access_token   => 'fake-token',
        any_ua         => $mock;
    return (\%doc, $mock);
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

subtest 'worksheet iteration' => sub {
    my($doc) = build_doc();

    $doc->{Sheet1}{A1} = 'x';
    $doc->{Sheet1}{B2} = 'y';

    is [ sort keys %{ $doc->{Sheet1} } ], [qw( A1 B2 )], 'keys lists populated cells';

    %{ $doc->{Sheet1} } = ();
    is [ keys %{ $doc->{Sheet1} } ], [], 'CLEAR on a worksheet empties it';
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

subtest 'API error propagation' => sub {
    my($doc, $mock) = build_doc();

    $mock->fail_next(403, 'The caller does not have permission');
    like dies { $doc->{Sheet1}{A1} }, qr/403.*permission/i, 'API error is surfaced with status and message';
};

done_testing;
