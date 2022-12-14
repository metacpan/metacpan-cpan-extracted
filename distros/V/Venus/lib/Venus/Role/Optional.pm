package Venus::Role::Optional;

use 5.018;

use strict;
use warnings;

use Venus::Role 'with';

# METHODS

sub clear {
  my ($self, $name) = @_;

  return if !$name;

  return delete $self->{$name};
}

sub has {
  my ($self, $name) = @_;

  return if !$name;

  return exists $self->{$name} ? true : false;
}

sub reset {
  my ($self, $name, @data) = @_;

  return if !$name || !$self->can($name);

  my $value = $self->clear($name);

  $self->$name(@data);

  return $value;
}

# BUILDERS

sub BUILD {
  my ($self, $data) = @_;

  for my $name ($self->META->attrs) {
    my @data = (exists $data->{$name} ? $data->{$name} : ());

    # option: default
    option_default($self, $name, @data);

    # option: initial
    option_initial($self, $name, @data);

    # option: require
    option_require($self, $name, @data);

    # option: coerce
    @data = option_coerce($self, $name, @data) if exists $data->{$name};

    # option: check
    option_check($self, $name, @data);

    # option: assert
    option_assert($self, $name, @data);
  }

  return $self;
}

# EXTENSIONS

sub ITEM {
  my ($self, $name, @data) = @_;

  my $value;

  return undef if !$name;

  @data = (!@data ? READ($self, $name, @data) : WRITE($self, $name, @data));

 # option: check
  option_check($self, $name, @data);

  # option: assert
  option_assert($self, $name, @data);

  # option: trigger
  option_trigger($self, $name, @data);

  return $data[0];
}

sub READ {
  my ($self, $name, @data) = @_;

  # option: default
  option_default($self, $name, @data);

  # option: builder
  option_builder($self, $name, @data);

  # option: coerce
  option_coerce($self, $name, @data);

  # option: reader
  return option_reader($self, $name, @data);
}

sub WRITE {
  my ($self, $name, @data) = @_;

  # option: readwrite
  option_readwrite($self, $name, @data);

  # option: readonly
  option_readonly($self, $name, @data);

  # option: builder
  option_builder($self, $name, @data);

  # option: coerce
  @data = option_coerce($self, $name, @data);

  # option: writer
  return option_writer($self, $name, @data);
}

# EXPORTS

sub EXPORT {
  ['clear', 'has', 'ITEM', 'reset']
}

# OPTIONS

sub option_assert {
  my ($self, $name, @data) = @_;

  if (my $code = $self->can("assert_${name}")) {
    require Scalar::Util;
    require Venus::Assert;
    my $label = join '.', ref $self, $name;
    my $assert = Venus::Assert->new($label);
    my $value = @data ? $data[0] : $self->{$name};
    my $return = $code->($self, $value, $assert);
    if (Scalar::Util::blessed($return)) {
      if ($return->isa('Venus::Assert')) {
        $return->validate($value);
      }
      else {
        require Venus::Throw;
        my $throw = Venus::Throw->new(join('::', map ucfirst, ref($self), 'error'));
        $throw->name('on.assert');
        $throw->message("Invalid return value: \"assert_$name\" in $self");
        $throw->stash(data => $value);
        $throw->stash(name => $name);
        $throw->stash(self => $self);
        $throw->error;
      }
    }
    elsif (length($return)) {
      $assert->name($label);
      $assert->accept($return)->validate($value);
    }
    else {
      require Venus::Throw;
      my $throw = Venus::Throw->new(join('::', map ucfirst, ref($self), 'error'));
      $throw->name('on.assert');
      $throw->message("Invalid return value: \"assert_$name\" in $self");
      $throw->stash(data => $value);
      $throw->stash(name => $name);
      $throw->stash(self => $self);
      $throw->error;
    }
  }
  return;
}

sub option_builder {
  my ($self, $name, @data) = @_;

  if (my $code = $self->can("build_${name}")) {
    my @return = $code->($self, (@data ? @data : $self->{$name}));
    $self->{$name} = $return[0] if @return;
  }
  return;
}

sub option_check {
  my ($self, $name, @data) = @_;

  if (my $code = $self->can("check_${name}")) {
    require Venus::Throw;
    my $throw = Venus::Throw->new(join('::', map ucfirst, ref($self), 'error'));
    $throw->name('on.check');
    $throw->message("Checking attribute value failed: \"$name\" in $self");
    $throw->stash(data => [@data]);
    $throw->stash(name => $name);
    $throw->stash(self => $self);
    if (!$code->($self, @data)) {
      $throw->error;
    }
  }
  return;
}

sub option_coerce {
  my ($self, $name, @data) = @_;

  if ((my $code = $self->can("coerce_${name}")) && (@data || exists $self->{$name})) {
    require Scalar::Util;
    require Venus::Space;
    my $value = @data ? $data[0] : $self->{$name};
    my $return = $code->($self, @data);
    my $package = Venus::Space->new($return)->load;
    my $method = $package->can('DOES')
      && $package->DOES('Venus::Role::Assertable') ? 'make' : 'new';
    return $self->{$name} = $package->$method($value)
      if !Scalar::Util::blessed($value)
      || (Scalar::Util::blessed($value) && !$value->isa($return));
  }
  return $data[0];
}

sub option_default {
  my ($self, $name, @data) = @_;

  if ((my $code = $self->can("default_${name}")) && !@data) {
    $self->{$name} = $code->($self, @data) if !exists $self->{$name};
  }
  return;
}

sub option_initial {
  my ($self, $name, @data) = @_;

  if ((my $code = $self->can("initial_${name}")) && !@data) {
    $self->{$name} = $code->($self, @data) if !exists $self->{$name};
  }
  return;
}

sub option_reader {
  my ($self, $name, @data) = @_;

  if ((my $code = $self->can("read_${name}")) && !@data) {
    return $code->($self, @data);
  }
  else {
    return $self->{$name};
  }
}

sub option_readonly {
  my ($self, $name, @data) = @_;

  if (my $code = ($self->can("readonly_${name}") || $self->can("readonly"))) {
    require Venus::Throw;
    my $throw = Venus::Throw->new(join('::', map ucfirst, ref($self), 'error'));
    $throw->name('on.readonly');
    $throw->message("Setting read-only attribute: \"$name\" in $self");
    $throw->stash(data => $data[0]);
    $throw->stash(name => $name);
    $throw->stash(self => $self);
    if ($code->($self, @data)) {
      $throw->error;
    }
  }
  return;
}

sub option_readwrite {
  my ($self, $name, @data) = @_;

  if (my $code = ($self->can("readwrite_${name}") || $self->can("readwrite"))) {
    require Venus::Throw;
    my $throw = Venus::Throw->new(join('::', map ucfirst, ref($self), 'error'));
    $throw->name('on.readwrite');
    $throw->message("Setting read-only attribute: \"$name\" in $self");
    $throw->stash(data => $data[0]);
    $throw->stash(name => $name);
    $throw->stash(self => $self);
    if (!$code->($self, @data)) {
      $throw->error;
    }
  }
  return;
}

sub option_require {
  my ($self, $name, @data) = @_;

  if (my $code = $self->can("require_${name}")) {
    require Venus::Throw;
    my $throw = Venus::Throw->new(join('::', map ucfirst, ref($self), 'error'));
    $throw->name('on.require');
    $throw->message("Missing required attribute: \"$name\" in $self");
    $throw->stash(data => [@data]);
    $throw->stash(name => $name);
    $throw->stash(self => $self);
    if ($code->($self, @data) && !@data) {
      $throw->error;
    }
  }
  return;
}

sub option_trigger {
  my ($self, $name, @data) = @_;

  if (my $code = $self->can("trigger_${name}")) {
    $code->($self, @data);
  }
  return;
}

sub option_writer {
  my ($self, $name, @data) = @_;

  if (my $code = $self->can("write_${name}")) {
    return $code->($self, @data);
  }
  else {
    return $self->{$name} = $data[0];
  }
}

1;



=head1 NAME

Venus::Role::Optional - Optional Role

=cut

=head1 ABSTRACT

Optional Role for Perl 5

=cut

=head1 SYNOPSIS

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  package main;

  my $person = Person->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides methods for automating
object construction and attribute accessors.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 clear

  clear(Str $name) (Any)

The clear method deletes an attribute and returns the removed value.

I<Since C<1.55>>

=over 4

=item clear example 1

  # given: synopsis

  package main;

  my $fname = $person->clear('fname');

  # "Elliot"

=back

=over 4

=item clear example 2

  # given: synopsis

  package main;

  my $lname = $person->clear('lname');

  # "Alderson"

  my $object = $person;

  # bless({fname => "Elliot"}, "Person")

=back

=over 4

=item clear example 3

  # given: synopsis

  package main;

  my $lname = $person->clear('lname');

  # "Alderson"

=back

=cut

=head2 has

  has(Str $name) (Boolean)

The has method returns truthy if the attribute specified exists, otherwise
returns falsy.

I<Since C<1.55>>

=over 4

=item has example 1

  # given: synopsis

  package main;

  my $has_fname = $person->has('fname');

  # true

=back

=over 4

=item has example 2

  # given: synopsis

  package main;

  my $has_mname = $person->has('mname');

  # false

=back

=cut

=head2 reset

  reset(Str $name) (Any)

The reset method rebuilds an attribute and returns the deleted value.

I<Since C<1.55>>

=over 4

=item reset example 1

  # given: synopsis

  package main;

  my $fname = $person->reset('fname');

  # "Elliot"

=back

=over 4

=item reset example 2

  # given: synopsis

  package main;

  my $lname = $person->reset('lname');

  # "Alderson"

  my $object = $person;

  # bless({fname => "Elliot"}, "Person")

=back

=over 4

=item reset example 3

  # given: synopsis

  package main;

  my $lname = $person->reset('lname', 'Smith');

  # "Alderson"

  my $object = $person;

  # bless({fname => "Elliot", lname => "Smith"}, "Person")

=back

=cut

=head1 FEATURES

This package provides the following features:

=cut

=over 4

=item asserting

This library provides a mechanism for automatically validating class attributes
using L<Venus::Assert> based on the return value of the attribute callback. The
callback should be in the form of C<assert_${name}>, and should return a
L<Venus::Assert> object or the name of any of its predefined valildations.

B<example 1>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub assert_fname {
    return 'string';
  }

  sub assert_lname {
    return 'string';
  }

  package main;

  my $person = Person->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

B<example 2>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub assert_fname {
    return 'string';
  }

  sub assert_lname {
    return 'string';
  }

  package main;

  my $person = Person->new(
    fname => 'Elliot',
    lname => 1234567890,
  );

  # Exception! (isa Venus::Assert::Error)

B<example 3>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub assert_fname {
    return 'string';
  }

  sub assert_lname {
    return 'string';
  }

  package main;

  my $person = Person->new(
    fname => 1234567890,
    lname => 'Alderson',
  );

  # Exception! (isa Venus::Assert::Error)

=back

=over 4

=item building

This library provides a mechanism for automatically building class attributes
during getting and setting its value, after any default values are processed,
based on the return value of the attribute callback. The callback should be in
the form of C<build_${name}>, and is passed any arguments provided.

B<example 1>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub build_fname {
    my ($self, $value) = @_;
    return $value ? ucfirst $value : undef;
  }

  sub build_lname {
    my ($self, $value) = @_;
    return $value ? ucfirst $value : undef;
  }

  sub build_email {
    my ($self, $value) = @_;
    return $value ? lc $value : undef;
  }

  package main;

  my $person = Person->new(
    fname => 'elliot',
    lname => 'alderson',
    email => 'E.ALDERSON@E-CORP.com',
  );

  # bless({fname => 'elliot', lname => 'alderson', ...}, 'Person')

  # $person->fname;

  # "Elliot"

  # $person->lname;

  # "Alderson"

  # $person->email;

  # "e.alderson@e-corp.com"

B<example 2>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub build_fname {
    my ($self, $value) = @_;
    return $value ? ucfirst $value : undef;
  }

  sub build_lname {
    my ($self, $value) = @_;
    return $value ? ucfirst $value : undef;
  }

  sub build_email {
    my ($self, $value) = @_;
    return $value ? lc $value : undef;
  }

  package Person;

  sub build_email {
    my ($self, $value) = @_;
    return lc join '@', (join '.', substr($self->fname, 0, 1), $self->lname),
      'e-corp.com';
  }

  package main;

  my $person = Person->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

  # $person->email;

  # "e.alderson@e-corp.com"

=back

=over 4

=item checking

This library provides a mechanism for automatically checking class attributes
after getting or setting its value. The callback should be in the form of
C<check_${name}>, and is passed any arguments provided.

B<example 1>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub check_fname {
    my ($self, $value) = @_;
    if ($value) {
      return true if lc($value) eq 'elliot';
    }
    return false;
  }

  sub check_lname {
    my ($self, $value) = @_;
    if ($value) {
      return true if lc($value) eq 'alderson';
    }
    return false;
  }

  package main;

  my $person = Person->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

B<example 2>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub check_fname {
    my ($self, $value) = @_;
    if ($value) {
      return true if lc($value) eq 'elliot';
    }
    return false;
  }

  sub check_lname {
    my ($self, $value) = @_;
    if ($value) {
      return true if lc($value) eq 'alderson';
    }
    return false;
  }

  package main;

  my $person = Person->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

  # $person->lname('Alderson');

  # "Alderson"

  # $person->lname('');

  # Exception! (isa Person::Error)

=back

=over 4

=item coercing

This library provides a mechanism for automatically coercing class attributes
into class instances using L<Venus::Space> based on the return value of the
attribute callback. The callback should be in the form of C<coerce_${name}>,
and should return the name of the package to be constructed. That package will
be instantiated via the customary C<new> method, passing the data recevied as
its arguments.

B<example 1>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub coerce_fname {
    my ($self, $value) = @_;

    return 'Venus::String';
  }

  sub coerce_lname {
    my ($self, $value) = @_;

    return 'Venus::String';
  }

  sub coerce_email {
    my ($self, $value) = @_;

    return 'Venus::String';
  }

  package main;

  my $person = Person->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({
  #   'fname' => bless({'value' => 'Elliot'}, 'Venus::String'),
  #   'lname' => bless({'value' => 'Alderson'}, 'Venus::String')
  # }, 'Person')

B<example 2>

  package Person;

  use Venus::Class;
  use Venus::String;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub coerce_fname {
    my ($self, $value) = @_;

    return 'Venus::String';
  }

  sub coerce_lname {
    my ($self, $value) = @_;

    return 'Venus::String';
  }

  sub coerce_email {
    my ($self, $value) = @_;

    return 'Venus::String';
  }

  package main;

  my $person = Person->new(
    email => 'e.alderson@e-corp.com',
  );

  # bless({
  #   'email' => bless({'value' => 'e.alderson@e-corp.com'}, 'Venus::String'),
  # }, 'Person')

=back

=over 4

=item defaulting

This library provides a mechanism for automatically defaulting class attributes
to predefined values, statically or dynamically based on the return value of
the attribute callback. The callback should be in the form of
C<default_${name}>, and should return the value to be used if no value exists
or has been provided to the constructor.

B<example 1>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub default_lname {
    my ($self, $value) = @_;

    return 'Alderson';
  }

  package main;

  my $person = Person->new(
    fname => 'Elliot',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

  # $person->lname('Johnston');

  # "Johnston"

  # $person->reset('lname');

  # "Johnston"

  # $person->lname;

  # "Alderson"

=back

=over 4

=item initialing

This library provides a mechanism for automatically setting class attributes to
predefined values, statically or dynamically based on the return value of the
attribute callback. The callback should be in the form of C<initial_${name}>,
and should return the value to be used if no value has been provided to the
constructor. This behavior is similar to the I<"defaulting"> mechanism but is
only executed during object construction.

B<example 1>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub initial_lname {
    my ($self, $value) = @_;

    return 'Alderson';
  }

  package main;

  my $person = Person->new(
    fname => 'Elliot',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

  # $person->lname('Johnston');

  # "Johnston"

  # $person->reset('lname');

  # "Johnston"

  # $person->lname;

  # undef

=back

=over 4

=item reading

This library provides a mechanism for hooking into the class attribute reader
(accessor) for reading values via the the attribute reader callback. The
callback should be in the form of C<read_${name}>, and should read and return
the value for the attribute specified.

B<example 1>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub read_fname {
    my ($self, $value) = @_;

    return ucfirst $self->{fname};
  }

  sub read_lname {
    my ($self, $value) = @_;

    return ucfirst $self->{lname};
  }

  package main;

  my $person = Person->new(
    fname => 'elliot',
    lname => 'alderson',
  );

  # bless({fname => 'elliot', lname => 'alderson'}, 'Person')

  # $person->fname;

  # "Elliot"

  # $person->lname;

  # "Alderson"

=back

=over 4

=item writing

This library provides a mechanism for hooking into the class attribute writer
(accessor) for writing values via the the attribute writer callback. The
callback should be in the form of C<write_${name}>, and should set and return
the value for the attribute specified.

B<example 1>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub write_fname {
    my ($self, $value) = @_;

    return $self->{fname} = ucfirst $value;
  }

  sub write_lname {
    my ($self, $value) = @_;

    return $self->{lname} = ucfirst $value;
  }

  package main;

  my $person = Person->new;

  # bless({}, 'Person')

  # $person->fname('elliot');

  # "Elliot"

  # $person->lname('alderson');

  # "Alderson"

=back

=over 4

=item triggering

This library provides a mechanism for automatically triggering routines after
reading or writing class attributes via an attribute callback. The callback
should be in the form of C<trigger_${name}>, and will be invoked after the
related attribute is read or written.

B<example 1>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub trigger_fname {
    my ($self, $value) = @_;

    if ($value) {
      $self->{dirty}{fname} = $value;
    }
    return;
  }

  sub trigger_lname {
    my ($self, $value) = @_;

    if ($value) {
      $self->{dirty}{lname} = $value;
    }
    return;
  }

  package main;

  my $person = Person->new;

  # bless({}, 'Person')

  # $person->fname('Elliot');

  # "Elliot"

  # $person->lname('Alderson');

  # "Alderson"

  # my $object = $person;

  # bless({..., dirty => {fname => 'Elliot', lname => 'Alderson'}}, 'Person')

=back

=over 4

=item readonly

This library provides a mechanism for marking class attributes as I<"readonly">
(or not) based on the return value of the attribute callback. The callback
should be in the form of C<readonly_${name}>, and should return truthy to
automatically throw an exception if a change is attempted.

B<example 1>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub readonly_fname {
    my ($self, $value) = @_;

    return true;
  }

  sub readonly_lname {
    my ($self, $value) = @_;

    return true;
  }

  package main;

  my $person = Person->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

  $person->fname('Mister');

  # Exception! (isa Person::Error)

  # $person->lname('Johnston');

  # Exception! (isa Person::Error)

=back

=over 4

=item readwrite

This library provides a mechanism for marking class attributes as I<"readwrite">
(or not) based on the return value of the attribute callback. The callback
should be in the form of C<readwrite_${name}>, and should return falsy to
automatically throw an exception if a change is attempted.

B<example 1>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub readwrite_fname {
    my ($self, $value) = @_;

    return false;
  }

  sub readwrite_lname {
    my ($self, $value) = @_;

    return false;
  }

  package main;

  my $person = Person->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

  $person->fname('Mister');

  # Exception! (isa Person::Error)

  # $person->lname('Johnston');

  # Exception! (isa Person::Error)

=back

=over 4

=item requiring

This library provides a mechanism for marking class attributes as I<"required">
(i.e. to be provided to the constructor) based on the return value of the
attribute callback. The callback should be in the form of C<require_${name}>,
and should return truthy to automatically throw an exception if the related
attribute is missing.

B<example 1>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub require_fname {
    my ($self, $value) = @_;

    return true;
  }

  sub require_lname {
    my ($self, $value) = @_;

    return true;
  }

  sub require_email {
    my ($self, $value) = @_;

    return false;
  }

  package main;

  my $person = Person->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

B<example 2>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub require_fname {
    my ($self, $value) = @_;

    return true;
  }

  sub require_lname {
    my ($self, $value) = @_;

    return true;
  }

  sub require_email {
    my ($self, $value) = @_;

    return false;
  }

  package main;

  my $person = Person->new(
    fname => 'Elliot',
  );

  # Exception! (isa Person::Error)

B<example 3>

  package Person;

  use Venus::Class;

  with 'Venus::Role::Optional';

  attr 'fname';
  attr 'lname';
  attr 'email';

  sub require_fname {
    my ($self, $value) = @_;

    return true;
  }

  sub require_lname {
    my ($self, $value) = @_;

    return true;
  }

  sub require_email {
    my ($self, $value) = @_;

    return false;
  }

  package main;

  my $person = Person->new(
    lname => 'Alderson',
  );

  # Exception! (isa Person::Error)

=back