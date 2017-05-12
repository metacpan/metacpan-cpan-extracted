# URI::Query hash methods

use strict;
use vars q($count);

BEGIN { $count = 5 }
use Test::More tests => $count;

use_ok('URI::Query');

my ($qq, $out);

# Load result strings
my $test = 't03';
my %result = ();
$test = "t/$test" if -d "t/$test";
die "missing data dir $test" unless -d $test;
{
  opendir my $dir, "$test" or die "can't open $test";
  for (readdir $dir) {
    next if m/^\./;
    open my $file, "<$test/$_" or die "can't read $test/$_";
    local $/ = undef;
    $result{$_} = <$file>;
  }
}

my $print = shift @ARGV || 0;
my $t = 3;
sub report {
  my ($data, $file, $inc) = @_;
  $inc ||= 1;
  if ($print == $t) {
    print STDERR "--> $file\n";
    print $data;
    exit 0;
  }
  $t += $inc;
}

ok($qq = URI::Query->new('foo=1&foo=2&bar=3;bog=abc;bar=7;fluffy=3'), "constructor ok");

SKIP: {
   my $yaml = eval { require YAML };
   skip "YAML not found", 2 unless $yaml;

   # Require YAML 0.39 on Windows (reported by Andy Grundman)
   if ($^O =~ m/^MSWin/i && ! defined eval { YAML->VERSION(0.39) }) {
     skip "YAML >= 0.39 required on windows", 2;
   }

   $out = YAML::Dump(scalar($qq->hash));
   report $out, "hash";
   is($out, $result{hash}, 'hash ok');
   
   $out = YAML::Dump(scalar($qq->hash_arrayref));
   report $out, "hash_arrayref";
   is($out, $result{hash_arrayref}, 'hash_arrayref ok');

}

$out = $qq->hidden;
report $out, "hidden";
is($out, $result{hidden}, 'hidden ok');

