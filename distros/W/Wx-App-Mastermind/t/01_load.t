#!/usr/bin/perl -w

use strict;
use Test::More tests => 11;

use_ok( 'Wx::App::Mastermind::Board::PegStrip' );
use_ok( 'Wx::App::Mastermind::Board::Peg' );
use_ok( 'Wx::App::Mastermind::Board::Editor' );
use_ok( 'Wx::App::Mastermind::Board' );
use_ok( 'Wx::App::Mastermind::Player' );
use_ok( 'Wx::App::Mastermind::Player::Computer' );
use_ok( 'Wx::App::Mastermind::Player::Human' );
use_ok( 'Wx::App::Mastermind' );
use_ok( 'Wx::Perl::Thread::Listener' );
use_ok( 'Wx::Perl::Thread::Object' );
use_ok( 'Wx::Perl::Thread::ClassPublisher' );
