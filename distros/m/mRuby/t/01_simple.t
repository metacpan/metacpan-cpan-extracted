use strict;
use warnings;
use utf8;
use Test::More;
use mRuby;

subtest 'basic' => sub {
    my $mruby = mRuby->new(src => '9');
    isa_ok $mruby, 'mRuby';
    my $ret = $mruby->run();
    is $ret, 9;
};

subtest 'basic funcall' => sub {
    my $mruby = mRuby->new(src => <<'...');
def ika()
  "geso"
end
...
    isa_ok $mruby, 'mRuby';
    my $ret = $mruby->funcall('ika');
    is $ret, 'geso';
};

subtest 'simple' => sub {
    my $mrb = mRuby::State->new();
    isa_ok($mrb, 'mRuby::State');
    my $st = $mrb->parse_string('9');
    isa_ok($st, 'mRuby::ParserState');
    my $proc = $mrb->generate_code($st);
    isa_ok($proc, 'mRuby::RProc');
    my $ret = $mrb->run($proc, undef);
    is($ret, 9);
};

subtest 'return string' => sub {
    my $mrb = mRuby::State->new();
    isa_ok($mrb, 'mRuby::State');
    my $st = $mrb->parse_string('"OK" + "JOHN"');
    isa_ok($st, 'mRuby::ParserState');
    my $proc = $mrb->generate_code($st);
    isa_ok($proc, 'mRuby::RProc');
    my $ret = $mrb->run($proc, undef);
    is($ret, 'OKJOHN');
};

subtest 'simple funcall' => sub {
    my $mrb = mRuby::State->new();
    isa_ok($mrb, 'mRuby::State');
    my $st = $mrb->parse_string(<<'...');
def nine()
  return 9
end
nil
...
    isa_ok($st, 'mRuby::ParserState');
    my $proc = $mrb->generate_code($st);
    isa_ok($proc, 'mRuby::RProc');
    $mrb->run($proc, undef);
    my $ret = $mrb->funcall('nine');
    note explain $ret;
    is($ret, 9);
};

subtest 'simple funcall return int' => sub {
    my $mrb = mRuby::State->new();
    isa_ok($mrb, 'mRuby::State');
    my $st = $mrb->parse_string(<<'...');
def incr(i)
  return i.to_i + 1
end
...
    isa_ok($st, 'mRuby::ParserState');
    my $proc = $mrb->generate_code($st);
    isa_ok($proc, 'mRuby::RProc');
    $mrb->run($proc, undef);
    my $ret = $mrb->funcall('incr', 1);
    is($ret, 2);
};

done_testing;

