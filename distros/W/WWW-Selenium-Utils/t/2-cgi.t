#!/usr/bin/perl
use warnings;
use strict;
use Test::More qw(no_plan);
use lib "lib";
use WWW::Selenium::Utils::CGI qw(run cat state);
use CGI;
use Cwd;
use t::MockCGI;

# cat tests
my $page = cat(MockCGI->new());
like $page, qr#Error!#, 'cat with no args';
like $page, qr#file is a mandatory#;

my $testfile = getcwd() . "/t/foo.conf";
open(my $fh, ">$testfile") or die "Can't open $testfile: $!";
print $fh "monkey poo\n";
close $fh or die "Can't write $testfile: $!";

$page = cat(MockCGI->new( file => $testfile ));
like $page, qr#Contents of $testfile#, 'cat with absolute args';
like $page, qr#<pre>monkey poo#;

$page = cat(MockCGI->new( file => $testfile, raw => 1 ));
like $page, qr#monkey poo#, 'raw cat';
unlike $page, qr#<pre>monkey#;


# run tests
$page = run(MockCGI->new());
like $page, qr#Error!#, 'run with no args';
like $page, qr#cmd is a mandatory#;

$page = run(MockCGI->new( cmd => "perl -e 'print q(Monkey)'" ));
like $page, qr#<div id='cmd'><h1>Output of "perl#, 'running a command';
like $page, qr#<div id='output'><pre>Monkey#;



# state tests
$page = state(MockCGI->new());
like $page, qr#Error!#, 'run with no args';
like $page, qr#key is a mandatory#;

$page = state(MockCGI->new( value => 'foo' ));
like $page, qr#Error!#, 'run with one args';
like $page, qr#key is a mandatory#;

$page = state(MockCGI->new( clear_state => 1 ));
like $page, qr#State cleared#;
my $statefile = '/tmp/selenium-utils-tests';
ok !-e $statefile, 'statefile is gone';

$page = state(MockCGI->new( key => 'bar', value => 'foo' ));
like $page, qr#Stored 'foo' in 'bar'#, 'bar=foo';
ok -e "/tmp/selenium-utils-state", "statefile exists";

$page = state(MockCGI->new( key => 'bar' ));
like $page, qr#'bar' is 'foo'#, 'run with one args';

$page = state(MockCGI->new( key => 'foo' ));
like $page, qr#Error!#, 'invalid key';
like $page, qr#'foo' is not a valid key#;

$page = state(MockCGI->new( clear_state => 1 ));
like $page, qr#State cleared#;
$statefile = '/tmp/selenium-utils-tests';
ok !-e $statefile, 'statefile is gone';


1;
