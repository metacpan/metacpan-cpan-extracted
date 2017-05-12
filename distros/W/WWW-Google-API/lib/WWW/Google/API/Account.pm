package WWW::Google::API::Account;

use strict;
use warnings;

use base qw(Class::Accessor);

__PACKAGE__->mk_ro_accessors(qw(ua));

sub new {
  my $class = shift;

  my $self = {
    ua => shift,
  };
  bless($self, $class);

  return $self;
}

sub authenticate {
  die 'Please sublcass';
}

1;
