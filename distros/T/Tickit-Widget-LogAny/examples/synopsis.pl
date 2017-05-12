#!/usr/bin/env perl
use strict;
use warnings;

use Tickit;
use Tickit::Widget::LogAny;
use Log::Any qw($log);

my $tickit = Tickit->new(
	root => Tickit::Widget::LogAny->new(
		stderr => 1,
	)
);
print STDERR "print to STDERR\n";
printf STDERR "printf(...) to %s", 'STDERR';
warn "a warning\n";
warn "a warning with no \\n";
$log->trace('trace message');
$log->info('info message');
$log->debug('debug message');
$log->notice('notice message');
$log->warn('warn message');
$log->error('error message');
$log->critical('critical message');
$tickit->run;
