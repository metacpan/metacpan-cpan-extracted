use strict;
use warnings;
package Test::Resub;
use base qw(Exporter);

our @EXPORT = qw(resub bulk_resub);

our $VERSION = 2.03;

use Carp qw(croak);
use Storable qw(dclone);
use Scalar::Util qw(weaken);

sub default_replacement_sub { sub {} }
sub set_prototype(&$) {
  if (_implements('Scalar::Util','set_prototype')) {
    goto \&Scalar::Util::set_prototype;
  } else {
    my $code = shift;
    my $proto = shift;
    $proto = defined $proto ? "($proto)" : '';
    local $@;
    return eval "sub $proto { goto \$code }";
  }
}

sub resub {
  my ($name, $code, %args) = @_;
  die "give me a fully qualified function name: $name ain't good enough\n"
    unless $name =~ /::/;
  return __PACKAGE__->new(
    %args,
    name => $name,
    code => $code,
  );
}

sub bulk_resub {
  my ($target, $data, %args) = @_;
  my %rs;
  foreach (keys %$data) {
    $rs{$_} = resub "$target\::$_", $data->{$_}, %args;
  }
  return %rs;
}

sub _validate_params_lameley {
  my ($class, %args) = @_;

  my %known =
    map { $_ => 1 }
    qw(name code create call capture deep_copy);

  my %bad =
    map { $_ => $args{$_} }
    grep { ! $known{$_} }
    keys %args;

  if (scalar keys %bad) {
    my $bad = join ', ', map { "$_ => $bad{$_}" } keys %bad;
    croak "$class->new - not sure how to handle unknown arg '$bad'\n";
  }

  croak "don't know how to handle 'call  => $args{call}'"
    if exists $args{call} && ! in($args{call}, qw(optional required forbidden));

  return (
    deep_copy => 0,
    call => 'required',
    %args,
  );
}

sub new {
  my $class = shift;

  # lame adaptor for old-style users of Test::Resub (are there any?)
  my %args = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;

  # I'm not gonna lie, this really is stupidly ugly
  %args = $class->_validate_params_lameley(%args);

  croak "I return a highly useful object, gotta call me in non-void context!\n"
    unless defined wantarray;

  my $name = $args{name};
  (my $sane = $name) =~ s{->}{::}g;
  $sane =~ s{[^\w:]}{}g;
  croak "bad method name: $args{name} (expected: $sane)" if $args{name} ne $sane;

  my $code = $args{code} || $class->default_replacement_sub;

  my ($orig_code, $autovivified) = $class->_get_orig_code(%args);

  my ($package, $sub) = $args{name} =~ m{^(.*)::(.*?)$};

  my $self = bless {
    %args,
    target_package => $package,
    target_sub => $sub,
    orig_code => $orig_code,
    called => 0,
    args => [],
    autovivified => $autovivified,
    stashed_variables => _save_variables($args{name}),
    deep_copy => $args{deep_copy},
  }, $class;

  weaken(my $weak_self = $self);
  my $wrapper_for_code = set_prototype(sub {
    $weak_self->{called}++;
    $weak_self->{was_called} = 1;
    push @{$weak_self->{args}}, ($weak_self->{deep_copy}
      ? do {
        local $Storable::Deparse = 1;
        local $Storable::Eval = 1;
        dclone(\@_);
      }
      : [@_]);

    # Are you debugging? Here's where we call the original code in its original context.
    return $code->(@_);
  }, prototype(\&{$self->{name}}));

  $self->swap_out($wrapper_for_code);
  _restore_variables($self->{name}, $self->{stashed_variables});

  return $self;
}

sub _context {
  my ($class) = @_;
  my $wantarray = (caller(1))[5];
  my $context = $wantarray
    ? 'list'
    : defined $wantarray
      ? 'scalar'
      : 'void';
  return $context;
}

sub _save_variables {
  my ($varname) = @_;
  no strict 'refs';
  return {
    scalar => $$varname,
    array => \@$varname,
    hash => \%$varname,
  };
}

sub _restore_variables {
  my ($varname, $data) = @_;
  no strict 'refs';
  no warnings 'uninitialized';
  $$varname = $data->{scalar};
  @$varname = @{$data->{array}};
  %$varname = %{$data->{hash}};
}

sub _implements {
  my ($package, $sub) = @_;

  local $@;
  my %stash = eval "\%$package\::";
  croak "finding $package\'s stash: $@\n" if $@;

  return exists $stash{$sub} && *{$stash{$sub}}{CODE} && *{$stash{$sub}}{NAME} eq $sub;
}

sub _get_orig_code {
  my ($class, %args) = @_;

  my ($package, $sub) = $args{name} =~ m{^(.*)::(.+)$};

  return (\&{$args{name}}, 0) if _implements($package, $sub);
  return ($package->can($sub), 1) if $package->can($sub);

  if (!$args{create}) {
    croak "Package $package doesn't implement nor inherit a sub named '$sub'. " .
      "Generally autovivifying subs into existance leads to bugs, but if you know " .
      "what you're doing you can pass the 'create' flag to $class->new";
  }

  return (\&{$args{name}}, 1);
}

sub in {
  my $needle = shift;
  foreach (@_) {
    return 1 if $_ eq $needle;
  }
  return 0;
}

sub _looks_moosey {
  my ($self, $code) = @_;
  my ($target_package, $target_sub) = @{$self}{qw(target_package target_sub)};
  my $meta = do { local $@; eval { Class::MOP::get_metaclass_by_name($target_package) } };
  return $meta;
}

sub swap_out {
  my ($self, $code, $is_destroy) = @_;

  my ($name, $target_package, $target_sub) = @{$self}{qw(name target_package target_sub)};

  my $do_simple_swap = sub {
    no strict 'refs';
    no warnings 'redefine';
    *{$name} = $code;
  };

  # find the Class::MOP metaclass associated with our victim's encapsulating class
  my $meta = $is_destroy ? 0 : do {
    local $@;
    eval { Class::MOP::get_metaclass_by_name($target_package) };
  };

  # If we're DESTROYing then we can simply swap stuff in: either we're not moosey (so there are no modifiers to
  # apply around our replacement code) -or- we are moosey but are destroying (in which case the original code we
  # saved off is already wrapped up).
  #
  # If we don't have a $meta then we don't have a metaclass so can simply swap things in and out, regardless of
  # whether we're DESTROYing or not: there's no Moose/Class::MOP wrappers to copy from the original code to our
  # replacement.
  if ($is_destroy || ! defined $meta) {
    $do_simple_swap->();
    return;
  }

  # If we got this far then we're not DESTROYing, and do have a $meta - so we need to find any wrappers for the
  # original code. Here's how we'd find it for some versions of Moose:
  my ($wrapped) = grep { $_->{name} eq $target_sub && $_->can('before_modifiers') } $meta->get_all_methods;

  # ugly code to go dig around for wrappers
  my ($before, $around, $after) = ([], [], []);
  if (defined $wrapped) {
    ($before, $around, $after) =
      map { [$wrapped->$_] }
      qw(before_modifiers around_modifiers after_modifiers);
  } else {
    if (_deep_exists($meta, methods => $target_sub => modifier_table =>)) {
      my $modifier_table = $meta->{methods}{$target_sub}{modifier_table};
      $before = [ @{$modifier_table->{before} || []} ];
      $around = [ @{$modifier_table->{around}{cache} || []} ];
      $after = [ @{$modifier_table->{after} || []} ];
    }
  }

  if (scalar grep { scalar @$_ } $before, $around, $after) {
    no strict 'refs';
    no warnings 'redefine';
    *{$name} = sub {
      my $context = _context();

      # call before hooks in correct context
      +{
        list => sub { ($_->(@_)) foreach @$before },
        scalar => sub { scalar $_->(@_) foreach @$before },
        void => sub { $_->(@_) foreach @$before },
      }->{$context}->(@_);

      # $_->($code, @$_) foreach @$around;

      # call swapped-in code in correct context
      my @out;
      +{
        list => sub { @out = $code->(@_) },
        scalar => sub { $out[0] = $code->(@_) },
        void => sub { $code->(@_); 1 },
      }->{$context}->(@_);

      # call after hooks in correct context
      +{
        list => sub { ($_->(@_)) foreach @$after },
        scalar => sub { scalar $_->(@_) foreach @$after },
        void => sub { $_->(@_) foreach @$after },
      }->{$context}->(@_);

      return $context eq 'list' ? @out : $out[0];
    };
  } else {
    # we're moose-like but don't have any wrappers: swap ourselves in!
    $do_simple_swap->();
  }
}

sub _deep_exists {
  my ($hashref, @keys) = @_;
  foreach (@keys) {
    return 0 unless exists $hashref->{$_};
    $hashref = $hashref->{$_};
  }
  return 1;
}

sub called { return shift->{called} }
sub was_called { return shift->{was_called} }

sub not_called { return ! shift->called }

sub _args {
  my ($self, $mutator) = @_;
  return [map { $mutator->() } @{$self->{args}}];
}

sub args { shift->_args(sub { [@$_] }) }
sub method_args { shift->_args(sub { my @copy = @$_; shift @copy; \@copy; }) }

sub named_args {
  my ($self, %args) = @_;

  return $self->_args(sub {
    my @copy = @$_;
    splice @copy, 0, $args{arg_start_index} if $args{arg_start_index};
    my @scalars = $args{scalars}
      ? splice @copy, 0, $args{scalars}
      : ();
    return $args{scalars}
      ? (@scalars, +{@copy})
      : +{@copy};
  });
}

sub named_method_args {
  my ($self, %args) = @_;
  $args{arg_start_index} += 1;
  return $self->named_args(%args);
}

sub reset {
  my ($self) = @_;
  $self->{called} = 0;
  $self->{args} = [];
}

sub DESTROY {
  my($self,) = @_;

  $self->swap_out($self->{orig_code}, 1);

  if ($self->{autovivified}) {
    my ($package, $sub) = @{$self}{qw(target_package target_sub)};
    local $@;
    eval "delete \$${package}::{$sub}";
    croak "ack: $@\n" if $@;
  }
  _restore_variables($self->{name}, $self->{stashed_variables});

  if (!$self->was_called && $self->{call} eq 'required') {
    my $text = 'was not called';
    print STDOUT "not ok 1000 - the " . __PACKAGE__ . " object for '$self->{name}' $text\n" . Carp::longmess;
  }
  if ($self->was_called && $self->{call} eq 'forbidden') {
    my $text = 'was called';
    print STDOUT "not ok 1000 - the " . __PACKAGE__ . " object for '$self->{name}' $text\n" . Carp::longmess;
  }
}

1;

__END__

=head1 NAME

Test::Resub - Lexically scoped monkey patching for testing

=head1 SYNOPSIS

  #!/usr/bin/perl

  use Test::More tests => 4;
  use Test::Resub qw(resub);

  {
    package Somewhere;
    sub show {
      my ($class, $message) = @_;
      return "$class, $message";
    }
  }

  # sanity
  is( Somewhere->show('beyond the sea'), 'Somewhere, beyond the sea' );

  # scoped replacement of subroutine with argument capturing
  {
    my $rs = resub 'Somewhere::show', sub { 'hi' };
    is( Somewhere->show('over the rainbow'), 'hi' );
    is_deeply( $rs->method_args, [['over the rainbow']] );
  }

  # scope ends, resub goes away, original code returns
  is( Somewhere->show('waiting for me'), 'Somewhere, waiting for me' );

=head1 DESCRIPTION

This module allows you to temporarily replace a subroutine/method with arbitrary
code. Later, you can tell how many times was it called and with what arguments
each time.

You may not actually need this module. Many times you'll be able to get away with
something like this:

=over 4

  {
    no warnings 'redefine'
    local *Somewhere::show = sub { return 'kwaa' };

    is( Somewhere->show('me the money'), 'kwaa' );
  }

=back

This module is handy if you're replacing a subroutine with a function prototype,
or for when you need to prove the inputs to the functions that you're calling.

=head1 CONSTRUCTOR

    use Test::Resub qw(resub);
    my $rs = resub 'package::method', sub { ... }, %args;

is equivalent to:

    use Test::Resub;
    my $rs = Test::Resub->new(
      name => 'package::method',
      code => sub { ... },
      %args,
    );

C<%args> can be any of the following named arguments:

=over 4

=item B<name>

The function/method which is to be replaced.

=item B<code>

The code reference which will replace C<name>.  Defaults to C<sub {}>

=item B<capture>

Boolean which indicates whether or not arguments should be captured.
A warning is emitted if you try to look at args without specifying a "true"
C<capture>.  Defaults to 0.

=item B<call>

One of the following values (defaults to 'required'):

=over 4

=item B<required>

If the subroutine/method was never called when the Test::Resub object is
destroyed, "not ok 1000" is printed to STDOUT.

=item B<forbidden>

If the subroutine/method was called when the Test::Resub object is
destroyed, "not ok 1000" is printed to STDOUT.

=item B<optional>

It doesn't matter if the subroutine/method gets called.  As a general rule,
your tests should know whether or not a subroutine/method is going to get
called, so avoid using this option if you can.

=back

=item B<create>

Boolean which indicates whether or not a function will be created if none
exists. If the package can't resolve the method
(i.e. ! UNIVERSAL::can($package, $method)), then an exception will be thrown
unless 'create' is true. Defaults to false.

This is mainly useful to catch typos.

=item B<deep_copy>

Whether or not to make a deep copy of saved-off arguments. Default is 0.
Occassionally one wants deep copies, but there is an associated performance
penalty, e.g. for large objects. Things like filehandles and sockets don't
perform well with deep_copy, and can cause superfluous test failures. Enable
this with caution.

=back

=head1 METHODS

=over 4

=item B<called>

Returns the number of times the replaced subroutine/method was called.  The
C<reset> method clears this data.

=item B<not_called>

Returns true if the replaced subroutine/method was never called.  The C<reset>
method clears this data.

=item B<was_called>

Returns the total number of times the replaced subroutine/method was called.
This data is B<not> cleared by the C<reset> method.

=item B<reset>

Clears the C<called>, C<not_called>, and C<args> data.

=item B<args>

Returns data on how the replaced subroutine/method was invoked.  Examples:

  Invocations:                             C<args> returns:
  ----------------------------             -------------------------
    (none)                                   []
    foo('a');                                [['a']]
    foo('a', 'b'); foo('d');                 [['a', 'b'], ['d']]

=item B<named_args>

Like C<args>, but each invocation's arguments are returned in a hashref.
Examples:

  Invocations:                             C<named_args> returns:
  ----------------------------             -------------------------
   (none)                                   []
   foo(a => 'b');                           [{a => 'b'}]

   foo(a => 'b', c => 'd'); foo(e => 'f');
                                            [{
                                              a => 'b', c => 'd',
                                            }, {
                                              e => 'f',
                                            }]

The C<arg_start_index> argument specifes that a certain number of
arguments are to be discarded. For example:

  my $rs = resub 'some_sub';
  ...
  some_sub('one', 'two', a => 1, b => 2);
  ...
  $rs->named_args(arg_start_index => 1);
  # returns ['two', {a => 1, b => 2}]

  $rs->named_args(arg_start_index => 2);
  # returns [{a => 1, b => 2}]


The C<scalars> argument specifies that a certain number of scalar
arguments precede the key/value arguments.  For example:

  my $rs = resub 'some_sub';
  ...
  some_sub(3306, a => 'b', c => 123);
  some_sub(9158, a => 'z', c => 456);
  ...
  $rs->named_args(scalars => 1);
  # returns [3306, {a => 'b', c => 123},
  #          9158, {a => 'z', c => 456}]

Note that C<named_args(scalars =E<gt> N)> will yield N scalars plus one hashref
per call regardless of how many arguments were passed to the
subroutine/method. For example:

  my $rs = Test::Resub->new({name => 'some_sub'});
  ...
  some_sub('one argument only');
  some_sub('many', 'arguments', a => 1, b => 2);
  ...
  $rs->named_args(scalars => 2);
  # returns ['one argument only', undef, {},
  #          'many', 'arguments', {a => 1, b => 2}]

=item B<method_args>

Like C<args>, but the first argument of each invocation is thrown away.
This is used when you're
resub'ing an object or class method and you're not interested in testing the
object or class argument.  Examples:

  Invocations:                             C<method_args> returns:
  ----------------------------             -------------------------
    (none)                                   []
    $obj->foo('a');                          [['a']]
    Class->foo('a', 'b'); Class->foo('d');   [['a', 'b'], ['d']]

=item B<named_method_args>

Like C<named_args>, but the first argument of each invocation is thrown away.
This is used when you're resub'ing an object or class method and the arguments
are name/value pairs.  Examples:

  Invocations:                             C<named_args> returns:
  ----------------------------             -------------------------
   (none)                                   []
   $obj->foo(a => 'b');                     [{a => 'b'}]

   $obj->foo(a => 'b', c => 'd');           [{
   Class->foo(e => 'f');                      a => 'b', c => 'd',
                                            }, {
                                              e => 'f',
                                            }]

C<named_method_args> also takes a "scalars" named argument which specifies
a number of scalar arguments preceding the name/value pairs of each invocation.
It works just like C<named_args> except that the first argument of each
invocation is automatically discarded.
For example:

  my $rs = resub 'SomeClass::some_sub';
  ...
  SomeClass->some_sub(3306, a => 'b', c => 123);
  SomeClass->some_sub(9158, a => 'z', c => 456);
  ...
  $rs->named_method_args(scalars => 1);
  # returns [3306, {a => 'b', c => 123},
  #          9158, {a => 'z', c => 456}]

Note: the first argument is automatically discarded B<before> the optional
C<arg_start_index> parameter is applied. That is,

  my $rs = resub 'SomeClass::some_sub';
  ...
  SomeClass->some_sub('first', b => 2);
  ...
  $rs->named_method_args(arg_start_index => 1);
  # returns [{b => 2}]

=back

=head1 HISTORY

Written at AirWave Wireless for internal testing, 2001-2007. Tidied up and released to CPAN in 2007.
AirWave was subsequently acquired by Aruba Networks in 2008. Aruba Networks transferred ownership,
future development, and copyright of future development to Belden Lyman in early 2012. See the
Changes file for changes.

=head1 AUTHOR

The development team at AirWave Wireless, http://www.airwave.com/

B<Please> do not submit bug reports to the Airwave Wireless team. Send them to the maintainer (below)
or submit them at https://github.com/belden/test-resub/issues

=head1 MAINTAINER

Belden Lyman <belden@cpan.org>

The latest copy of this package can be checked out from GitHub at http://github.com/belden/test-resub

=head1 COPYRIGHT AND LICENSE

=over

=item (c) 2001-2008 AirWave Wireless, Inc.

=item (c) 2008-2012 Aruba Wireless Networks, Inc.

=item (c) 2012- Belden Lyman

=back

This module is free software; you can redistribute it or modify it under the terms of Perl itself.

=cut
