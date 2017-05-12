use Test::More;

BEGIN {

    our @valid_types = qw(INI Query GlobalVar EnvVar Constant DataFile);
    our $total       = scalar(@valid_types);

    plan tests => $total + 2;

    use_ok('Win32::SqlServer::DTS::AssignmentTypes');

}

$total--;

can_ok( 'Win32::SqlServer::DTS::AssignmentTypes', qw(get_class_name) );

for ( my $counter = 0 ; $counter <= $total ; $counter++ ) {

    cmp_ok( Win32::SqlServer::DTS::AssignmentTypes->get_class_name($counter),
        'eq', $valid_types[$counter],
        "Convertion from $counter code to $valid_types[$counter]" );

}

