# -*- Mode: CPerl -*-
# t/04_json.t: test json subclass

use Test::More tests=>5;
use Tie::File::Indexed::JSON;
my $TEST_DIR = ".";

##-- common variables
my $file = "$TEST_DIR/test_json.dat";
my @w = (undef, 'string', 42, 24.7, {label=>'hash'}, [qw(a b c)]);

##-- 1+3: json data
ok(tie(my @a, 'Tie::File::Indexed::JSON', $file, mode=>'rw'), "json: tie");
@a = @w;
is($#a, $#w, "json: size");
my @atmp = map {tied(@a)->saveJsonString($_)} @a;
my @wtmp = map {tied(@a)->saveJsonString($_)} @w;
is_deeply(\@atmp,\@wtmp, "json: content");

##-- 4+1: gaps -> undef
my $gap = @a;
$a[$gap+1] = 'post-gap';
is($a[$gap], undef, "json: gap ~ undef");

##-- 5+1: unlink
ok(tied(@a)->unlink, "json: unlink");

# end of t/04_json.t
