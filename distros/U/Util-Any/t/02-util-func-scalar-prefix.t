use Test::More qw/no_plan/;

use Util::Any {Scalar => [qw/blessed weaken/]}, {prefix => 1};
no strict 'refs';

ok(defined &scalar_weaken , 'scalar_weaken');
ok(defined &scalar_blessed , 'scalar_blessed');
my $hoge = bless {};
ok(scalar_blessed $hoge, "blessed test");

foreach (grep {$_ ne 'weaken' and $_ ne 'blessed'} @Scalar::Util::EXPORT_OK) {
  ok(! defined &{'scalar_' . $_} , 'not defined ' . $_);
}

foreach (@Hash::Util::EXPORT_OK) {
  no strict 'refs';
  ok(! defined &{$_} , 'not defined ' . $_) if defined &{'Hash::Util::' . $_};
}

foreach (@List::Util::EXPORT_OK) {
  ok(! defined &{'list_' . $_} , 'not defined ' . $_);
}

foreach (@List::MoreUtils::EXPORT_OK) {
  ok(! defined &{'list_' . $_} , 'not defined ' . $_);
}
