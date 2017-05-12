package
  ToyApp1;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use YATT::Lite::WebMVC0::DirApp -as_base;
use YATT::Lite qw/Entity *CON/;

use List::Util qw/sum/;

Entity sum => sub {
  my ($this, @args) = @_;
  sum @args;
};

1;
