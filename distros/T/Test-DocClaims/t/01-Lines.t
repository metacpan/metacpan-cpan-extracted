#!perl

use strict;
use warnings;
use lib "lib";
use Test::More tests => 152;

BEGIN { use_ok('Test::DocClaims::Lines'); }
can_ok('Test::DocClaims::Lines', 'new');

my @data = (
[ 0,  undef,  undef, 'package code1;'],
[ 0,  undef,  undef, ''],
[ 1,  undef,  undef, '=head1 HEADING'],
[ 1,  undef,  undef, ''],
[ 0,  undef, {y=>2}, '=for DC_TODO y=2'],
[ 1,  undef,  undef, ''],
[ 0, {x=>1},  undef, '=begin DC_CODE x=1'],
[ 1, {x=>1},  undef, ''],
[ 1, {x=>1},  undef, '    example();'],
[ 1, {x=>1},  undef, ''],
[ 0,  undef,  undef, '=end DC_CODE'],
[ 1,  undef,  undef, ''],
[ 0,  undef,  undef, '=cut'],
[ 0,  undef,  undef, ''],
[ 0,  undef,  undef, ''],
[ 0,  undef,  undef, '  use Bar;'],
[ 0,  undef,  undef, ''],
[ 0,  undef,  undef, 'sub example {'],
[ 0,  undef,  undef, '    return 42;'],
[ 0,  undef,  undef, '}'],
[ 0,  undef,  undef, ''],
);

my ( $lines, $line );

my $path = "t/Foo.t";
eval { $lines = Test::DocClaims::Lines->new($path); };
is($@, "", "does not die") or diag $@;
isa_ok($lines, "Test::DocClaims::Lines");

my $lnum = 0;
foreach my $entry (@data) {
    my ( $is_doc, $code, $todo, $expect ) = @$entry;
    $lnum++;
    my $where = "at $path line $lnum";
    ok(!$lines->is_eof, "is_eof $where");
    $line = $lines->current_line;
    isa_ok($line, "Test::DocClaims::Line", "isa_ok $where");
    is(!!$line->has_pod, !!1, "has_pod $where");
    is(!!$line->is_doc, !!$is_doc, "is_doc $where");
    is_deeply($line->code, $code, "code $where");
    is_deeply($line->todo, $todo, "todo $where");
    my $text = $expect;
    $text =~ s/^\s*#[@?][a-z]*( |$)//;
    $text =~ s/^\s+/ /;
    is($line->text, $text, "text $where");

    $lines->advance_line;
}
ok($lines->is_eof);

#-----------------------------------------------------------------------------
no warnings 'redefine';

sub Test::DocClaims::Lines::_read_file {
    my $self = shift;
    my $path = shift;
    return [ map { $_->[3] . "\n" } @data ];
}

