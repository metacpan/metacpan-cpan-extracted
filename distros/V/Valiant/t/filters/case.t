use Test::Lib;
use Test::Most;

{
  package Local::Test::User;

  use Moo;
  use Valiant::Filters;

  has 'uc_first' => (is=>'ro', required=>1);
  has 'upper' => (is=>'ro', required=>1);
  has 'lower' => (is=>'ro', required=>1);
  has 'title' => (is=>'ro', required=>1);
  has 'nickname' => (is=>'ro', default=>'anon');
  has 'callsign' => (is=>'ro', default=>'anon');

  filters uc_first => (uc_first => 1);
  filters upper => (upper => 1);
  filters lower => (lower => 1);
  filters title => (title => 1);
  filters nickname => (upper => 1);
  filters callsign => (uc_first => 1);
}

my @warnings;
my $user = do {
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  Local::Test::User->new(
    uc_first=>'john',
    upper=>'john',
    lower=>'JOHN',
    title=>'john NAPIORKOWSKI',
  );
};

is $user->uc_first, 'John';
is $user->upper, 'JOHN';
is $user->lower, 'john';
is $user->title, 'John Napiorkowski';
is $user->nickname, undef, 'an omitted upper-filtered attribute is left undef, not clobbered with ""';
is $user->callsign, undef, 'an omitted uc_first-filtered attribute is left undef, not clobbered with ""';
is_deeply \@warnings, [], 'omitting a filtered attribute does not raise an uninitialized-value warning';

done_testing;
