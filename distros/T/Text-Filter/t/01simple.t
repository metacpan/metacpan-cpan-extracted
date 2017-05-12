#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    use_ok q(Text::Filter);
}

chdir("t") if -d "t";

my $id;

my $data = <<EOD;
Tijd mag niets
minder zijn
dan zonder meer
bestede Liefde
EOD

my $expect = $data;

my $expect2 = <<EOD;
Tijd mag niets
minder zijn
bestede Liefde
EOD

my $catch;
my $input;

$id = "Quickie";
$input = $data; $catch = "";
Text::Filter->run(input => \$input,
		  output => \$catch);
is($catch, $expect, $id);

$id = "Object";
$input = $data; $catch = "";
my $f = Text::Filter->new(input => \$input,
			  output => \$catch);
$f->run;
is($catch, $expect, $id);

$id = "Object w/proc";
$input = $data; $catch = "";
$f = Text::Filter->new(input => \$input,
		       output => \$catch,
		       filter => sub {
			   local($_) = shift;
			   return unless /i/;
			   $_;
		       }
		      );

$f->run;
is($catch, $expect2, $id);

$id = "Object run w/proc";
$input = $data; $catch = "";
$f = Text::Filter->new(input => \$input,
		       output => \$catch);
$f->run(sub {
	    local($_) = shift;
	    return unless /i/;
	    $_;
	}
       );
is($catch, $expect2, $id);
