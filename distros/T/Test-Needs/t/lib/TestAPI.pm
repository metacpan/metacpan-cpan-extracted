package TestAPI;
use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Config ();

my @perl = $^X =~ /(.*)/s;

{
  my $taint;
  local $^W = 0;
  local $@;
  local $SIG{__DIE__};
  local $SIG{__WARN__} = sub {
    $taint = 1;
    push @perl, '-t';
  };
  if (!eval { eval substr($ENV{PATH}, 0, 0); 1 }) {
    $taint = 1;
    push @perl, '-T';
  }
  if ($taint) {
    $ENV{PATH} = '/';
    delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
  }
}

my %inc;
{
  my $cmd = join ' ', map qq{"$_"}, @perl, '-le', 'print for @INC';
  my @inc = `$cmd`;
  chomp @inc;
  @inc{@inc} = ();
}
my @need_inc;
my $i = -1;
push @need_inc, $INC[$i]
  while ++$i < @INC && !exists $inc{$INC[$i]};

my $inc_extension = qr/[\\\/]\Q$Config::Config{archname}\E|[\\\/]\Q$Config::Config{version}\E(?:[\\\/]\Q$Config::Config{archname}\E)?/;

my $bare;
for my $path (@need_inc) {
  unless (defined $bare and $path =~ /\A\Q$bare\E$inc_extension\z/) {
    $bare = $path;
    push @perl, "-I$path";
  }
}

push @perl, "-It/lib";

my $missing = "Module::Does::Not::Exist::".time;

sub capture {
  my $pid = open3 my $stdin, my $stdout, undef, @_
    or die "can't run @_: $!";
  my $out = do { local $/; <$stdout> };
  close $stdout;
  waitpid $pid, 0;
  my $exit = $?;
  $out =~ s{^Possible precedence issue with control flow operator at .*Test/Builder\.pm.*\n}{};
  return wantarray ? ($exit, $out) : $exit;
}

BEGIN {
  *note = sub { print '# '.join('', @_)."\n" }
    if !defined &note;
}

sub check {
  my ($load, $args, $match, $name) = @_;
  my ($label, @load) = @$load;
  my @args = ((map "--load=$_", @load), @$args);
  my ($exit, $out)
    = capture @perl, '-MTestScript' . (@args ? '='.join(',', @args) : '');
  $name = "$label: $name";
  my $want_exit;
  my $unmatch;
  if (ref $match eq 'HASH') {
    $want_exit = $match->{exit};
    $unmatch = $match->{unmatch};
    $match = $match->{match};
  }
  $match   = !defined $match    ? [] : ref $match eq 'ARRAY'    ? $match    : [$match];
  $unmatch = !defined $unmatch  ? [] : ref $unmatch eq 'ARRAY'  ? $unmatch  : [$unmatch];
  if (!is $exit == 0, !$want_exit, "$name - exit status") {
    ok 0, $name
      for 1, 0 .. $#$match, 0 .. $#$unmatch;
    diag "Exit status $exit\nOutput:\n$out";
    return;
  }

  my $plan_count = () = $out =~ /^[0-9]+\.\.[0-9]+(?: |$)/mg;
  if (!ok $plan_count <= 1, "$name - no excess plans") {
    ok 0, $name
      for 0 .. $#$match, 0 .. $#$unmatch;
    diag "Output:\n$out";
    return;
  }

  for my $m (@$match) {
    like $out, $m, $name;
  }
  for my $um (@$unmatch) {
    unlike $out, $um, $name;
  }
}

sub test_api {
  my ($label, @load) = @_;
  local $ENV{RELEASE_TESTING};
  delete $ENV{RELEASE_TESTING};

  my @using = map {
    my ($e, $o) = capture @perl, "-m$_", "-eprint+$_->VERSION";
    $e ? () : "$_ $o";
  } @load;

  if (@using != @load) {
    plan skip_all => "$label not available";
    return;
  }

  plan tests => ( 14*3 + 1*4 ) * !!@load + (7*3 + 1*4);

  note "Checking against ".join(', ', @using)."\n"
    if @using;

  check([@_],
    [$missing],
    qr/^1\.\.0 # SKIP/i,
    'Missing module SKIPs',
  );
  check([@_],
    ['BrokenModule'],
    { match => qr/syntax error/, exit => 1 },
    'Broken module dies',
  );
  check([@_],
    ['ModuleWithVersion'],
    qr/^(?!1\.\.0 # SKIP)/i,
    'Working module runs',
  );
  check([@_],
    ['ModuleWithVersion', 2],
    qr/^1\.\.0 # SKIP/i,
    'Outdated module SKIPs',
  );

  {
    local $ENV{RELEASE_TESTING} = 1;
    check([@_],
      [$missing],
      { match => qr/^not ok/m, exit => 1 },
      'Missing module fails with RELEASE_TESTING',
    );
    check([@_],
      ['BrokenModule'],
      { match => qr/syntax error/, exit => 1 },
      'Broken module dies with RELEASE_TESTING',
    );
    check([@_],
      ['ModuleWithVersion'],
      qr/^(?!1\.\.0 # SKIP)/i,
      'Working module runs with RELEASE_TESTING',
    );
    check([@_],
      ['ModuleWithVersion', 2],
      { match => qr/^not ok/m, unmatch => qr/Cleaning up the CONTEXT stack/, exit => 1 },
      'Outdated module fails with RELEASE_TESTING',
    );
  }

  return
    unless @load;

  check([@_],
    [$missing, '--plan'],
    qr/# skip/,
    'Missing module skips with plan',
  );
  check([@_],
    [$missing, '--no_plan'],
    qr/# skip/,
    'Missing module skips with no_plan',
  );
  SKIP: {
    skip 'Test::More too old to run tests without plan', 3
      if !Test::More->can('done_testing');
    check([@_],
      [$missing, '--tests'],
      qr/# skip/,
      'Missing module skips with tests',
    );
  }
  check([@_],
    [$missing, '--plan', '--tests'],
    qr/# skip/,
    'Missing module passes with plan and tests',
  );
  check([@_],
    [$missing, '--no_plan', '--tests'],
    qr/# skip/,
    'Missing module passes with no_plan and tests',
  );

  SKIP: {
    skip 'Test::More too old to run subtests', 9*3 + 1*4
      if !Test::More->can('subtest');

    check([@_],
      [$missing, '--subtest'],
      qr/^ +1\.\.0 # SKIP/mi,
      'Missing module skips in subtest',
    );
    check([@_],
      ['BrokenModule', '--subtest'],
      { match => qr/syntax error/, exit => 1 },
      'Broken module dies in subtest',
    );
    check([@_],
      ['ModuleWithVersion', '--subtest'],
      [ qr/^ +1\.\.(?!0 # SKIP)/mi, qr/^ok[^\n#]+(?!# skip)/m ],
      'Working module runs in subtest',
    );
    check([@_],
      ['ModuleWithVersion', 2, '--subtest'],
      qr/^ +1\.\.0 # SKIP/mi,
      'Outdated module skips in subtest',
    );

    check([@_],
      [$missing, '--subtest', '--plan'],
      qr/# skip/,
      'Missing module skips with plan in subtest',
    );
    check([@_],
      [$missing, '--subtest', '--no_plan'],
      qr/# skip/,
      'Missing module skips with no_plan in subtest',
    );
    check([@_],
      [$missing, '--subtest', '--tests'],
      qr/# skip/,
      'Missing module skips with tests in subtest',
    );
    check([@_],
      [$missing, '--subtest', '--plan', '--tests'],
      qr/# skip/,
      'Missing module passes with plan and tests in subtest',
    );
    check([@_],
      [$missing, '--subtest', '--no_plan', '--tests'],
      qr/# skip/,
      'Missing module passes with no_plan and tests in subtest',
    );

    local $ENV{RELEASE_TESTING} = 1;
    check([@_],
      [$missing, '--subtest'],
      { match => qr/^ +not ok/m, exit => 1 },
      'Missing module fails in subtest with RELEASE_TESTING',
    );
  }
}

1;
