package Hoge;

use Tie::Trace qw/watch/;


sub new {
  watch my %hoge;
  return bless \%hoge;
}

sub param {
  my $self = shift;
  if (@_ == 2) {
    my($key, $value) = @_;
    return $self->{$key} = $value;
  } else {
    return $self->{shift()};
  }
}

1;
