use strict;
use YATT::Lite qw/Entity/;

Entity localtime => sub {
  my ($this, $time) = @_;
  require Time::Piece;
  # Intentionally use problematic style to test $SIG{__DIE__}
  Time::Piece::localtime($time);
};
