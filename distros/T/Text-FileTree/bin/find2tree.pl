#!/usr/bin/perl
# Copyright (c) 2012 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use warnings;
use strict;
use feature qw/say/;
use Text::FileTree;

sub out_node {
	my $tree = shift;
	my $level = shift // 0;

	for(sort keys %{$tree}) {
		say ' 'x$level, $_;
		out_node($tree->{$_}, $level + 1);
	}
}

my $ft = Text::FileTree->new;
out_node($ft->parse(<>));
