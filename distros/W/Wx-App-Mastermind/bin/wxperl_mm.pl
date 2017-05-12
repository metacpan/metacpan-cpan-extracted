#!/usr/bin/perl -w

use strict;
use warnings;
use lib 'lib';
use threads;

use Wx;
use Wx::App::Mastermind;

my $app = Wx::SimpleApp->new;
Wx::App::Mastermind->new;
$app->MainLoop;
