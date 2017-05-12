# -*- mode: perl; coding: utf-8 -*-
package YATT::Util::Symbol;
use base qw(Exporter);
use strict;
use warnings qw(FATAL all NONFATAL misc);

BEGIN {
  our @EXPORT_OK = qw(class globref stash
		      fields_hash fields_hash_of_class
		      add_isa lift_isa_to
		      declare_alias
		      define_const
		      rebless_with
		    );
  our @EXPORT    = @EXPORT_OK;
}

use Carp;
use YATT::Util qw(numeric lsearch);

sub class {
  ref $_[0] || $_[0]
}

sub globref {
  my ($thing, @name) = @_;
  no strict 'refs';
  \*{join("::", class($thing), @name)};
}

sub stash {
  *{globref($_[0], '')}{HASH}
}

sub declare_alias ($$) {
  my ($name, $sub, $pack) = @_;
  $pack ||= caller;
  *{globref($pack, $name)} = $sub;
}

sub define_const {
  my ($name_or_glob, $value) = @_;
  my $glob = ref $name_or_glob ? $name_or_glob : globref($name_or_glob);
  *$glob = sub () { $value };
}

sub fields_hash_of_class {
  *{globref($_[0], 'FIELDS')}{HASH};
}

*fields_hash = do {
  if ($] >= 5.009) {
    \&fields_hash_of_class;
  } else {
    sub { $_[0]->[0] }
  }
};

sub rebless_array_with {
  my ($self, $newclass) = @_;
  $self->[0] = fields_hash_of_class($newclass);
  bless $self, $newclass;
}

*rebless_with = do {
  if ($] >= 5.009) {
    require YATT::Util::SymbolHash;
    \&YATT::Util::SymbolHash::rebless_hash_with;
  } else {
    \&rebless_array_with;
  }
};

sub add_isa {
  my ($pack, $targetClass, @baseClass) = @_;
  my $isa = globref($targetClass, 'ISA');
  my @uniqBase;
  if (my $array = *{$isa}{ARRAY}) {
    foreach my $baseClass (@baseClass) {
      next if $targetClass eq $baseClass;
      next if lsearch {$_ eq $baseClass} $array;
      push @uniqBase, $baseClass;
    }
  } else {
    *{$isa} = [];
    @uniqBase = @baseClass;
  }
  push @{*{$isa}{ARRAY}}, @uniqBase;
}

sub lift_isa_to {
  my ($new_parent, $child) = @_;
  my $orig = *{globref($child, 'ISA')};
  my $isa = *{$orig}{ARRAY};
  *{$orig} = $isa = [] unless $isa;
  my @orig = @$isa;
#  croak "Multiple inheritance is not supported: $child isa @orig"
#    if @orig > 1;

  # !!: *{$orig} = [$new_parent]; is not ok.
  @$isa = $new_parent;

  return unless @orig;
  add_isa(undef, $new_parent, @orig);
}

1;
