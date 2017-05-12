package YATT::Lite::Test::TestUtil;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use Exporter qw/import/;

our @EXPORT = qw/eq_or_diff/;
our @EXPORT_OK = (@EXPORT
		  , qw/capture_stderr/);

require Test::More;

if (eval {require Test::Differences}) {
  *eq_or_diff = *Test::Differences::eq_or_diff;
} else {
  *eq_or_diff = *Test::More::is;
}

sub capture_stderr (&) {
  my ($sub) = @_;
  my $buffer = "";
  {
    open my $fh, '>', \$buffer;
    local *STDERR = *$fh;
    $sub->();
  }
  $buffer;
}

1;
