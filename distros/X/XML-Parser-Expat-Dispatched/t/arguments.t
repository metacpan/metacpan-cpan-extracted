use Test::More;
use strict;
use warnings;


BEGIN{
  plan(tests =>2);
  use_ok ('t::testparser');
}


subtest 'checking arguments', sub {

  my  %expected_args =
    (End             => [['bar'],['test'],['tests']],
     End_foo         => [(['foo'])x2],
     Start_Foo       => [['foo', 'arg', 'hallo'], ['foo']],
     Char_handler    => [(["\n"])x4,["What a test"], ["\n"]],
     Proc_handler    => [['perl', 'aha']],
     Comment_handler => [['Comment']],
     Default_handler => [['<?xml version="1.0"?>'], ["\n"],["\n"]],
    );
  t::testparser->init(keys %expected_args, sub{lc $_[1]});
  plan tests => 1+ keys %expected_args;
  my $p = new_ok 't::testparser';
  $p->parse(*DATA);

  foreach (sort keys %expected_args){
    is_deeply($p->handler_arguments($_),$expected_args{$_},
	      "arguments for $_ as expected");
  }
};


__DATA__
<?xml version="1.0"?>
<tests><?perl aha?>
<foo arg="hallo" ></foo>
<foo /><!--Comment-->
<bar></bar>
<test>What a test</test>
</tests>
