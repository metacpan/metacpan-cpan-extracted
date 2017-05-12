#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Expect;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $medium_name = 'prefer';

urpmi_addmedia("$medium_name $::pwd/media/$medium_name");

urpmi("--auto --prefer b a");
check_installed_and_remove('a', 'b');

urpmi("--auto --prefer c a");
check_installed_and_remove('a', 'c');

test('/foo/', 'foo');
test('a,a_foo', '^(a|a_foo)$');


sub test {
    my ($prefer, $regexp) = @_;

    my $options = "--prefer '$prefer' a";
    my @expected = (
	[ 'What is your choice', "\n" ],
	[ 'Proceed with the installation of the 2 packages?', "\n" ],
    );

    if (0) {
	#- try it interactively for debugging
	system_(urpm_cmd('urpmi', '-d') . " $options");
	return;
    }

    my $cmd = urpmi_cmd() . " $options";
    print "# $cmd\n";
    my $expect = Expect->spawn($cmd);
    
    my $choices;
    foreach (@expected) {
	my ($msg, $to_send) = @$_;

	my $ok = $expect->expect(2, # timeout in seconds 
				 [ $msg => sub { $choices ||= $expect->before; $expect->send($to_send); } ]);
	print "$to_send";
	ok($ok, qq(expecting "$msg"));
	$ok or return;
    }
    my @choices = grep { s/^\s*\d+- (.*?)-.*?:.*/$1/ } split("\n", $choices);
    is(int(@choices), 4, "4 choices in $choices");
    my $other = '';
    foreach (@choices) {
	if (/$regexp/) {
	    ok(!$other, "line $_ must be before $other line");
	} else {
	    $other = $_;
	}
    }

    $expect->expect(2, [ 'eof' => sub {} ]);

    $expect->soft_close;
    is($expect->exitstatus, 0, $cmd);

    check_installed_and_remove('a', $choices[0]);
}
