use Test::Base;

use lib qw{t/lib};
use Hoge;
use strict;

my $hoge = new Hoge;

sub to_param {
  my $err;
  local $SIG{__WARN__} = sub { $err .= shift; };
  $hoge->param(@_);
  return $err;
}

sub hoge {
  my($key, $value) = @_;
  my $err;
  local $SIG{__WARN__} = sub { $err .= shift; };
  $hoge->param($key => $value);
  return $err;
}

sub hoge2 {
  my($key, $value) = @_;
  my $err;
  local $SIG{__WARN__} = sub { $err .= shift; };
  $hoge->{$key} = $value;
  $err =~s{t[/\\]tie-trace-module\.t}{t-tie-trace-module\.t}g;
  return $err;
}

filters {
        i       => ['eval', 'to_param'],
        i_hoge  => ['eval', 'hoge'],
        i_hoge2 => ['eval', 'hoge2'],
};

run_is i       => 'e';
run_is i_hoge  => 'e';
run_is i_hoge2 => 'e';

__END__
=== param
--- i
key => "a"
--- e
Hoge:: %hoge => {key} => 'a' at t/lib/Hoge.pm line 15.
=== param2
--- i
key => "b"
--- e
Hoge:: %hoge => {key} => 'b' at t/lib/Hoge.pm line 15.
=== hoge
--- i_hoge
abc => "def"
--- e
Hoge:: %hoge => {abc} => 'def' at t/lib/Hoge.pm line 15.
=== hoge2
--- i_hoge2
key => "value"
--- e
Hoge:: %hoge => {key} => 'value' at t-tie-trace-module.t line 28.
