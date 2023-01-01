#!perl
use Test2::V0;

my @modules = <<'EOM' =~ m/([A-Z][A-Za-z0-9:]+)/g;
Test2::Tools::Command
EOM

my $loaded = 0;
for my $m (@modules) {
    local $@;
    eval "require $m";
    if ($@) { bail_out "require failed '$m': $@" }
    $loaded++;
}

diag
  "Testing Test2::Tools::Command $Test2::Tools::Command::VERSION, Perl $], $^X";
is $loaded, scalar @modules;
done_testing;
