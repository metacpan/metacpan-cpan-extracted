package t::Util;
use strict;
use warnings;

use Test::Tester;
use Test::More;
use Exporter qw(import);
use List::MoreUtils qw(any all);

our @EXPORT_OK = qw(expect_fail expect_pass);

sub expect_fail(&;$) {
    my ($code, $name) = @_;
    my ($premature, @results) = run_tests($code);
    ok((any { !$_->{ok} } @results),
       'expect_fail' . (defined $name ? " - $name" : ''));
}

sub expect_pass(&;$) {
    my ($code, $name) = @_;
    my ($premature, @results) = run_tests($code);
    ok((all { $_->{ok} } @results),
       'expect_pass' . (defined $name ? " - $name" : ''));
}

1;
