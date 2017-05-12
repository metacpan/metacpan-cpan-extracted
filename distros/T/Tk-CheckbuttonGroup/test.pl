# Test script for Tk::CheckbuttonGroup
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

my $checkbuttongroup;
my $class = 'CheckbuttonGroup';

eval "require Tk::$class;";
ok($@, "", "Error loading Tk::$class");

my @selected = qw(two four);
eval {
	$checkbuttongroup = $top->CheckbuttonGroup (
		-list => [qw( one two three four five )],
		-orientation => 'vertical',
		-variable => \@selected,
		-command => sub {
			print @selected, "\n";
		}
	)->pack();
};
ok($@, "", "can't create $class widget");
skip($@, Tk::Exists($checkbuttongroup), 1, "$class instance does not exist");

if (Tk::Exists($checkbuttongroup)) {

	sleep(1);
    eval { $checkbuttongroup->configure(
		-list => [qw( two three four five six seven )],
		-orientation => 'horizontal',
	); };
    ok ($@, "", "Can't configure a $class widget");
    eval { $top->update(); };
    ok ($@, "", "Error during 'update' for $class widget");

	sleep(1);
    eval { $checkbuttongroup->configure(
		-variable => [qw(three seven eight)]
	); };
    ok ($@, "", "Can't configure a $class widget");
    eval { $top->update(); };
    ok ($@, "", "Error during 'update' for $class widget");

	sleep(1);
    eval { $checkbuttongroup->configure(
		-variable => [qw(three seven eight)]
	); };
    ok ($@, "", "Can't configure a $class widget");
    eval { $top->update(); };
    ok ($@, "", "Error during 'update' for $class widget");

	sleep(1);
    eval { $checkbuttongroup->configure(
		-font => 24
	); };
    ok ($@, "", "Can't configure a $class widget");
    eval { $top->update(); };
    ok ($@, "", "Error during 'update' for $class widget");

} else  { 
    for (1..6) { skip (1,1,1, "skipped because widget couldn't be created"); }
}

