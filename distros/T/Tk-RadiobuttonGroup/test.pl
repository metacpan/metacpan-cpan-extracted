# Test script for Tk::RadiobuttonGroup
#
# By; Joseph Annino  jannino@jannino.com
#
# Thanks to Stephen O. Lidie <lusol@Pandora.cc.lehigh.edu>
# for suggestions for improvements to the test script

use Test;
use strict;

BEGIN { plan tests => 13 };

eval { require Tk; };
ok($@, "", "loading Tk module");

my $top;
eval {$top = Tk::MainWindow->new();};
ok($@, "", "can't create MainWindow");
ok(Tk::Exists($top), 1, "MainWindow creation failed");
#eval { $top->geometry('+10+10'); };

my $radiobuttongroup;
my $class = 'RadiobuttonGroup';

eval "require Tk::$class;";
ok($@, "", "Error loading Tk::$class");

my @selected = qw(two four);
my $var = 'three';
eval {
	$radiobuttongroup = $top->RadiobuttonGroup (
		-list => [qw( one two three four five )],
		-orientation => 'vertical',
		-variable => \$var,
		-command => sub {
			print @selected, "\n";
		}
	)->pack();
};
ok($@, "", "can't create $class widget");
skip($@, Tk::Exists($radiobuttongroup), 1, "$class instance does not exist");

if (Tk::Exists($radiobuttongroup)) {

	sleep(1);
    eval { $radiobuttongroup->configure(
		-list => [[two => 2,three => 3,four => 4,five => 5,six => 6,seven => 7]],
		-orientation => 'horizontal',
	); };
    ok ($@, "", "Can't configure a $class widget");
    eval { $top->update(); };
    ok ($@, "", "Error during 'update' for $class widget");

	sleep(1);
    eval { $radiobuttongroup->configure(
		-variable => \$var,
	); };
    ok ($@, "", "Can't configure a $class widget");
    eval { $top->update(); };
    ok ($@, "", "Error during 'update' for $class widget");

	sleep(1);
    eval { 
    	my $var = 5;
		$radiobuttongroup->configure(
			-variable => \$var,
	); };
    ok ($@, "", "Can't configure a $class widget");
    eval { $top->update(); };
    ok ($@, "", "Error during 'update' for $class widget");

	sleep(1);
    eval { $radiobuttongroup->configure(
		-font => 24
	); };
    ok ($@, "", "Can't configure a $class widget");
    eval { $top->update(); };
    ok ($@, "", "Error during 'update' for $class widget");

} else  { 
    for (1..6) { skip (1,1,1, "skipped because widget couldn't be created"); }
}

