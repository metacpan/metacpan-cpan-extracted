#!/usr/bin/env perl

use inc::Module::Install;

# -----------------------

name 'WWW-Scraper-Wikipedia-ISO3166';

license 'perl';

all_from 'lib/WWW/Scraper/Wikipedia/ISO3166.pm';

install_share;

license 'perl';

resources
repository => 'https://github.com/ronsavage/WWW-Scraper-Wikipedia-ISO3166.git';

requires 'Capture::Tiny'				=> 0.36;
requires 'Config::Tiny'					=> 2.14;
requires 'DBD::SQLite'					=> 1.50;
requires 'DBI'							=> 1.620;
requires 'DBIx::Admin::CreateTable'		=> 2.07;
requires 'feature'						=> 0,
requires 'File::ShareDir'				=> 1.03;
requires 'File::Slurper'				=> 0.008;
requires 'File::Spec'					=> 3.33;
requires 'Getopt::Long'					=> 2.38;
requires 'HTTP::Tiny'					=> 0.056;
requires 'List::AllUtils'				=> 0.03;
requires 'List::Compare'				=> 0.37;
requires 'Log::Handler'					=> 0.84;
requires 'Mojolicious'					=> 6.62;
requires 'Mojo::DOM'					=> 0; # This is just for my Makefile.PL cross-checker.
requires 'Moo'							=> 2.001001;
requires 'open'							=> 1.08;
requires 'parent'						=> 0.225;
requires 'perl'							=> 5.10.1;
requires 'PerlIO::utf8_strict'			=> 0.006; # Optionally used by File::Slurper.
requires 'Pod::Usage'					=> 1.51;
requires 'Sort::Naturally'				=> 1.03;
requires 'strict'						=> 1.04;
requires 'Text::Xslate'					=> 1.5008;
requires 'Types::Standard'				=> 1.000005;
requires 'Unicode::CaseFold'			=> 1.00;
requires 'Unicode::Normalize'			=> 1.25;
requires 'warnings'						=> 1.12;

test_requires 'Test2::Bundle::Extended'	=> '0.000030';
test_requires 'Test::More'				=> '1.302022';	# Used by xt/t/pod.t.
test_requires 'Test::Pod'				=> '1.51';		# Used by xt/t/pod.t.

WriteAll;
