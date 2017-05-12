package # no_index
  TestHelpers;

use Test::More;

use Sub::Exporter -setup => {
  exports => [qw(
    no_error_ok
    no_warnings_ok
    warnings_like
    trap_warnings
  )]
};

sub no_error_ok () {
  is $@, '', 'no error';
}

my @warnings;

sub no_warnings_ok () {
  is scalar(@warnings), 0, 'no warnings'
    or diag explain \@warnings;
}

sub warnings_like (@) {
  while( my ($re, $desc) = splice(@_, 0, 2) ){
    like shift(@warnings), $re, $desc;
  }
  no_warnings_ok();
}

sub trap_warnings (&) {
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  local $@ = 'no error yet';
  $_[0]->();
}

1;
