use strict;
use warnings;
use Test::More tests => 17*3 + 31*2;
use IPC::Open3;
use Config ();

delete $ENV{RELEASE_TESTING};

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
  return wantarray ? ($exit, $out) : $exit;
}

for my $api (
  ['standalone'],
  ['Test2' => 'Test2::API'],
  ['Test::Builder' => 'Test::Builder']
) {
  SKIP: {
    my ($label, @load) = @$api;
    my @using = map {
      my ($e, $o) = capture @perl, "-m$_", "-eprint+$_->VERSION";
      skip "$label not available", 17+31
        if $e;
      "$_ $o";
    } @load;
    print "# Checking against ".join(', ', @using)."\n"
      if @using;
    my $check = sub {
      my ($args, $match, $name) = @_;
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
      $match = !defined $match ? [] : ref $match eq 'ARRAY' ? $match : [$match];
      $unmatch = !defined $unmatch ? [] : ref $unmatch eq 'ARRAY' ? $unmatch : [$unmatch];
      if (!is $exit == 0, !$want_exit, "$name - exit status") {
        ok 0, $name
          for 0 .. $#$match, 0 .. $#$unmatch;
        diag "Exit status $exit\nOutput:\n$out";
      }
      else {
        for my $m (@$match) {
          like $out, $m, $name;
        }
        for my $um (@$unmatch) {
          unlike $out, $um, $name;
        }
      }
    };

    $check->(
      [$missing],
      qr/^1\.\.0 # SKIP/i,
      'Missing module SKIPs',
    );
    $check->(
      ['BrokenModule'],
      { match => qr/syntax error/, exit => 1 },
      'Broken module dies',
    );
    $check->(
      ['ModuleWithVersion'],
      qr/^(?!1\.\.0 # SKIP)/i,
      'Working module runs',
    );
    $check->(
      ['ModuleWithVersion', 2],
      qr/^1\.\.0 # SKIP/i,
      'Outdated module SKIPs',
    );

    {
      local $ENV{RELEASE_TESTING} = 1;
      $check->(
        [$missing],
        { match => qr/^not ok/m, exit => 1 },
        'Missing module fails with RELEASE_TESTING',
      );
      $check->(
        ['BrokenModule'],
        { match => qr/syntax error/, exit => 1 },
        'Broken module dies with RELEASE_TESTING',
      );
      $check->(
        ['ModuleWithVersion'],
        qr/^(?!1\.\.0 # SKIP)/i,
        'Working module runs with RELEASE_TESTING',
      );
      $check->(
        ['ModuleWithVersion', 2],
        { match => qr/^not ok/m, unmatch => qr/Cleaning up the CONTEXT stack/, exit => 1 },
        'Outdated module fails with RELEASE_TESTING',
      );
    }

    next
      unless @load;

    $check->(
      [$missing, '--plan'],
      qr/# skip/,
      'Missing module skips with plan',
    );
    $check->(
      [$missing, '--no_plan'],
      qr/# skip/,
      'Missing module skips with no_plan',
    );
    SKIP: {
      skip 'Test::More too old to run tests without plan', 2
        if !Test::More->can('done_testing');
      $check->(
        [$missing, '--tests'],
        qr/# skip/,
        'Missing module skips with tests',
      );
    }
    $check->(
      [$missing, '--plan', '--tests'],
      qr/# skip/,
      'Missing module passes with plan and tests',
    );
    $check->(
      [$missing, '--no_plan', '--tests'],
      qr/# skip/,
      'Missing module passes with no_plan and tests',
    );

    SKIP: {
      skip 'Test::More too old to run subtests', 21
        if !Test::More->can('subtest');

      $check->(
        [$missing, '--subtest'],
        qr/^ +1\.\.0 # SKIP/mi,
        'Missing module skips in subtest',
      );
      $check->(
        ['BrokenModule', '--subtest'],
        { match => qr/syntax error/, exit => 1 },
        'Broken module dies in subtest',
      );
      $check->(
        ['ModuleWithVersion', '--subtest'],
        [ qr/^ +1\.\.(?!0 # SKIP)/mi, qr/^ok[^\n#]+(?!# skip)/m ],
        'Working module runs in subtest',
      );
      $check->(
        ['ModuleWithVersion', 2, '--subtest'],
        qr/^ +1\.\.0 # SKIP/mi,
        'Outdated module skips in subtest',
      );

      $check->(
        [$missing, '--subtest', '--plan'],
        qr/# skip/,
        'Missing module skips with plan in subtest',
      );
      $check->(
        [$missing, '--subtest', '--no_plan'],
        qr/# skip/,
        'Missing module skips with no_plan in subtest',
      );
      $check->(
        [$missing, '--subtest', '--tests'],
        qr/# skip/,
        'Missing module skips with tests in subtest',
      );
      $check->(
        [$missing, '--subtest', '--plan', '--tests'],
        qr/# skip/,
        'Missing module passes with plan and tests in subtest',
      );
      $check->(
        [$missing, '--subtest', '--no_plan', '--tests'],
        qr/# skip/,
        'Missing module passes with no_plan and tests in subtest',
      );

      local $ENV{RELEASE_TESTING} = 1;
      $check->(
        [$missing, '--subtest'],
        { match => qr/^ +not ok/m, exit => 1 },
        'Missing module fails in subtest with RELEASE_TESTING',
      );
    }
  }
}
