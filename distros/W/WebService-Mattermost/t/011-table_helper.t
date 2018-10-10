#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Test::Most tests => 5;
use Test::Exception;

use lib "$FindBin::RealBin/../lib";

use WebService::Mattermost::Helper::Table;

ok my $helper = WebService::Mattermost::Helper::Table->new({
    alignment => [ qw(l c r) ],
    headers   => [ qw(first second third) ],
    values    => [
        [ qw(r1-col1 r1-col2 r1-col3) ],
        [ qw(r2-col1 r2-col2 r2-col3) ],
    ],
}), 'Constructing a table...';

my $expected_table = <<'TBL';
| first| second| third|
|:----|:---:|----:|
|r1-col1|r1-col2|r1-col3|
|r2-col1|r2-col2|r2-col3|
TBL

is $helper->table, $expected_table, 'Table set up correctly';

ok $helper = WebService::Mattermost::Helper::Table->new({
    headers   => [ qw(first second third) ],
    values    => [
        [ qw(r1-col1 r1-col2 r1-col3) ],
        [ qw(r2-col1 r2-col2 r2-col3) ],
    ],
}), 'Constructing another table...';

$expected_table = <<'TBL';
| first| second| third|
|:----|:----|:----|
|r1-col1|r1-col2|r1-col3|
|r2-col1|r2-col2|r2-col3|
TBL

is $helper->table, $expected_table, 'Table set up correctly';

dies_ok {
    $helper = WebService::Mattermost::Helper::Table->new({
        alignment => [ qw(bad col alignment) ],
        headers   => [ qw(first second third) ],
        values    => [
            [ qw(r1-col1 r1-col2 r1-col3) ],
            [ qw(r2-col1 r2-col2 r2-col3) ],
        ],
    })
} 'Passed bad names to alignment enum';
__END__

=head1 NAME

t/011-table_helper.t

=head1 DESCRIPTION

Unit test for the table helper.

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

