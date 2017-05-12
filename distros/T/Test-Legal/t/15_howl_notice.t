use Test::More 'no_plan';
use Test::Legal::Util qw/ howl_notice /;


my $msg = '# Copyright (C) by  bottle';

my $dir     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';

is howl_notice('hi'),'# hi', 'simple string';
like howl_notice(), qr/^\Q# Copyright (C)/o;
like howl_notice(''), qr/^\Q# Copyright (C)/o;
like howl_notice(0), qr/^\Q# Copyright (C)/o;
like howl_notice("$dir/bak/apple"), qr{^\Q#/usr/bin/env}o;;
like howl_notice("$dir/bak/blank"), qr/^\Q# Copyright (C)/o;

