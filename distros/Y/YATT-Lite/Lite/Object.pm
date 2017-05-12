package YATT::Lite::Object; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use mro 'c3';

use fields;

use YATT::Lite::XHF qw(read_file_xhf);

require YATT::Lite::Util;

sub new {
  my $self = fields::new(shift);
  if (@_) {
    my @task = $self->configure(@_);
    $self->_before_after_new;
    $self->after_new;
    $$_[0]->($self, $$_[1]) for @task;
  } else {
    $self->_before_after_new;
    $self->after_new;
  }

  # To tolerate ``forgotten ->SUPER::after_new() bug'' in user class.
  $self->_after_after_new;

  $self;
}

sub just_new {
  my $self = fields::new(shift);
  # To delay configure_zzz.
  ($self, $self->configure(@_));
}

# General initialization hook for each user class.
sub after_new {};

# Two more initialization hooks for framework writer.

# Called just after parameter initialization.
# Good for private member initialization.
sub _before_after_new {}

# Called after all configure_ZZZ hook is called.
sub _after_after_new  {}

our $loading_file;
sub _loading_file {
  return "\n  loaded from (unknown file)" unless defined $loading_file;
  sprintf qq|\n  loaded from file '%s'|, $loading_file;
}
sub _with_loading_file {
  my ($self, $fn, $method) = @_[0 .. 2];
  local $loading_file = $fn;
  if (ref $method eq 'CODE') {
    $method->(@_[3 .. $#_]);
  } else {
    $self->$method(@_[3 .. $#_]);
  }
}

# XXX: To hide from subclass. (Might harm localization)
my $NO_SUCH_CONFIG_ITEM = sub {
  my ($self, $name) = @_;
  "No such config item $name in class " . ref($self)
    . $self->_loading_file;
};

sub cget {
  my ($self, $key, $default) = @_;
  my $name = "cf_$key";
  my $fields = YATT::Lite::Util::fields_hash($self);
  unless (not exists $fields->{"cf_$name"}) {
    confess $NO_SUCH_CONFIG_ITEM->($self, $name);
  }
  $self->{$name} // $default;
}

sub configure {
  my $self = shift;
  my (@task);
  my $fields = YATT::Lite::Util::fields_hash($self);
  my @params = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
  while (my ($name, $value) = splice @params, 0, 2) {
    unless (defined $name) {
      croak "Undefined name given for @{[ref($self)]}->configure(name=>value)!";
    }
    $name =~ s/^-//;
    if (my $sub = $self->can("configure_$name")) {
      push @task, [$sub, $value];
    } elsif (not exists $fields->{"cf_$name"}) {
      confess $NO_SUCH_CONFIG_ITEM->($self, $name);
    } else {
      $self->{"cf_$name"} = $value;
    }
  }
  if (wantarray) {
    # To delay configure_zzz.
    @task;
  } else {
    $$_[0]->($self, $$_[1]) for @task;
    $self;
  }
}

sub cf_list {
  my $obj_or_class = shift;
  my $pat = shift || qr{^cf_(.*)};
  my $fields = YATT::Lite::Util::fields_hash($obj_or_class);
  sort map {($_ =~ $pat) ? $1 : ()} keys %$fields;
}

sub cf_pairs {
  my ($obj) = shift;
  my $fields = YATT::Lite::Util::fields_hash($obj);
  map {
    [substr($_, 3) => $obj->{$_}]
  } grep {/^cf_/} keys %$fields;
}

#
# util for delegate
#
sub cf_delegate {
  my MY $self = shift;
  my $fields = YATT::Lite::Util::fields_hash($self);
  map {
    my ($from, $to) = ref $_ ? @$_ : ($_, $_);
    unless (exists $fields->{"cf_$from"}) {
      confess $NO_SUCH_CONFIG_ITEM->($self, $from);
    }
    $to => $self->{"cf_$from"}
  } @_;
}

sub cf_delegate_defined {
  my MY $self = shift;
  my $fields = YATT::Lite::Util::fields_hash($self);
  $self->cf_delegate_known(1, $fields, @_);
}

sub cf_delegate_known {
  (my MY $self, my ($raise_err, $fields)) = splice @_, 0, 3;
  map {
    my ($from, $to) = ref $_ ? @$_ : ($_, $_);
    if (not exists $fields->{"cf_$from"}) {
      $raise_err ? (confess $NO_SUCH_CONFIG_ITEM->($self, $from)) : ();
    } else {
      defined $self->{"cf_$from"} ? ($to => $self->{"cf_$from"}) : ();
    }
  } @_;
}

# Or, say, with_option.
# XXX: configure_ZZZ hook is not applied.
sub cf_let {
  (my MY $self, my ($binding, $task)) = splice @_, 0, 3;
  my ($keys, $values) = $self->cf_bindings(@$binding);
  local @{$self}{@$keys} = @$values;
  if (ref $task) {
    $task->($self, @_);
  } else {
    $self->$task(@_);
  }
}

sub cf_bindings {
  my MY $self = shift;
  carp "Odd number of key value bindings" if @_ % 2;
  my (@keys, @values);
  while (my ($key, $value) = splice @_, 0, 2) {
    # XXX: key check!
    # XXX: task extraction!
    push @keys, "cf_$key"; push @values, $value;
  }
  (\@keys, \@values);
}


sub cf_unknowns {
  my $self = shift;
  my $class = ref $self || $self;
  my $fields = YATT::Lite::Util::fields_hash($class);
  my @unknown;
  while (my ($name, $value) = splice @_, 0, 2) {
    next if $fields->{"cf_$name"};
    next if $self->can("configure_$name");
    push @unknown, $name;
  }
  @unknown;
}

sub cf_by_file {
  (my MY $self, my $fn) = @_[0..1];
  my ($ext) = $fn =~ m{\.(\w+)$};
  $self->cf_by_filetype($ext, $fn, @_[3..$#_]);
}

sub cf_by_filetype {
  (my MY $self, my ($ext, $fn)) = @_[0..2];
  $ext //= 'xhf';
  my $sub = $self->can("read_file_$ext")
    or croak "Unknown config file type: $fn";
  $self->_with_loading_file
    ($fn, sub {
       $self->configure($sub->($self, $fn));
     });
}

sub define {
  my ($class, $name, $sub) = @_;
  *{YATT::Lite::Util::globref($class, $name)} = $sub;
}

sub cf_mkaccessors {
  my ($class, @names) = @_;
  my $fields = YATT::Lite::Util::fields_hash($class);
  foreach my $name (@names) {
    my $cf = "cf_$name";
    unless ($fields->{$cf}) {
      croak "No such config: $name";
    }
    *{YATT::Lite::Util::globref($class, $name)} = sub {
      shift->{$cf};
    };
  }
}
1;
