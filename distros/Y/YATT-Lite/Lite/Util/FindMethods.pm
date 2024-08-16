package YATT::Lite::Util::FindMethods;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use Exporter qw(import);
our @EXPORT = qw(FindMethods);

use YATT::Lite::Util qw(symtab);

sub FindMethods {
  # depth first, pre-order search of 'sub'.
  # In the real sense, this should be called 'Findsubs'.
  my ($obj, $pattern, $visited, $found) = @_;
  $visited ||= {};
  $found   ||= {};
  my $class = ref($obj) ? ref($obj) : $obj;
  $visited->{$class} = 1;
  my $symtab = symtab($class);
  local $_;
  foreach my $orig (keys %$symtab) {
    $_ = $orig;
    if ($pattern) {
      if (ref $pattern eq 'CODE') {
	$pattern->($_) or next;
      } else {
	$_ =~ $pattern or next;
      }
    }
    my $glob = $symtab->{$orig};
    next if ref $glob;
    # {
    #   local $@;
    #   # To avoid 'Not a GLOB reference'.
    #   my $is_code = eval {*{$glob}{CODE}};
    #   if ($@) {
    #     next;
    #   } elsif (not $is_code) {
    #     next;
    #   }
    # }
    next unless *{$glob}{CODE};
    $found->{$_} //= $class;
  }

  my $isa = $symtab->{ISA};
  if (defined $isa and *{$isa}{ARRAY}) {
    foreach my $super (@{*{$isa}{ARRAY}}) {
      FindMethods($super, $pattern, $visited, $found)
	unless $visited->{$super};
    }
  }

  if (wantarray) {
    sort keys %$found
  } else {
    $found;
  }
}

1;
