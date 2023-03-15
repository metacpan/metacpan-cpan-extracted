use strict;
use warnings;
use PICA::Schema::Builder;
use Test::More;

my $builder = PICA::Schema::Builder->new( title => 'my schema' );
is $builder->{title}, 'my schema', 'constructor';
is_deeply $builder->schema, $builder;

$builder->add([['003@', undef, '0', '1234']]);

my $fields = {
    '003@' => {
        tag       => '003@',
        required  => \1,
        subfields => {'0' => {code => '0', required => \1}},
        total     => 1,
        records   => 1
    }
};
is_deeply $builder->{fields}, $fields;

$builder->add(
    [
        ['003@', undef, '0', 111, 0, 222],    # repeat existing subfield
        ['144Z', '', 'x', 333],               # introduce new field
    ]
);

$fields->{'003@'}{subfields}{0}{repeatable} = \1;
$fields->{'003@'}{total}++;
$fields->{'003@'}{records}++;
$fields->{'144Z'} = {
        tag => '144Z',
        subfields => {x => {code => 'x', required => \1}}, 
        total => 1,
        records => 1,
    };

is_deeply $builder->{fields}, $fields;

$builder->add(
    [
        ['003@', '', '0', 333, 'x', 444],    # introduce new subfield
    ]
);

$fields->{'003@'}{total}++;
$fields->{'003@'}{records}++;
$fields->{'003@'}{subfields}{x} = {code => 'x'};

is_deeply $builder->{fields}, $fields;

$builder->add(
    [
        # omit 003@
        ['028B', '01', 'x', 1, ' '],         # new annotated field with occurrence
        ['144Z', '',   'y', 0],              # omit 114Z$x
        ['144Z', '',   'x', 2],              # repeated
    ]
);

delete $fields->{'003@'}{required};
delete $fields->{'144Z'}{subfields}{x}{required};
$fields->{'144Z'}{subfields}{y} = {code => 'y'};
$fields->{'144Z'}{repeatable} = \1;
$fields->{'144Z'}{total} += 2;
$fields->{'144Z'}{records}++;
$fields->{'028B/01'} = {
    tag        => '028B',
    occurrence => '01',
    subfields  => {x => {code => 'x', required => \1}},
    total      => 1,
    records    => 1,
};

is_deeply $builder->{fields}, $fields;

$builder->{fields}{'144Z'}{total} = 0;
delete $fields->{'144Z'};

is_deeply $builder->schema->{fields}, $fields, '->schema removes fields with total=0';

$builder = PICA::Schema::Builder->new( fields => { '045Q/01-09' => { } } );
$builder->add([[qw(045Q 01 0 0)]]);

is_deeply [ keys %{$builder->schema->{fields}} ], ['045Q/01-09'], 'occurrence ranges';

done_testing;
