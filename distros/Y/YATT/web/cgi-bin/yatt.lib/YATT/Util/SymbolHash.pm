package YATT::Util::SymbolHash;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use Exporter qw(import);
our @EXPORT = qw(rebless_hash_with);

use Hash::Util qw(lock_keys unlock_keys);

sub rebless_hash_with {
  my ($self, $newclass) = @_;
  unlock_keys(%$self);
  bless $self, $newclass;
  lock_keys(%$self, keys %{YATT::Util::Symbol::fields_hash_of_class($newclass)});
  $self
}

1
