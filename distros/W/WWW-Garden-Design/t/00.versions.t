#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use WWW::Garden::Design; # For the version #.

use Test::More;

use base;
use boolean;
use Config::Tiny;
use Data::Dumper::Concise;
use Date::Simple;
use DBD::SQLite;
use DBI;
use DBIx::Admin::CreateTable;
use DBIx::Simple;
use Encode;
use File::Copy;
use File::HomeDir;
use File::Slurper;
use File::Spec;
use FindBin;
use Getopt::Long;
use Imager;
use Imager::Fill;
use lib;
use Lingua::EN::Inflect;
use Mojolicious;
use Mojo::Base;
use Mojo::Collection;
use Mojo::Log;
use Mojo::Pg;
use MojoX::Validate::Util;
use Moo;
use Params::Classify;
use Path::Tiny;
use Pod::Usage;
use Sort::Naturally;
use strict;
use SVG::Grid;
use Text::CSV;
use Text::CSV::Encoded;
use Text::Xslate;
use Time::HiRes;
use Try::Tiny;
use Types::Standard;
use Unicode::Collate;
use URI::Find::Schemeless;
use utf8;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	base
	boolean
	Config::Tiny
	Data::Dumper::Concise
	Date::Simple
	DBD::SQLite
	DBI
	DBIx::Admin::CreateTable
	DBIx::Simple
	Encode
	File::Copy
	File::HomeDir
	File::Slurper
	File::Spec
	FindBin
	Getopt::Long
	Imager
	Imager::Fill
	lib
	Lingua::EN::Inflect
	Mojolicious
	Mojo::Base
	Mojo::Collection
	Mojo::Log
	Mojo::Pg
	MojoX::Validate::Util
	Moo
	Params::Classify
	Path::Tiny
	Pod::Usage
	Sort::Naturally
	strict
	SVG::Grid
	Text::CSV
	Text::CSV::Encoded
	Text::Xslate
	Time::HiRes
	Try::Tiny
	Types::Standard
	Unicode::Collate
	URI::Find::Schemeless
	utf8
	warnings
/;

diag "Testing WWW::Garden::Design V $WWW::Garden::Design::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
