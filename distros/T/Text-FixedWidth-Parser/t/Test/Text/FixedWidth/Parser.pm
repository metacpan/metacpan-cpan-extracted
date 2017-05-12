# ========================================================================== #
# Test/Text/FixedWidth/Parser.pm  - This module used to test Text::FixedWidth::Parser
# ========================================================================== #

package Test::Text::FixedWidth::Parser;

use Test::Most;

use base 'Test::Class';

sub class { 'Text::FixedWidth::Parser' }

sub startup : Tests(startup => 1)
{
    my $test = shift;

    my $class = $test->class;

    use_ok $test->class;

    my $fw_obj = $class->new(
        {
            TimestampToEpochFields => ['Field15'],
            StringMapper           => {
                Field1          => [1,   13],
                Field2          => [14,  100],
                Field3          => [114, 5],
                Field4          => [119, 1],
                Field5          => [120, 10],
                Field6          => [130, 10],
                Field7          => [140, 100],
                Field8          => [305, 4],
                Field9          => [310, 9],
                Field10         => [240, 30],
                Field11         => [278, 5],
                Field12         => [293, 2],
                Field13         => [309, 1],
                Field14         => [270, 8],
                Field14Pattern  => '%Y%m%d',
                Field14Timezone => 'America/Chicago'
            }
        }
    );

    $fw_obj->set_timestamp_to_epoch_fields(['Field14']);

    $test->{fw_obj} = $fw_obj;
}

sub read : Tests(2)
{
    my $test = shift;

    my $fw_obj = $test->{fw_obj};

    open my $fh, '<', 't/test_file.txt' or die " $! ";

    my $data     = $fw_obj->read($fh);
    my $expected = {
        'Field3'  => '11111',
        'Field7'  => '',
        'Field4'  => '1',
        'Field11' => '1',
        'Field2'  => 'xxxxxxx x xxxxxxx',
        'Field14' => '1398056400',
        'Field6'  => '',
        'Field13' => '5',
        'Field12' => 'El',
        'Field8'  => 'MD04',
        'Field1'  => '000000000001',
        'Field9'  => '398.11000',
        'Field5'  => '1111111111',
        'Field10' => '123456'
    };
    is_deeply($data, $expected, "Data received correctly");

    $fw_obj->{EmptyAsUndef} = 1;

    $data     = $fw_obj->read($fh);
    $expected = {
        'Field1'  => '000000000002',
        'Field9'  => '142.71000',
        'Field6'  => '1112222222',
        'Field14' => '1369803600',
        'Field12' => 'El',
        'Field7'  => undef,
        'Field8'  => 'MD16',
        'Field13' => '5',
        'Field11' => '1',
        'Field5'  => '1111111112',
        'Field2'  => 'yyyyy Y yyyyyyy',
        'Field10' => '123456',
        'Field3'  => '11111',
        'Field4'  => '1'
    };
    is_deeply($data, $expected, "Data received correctly with undef on empty places");
}

sub read_all : Tests(4)
{
    my $test = shift;

    my $fw_obj = $test->{fw_obj};

    open my $fh1, '<', 't/test_file.txt' or die " $! ";

    my $data = $fw_obj->read_all($fh1);

    close $fh1;

    ok(@$data == 6, "read_all method returned all data correctly");

    my $st_map = $fw_obj->get_string_mapper;
    $st_map->{Rule} = {
        'Field1'     => [1, 13],
        'Expression' => "Field1 == 000000000006 || Field1 == 000000000004"
    };

    $st_map->{Field1} = {Id => [1, 13]};
    $fw_obj->set_string_mapper($st_map);

    open my $fh2, '<', 't/test_file.txt' or die " $! ";

    $data = $fw_obj->read_all($fh2);

    close $fh2;

    ok(ref($data->[0]{Field1}) eq 'HASH', "Field1 received as HashRef as mentioned in StringMapper");

    ok(@$data == 2, "Data's filtered correctly based on Rule");

    #Multiple String mappers
    my $string_mapper = [
        {
            Rule => {
                LinePrefix => [1, 7],
                Expression => "LinePrefix eq 'ADDRESS'"
            },
            Id   => [8,  3],
            Name => [11, 13],
            Address => {DoorNo => [24, 2], Street => [26, 14]},
            Country => [40, 3]
        },
        {
            Rule => {
                LinePrefix => [1, 4],
                Expression => "LinePrefix eq 'MARK'"
            },
            Id    => [5,  3],
            Mark1 => [8,  2],
            Mark2 => [10, 2],
            Mark3 => [12, 2],
            Mark4 => [14, 3],
        }
    ];

    $fw_obj->set_string_mapper($string_mapper);

    open my $fh3, '<', 't/test_file2.txt' or die " $! ";

    $data = $fw_obj->read_all($fh3);

    close $fh3;

    my $expected = [
        {
            'Address' => {
                'DoorNo' => '84',
                'Street' => 'SOUTH STREET'
            },
            'Country' => 'USA',
            'Id'      => '001',
            'Name'    => 'XXXXX YYYYYYY'
        },
        {
            'Id'    => '001',
            'Mark1' => '82',
            'Mark2' => '86',
            'Mark3' => '98',
            'Mark4' => '90'
        },
        {
            'Address' => {
                'DoorNo' => '69',
                'Street' => 'BELL STREET'
            },
            'Country' => 'UK',
            'Id'      => '002',
            'Name'    => 'YYYYYYY'
        },
        {
            'Id'    => '002',
            'Mark1' => '88',
            'Mark2' => '69',
            'Mark3' => '89',
            'Mark4' => '39'
        }
    ];

    is_deeply($data, $expected, "Test data fetched correctly from file using mulitiple string mapper");

}

1;

__END__

=head1 AUTHORS

Venkatesan Narayanan, <venkatesanmusiri@gmail.com>

=cut

# vim: ts=4
# vim600: fdm=marker fdl=0 fdc=3

