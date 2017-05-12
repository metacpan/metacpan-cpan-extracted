#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

use Ubic::Service::Hypnotoad;

ok(1, 'Module loaded successfully');

my $h = Ubic::Service::Hypnotoad->new({
	bin => [qw/ carton exec hypnotoad /],
	app => '/home/www/script/app.pl',
});

is $h->{pid_file}, '/home/www/script/hypnotoad.pid', 'default pidfile';
is_deeply $h->{bin}, [qw/ carton exec hypnotoad /], 'array bin';
is $h->{wait_status}{step}, 0.1, 'default step';
is $h->{wait_status}{trials}, 10, 'default trials';

$h = Ubic::Service::Hypnotoad->new({
	bin => '  carton     exec      hypnotoad     ',
	app => '/home/www/script/app.pl',
	pid_file => '/home/www/hypno.pid',
	wait_status => {
		step => 2,
		trials => 4,
	},
});

is $h->{pid_file}, '/home/www/hypno.pid', 'set pidfile';
is_deeply $h->{bin}, [qw/ carton exec hypnotoad /], 'string bin';
is $h->{wait_status}{step}, 2, 'set step';
is $h->{wait_status}{trials}, 4, 'set trials';

done_testing;
