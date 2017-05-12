#!/usr/bin/perl -w
use strict;
use Test::More tests => 4;
use File::Spec;
use File::Temp qw(tempfile);

my $perl = $^X;
if ($perl =~ /\s/) {
    $perl = qq{"$perl"};
};

my ($fh,$temp) = tempfile();
print {$fh} "quit\n";
close $fh;

my $res = system($perl, "-I./blib/lib", "-MWWW::Mechanize::Shell", "-eshell(warnings=>undef)", $temp);
is $res,0,"Shell launch works";
is $?, 0, "No error on exit";
unlink $temp
    or diag "Couldn't remove '$temp': $!";

use_ok "WWW::Mechanize::Shell";
my $s = WWW::Mechanize::Shell->new("shell",warnings=>undef);
my $prompt = eval { $s->prompt_str };
is $@, '', "prompt_str() doesn't die for empty WWW::Mechanize";
