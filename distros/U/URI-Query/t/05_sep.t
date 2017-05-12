# Test separator handling

use strict;
use vars q($count);

BEGIN { $count = 6 }
use Test::More tests => $count;

use_ok('URI::Query');

my ($qq, $out);

# Load result strings
my $test = 't05';
my %result = ();
$test = "t/$test" if -d "t/$test";
die "missing data dir $test" unless -d $test;
{
  opendir my $dir, "$test" or die "can't open $test";
  for (readdir $dir) {
    next if m/^\./;
    open my $file, "<$test/$_" or die "can't read $test/$_";
    {
      local $/ = undef;
      $result{$_} = <$file>;
    }
    chomp $result{$_};
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
$out = $qq->stringify;
report $out, "standard";
is($out, $result{standard}, "standard stringify ok");

# Stringify with an explicit separator
$out = $qq->stringify(';');
report $out, "explicit";
is($out, $result{explicit}, "explicit separator ok");

# Recheck standard in place
$out = $qq->stringify;
report $out, "standard";
is($out, $result{standard}, "standard stringify ok");

# Set default separator
$qq->separator(';');
$out = $qq->stringify;
report $out, "default";
is($out, $result{default}, "setting default separator ok");

