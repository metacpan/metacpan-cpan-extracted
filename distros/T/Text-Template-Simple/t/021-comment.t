#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $TEMPLATE = <<'COMMENT';
No comment<%#
This
is
a
multi-line
comment
which
will
be
ignored
%>
COMMENT

chomp $TEMPLATE;

ok( my $t = Text::Template::Simple->new(), 'Got the object' );

is( $t->compile( $TEMPLATE ), 'No comment', 'Comment removed successfully' );
