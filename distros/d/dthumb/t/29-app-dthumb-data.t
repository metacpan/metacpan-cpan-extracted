#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use autodie;

use App::Dthumb::Data;
use Test::More;

opendir(my $share, 'share');
my @files = grep { /^[^.]/ } readdir($share);
closedir($share);

plan(
	tests => 1 + scalar @files,
);

my $dthumb = App::Dthumb::Data->new();

isa_ok($dthumb, 'App::Dthumb::Data', 'App::Dthumb::Data->new()');

for my $file (@files) {
	open(my $fh, '<', "share/${file}");
	my $data = do { local $/ = undef; <$fh> };
	close($fh);

	is($dthumb->get($file), $data, "\$dthumb->get($file)");
}
