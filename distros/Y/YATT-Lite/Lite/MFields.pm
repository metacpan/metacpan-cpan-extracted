package YATT::Lite::MFields; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use 5.009; # For real hash only. (not works for pseudo-hash)

use constant DEBUG_IMPORT => $ENV{DEBUG_YATT_IMPORT} // 0;

use parent qw/YATT::Lite::Object/;

sub Decl () {'YATT::Lite::MFields::Decl'}
BEGIN {
  package YATT::Lite::MFields::Decl;
  use parent qw/YATT::Lite::Object/;
  our %FIELDS = map {$_ => 1}
    qw/is isa required
       name public_name getter
       package
       default
       doc label
       only_if_missing
      /;
}

BEGIN {
  our %FIELDS = map {$_ => Decl->new(name => $_)}
    qw/_fields package _known_parent/;
}

use YATT::Lite::Util qw/globref look_for_globref list_isa fields_hash
			lexpand
                        terse_dump
		       /;
use Carp;

sub import {
  Carp::carp(scalar caller, " calls $_[0]->import()") if DEBUG_IMPORT;
  my $pack = shift;
  my $callpack = caller;
  $pack->define_fields($callpack, @_);
}

sub configure_package {
  (my MY $self, my $pack) = @_;
  $self->{package} = $pack;
  my $sym = globref($pack, 'FIELDS');
  *$sym = {} unless *{$sym}{HASH};
  $self->{_fields} = *{$sym}{HASH};
}

{
  my %meta;
  # XXX: This might harm if we need to care about package removal.
  # $PACKAGE::FIELDS might be good alternative place.

  sub get_meta {
    my ($pack, $callpack) = @_;
    $meta{$callpack} //= $pack->new(package => $callpack);
  }
}

sub has_fields {
  my ($pack, $callpack) = @_;
  fields_hash($callpack);
}

sub define_fields {
  my ($pack, $callpack) = splice @_, 0, 2;

  my MY $meta = $pack->get_meta($callpack);

  $meta->import_fields_from(list_isa($callpack));

  if (@_ == 1 and ref $_[0] eq 'CODE') {
    $_[0]->($meta);
  } else {
    foreach my $item (@_) {
      $meta->has(ref $item ? @$item : $item);
    }
  }

  $meta;
}

sub import_fields_from {
  (my MY $self) = shift;
  foreach my $item (@_) {
    my ($class, $fields);
    if (ref $item) {
      unless (UNIVERSAL::isa($item, MY)) {
	croak "Invalid item for MFields::Meta->import_fields_from: $item";
      }
      my MY $super = $item;
      $class = $super->{package};
      next if $self->{_known_parent}{$class}++;
      $fields = $super->{_fields};
    } else {
      $class = $item;
      next if $self->{_known_parent}{$class}++;
      my $sym = look_for_globref($class, 'FIELDS')
	or next;
      $fields = *{$sym}{HASH}
	or next;
    }

    foreach my $name (keys %$fields) {
      my Decl $importing = $fields->{$name};
      unless (UNIVERSAL::isa($importing, $self->Decl)) {
	croak "Importing raw field $class.$name is prohibited!";
      }

      unless (my Decl $existing = $self->{_fields}->{$name}) {
	$self->{_fields}->{$name} = $importing;
      } elsif (not UNIVERSAL::isa($existing, $self->Decl)) {
	croak "Importing $class.$name onto raw field"
	  . " (defined in $self->{package}) is prohibited";
      } elsif ($importing->{only_if_missing}) {
        ; # import $importing only if it is missing in target package.
      } elsif ($importing != $existing) {
	croak "Conflicting import $class.$name"
	  . " (defined in $importing->{package}) "
	    . "onto $existing->{package}";
      }
    }
  }
}

sub fields {
  (my MY $self) = @_;
  my $f = $self->{_fields};
  wantarray ? map([$_ => $f->{$_}], keys %$f) : $f;
}

sub has {
  (my MY $self, my $nameSpec, my @atts) = @_;
  print STDERR YATT::Lite::Util::terse_dump($nameSpec, \@atts), "\n"
    if DEBUG_IMPORT;
  (my $attName, @atts) = ($self->parse_field_spec($nameSpec), @atts);
  print STDERR YATT::Lite::Util::terse_dump("=> ", $attName, \@atts), "\n"
    if DEBUG_IMPORT;
  if (my $old = $self->{_fields}->{$attName}) {
    carp "Redefinition of field $self->{package}.$attName is prohibited!";
  }
  unless (@atts % 2 == 0) {
    croak "Invalid number of field spec for $self->{package}.$attName";
  }
  my Decl $field = $self->Decl->new(
    name => $attName, @atts, package => $self->{package}
  );
  if ($field->{getter}) {
    my ($name, $code) = lexpand($field->{getter});
    if (not defined $code) {
      $code = sub {$_[0]->{$attName}};
    } elsif (not ref $code) {
      $code = $self->make_accessor_type($code, $attName);
    } elsif (ref $code ne 'CODE') {
      croak "field getter code must be CODE ref! for field $attName";
    }
    *{globref($field->{package}, $name)} = $code;
  }
  $self->{_fields}->{$attName} = $field;
}

sub make_accessor_type {
  (my MY $self, my ($type, $name)) = @_;
  my $builder = $self->can("make_accessor_type_$type")
  or croak "Unknown auto accessor type: $type";
  $builder->($self, $name);
}

sub make_accessor_type_hash {
  (my MY $self, my $name) = @_;
  sub { $_[0]->{$name} }
}

sub make_accessor_type_glob {
  (my MY $self, my $name) = @_;
  sub { (*{$_[0]}{HASH})->{$name} }
}

sub parse_field_spec {
  my ($pack, $spec) = @_;
  my @atts;
  if ($spec =~ s/\^(\w+)\z/$1/) {
    push @atts, getter => $1;
  }
  if ($spec !~ m{^_}) {
    push @atts, public_name => $spec;
  }
  ($spec, @atts);
}

sub add_isa_to {
  my ($pack, $target, @base) = @_;
  my $sym = globref($target, 'ISA');
  my $isa;
  unless ($isa = *{$sym}{ARRAY}) {
    *$sym = $isa = [];
  }

  my $using_c3 = mro::get_mro($target) eq 'c3';
  foreach my $base (@base) {
    my $cur_linear = mro::get_linear_isa($target);
    next if grep {$_ eq $base} @$cur_linear;
    if ($using_c3) {
      my $adding = mro::get_linear_isa($base);

      local $@;
      eval {
        unshift @$isa, $base;
      };
      if (my $err = $@) {
        croak "Can't add base '$base' to '$target'!\n"
          .  "  Target '$target' ISA (\n    ".join("\n    ", map {
            YATT::Lite::Util::ns_filename($_)
          } @$cur_linear).")\n"
          .  "  Adding '$base' ISA (\n    ".join("\n    ", map {
            YATT::Lite::Util::ns_filename($_)
          } @$adding)
          ."\n) because of this error: " . $err;
      }
    } else {
      push @$isa, $base
    }
  }

  $pack;
}

1;

__END__

=head1 NAME

YATT::Lite::MFields -- fields for multiple inheritance.

=head1 SYNOPSIS

  #
  # Like fields.pm
  #
  use YATT::Lite::MFields qw/foo bar baz/;

  #
  # Getter generation.
  #
  use YATT::Lite::MFields qw/^name ^age/;
  #
  # In above, ->name and ->age are defined.

  # Or more descriptive (but most attributes are only for documentation)
  use YATT::Lite::MFields
    ([name => (is => 'ro', doc => "Name of the user"
              , getter => "get_name")]
    , [age => (is => 'rw', doc => "Age of the user")]
    );

  # Or, more procedural way.
  use YATT::Lite::MFields sub {
    my ($meta) = @_;
    $meta->has(name => is => 'ro', doc => "Name of the user");
    $meta->has(age => is => 'rw', doc => "Age of the user");
  };

=head1 DESCRIPTION

This module manipulates caller's C<%FIELDS> hash at compile time so that
caller can detect field-name error at compile time.
Traditionally this is done by L<fields> module. But it explicitly prohibits
multiple inheritance.

Yes, avoiding care-less use of multiple inheritance is important.
But if used correctly, multi-inheritance is good tool
to make your program being modular.

