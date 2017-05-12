#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 10;

BEGIN {
    use_ok q(Text::Filter);
}

chdir("t") if -d "t";

require_ok("../examples/testfilter.pl");

my @catch = ();
my $id;

my $testfile = "00basic.dat";
my $data;
open (my $out, '>', $testfile);
while ( <DATA> ) {
    chomp;
    $_ .= "\n";
    $data .= $_;
    print { $out } $_;
}
close($out);

my $expect = <<EOD;
Red Hat Linux release 5.2 (Apollo)
Kernel 2.2.3 on an i686
Mandatory
EOD

$id = "Quickie";
@catch = ();
Grepper::grepper ($testfile,
		  sub { push (@catch, shift) },
		  "a");
is(join('',@catch), $expect, $id);

$id = "File -> code";
@catch = ();
Grepper->new
  (input => $testfile,
   output => sub { push (@catch, shift) })->grep("a");
is(join('',@catch), $expect, $id);

$id = "code -> code, chomp";
my @inp = @catch;
@catch = ();
Grepper->new
  (input => sub { shift(@inp) },
   input_postread => 'chomp',
   output => sub { push (@catch, shift(@_)."\n") })->grep("a");
is(join('',@catch), $expect, $id);

$id = "code -> code, newline";
@inp = @catch;
chomp (@inp);
@catch = ();
Grepper->new
  (input => sub { shift(@inp) },
   output_prewrite => 'newline',
   output => sub { push (@catch, shift(@_)) })->grep("a");
is(join('',@catch), $expect, $id);

$id = "array -> array";
@inp = @catch;
@catch = ();
Grepper->new
  (input => \@inp,
   output => \@catch)->grep("a");
is(join('',@catch), $expect, $id);

$id = "string -> array";
my $inp = join('',@catch);
@catch = ();
Grepper->new
  (input => \$inp,
   output => \@catch)->grep("a");
is(join('',@catch), $expect, $id);

$id = "File -> array";
@catch = ();
local (*FD);
open (FD, $testfile);
Grepper->new
  (input => *FD,
   output => \@catch)->grep("a");
is(join('',@catch), $expect, $id);

$id = "array -> scalar";
@inp = @catch;
my $catch;
Grepper->new
  (input => \@inp,
   output => \$catch)->grep("a");
is(join('',@catch), $expect, $id);

__END__
Nope
Red Hat Linux release 5.2 (Apollo)
Kernel 2.2.3 on an i686

Mandatory
