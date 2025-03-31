use strict;
use warnings;
use Test::More;
use Type::Guess;
use Mojo::Util qw/dumper/;

$\ = "\n"; $, = "\t";

my @list = qw/a b cd efg hijk/;
my $str = Type::Guess->with_roles(qw/+Unicode +Tiny/)->new();

$str = $str->analyse(@list);
ok($str->to_string eq '%-4s');

@list = qw/1 23 456 12000 12.0/;
$str = $str->analyse(@list);
ok($str->to_string eq '%5i');

@list = qw/1.12345 23 456 12000 12.0/;
$str = $str->analyse(@list);
ok($str->to_string eq '%11.5f');

done_testing()
