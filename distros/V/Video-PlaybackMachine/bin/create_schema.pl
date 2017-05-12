#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.09'; # VERSION

use Video::PlaybackMachine::DB;

my $schema = Video::PlaybackMachine::DB->schema();

$schema->create_ddl_dir(['SQLite'], '0.01', './', undef, { 'add_drop_table' => 0 });
