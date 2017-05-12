#!/usr/bin/perl -w
use strict;
use lib './inc';
use IO::Catch;
use File::Temp qw( tempfile );

# pre-5.8.0's warns aren't caught by a tied STDERR.
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;

use Test::More tests => 7;
# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;

use_ok('WWW::Mechanize::Shell');

my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );

my ($fh,$name) = tempfile();
close $fh;

$s->cmd('autofill foo Fixed bar');
$s->cmd(sprintf 'history "%s"', $name);

my $script = join("\n", $s->history)."\n";
ok(-f $name, "History file exists");
open F, "< $name"
  or die "Couldn't open tempfile $name : $!";
my $file = do { local $/; <F> };
close F;
is($file, $script, "Written history is the same as history()");

unlink $name
  or warn "Couldn't remove tempfile $name : $!";

($fh,$name) = tempfile();
close $fh;

$s->cmd(sprintf 'script "%s"', $name);

$script = join("\n", $s->script("  "))."\n";
ok(-f $name, "Script file exists");
open F, "< $name"
  or die "Couldn't open tempfile $name : $!";
$file = do { local $/; <F> };
close F;
is($file, $script, "Written script is the same as script()");

unlink $name
  or warn "Couldn't remove tempfile $name : $!";

($fh,$name) = tempfile();
close $fh;

$s->agent->{content} = "<html><body>test</body></html>";
$s->cmd(sprintf 'content "%s"', $name);
my $content = $s->agent->content . "\n";
ok(-f $name, "Script file exists");
open F, "< $name"
  or die "Couldn't open tempfile $name : $!";
$file = do { local $/; <F> };
close F;
is($file, $content, 'Written content is the same as $agent->content');

unlink $name
  or warn "Couldn't remove tempfile $name : $!";

