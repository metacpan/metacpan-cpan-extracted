package WWW::Jawbone::Up::User;

use 5.010;
use strict;
use warnings;

use base 'WWW::Jawbone::Up::JSON';

__PACKAGE__->add_accessors(
  qw(first last name short_name), {
    friend => 'user_is_friend'
  });

sub image {
  my $self = shift;
  return 'https://jawbone.com/' . $self->{image};
}

1;

