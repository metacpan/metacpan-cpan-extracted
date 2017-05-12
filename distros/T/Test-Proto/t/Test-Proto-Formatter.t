#!perl -T
use Test::More;
use Test::Proto::Formatter;
ok (1, 'ok is ok');

sub new_formatter { Test::Proto::Formatter->new(@_); }

ok defined new_formatter, 'Formatter->new is defined';
ok ref new_formatter, 'Formatter->new is an object';
isa_ok new_formatter, 'Test::Proto::Formatter', 'Formatter->new is a Test::Proto::Formatter';


done_testing;

