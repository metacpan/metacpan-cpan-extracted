use Test2::V0 -no_srand => 1;
use v5.42;
use Test2::Require::EnvVar 'TEST_TIE_GOOGLE_SHEETS_DOCUMENT_ID';
use Test2::Require::EnvVar 'TEST_TIE_GOOGLE_SERVICE_TOKEN';
use Tie::Google::Sheets;

subtest 'basic' => sub {

    tie my %doc, 'Tie::Google::Sheets',
        spreadsheet_id  => $ENV{TEST_TIE_GOOGLE_SHEETS_DOCUMENT_ID},
        service_account => $ENV{TEST_TIE_GOOGLE_SERVICE_TOKEN},
        backoff_retry   => 8,
    ;

    is
        tied(%doc),
        object {
            prop isa => 'Tie::Google::Sheets';
        },
        'tied object is the right class',
    ;

    my $title_one = "foo-$$-" . time;
    my $sheet = tied(%doc)->add_worksheet($title_one);

    is
        tied(%$sheet),
        object {
            prop isa => 'Tie::Google::Sheets::Worksheet';
        },
        'sheet object is the right class',
    ;

    is $doc{$title_one}, D(), 'worksheet exists';

    is $doc{$title_one}{A1}, U(), 'value has no value yet';
    is $doc{$title_one}{A1} = 'foo', 'foo', 'assign value';
    is $doc{$title_one}{A1}, 'foo', 'fetch value';

    $doc{$title_one}{A2} = 1;
    $doc{$title_one}{A3} = 2;
    $doc{$title_one}{A4} = 3;
    $doc{$title_one}{A5} = "=A2+A3+A4";
    is $doc{$title_one}{A5}, 6, 'fetch returns value';

    my $ws = $doc{$title_one};
    is(tied(%$ws)->fetch_mode, 'value', 'default fetch mode');
    is(tied(%$ws)->fetch_mode('formula'), 'formula', 'set to formula');
    is $doc{$title_one}{A5}, '=A2+A3+A4', 'fetch returns formula';

    is delete $doc{$title_one}, U(), 'delete worksheet';
    is $doc{$title_one}, U(), 'worksheet does not exist';

    my $title_two = "bar-$$-" . time;

    $ws = tied(%doc)->copy_worksheet('template', $title_two);

    is
        tied(%$ws),
        object {
            prop isa => 'Tie::Google::Sheets::Worksheet';
        },
        'second sheet object is the right class',
    ;

    is $ws->{A1}, 'A';
    is $ws->{B1}, 'B';
    is $ws->{A2}, 1;

    delete $doc{$_} for grep /^(foo|bar)-/n, keys %doc;
};

done_testing;
