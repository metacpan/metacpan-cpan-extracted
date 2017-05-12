# -*- mode: perl; coding: utf-8 -*-
package YATT::Fields;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use YATT::Util::Symbol;

sub import {
  require fields;
  my ($thispack) = shift;
  my ($callpack) = caller;
  my @public;
  my @setter;
  my @FIELDS;
  foreach my $desc (@_) {
    my ($slot, $default);
    if (ref $desc) {
      $slot = shift @$desc;
      $default = do {
	if (@$desc > 1) {
	  sub { wantarray ? @$desc : [@$desc]; };
	} elsif (! @$desc) {
	  undef;
	} elsif (ref(my $value = $desc->[0]) eq 'CODE') {
	  $value;
	} else {
	  sub () { $value; }
	}
      };
    } else {
      $slot = $desc;
    }
    if ($slot =~ s/^([\^=]+)((?:cf_)?)//) {
      my $func_name = $slot;
      my $cf_slot = "$2$slot";
      foreach my $ch (split //, $1) {
	push @public, [$func_name, $cf_slot] if $ch eq '^';
	push @setter, [$func_name, $cf_slot] if $ch eq '=';
      }
      push @FIELDS, $cf_slot;
    } else {
      push @FIELDS, $slot;
    }
    if (defined $default) {
      *{globref($callpack, "default_$slot")} = $default;
    }
  }

  my $script = <<END;
package $callpack;
use fields qw(@FIELDS);
sub MY () {__PACKAGE__}
END

  $script .= join "", map {sprintf <<'END', @$_} @public;
sub %1$s {
  my MY $self = shift;
  return $self->{%2$s} if defined $self->{%2$s};
  return undef unless my $sub = $self->can('default_%1$s');
  $self->{%2$s} = $sub->();
}
END

  $script .= join "", map {sprintf <<'END', @$_} @setter;
sub set_%s {
  my MY $self = shift;
  $self->{%s} = shift;
  $self;
}
END

  eval qq{#line 1 "/dev/null"\n}.$script;
  die "$@\n$script" if $@;
}

1;
