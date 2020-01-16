#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Expect;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

$ENV{TESTING_priority_upgrade} = 1;
$ENV{PERL5LIB} = ".."; #- for restart with local urpmi
my $name = 'priority-upgrade';

test('a b', 'a', 'a', 'b');

test('a-strict b', 'a-strict', 'a-strict b bb1', 'b',
     [ 'What is your choice', "\n" ],
     [ 'Proceed with the installation of the 2 packages?', "\n" ],
     [ 'restarting urpmi', '' ],
 );

test_ab_auto_select('', 
     [ 'What is your choice', "\n" ],
     [ 'Proceed with the installation of the 3 packages?', "\n" ],
 );
test_ab_auto_select('a',
     [ 'Proceed with the installation of one package?', "\n" ],
     [ 'restarting urpmi', '' ],
     [ 'What is your choice', "\n" ],
     [ 'Proceed with the installation of the 2 packages?', "\n" ],
 );	
test_ab_auto_select('b',
     [ 'What is your choice', "\n" ],
     [ 'Proceed with the installation of the 2 packages?', "\n" ],
     [ 'restarting urpmi', '' ],
     [ 'Proceed with the installation of one package?', "\n" ],
 );	
test_ab_auto_select('a,b',
     [ 'What is your choice', "\n" ],
     [ 'Proceed with the installation of the 3 packages?', "\n" ],
 );


sub test_ab_auto_select {
    my ($priority_upgrade, @expected) = @_;
    test('a b', undef, 'a b bb1', $priority_upgrade, @expected);
}

sub test {
    my ($pkgs_v1, $wanted_v2, $pkgs_v2, $priority_upgrade, @expected) = @_;

    unlink "$::pwd/media/$name";
    symlink "$name-1", "$::pwd/media/$name";

    urpmi_addmedia("$name $::pwd/media/$name");    

    if ($priority_upgrade) {
	set_urpmi_cfg_global_options({ 'priority-upgrade' => $priority_upgrade });
    }

    urpmi($pkgs_v1);
    my @pkgs_v1 = split(' ', $pkgs_v1);   
    check_installed_fullnames(map { "$_-1-1" } @pkgs_v1);

    unlink "$::pwd/media/$name";
    symlink "$name-2", "$::pwd/media/$name";

    if ($wanted_v2) {
	urpmi_update('-a');
	urpmi_expected($wanted_v2, \@expected);
    } else {
	urpmi_expected('--auto-update', \@expected);
    }


    my @pkgs_v2 = split(' ', $pkgs_v2);
    my @l = (
	(map { "$_-2-1" } @pkgs_v2),
	(map { "$_-1-1" } difference2(\@pkgs_v1, \@pkgs_v2)),
    );
    check_installed_fullnames(sort @l);

    system_('rm -rf root');
}

sub urpmi_expected {
    my ($options, $expected) = @_;

    if (0) {
	#- try it interactively for debugging
	system_(urpm_cmd('urpmi', '-d') . " $options");
	return;
    }

    my $cmd = urpmi_cmd() . " $options";
    print "# $cmd\n";
    my $expect = Expect->spawn($cmd);

    foreach (@$expected) {
	my ($msg, $to_send) = @$_;

	my $ok = $expect->expect(2, # timeout in seconds 
				 [ $msg => sub { $expect->send($to_send); } ]);
	print "$to_send\n";
	ok($ok, qq(expecting "$msg"));
	$ok or return;
    }

    $expect->expect(2, 
		    [ qr/restarting urpmi/ => sub { fail('not restarting urpmi') } ], 
		    [ 'eof' => sub {} ]);

    $expect->soft_close;
    is($expect->exitstatus, 0, $cmd);
}
