use strict;
use warnings;
use PICA::Data qw(pica_parser);
use PICA::Schema qw(field_identifier);
use PICA::Error;
use Test::More;
use YAML::Tiny;
use Test::Deep;

is field_identifier(['003@']), '003@', 'field_identifer (003@)';
is field_identifier(['012A', '1']), '012A/01', 'field_identifer (012A/01)';
is field_identifier(['209A', '01']), '209A',    'field_identifer (209A/XX)';

my $schema = PICA::Schema->new({ fields => { '012A/01-11' => { } } });
is $schema->field_identifier(['012A', '01']), '012A/01-11', 'field_identifer with occurrence range';
is $schema->field_identifier(['012A', '12']), '012A/12', 'field_identifer with occurrence range';

my $tests = YAML::Tiny->read('t/files/schema-tests.yaml')->[0];

my %records
    = map {($_ => pica_parser('plain', fh => \($tests->{records}{$_}))->next())}
    keys %{$tests->{records}};
my %schemas = map {$_ => PICA::Schema->new($tests->{schemas}{$_})}
    keys %{$tests->{schemas}};

foreach (@{$tests->{tests}}) {
    my $schema = $schemas{$_->{schema}};
    my $record = $records{$_->{record}};

    my @errors = $schema->check($record, %{$_->{options} || {}});
    my @expect = @{$_->{errors} || []};
    bless $_, 'PICA::Error' for @expect;
    if (!cmp_deeply \@errors, \@expect, $_->{check}) {
        note explain $_ for @errors;
    }
}

{
    my $record = pica_parser('plain', fh => 't/files/bgb.example')->next;
    my $schema = PICA::Schema->new({
        fields => {
            '201B' => {
                subfields => {
                    x => { required => 1 }
                }
            }
        }
    });
    is scalar($schema->check($record)), 77, "report errors only once";

    $record = [undef,['003@','','0','123']];
    is_deeply [ $schema->check($record) ], [bless {
          message => "PICA field must be array reference"
        }, 'PICA::Error'], "report malformed data";
}

{
    my $a = PICA::Schema->new({ fields => { '021A/00' => {} } });
    my $b = PICA::Schema->new({ fields => { '021A' => {} } });
    is_deeply $a, $b, 'normalize occurrence zero';
}

{
    my $fields = {
        '222Xx0' => {},
        '222Xx1-4' => {},
        '222Xx00-04' => {},
    };
    my $schema = PICA::Schema->new({ fields => $fields });
    is $schema->field_identifier([qw(222X 0 x 0)]), '222Xx0', 'x-counter';
    is $schema->field_identifier([qw(222X 0 y 0)]), '222X', 'no x-counter';
    is $schema->field_identifier([qw(222X 0 x 2)]), '222Xx1-4', 'x-counter';
    is $schema->field_identifier([qw(222X 0 x 01)]), '222Xx00-04', 'x-counter';
}

done_testing;
