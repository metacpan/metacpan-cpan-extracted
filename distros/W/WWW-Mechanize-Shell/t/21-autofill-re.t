#!/usr/bin/perl -w
use strict;
use lib './inc';
use File::Temp qw( tempfile );
use IO::Catch;
use vars qw($_STDOUT_ $_STDERR_);

# pre-5.8.0's warns aren't caught by a tied STDERR.
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;
tie *STDERR, 'IO::Catch', '_STDERR_' or die $!;

use Test::More tests => 2;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;

use_ok('WWW::Mechanize::Shell');

my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );
$s->agent->{content} = q{<html><form name='f' action="/formsubmit"><input type="text" name="query" value="not filled"/></form></html>};
$s->agent->{forms} = [ HTML::Form->parse($s->agent->{content}, "http://www.example.com/" )];
$s->agent->{form}  = $s->agent->{forms}->[0];

$s->cmd( 'autofill /qu/i Fixed "filled"' );
$s->cmd( 'fillout' );

is($s->agent->current_form->find_input("query")->value,"filled", "autofill via RE works");
