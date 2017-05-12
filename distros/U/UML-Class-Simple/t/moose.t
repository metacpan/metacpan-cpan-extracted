#!/usr/bin/perl
# -*- perl -*-

use strict;
no warnings;

my $skip; 
BEGIN {
    eval "use Moose";
    if ($@) { $skip = 'Moose required for this test' }
};

use Config;
use YAML::Syck;
use File::Slurp;
use IPC::Run3;
use Test::More $skip ? (skip_all => $skip) : ();

my $script = 'script/umlclass.pl';
my @cmd = ($^X, '-Ilib', $script);
my ($stdout, $stderr);

{
    my $outfile = 'moouseish.yml';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, qw(-M Moose -p Moouseish -o), $outfile, qw(-r t)], \undef, \$stdout, \$stderr ),
        "umlclass -M Moose -p Moouseish -o $outfile -r t";
    is $stdout, "Moouseish::Bar\nMoouseish::Baz\nMoouseish::Foo\nMoouseish::Garply\nMoouseish::Quux\nMoouseish::Zot\n\n$outfile generated.\n",
        "stdout ok - $outfile generated.";
    # will generate warnings on stderr, we don't care
    ok -f $outfile, "$outfile exists";
    my $yml = read_file($outfile);
    like $yml, qr/^\s*- Moouseish::Garply/m, 'yml caught role consumer';
}

# Check --no-methods

{
    my $outfile = 'nomethods.dot';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, qw(-M Moose -p Moouseish -o), $outfile, qw(--no-methods -r t)], \undef, \$stdout, \$stderr ),
        "umlclass -M Moose -p Moouseish -o $outfile --no-methods -r t";
    is $stdout, "Moouseish::Bar\nMoouseish::Baz\nMoouseish::Foo\nMoouseish::Garply\nMoouseish::Quux\nMoouseish::Zot\n\n$outfile generated.\n",
        "stdout ok - $outfile generated.";
    # will generate warnings on stderr, we don't care
    ok -f $outfile, "$outfile exists";
    my $yml = read_file($outfile);
    like $yml, qr/<td port="methods"\s*>\s*<\/td>/m, 'empty methods port'
}

# Check --no-inheritance

{
    my $outfile = 'noinheritance.dot';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, qw(-M Moose -p Moouseish -o), $outfile, qw(--no-inheritance -r t)], \undef, \$stdout, \$stderr ),
        "umlclass -M Moose -p Moouseish -o $outfile --no-inheritance -r t";
    is $stdout, "Moouseish::Bar\nMoouseish::Baz\nMoouseish::Foo\nMoouseish::Garply\nMoouseish::Quux\nMoouseish::Zot\n\n$outfile generated.\n",
        "stdout ok - $outfile generated.";
    # will generate warnings on stderr, we don't care
    ok -f $outfile, "$outfile exists";
    my $yml = read_file($outfile);
    unlike $yml, qr/class.*->.*class/, 'no edges from class to class';
}


# Check --moose-roles

{
    my $outfile = 'rolesonly.dot';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, qw(-M Moose -p Moouseish -o), $outfile, qw(--no-inheritance --moose-roles -r t)], \undef, \$stdout, \$stderr ),
        "umlclass -M Moose -p Moouseish -o $outfile --no-inheritance --moose-roles -r t";
    is $stdout, "Moouseish::Bar\nMoouseish::Baz\nMoouseish::Foo\nMoouseish::Garply\nMoouseish::Quux\nMoouseish::Zot\n\n$outfile generated.\n",
        "stdout ok - $outfile generated.";
    # will generate warnings on stderr, we don't care
    ok -f $outfile, "$outfile exists";
    my $yml = read_file($outfile);
    like $yml, qr/edge.*blue/, 'role edge color';
    like $yml, qr/node.*triangle.*orange/, 'role node color';
    like $yml, qr/angle_\d.*->.*class_\d/, 'at least one role provider';
    like $yml, qr/class_\d.*->.*angle_\d/, 'at least one role consumer';
}


done_testing();
