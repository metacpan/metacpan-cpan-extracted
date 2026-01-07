#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Core modules
use_ok('WWW::ARDB');
use_ok('WWW::ARDB::Request');
use_ok('WWW::ARDB::Cache');

# Result classes
use_ok('WWW::ARDB::Result::Item');
use_ok('WWW::ARDB::Result::Quest');
use_ok('WWW::ARDB::Result::ArcEnemy');

# CLI modules
use_ok('WWW::ARDB::CLI');
use_ok('WWW::ARDB::CLI::Cmd::Items');
use_ok('WWW::ARDB::CLI::Cmd::Item');
use_ok('WWW::ARDB::CLI::Cmd::Quests');
use_ok('WWW::ARDB::CLI::Cmd::Quest');
use_ok('WWW::ARDB::CLI::Cmd::Enemies');
use_ok('WWW::ARDB::CLI::Cmd::Enemy');

done_testing;
