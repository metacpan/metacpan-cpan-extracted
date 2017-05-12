# Conditional testing that plugin-installed methods are visible
# from the underlying Mech object returned by mech()
use Test::More tests=>2;
use Test::WWW::Simple;

my $snapshot_loaded;

BEGIN {
  eval "use WWW::Mechanize::Plugin::Snapshot";
  $snapshot_loaded = !$@;
}

SKIP: {
  skip "WWW::Mechanize::Plugin::Snapshot not installed",2
    unless $snapshot_loaded;
  ok mech->can('snapshots_to'), "snapshots_to available";
  ok mech->can('snapshot'),     "snapshot available";
}
