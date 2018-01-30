use 5.012;
use strict;
use warnings;
use Test::More;
use lib 'lib';

use Util::EvalSnippet;

{
  use Cwd qw(abs_path);
  my $path = abs_path(__FILE__);
  $path =~ s|(^.*?)/t/.*|$1/t/data/test-snippets|;
  $ENV{SNIPPET_DIR} = $path;
}

our ($y,@y,%y);

# snippet with no name works
subtest basic => sub {
  my $x=0;
  eval_snippet();
  is($x,12,'basic snippet');
};

# vars with the same name interpolate correctly
subtest same_name => sub {
  my $x; my @x; my %x;

  eval_snippet('same_name_basics');

  is($x,1,'my scalar');
  is(scalar(@x),2,'my array');
  is($x{test},'value','my hash');

  is($y,1,'our scalar');
  is(scalar(@y),2,'our array');
  is($y{test},'value','our hash');
};

subtest substring_name => sub {
  my $x=0; my $xx=10;

  eval_snippet('substring_name');

  is($x,1,'$x is OK');
  is($xx,11,'$xx is OK');
};

subtest symbols=> sub {
  my $x=0;
  use constant SEVEN => 7;

  # method doesn't exist
  eval { set_to_100($x); };
  ok($@,"non-existent method call dies");

  eval_snippet('symbols');

  is($x,7,"CONSTANT works");

  # method now exists
  set_to_100($x);
  is($x,100,"method created in snippet works");
};

subtest references => sub {
  my $x=0;
  my $sub_ref   = sub { $_[0]++; };
  my $hash_ref  = {test=>'value'};
  my $array_ref = [1,2,3];

  eval_snippet('refs_1');

  is($x,1,'sub ref in parent');
  is($hash_ref->{one},'two','dereferenced hashref assignment');
  is($hash_ref->{three},'four','hashref assignment');
  is($array_ref->[0],0,'push arrayref');
  is($array_ref->[3],4,'arrayref element assignment');

};

subtest create_snippet => sub {
  my $path = Util::EvalSnippet::_snippet_dir.'/main-NEW';
  ok(! -f $path, "NEW snippet doesn't exist");
  eval_snippet('NEW');
  ok(-f $path, "NEW snippet exists");
  Util::EvalSnippet::_delete('NEW');
  ok(! -f $path, "NEW snippet deleted");
};

subtest safe_mode => sub {
  local $ENV{ALLOW_SNIPPETS};
  eval "use Util::EvalSnippet 'safe';";
  ok($@,"Won't load in safe mode");
  $ENV{ALLOW_SNIPPETS}=1;
  eval "use Util::EvalSnippet 'safe';";
  ok(!$@,"Loads in safe mode after ENV var set");
};

done_testing();

sub increment_by_one {
  return 1+shift;
}
