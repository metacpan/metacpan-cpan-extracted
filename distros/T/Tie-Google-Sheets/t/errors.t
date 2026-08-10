use Test2::V0 -no_srand => 1;
use v5.42;
use Path::Tiny qw( tempfile );
use lib 't/lib';
use Local::FakeSheetsUA;
use Tie::Google::Sheets;
use Tie::Google::Sheets::Client;

# Every exception in this distribution is raised with Carp::croak, which is
# supposed to blame the code that called into this distribution rather than
# the internal frame that happened to notice the problem. That only works if
# every internal package trusts every other one (see @CARP_NOT in each
# module); this test asserts that trust actually holds, by checking that
# the "at FILE line NNN" location on every croak below points back to this
# test file, never to a .pm under lib/.

sub caller_ok ($err, $desc) {
    my $here = __FILE__;
    like $err, qr/\Q$here\E line \d+/, "$desc: blames the caller";
    unlike $err, qr{lib[/\\]Tie[/\\]Google[/\\]Sheets}, "$desc: does not blame module internals";
}

sub build_doc (%extra) {
    my $mock = Local::FakeSheetsUA->new;
    tie my %doc, 'Tie::Google::Sheets',
        spreadsheet_id => 'test-spreadsheet',
        access_token   => 'fake-token',
        any_ua         => $mock,
        %extra;
    return (\%doc, $mock);
}

subtest 'Tie::Google::Sheets::Client construction' => sub {
    my $err = dies { Tie::Google::Sheets::Client->new(access_token => 'x') };
    like $err, qr/spreadsheet_id/, 'missing spreadsheet_id/url';
    caller_ok $err, 'missing spreadsheet_id/url';

    $err = dies { Tie::Google::Sheets::Client->new(spreadsheet_id => 'x') };
    like $err, qr/one of service_account or access_token is required/, 'missing auth';
    caller_ok $err, 'missing auth';

    $err = dies {
        Tie::Google::Sheets::Client->new(
            spreadsheet_id => 'x', access_token => 'y',
            ua => bless({}, 'Local::FakeUA'), any_ua => Local::FakeSheetsUA->new,
        );
    };
    like $err, qr/only one of ua or any_ua may be given/, 'both ua and any_ua given';
    caller_ok $err, 'both ua and any_ua given';

    $err = dies { Tie::Google::Sheets::Client->new(spreadsheet_id => 'x', access_token => 'y', batch_size => 0) };
    like $err, qr/batch_size must be a positive integer/, 'zero batch_size';
    caller_ok $err, 'zero batch_size';

    $err = dies { Tie::Google::Sheets::Client->new(spreadsheet_id => 'x', access_token => 'y', backoff_retry => 0) };
    like $err, qr/backoff_retry must be a positive integer/, 'zero backoff_retry';
    caller_ok $err, 'zero backoff_retry';

    $err = dies {
        Tie::Google::Sheets::Client->new(spreadsheet_id => 'x', access_token => 'y', service_account => [1, 2]);
    };
    like $err, qr/service_account must be a hashref/, 'service_account is neither hashref nor path';
    caller_ok $err, 'service_account is neither hashref nor path';

    $err = dies {
        Tie::Google::Sheets::Client->new(spreadsheet_id => 'x', access_token => 'y', bogus => 1, also_bogus => 2);
    };
    like $err, qr/unknown constructor argument\(s\): also_bogus bogus/, 'unknown constructor arguments';
    caller_ok $err, 'unknown constructor arguments';

  SKIP: {
        skip 'root can read unreadable files', 2 if $> == 0;

        my $path = tempfile();
        $path->spew('{}');
        $path->chmod(0000);

        my $err = dies { Tie::Google::Sheets::Client->new(spreadsheet_id => 'x', service_account => "$path") };
        like $err, qr/unable to open service account key file/, 'service_account file cannot be opened';
        caller_ok $err, 'service_account file cannot be opened';

        $path->chmod(0600);
    }
};

subtest 'Tie::Google::Sheets tied hash operations' => sub {
    my($doc, $mock) = build_doc();

    my $err = dies { $doc->{Sheet1} = { A1 => 'nope' } };
    like $err, qr/already exists/, 'assigning over an existing worksheet';
    caller_ok $err, 'assigning over an existing worksheet';

    $err = dies { $doc->{NewSheet} = 'not a hashref' };
    like $err, qr/may only be assigned undef, or a hashref/, 'assigning a non-hashref to a new worksheet';
    caller_ok $err, 'assigning a non-hashref to a new worksheet';

    $err = dies { %$doc = () };
    like $err, qr/cannot delete every worksheet/, 'clearing the document';
    caller_ok $err, 'clearing the document';

    $err = dies { delete $doc->{NoSuchSheet} };
    like $err, qr/no such worksheet/, 'deleting an unknown worksheet';
    caller_ok $err, 'deleting an unknown worksheet';
};

subtest 'Tie::Google::Sheets::Worksheet tied hash operations' => sub {
    my($doc) = build_doc();

    my $err = dies { $doc->{Sheet1}{'not a cell'} };
    like $err, qr/invalid cell reference/, 'bad cell reference on read';
    caller_ok $err, 'bad cell reference on read';

    $err = dies { $doc->{Sheet1}{'not a cell'} = 'x' };
    like $err, qr/invalid cell reference/, 'bad cell reference on write';
    caller_ok $err, 'bad cell reference on write';
};

subtest 'API error propagation' => sub {
    my($doc, $mock) = build_doc();

    $mock->fail_next(403, 'The caller does not have permission');
    my $err = dies { my $x = $doc->{Sheet1}{A1} };
    like $err, qr/403.*permission/i, 'API error is surfaced with status and message';
    caller_ok $err, 'API error is surfaced with status and message';
};

done_testing;
