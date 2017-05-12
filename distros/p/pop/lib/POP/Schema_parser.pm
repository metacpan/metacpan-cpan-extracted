package POP::Schema_parser;

use Carp;
use strict;

sub new {
  my $type = shift;
  $type = ref($type) || $type;
  return bless {}, $type;
}

sub parse {
  my($this, $fh) = @_;
  local $/ = ""; # Paragraph mode
  while (<$fh>) {
    s/^--([A-Z]+)(?:\s+CLASS=\[([^\]]+)\])?\n// or croak "Syntax error [$_]";
    my($type, $class) = ($1, $2);
    $class ||= 'GLOBAL';
    push(@{$this->{$class}}, {'type' => $type, 'sql' => $_});
  }
}

1;
