package Test::FitNesse::Slim::StatementExecutor;

use 5.36.0;
use strict;
use warnings;

use HTML::TreeBuilder;
use Scalar::Util qw(reftype refaddr);
use Time::HiRes qw(alarm);
use Test::FitNesse::Slim::Statement;
use Test::FitNesse::Slim::SlimHelperLibrary;
use Test::FitNesse::Slim::MapResult;
use Test::FitNesse::Slim::ConverterRegistry;

my $FIXTURE_HANDLES_SYMBOLS = "SLIM_AGENT_FIXTURE_HANDLES_SYMBOLS";

sub new {
  my($class,%options) = @_;
  my $self = bless {
    imports  => [],
    instance => {},
    library  => [],
    symbol   => {},
    fixture_symbol_pattern => undef,
    stop_requested => undef,
    converters => Test::FitNesse::Slim::ConverterRegistry->new,
    statement_timeout => $options{statement_timeout},
  } => $class;

  $self->{instance}{__slim_helper_library} =
    Test::FitNesse::Slim::SlimHelperLibrary->new($self->{instance});
  push @{ $self->{library} }, {
    id => "__slim_helper_library",
    object => $self->{instance}{__slim_helper_library},
  };
  $self;
}

sub add_import {
    my($self, $prefix) = @_;
    push @{ $self->{imports} }, $self->slim_to_perl_class($prefix);
}

sub path_to_class {
  my($self,$name) = @_;
  $name =~ s!::!/!g;
  $name . ".pm";
}

sub require {
  my($self,$class) = @_;
  eval { require $self->path_to_class($class) };
  return $class unless $@;
  chomp $@;
  die "message:<<COULD_NOT_INVOKE_CONSTRUCTOR $class $@>>\n";
}

sub slim_to_perl_class {
  my($self,$name) = @_;
  $name =~ s/\s+(\w)/\u$1/g;
  join "::" => map "\u$_", split /\.|::/, $name;
}

sub resolve_class {
  my($self, $name) = @_;

  my $class = $self->slim_to_perl_class($name);

  # A nested import must remain usable when a page also imports its parent
  # package (for example, table fixtures for fixture-managed symbols).
  my @imports = reverse @{ $self->{imports} };
  my @candidates = (
      (map("${_}::${class}", sort { length($b) <=> length($a) } @imports)),
      $class,
  );

  for my $candidate (@candidates) {
      my $path = $self->path_to_class($candidate);
      return $candidate if eval { require $path; 1 };
  }

  die "message:<<NO_CLASS $class>>\n";
}

sub slim_to_perl_method {
  my($self,$name) = @_;
  # Split acronym suffixes from a following title-cased word, then ordinary
  # lower/digit-to-upper camelCase boundaries. A final one-letter boundary
  # handles names such as makeATestPage without splitting IPv6.
  $name =~ s/([A-Z]{2,})([A-Z][a-z])/$1_$2/g;
  $name =~ s/([a-z0-9])([A-Z])/$1_$2/g;
  $name =~ s/([A-Z])([A-Z][a-z]+)(?!\d)/$1_$2/g;
  lc $name;
}

sub _method_for {
  my ($self, $object, $requested) = @_;
  return unless $object && ref $object;

  my $translated = $self->slim_to_perl_method($requested);
  my @candidates = ($requested);
  push @candidates, $translated if $translated ne $requested;
  for my $candidate (@candidates) {
    return $candidate if $object->can($candidate);
  }
  # Perl's declared AUTOLOAD is an explicit dynamic-dispatch hook. Only use it
  # after both concrete spellings have been checked.
  return $requested if $object->can('AUTOLOAD');
  return;
}

sub _enum_types_for {
  my ($self, $fixture) = @_;
  my $class = ref($fixture) || $fixture;
  return {} unless $class->can('slim_enum_types');
  return $self->{converters}->validate_enum_types($class->slim_enum_types);
}

sub create {
  my($self,$id,$class,$args) = @_;
  my $is_library = $id =~ /^library/;
  my ($registered, $had_instance, $previous_instance, $library_entry);

  eval {
    ($class) = $self->replace_symbols($class);

    my $object;
    if (ref $class) {
      $object = $class;
    }
    else {
      $class = $self->resolve_class($class);
      my @constructor_args =
        $self->replace_tables_with_hashes($self->replace_symbols(@$args));
      my $signature = $class->can('slim_constructor_signature')
        ? $class->slim_constructor_signature
        : undef;
      if ($signature) {
        $signature = {
          %$signature,
          enum_types => $self->_enum_types_for($class),
        };
      }
      $self->{converters}->validate_arity(
        $signature, "$class constructor", scalar @constructor_args,
        'constructor', $class
      );
      @constructor_args = $self->{converters}->convert_arguments(
        $signature, "$class constructor", @constructor_args
      ) if $signature;
      $object = $self->_timed(sub {
        $class->new(@constructor_args);
      });
    }

    if ($is_library) {
      $library_entry = { id => $id, object => $object };
      push @{ $self->{library} }, $library_entry;
      $registered = 1;
    }
    else {
      $had_instance = exists $self->{instance}{$id};
      $previous_instance = $self->{instance}{$id} if $had_instance;
      $self->{instance}{$id} = $object;
      $registered = 1;
    }
    $object->set_statement_executor($self)
      if $object->can('set_statement_executor');
  };
  return "OK" unless $@;

  my $error = $@;
  if ($registered) {
    if ($is_library) {
      my $entry_id = refaddr($library_entry);
      @{ $self->{library} } = grep { refaddr($_) != $entry_id }
        @{ $self->{library} };
    }
    elsif ($had_instance) {
      $self->{instance}{$id} = $previous_instance;
    }
    else {
      delete $self->{instance}{$id};
    }
  }

  $self->exception_result($error, 1);
}

sub construct_instance {
  my($self,$id,$class,$args) = @_;

  eval {
    $self->{instance}{$id} = $class->new(
      $self->replace_tables_with_hashes($self->replace_symbols(@$args))
    );
  };
  die $@ if $@;
  return $self->{instance}{$id};
}

sub replace_symbols {
  my($self,@args) = @_;

  my @result;
  for (@args) {
    if (ref $_ eq "ARRAY") {
      push @result, [ $self->replace_symbols(@$_) ];
    }
    elsif (defined($_) && !ref($_) && /^\$(\w+)\z/) {
      my $name = $1;
      push @result, exists $self->{symbol}{$name}
        ? $self->{symbol}{$name}
        : $_;
    }
    else {
      s{ (?<orig> \$ (?<sym> \w+ ) ) } [
        exists $self->{symbol}{$+{sym}}
          ? (defined $self->{symbol}{$+{sym}} ? $self->{symbol}{$+{sym}} : 'null')
          : $+{orig}
      ]gex;
      push @result, $_;
    }
  }

  @result;
}

sub replace_tables_with_hashes {
  my($self,@args) = @_;
  map $self->replace_table_with_hash($_), @args;
}

sub replace_table_with_hash {
  my($self,$arg) = @_;
  return $arg unless defined($arg) && !ref($arg);

  my $hash = eval {
    my $p = HTML::TreeBuilder->new_from_content($arg);
    my $table = $p->guts->look_down(_tag => "table");
    die "no table" unless $table;

    my %result;
    foreach my $row ($table->look_down(_tag => "tr")) {
      my @cols = map $_->content_list, $row->look_down(_tag => "td");
      die "bad columns"
        unless @cols == 2 && grep(!ref($_), @cols);
      s/^\s+//, s/\s+$// for @cols;
      $result{ $cols[0] } = $cols[1];
    }

    \%result;
  };

  return $@ eq "" ? $hash : $arg;
}

sub instance {
  my($self,$id) = @_;
  return $self->{instance}{$id} if exists $self->{instance}{$id};
  if ($id =~ /^library/) {
    for my $library (@{ $self->{library} }) {
      return $library->{object} if $library->{id} eq $id;
    }
  }
  return;
}

sub set_symbol {
  my($self,$symbol,$value) = @_;
  $self->{symbol}{$symbol} = $value;
  if ($symbol eq $FIXTURE_HANDLES_SYMBOLS) {
    $self->{fixture_symbol_pattern} = undef;
    if (defined $value) {
      my $pattern = eval { qr/$value/ };
      $self->{fixture_symbol_pattern} = $pattern unless $@;
    }
  }
  return $value;
}

sub get_symbol {
  my($self,$symbol,$value) = @_;
  $self->{symbol}{$symbol};
}

sub add_converter {
  my ($self, @args) = @_;
  $self->{converters}->add_converter(@args);
}

sub get_converter {
  my ($self, @args) = @_;
  $self->{converters}->get_converter(@args);
}

sub reset_converters {
  my ($self) = @_;
  $self->{converters}->reset;
  return;
}

sub call {
  my($self,@args) = @_;
  my $result = $self->_call(@args);
  return defined($result) ? $result : "null";
}

sub call_and_assign {
  my($self,$symbol,@args) = @_;
  my ($result, $raw_result) = $self->_call(@args);
  $self->set_symbol($symbol, ref($raw_result) ? $raw_result : $result)
    unless $self->{call_failed};
  return defined($result) ? $result : "null";
}

sub _call {
  my($self,$instance,$method,@args) = @_;
  $self->{call_failed} = 0;

  my $requested_method = $method;
  my $translated_method = $self->slim_to_perl_method($method);

  # FitNesse routes this helper call through the reserved "null" actor.
  if ($instance eq "null" && $translated_method eq "clone_symbol" && @args == 1) {
    return ($self->replace_symbols(@args))[0];
  }

  my $has_instance = exists $self->{instance}{$instance};
  my $obj = $self->{instance}{$instance};
  if (!$has_instance && $instance =~ /^library/) {
    for my $library (@{ $self->{library} }) {
      if ($library->{id} eq $instance) {
        $obj = $library->{object};
        $has_instance = 1;
        last;
      }
    }
  }
  my $method_obj;
  my $invoked_method = $has_instance
    ? $self->_method_for($obj, $requested_method)
    : undef;
  $method_obj = $obj if $invoked_method;

  unless ($method_obj) {
    my $sut = $has_instance ? $self->_system_under_test($obj) : undef;
    $invoked_method = $self->_method_for($sut, $requested_method);
    $method_obj = $sut if $invoked_method;
  }
  unless ($has_instance) {
    for my $lib_id (reverse @{ $self->{library} }) {
      my $lib = $lib_id->{object};
      next unless $lib && ref $lib;
      if (my $candidate = $self->_method_for($lib, $requested_method)) {
        $obj = $lib;
        $method_obj = $lib;
        $invoked_method = $candidate;
        last;
      }
    }
    return $Test::FitNesse::Slim::Statement::EXCEPTION_TAG
             . "message:<<NO_INSTANCE $instance.$requested_method.>>"
      unless $obj;
  }

  unless ($method_obj && $invoked_method) {
    for my $lib_id (reverse @{ $self->{library} }) {
      my $lib = $lib_id->{object};
      next unless $lib && ref $lib;
      if (my $candidate = $self->_method_for($lib, $requested_method)) {
        $method_obj = $lib;
        $invoked_method = $candidate;
        last;
      }
    }
  }

  my $n = @args;
  my $class = ref $obj;
  return $Test::FitNesse::Slim::Statement::EXCEPTION_TAG
           . "message:<<NO_METHOD_IN_CLASS $requested_method\[$n] $class>>"
    unless $method_obj && $invoked_method;

  my ($result, $raw_result, $retain_raw_result);
  eval {
    my @call_args = @args;
    unless ($self->{fixture_symbol_pattern}
        && "$instance.$requested_method" =~ /\A(?:$self->{fixture_symbol_pattern})\z/) {
      @call_args = $self->replace_symbols(@call_args);
    }
    @call_args = $self->replace_tables_with_hashes(@call_args);
    my $signature = $method_obj->can('slim_method_signature')
      ? $method_obj->slim_method_signature($invoked_method)
      : undef;
    if ($signature) {
      $signature = {
        %$signature,
        enum_types => $self->_enum_types_for($method_obj),
      };
    }
    $self->{converters}->validate_arity(
      $signature, $requested_method, scalar @call_args,
      'method', ref($method_obj)
    );
    @call_args = $self->{converters}->convert_arguments(
      $signature, $requested_method, @call_args
    ) if $signature;
    $result = $self->_timed(sub { $method_obj->$invoked_method(@call_args) });
    $raw_result = $result;
    $retain_raw_result = $signature
      && $self->{converters}->is_typed_sequence(
        $signature->{return}, $signature->{enum_types}
      );
    ($result) = $self->{converters}->convert_result($signature, $result)
      if $signature;
    $result = Test::FitNesse::Slim::MapResult->convert($result)
      if ref($result) eq "HASH";
  };
  unless ($@) {
    $result =~ s/\s+$// if defined($result) && !ref($result);
    return wantarray
      ? ($result, $retain_raw_result ? $raw_result : undef)
      : $result;
  }

  $self->{call_failed} = 1;
  $self->exception_result($@)
}

sub exception_result {
  my($self,$error,$pretty_print) = @_;
  chomp $error;

  return $Test::FitNesse::Slim::Statement::EXCEPTION_TAG . $error
    if $error =~ /^message:<<.*?>>\nTried to invoke: .*$/s;

  return $Test::FitNesse::Slim::Statement::EXCEPTION_TAG . $error
    if $error =~ /^message:<<.*>>$/s;

  if ($error =~ /^[\w.\$]*IgnoreScriptTest[\w.\$]*:/) {
    $self->{stop_requested} = 'ignore_script';
    return $Test::FitNesse::Slim::Statement::EXCEPTION_TAG . 'IGNORE_SCRIPT_TEST:';
  }
  if ($error =~ /^[\w.\$]*IgnoreAllTests[\w.\$]*:/) {
    $self->{stop_requested} = 'ignore_all';
    return $Test::FitNesse::Slim::Statement::EXCEPTION_TAG . 'IGNORE_ALL_TESTS:';
  }

  if ($error =~ /([\w.\$]*StopTest\w*Exception):\s*(.*)/s) {
    $self->{stop_requested} = 'test';
    return $Test::FitNesse::Slim::Statement::EXCEPTION_TAG
      . "ABORT_SLIM_TEST:"
      . ($pretty_print ? "message:<<$1: $2>>" : "$1: $2");
  }
  if ($error =~ /([\w.\$]*StopSuite\w*Exception):\s*(.*)/s) {
    $self->{stop_requested} = 'suite';
    return $Test::FitNesse::Slim::Statement::EXCEPTION_TAG
      . "ABORT_SLIM_SUITE:"
      . ($pretty_print ? "message:<<$1: $2>>" : "$1: $2");
  }

  if ($error =~ /^((?:java|fitnesse)\.[\w.\$]+):\s*(.*)/s) {
    return $Test::FitNesse::Slim::Statement::EXCEPTION_TAG
      . ($pretty_print ? "message:<<$1: $2>>" : "$1: $2");
  }

  $Test::FitNesse::Slim::Statement::EXCEPTION_TAG . "message:<<$error>>"
}

sub _timed {
  my($self,$code) = @_;
  my $timeout = $self->{statement_timeout};
  return $code->() unless defined $timeout;

  my $previous = alarm 0;
  local $SIG{ALRM} = sub { die "message:<<TIMED_OUT $timeout>>\n" };
  my($result,$ok,$error);
  $ok = eval {
    alarm $timeout;
    $result = $code->();
    1;
  };
  $error = $@ unless $ok;
  alarm 0;
  alarm $previous if $previous;
  die $error unless $ok;
  return $result;
}

sub stop_requested { $_[0]->{stop_requested} }
sub reset_stop_requested { $_[0]->{stop_requested} = undef }

sub _system_under_test {
  my($self,$fixture) = @_;
  return unless ref($fixture) && (reftype($fixture) || '') eq 'HASH';
  my $sut = exists $fixture->{system_under_test}
    ? $fixture->{system_under_test}
    : $fixture->{systemUnderTest};
  return ref($sut) ? $sut : undef;
}

1;

=head1 NAME

Test::FitNesse::Slim::StatementExecutor - Own fixture and symbol state for a SLiM session

=head1 DESCRIPTION

The statement executor owns imported Perl package prefixes, actors,
registered libraries, symbols, stop state, and a per-session
L<Test::FitNesse::Slim::ConverterRegistry>. It resolves fixture classes and methods,
constructs fixtures, substitutes symbols, applies declared conversions,
dispatches calls, and formats results and exceptions.

Method dispatch checks an actor first, then its declared system under test,
then registered libraries newest-first. Fixture class imports prefer the
most-specific imported package; later imports win among equally specific
candidates. Failed construction restores executor-owned actor or library
registration state. These rules preserve the current Perl fixture model and
do not implement Java reflection or overload selection.

=head1 METHODS

=head2 new

    my $executor = Test::FitNesse::Slim::StatementExecutor->new(%options);

Create isolated session state. C<statement_timeout> optionally bounds each
fixture invocation.

=head2 add_import

Register a FitNesse import prefix for later fixture class resolution.

=head2 path_to_class and require

C<path_to_class> maps a Perl package name to its module path. C<require>
loads that module and wraps load errors as constructor-resolution errors.
Both methods are internal class-loading helpers.

=head2 slim_to_perl_class and slim_to_perl_method

Translate FitNesse-style fixture class names and method names to Perl
package and snake_case spellings. Method invocation checks the exact
requested name before the translated spelling.

=head2 resolve_class

Resolve and load a fixture class using the imported package precedence.
Return its Perl package name or throw a structured C<NO_CLASS> error.

=head2 create

    my $result = $executor->create($id, $class, \@arguments);

Construct a fixture and register it as an actor or library according to
its identifier. Declared constructor arity and conversions are validated
before construction. A constructor or initialization failure returns a
structured SLiM exception and does not leave a partial executor
registration.

=head2 instance

Return an actor or explicitly named library object by identifier, or
C<undef> when none is registered.

=head2 construct_instance

Construct and register an already-resolved class directly. This lower-level
helper is retained for internal callers; normal SLiM C<make> instructions
use C<create> so conversion, initialization, and registration rollback are
applied.

=head2 replace_symbols

Resolve exact symbol references without stringifying their values, and
interpolate embedded scalar references. Return the transformed values in
argument order.

=head2 replace_tables_with_hashes and replace_table_with_hash

Convert FitNesse two-column HTML tables to Perl hashes where fixture
arguments use table data. Non-table strings pass through unchanged.

=head2 set_symbol

Store a value in the session symbol table and update the special fixture
symbol-handling pattern when its control symbol is assigned. Return the
stored value.

=head2 get_symbol

Return the current value of a session symbol, or C<undef> if it is absent.

=head2 add_converter

Register a converter in this executor's registry.

=head2 get_converter

Resolve a converter in this executor's registry.

=head2 reset_converters

Restore built-in converters and discard custom registrations for this
executor only.

=head2 call

Invoke a method through actor, SUT, and library resolution. Return the
formatted result or a structured SLiM exception string.

=head2 call_and_assign

Invoke a method and store its result in a symbol. Typed sequence results
retain their raw array reference in the symbol table while returning the
declared display string.

=head2 exception_result

Convert fixture exceptions and FitNesse stop/ignore markers into protocol
exception strings. Stop markers also set batch control state.

=head2 stop_requested and reset_stop_requested

Inspect or clear a FitNesse stop/ignore request raised by the most recent
instruction. The list executor clears this state between batches.

=head1 FIXTURE METADATA

Fixtures may implement C<slim_constructor_signature>,
C<slim_method_signature>, and C<slim_enum_types>. See
C<docs/fixture-conversion.md> for executable declarations and conversion
limits.

=cut
