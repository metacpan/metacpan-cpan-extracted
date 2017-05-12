package Test::VUser::Google::Groups;
use warnings;
use strict;

use Test::Most;
use base 'My::Test::Class';

my $acct;

sub constructor : Tests(3) {
    my $test = shift;
    my $class = $test->class;

    can_ok $class, 'new';
    ok my $api = $class->new(google => $test->create_google),
        '... and the constructor should succeed';
    isa_ok $api, $class, '... and the object it returns';
}

sub get_test_group {
    my $self = shift;

    if (1 || not defined $acct) {
	my @time = localtime;
	$acct = sprintf (
	    'test.group.%04d.%02d.%02d.%02d.%02d.%02d',
	    $time[5]+1900,
	    $time[4]+1,
	    $time[3],
	    $time[2],
	    $time[1],
	    $time[0]
	);
    }

    return $acct;
}

1;
