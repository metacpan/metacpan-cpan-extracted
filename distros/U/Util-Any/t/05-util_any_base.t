use Test::More qw/no_plan/;

use lib qw(./lib ./t/lib);
use List::Util ();
use List::MoreUtils ();
use Hash::Util ();
use Scalar::Util ();

use MyUtilBase qw/List/;
no strict 'refs';

my %already_defined;
foreach (@List::Util::EXPORT_OK) {
  ok(defined &{$_} , $_) and $already_defined{$_}++;
}

foreach (@List::MoreUtils::EXPORT_OK) {
  ok(! defined &{$_} , $_) if not $already_defined{$_};
}

foreach (@Scalar::Util::EXPORT_OK) {
  ok(! defined &{$_} , $_) if not $laready_defined{$_};
}

foreach (@Hash::Util::EXPORT_OK) {
  no strict 'refs';
  ok(! defined &{$_} , $_) if defined &{'Hash::Util::' . $_};
}

