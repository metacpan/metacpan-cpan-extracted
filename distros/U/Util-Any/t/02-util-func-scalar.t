use Test::More qw/no_plan/;

use Util::Any {Scalar => [qw/blessed weaken/]};
no strict 'refs';

ok(defined &weaken , 'weaken');
ok(defined &blessed , 'blessed');
my $hoge = bless {};
ok(blessed $hoge, "blessed test");

foreach (grep {$_ ne 'weaken' and $_ ne 'blessed'} @Scalar::Util::EXPORT_OK) {
  ok(! defined &{$_} , $_);
}

foreach (@Hash::Util::EXPORT_OK) {
  no strict 'refs';
  ok(! defined &{$_} , $_) if defined &{'Hash::Util::' . $_};
}

foreach (@List::Util::EXPORT_OK) {
  ok(! defined &{$_} , $_);
}

foreach (@List::MoreUtils::EXPORT_OK) {
  ok(! defined &{$_} , $_);
}
