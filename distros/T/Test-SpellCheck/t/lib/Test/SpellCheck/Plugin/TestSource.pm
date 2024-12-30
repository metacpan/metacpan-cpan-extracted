package Test::SpellCheck::Plugin::TestSource;

use strict;
use warnings;
use experimental qw( signatures );

sub new ($class, %args)
{
  bless {
    events => $args{events},
  }, $class;
}

sub stream ($self, $filename, $, $callback)
{
  foreach my $event ($self->{events}->@*)
  {
    my($type, $ln, $word) = @$event;
    $callback->($type, $filename, $ln, $word);
  }
}

1;
