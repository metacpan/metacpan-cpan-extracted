use strict;
use warnings;
package String::Formatter;
{
  $String::Formatter::VERSION = '0.102084';
}
# ABSTRACT: build sprintf-like functions of your own


require 5.006;

use Params::Util ();
use Sub::Exporter -setup => {
  exports => {
    stringf => sub {
      my ($class, $name, $arg, $col) = @_;
      my $formatter = $class->new($arg);
      return sub { $formatter->format(@_) };
    },
    method_stringf => sub {
      my ($class, $name, $arg, $col) = @_;
      my $formatter = $class->new({
        input_processor => 'require_single_input',
        string_replacer => 'method_replace',
        %$arg,
      });
      return sub { $formatter->format(@_) };
    },
    named_stringf => sub {
      my ($class, $name, $arg, $col) = @_;
      my $formatter = $class->new({
        input_processor => 'require_named_input',
        string_replacer => 'named_replace',
        %$arg,
      });
      return sub { $formatter->format(@_) };
    },
    indexed_stringf => sub {
      my ($class, $name, $arg, $col) = @_;
      my $formatter = $class->new({
        input_processor => 'require_arrayref_input',
        string_replacer => 'indexed_replace',
        %$arg,
      });
      return sub { $formatter->format(@_) };
    },
  },
};

my %METHODS;
BEGIN {
  %METHODS = (
    format_hunker   => 'hunk_simply',
    input_processor => 'return_input',
    string_replacer => 'positional_replace',
    hunk_formatter  => 'format_simply',
  );

  no strict 'refs';
  for my $method (keys %METHODS) {
    *$method = sub { $_[0]->{ $method } };

    my $default = "default_$method";
    *$default = sub { $METHODS{ $method } };
  }
}


sub default_codes {
  return {};
}

sub new {
  my ($class, $arg) = @_;

  my $_codes = {
    %{ $class->default_codes },
    %{ $arg->{codes} || {} },
  };

  my $self = bless { codes => $_codes } => $class;

  for (keys %METHODS) {
    $self->{ $_ } = $arg->{ $_ } || do {
      my $default_method = "default_$_";
      $class->$default_method;
    };

    $self->{$_} = $self->can($self->{$_}) unless ref $self->{$_};
  }

  my $codes = $self->codes;

  return $self;
}

sub codes { $_[0]->{codes} }


sub format {
  my $self   = shift;
  my $format = shift;

  Carp::croak("not enough arguments for stringf-based format")
    unless defined $format;

  my $hunker = $self->format_hunker;
  my $hunks  = $self->$hunker($format);

  my $processor = $self->input_processor;
  my $input = $self->$processor([ @_ ]);

  my $replacer = $self->string_replacer;
  $self->$replacer($hunks, $input);

  my $formatter = $self->hunk_formatter;
  ref($_) and $_ = $self->$formatter($_) for @$hunks;

  my $string = join q{}, @$hunks;

  return $string;
}


my $regex = qr/
 (%                # leading '%'
  (-)?             # left-align, rather than right
  ([0-9]+)?        # (optional) minimum field width
  (?:\.([0-9]*))?  # (optional) maximum field width
  (?:{(.*?)})?     # (optional) stuff inside
  (\S)             # actual format character
 )
/x;

sub hunk_simply {
  my ($self, $string) = @_;

  my @to_fmt;
  my $pos = 0;

  while ($string =~ m{\G(.*?)$regex}gs) {
    push @to_fmt, $1, {
      alignment => $3,
      min_width => $4,
      max_width => $5,

      literal     => $2,
      argument    => $6,
      conversion  => $7,
    };

    $to_fmt[-1] = '%' if $to_fmt[-1]{literal} eq '%%';

    $pos = pos $string;
  }

  push @to_fmt, substr $string, $pos if $pos < length $string;

  return \@to_fmt;
}


sub return_input {
  return $_[1];
}


sub require_named_input {
  my ($self, $args) = @_;

  Carp::croak("routine must be called with exactly one hashref arg")
    if @$args != 1 or ! Params::Util::_HASHLIKE($args->[0]);

  return $args->[0];
}


sub require_arrayref_input {
  my ($self, $args) = @_;

  Carp::croak("routine must be called with exactly one arrayref arg")
    if @$args != 1 or ! Params::Util::_ARRAYLIKE($args->[0]);

  return $args->[0];
}


sub require_single_input {
  my ($self, $args) = @_;

  Carp::croak("routine must be called with exactly one argument after string")
    if @$args != 1;

  return $args->[0];
}


sub forbid_input {
  my ($self, $args) = @_;

  Carp::croak("routine must be called with no arguments after format string")
    if @$args;

  return $args;
}


sub __closure_replace {
  my ($closure) = @_;

  return sub {
    my ($self, $hunks, $input) = @_;

    my $heap = {};
    my $code = $self->codes;

    for my $i (grep { ref $hunks->[$_] } 0 .. $#$hunks) {
      my $hunk = $hunks->[ $i ];
      my $conv = $code->{ $hunk->{conversion} };

      Carp::croak("Unknown conversion in stringf: $hunk->{conversion}")
        unless defined $conv;

      if (ref $conv) {
        $hunks->[ $i ]->{replacement} = $self->$closure({
          conv => $conv,
          hunk => $hunk,
          heap => $heap,
          input => $input,
        });
      } else {
        $hunks->[ $i ]->{replacement} = $conv;
      }
    }
  };
}

# $self->$string_replacer($hunks, $input);
BEGIN {
  *positional_replace = __closure_replace(sub {
    my ($self, $arg) = @_;
    local $_ = $arg->{input}->[ $arg->{heap}{nth}++ ];
    return $arg->{conv}->($self, $_, $arg->{hunk}{argument});
  });

  *named_replace = __closure_replace(sub {
    my ($self, $arg) = @_;
    local $_ = $arg->{input}->{ $arg->{hunk}{argument} };
    return $arg->{conv}->($self, $_, $arg->{hunk}{argument});
  });

  *indexed_replace = __closure_replace(sub {
    my ($self, $arg) = @_;
    local $_ = $arg->{input}->[ $arg->{hunk}{argument} ];
    return $arg->{conv}->($self, $_, $arg->{hunk}{argument});
  });
}


# should totally be rewritten with commonality with keyed_replace factored out
sub method_replace {
  my ($self, $hunks, $input) = @_;

  my $heap = {};
  my $code = $self->codes;

  for my $i (grep { ref $hunks->[$_] } 0 .. $#$hunks) {
    my $hunk = $hunks->[ $i ];
    my $conv = $code->{ $hunk->{conversion} };

    Carp::croak("Unknown conversion in stringf: $hunk->{conversion}")
      unless defined $conv;

    if (ref $conv) {
      local $_ = $input;
      $hunks->[ $i ]->{replacement} = $input->$conv($hunk->{argument});
    } else {
      local $_ = $input;
      $hunks->[ $i ]->{replacement} = $input->$conv(
        defined $hunk->{argument} ? $hunk->{argument} : ()
      );
    }
  }
}


# should totally be rewritten with commonality with method_replace factored out
sub keyed_replace {
  my ($self, $hunks, $input) = @_;

  my $heap = {};
  my $code = $self->codes;

  for my $i (grep { ref $hunks->[$_] } 0 .. $#$hunks) {
    my $hunk = $hunks->[ $i ];
    my $conv = $code->{ $hunk->{conversion} };

    Carp::croak("Unknown conversion in stringf: $hunk->{conversion}")
      unless defined $conv;

    if (ref $conv) {
      local $_ = $input;
      $hunks->[ $i ]->{replacement} = $input->$conv($hunk->{argument});
    } else {
      local $_ = $input;
      $hunks->[ $i ]->{replacement} = $input->{$conv};
    }
  }
}


sub format_simply {
  my ($self, $hunk) = @_;

  my $replacement = $hunk->{replacement};
  my $replength   = length $replacement;

  my $alignment   = $hunk->{alignment} || '';
  my $min_width   = $hunk->{min_width} || 0;
  my $max_width   = $hunk->{max_width} || $replength;

  $min_width ||= $replength > $min_width ? $min_width : $replength;
  $max_width ||= $max_width > $replength ? $max_width : $replength;

  return sprintf "%$alignment${min_width}.${max_width}s", $replacement;
}

1;

__END__

=pod

=head1 NAME

String::Formatter - build sprintf-like functions of your own

=head1 VERSION

version 0.102084

=head1 SYNOPSIS

  use String::Formatter stringf => {
    -as   => 'str_rf',
    codes => {
      f => sub { $_ },
      b => sub { scalar reverse $_ },
      o => 'Okay?',
    },
  };

  print str_rf('This is %10f and this is %-15b, %o', 'forward', 'backward');

...prints...

  This is    forward and this is drawkcab       , okay?

=head1 DESCRIPTION

String::Formatter is a tool for building sprintf-like formatting routines.
It supports named or positional formatting, custom conversions, fixed string
interpolation, and simple width-matching out of the box.  It is easy to alter
its behavior to write new kinds of format string expanders.  For most cases, it
should be easy to build all sorts of formatters out of the options built into
String::Formatter.

Normally, String::Formatter will be used to import a sprintf-like routine
referred to as "C<stringf>", but which can be given any name you like.  This
routine acts like sprintf in that it takes a string and some inputs and returns
a new string:

  my $output = stringf "Some %a format %s for you to %u.\n", { ... };

This routine is actually a wrapper around a String::Formatter object created by
importing stringf.  In the following code, the entire hashref after "stringf"
is passed to String::Formatter's constructor (the C<new> method), save for the
C<-as> key and any other keys that start with a dash.

  use String::Formatter
    stringf => {
      -as => 'fmt_time',
      codes           => { ... },
      format_hunker   => ...,
      input_processor => ...,
    },
    stringf => {
      -as => 'fmt_date',
      codes           => { ... },
      string_replacer => ...,
      hunk_formatter  => ...,
    },
  ;

As you can see, this will generate two stringf routines, with different
behaviors, which are installed with different names.  Since the behavior of
these routines is based on the C<format> method of a String::Formatter object,
the rest of the documentation will describe the way the object behaves.

There's also a C<named_stringf> export, which behaves just like the C<stringf>
export, but defaults to the C<named_replace> and C<require_named_input>
arguments.  There's a C<method_stringf> export, which defaults
C<method_replace> and C<require_single_input>.  Finally, a C<indexed_stringf>,
which defaults to C<indexed_replaced> and C<require_arrayref_input>.  For more
on these, keep reading, and check out the cookbook.

L<String::Formatter::Cookbook> provides a number of recipes for ways to put
String::Formatter to use.

=head1 METHODS

=head2 new

=head2 format

  my $result = $formatter->format( $format_string, @input );

  print $formatter->format("My %h is full of %e.\n", 'hovercraft', 'eels');

This does the actual formatting, calling the methods described above, under
C<L</new>> and returning the result.

=head2 format_hunker

Format hunkers are passed strings and return arrayrefs containing strings (for
fixed content) and hashrefs (for formatting code sections).

The hashref hunks should contain at least two entries:  C<conversion> for the
conversion code (the s, d, or u in %s, %d, or %u); and C<literal> for the
complete original text of the hunk.  For example, a bare minimum hunker should
turn the following:

  I would like to buy %d %s today.

...into...

  [
    'I would like to buy ',
    { conversion => 'd', literal => '%d' },
    ' ',
    { conversion => 's', literal => '%d' },
    ' today.',
  ]

Another common entry is C<argument>.  In the format strings expected by
C<hunk_simply>, for example, these are free strings inside of curly braces.
These are used extensively other existing helpers for things liked accessing
named arguments or providing method names.

=head2 hunk_simply

This is the default format hunker.  It implements the format string semantics
L<described above|/FORMAT STRINGS>.

This hunker will produce C<argument> and C<conversion> and C<literal>.  Its
other entries are not yet well-defined for public consumption.

=head2 input_processor

The input processor is responsible for inspecting the post-format-string
arguments, validating them, and returning them in a possibly-transformed form.
The processor is passed an arrayref containing the arguments and should return
a scalar value to be used as the input going forward.

=head2 return_input

This input processor, the default, simply returns the input it was given with
no validation or transformation.

=head2 require_named_input

This input processor will raise an exception unless there is exactly one
post-format-string argument to the format call, and unless that argument is a
hashref.  It will also replace the arrayref with the given hashref so
subsequent phases of the format can avoid lots of needless array dereferencing.

=head2 require_arrayref_input

This input processor will raise an exception unless there is exactly one
post-format-string argument to the format call, and unless that argument is a
arrayref.  It will also replace the input with that single arrayref it found so
subsequent phases of the format can avoid lots of needless array dereferencing.

=head2 require_single_input

This input processor will raise an exception if more than one input is given.
After input processing, the single element in the input will be used as the
input itself.

=head2 forbid_input

This input processor will raise an exception if any input is given.  In other
words, formatters with this input processor accept format strings and nothing
else.

=head2 string_replacer

The string_replacer phase is responsible for adding a C<replacement> entry to
format code hunks.  This should be a string-value entry that will be formatted
and concatenated into the output string.  String replacers can also replace the
whole hunk with a string to avoid any subsequent formatting.

=head2 positional_replace

This replacer matches inputs to the hunk's position in the format string.  This
is the default replacer, used in the L<synopsis, above|/SYNOPSIS>, which should
make its behavior clear.  At present, fixed-string conversions B<do not> affect
the position of arg matched, meaning that given the following:

  my $formatter = String::Formatter->new({
    codes => {
      f => 'fixed string',
      s => sub { ... },
    }
  });

  $formatter->format("%s %f %s", 1, 2);

The subroutine is called twice, once for the input C<1> and once for the input
C<2>.  B<This behavior may change> after some more experimental use.

=head2 named_replace

This replacer should be used with the C<require_named_input> input processor.
It expects the input to be a hashref and it finds values to be interpolated by
looking in the hashref for the brace-enclosed name on each format code.  Here's
an example use:

  $formatter->format("This was the %{adj}s day in %{num}d weeks.", {
    adj => 'best',
    num => 6,
  });

=head2 indexed_replace

This replacer should be used with the C<require_arrayref_input> input
processor.  It expects the input to be an arrayref and it finds values to be
interpolated by looking in the arrayref for the brace-enclosed index on each
format code.  Here's an example use:

  $formatter->format("This was the %{1}s day in %{0}d weeks.", [ 6, 'best' ]);

=head2 method_replace

This string replacer method expects the input to be a single value on which
methods can be called.  If a value was given in braces to the format code, it
is passed as an argument.

=head2 keyed_replace

This string replacer method expects the input to be a single hashref.  Coderef
code values are used as callbacks, but strings are used as hash keys.  If a
value was given in braces to the format code, it is ignored.

For example if the codes contain C<< i => 'ident' >> then C<%i> in the format
string will be replaced with C<< $input->{ident} >> in the output.

=head2 hunk_formatter

The hunk_formatter processes each the hashref hunks left after string
replacement and returns a string.  When it is called, it is passed a hunk
hashref and must return a string.

=head2 format_simply

This is the default hunk formatter.  It deals with minimum and maximum width
cues as well as left and right alignment.  Beyond that, it does no formatting
of the replacement string.

=head1 FORMAT STRINGS

Format strings are generally assumed to look like Perl's sprintf's format
strings:

  There's a bunch of normal strings and then %s format %1.4c with %% signs.

The exact semantics of the format codes are not totally settled yet -- and they
can be replaced on a per-formatter basis.  Right now, they're mostly a subset
of Perl's astonishingly large and complex system.  That subset looks like this:

  %    - a percent sign to begin the format
  ...  - (optional) various modifiers to the format like "-5" or "#" or "2$"
  {..} - (optional) a string inside braces
  s    - a short string (usually one character) identifying the conversion

Not all format modifiers found in Perl's C<sprintf> are yet supported.
Currently the only format modifiers must match:

    (-)?          # left-align, rather than right
    (\d*)?        # (optional) minimum field width
    (?:\.(\d*))?  # (optional) maximum field width

Some additional format semantics may be added, but probably nothing exotic.
Even things like C<2$> and C<*> are probably not going to appear in
String::Formatter's default behavior.

Another subtle difference, introduced intentionally, is in the handling of
C<%%>.  With the default String::Formatter behavior, string C<%%> is not
interpreted as a formatting code.  This is different from the behavior of
Perl's C<sprintf>, which interprets it as a special formatting character that
doesn't consume input and always acts like the fixed string C<%>.  The upshot
of this is:

  sprintf "%%";   # ==> returns "%"
  stringf "%%";   # ==> returns "%%"

  sprintf "%10%"; # ==> returns "         %"
  stringf "%10%"; # ==> dies: unknown format code %

=for Pod::Coverage codes 
  default_format_hunker
  default_input_processor
  default_string_replacer
  default_hunk_formatter

  my $formatter = String::Formatter->new({
    codes => { ... },
    format_hunker   => ...,
    input_processor => ...,
    string_replacer => ...,
    hunk_formatter  => ...,
  });

This returns a new formatter.  The C<codes> argument contains the formatting
codes for the formatter in the form:

  codes => {
    s => 'fixed string',
    S => 'different string',
    c => sub { ... },
  }

Code values (or "conversions") should either be strings or coderefs.  This
hashref can be accessed later with the C<codes> method.

The other four arguments change how the formatting occurs.  Formatting happens
in five phases:

=over 4

=item 1

format_hunker - format string is broken down into fixed and %-code hunks

=item 2

input_processor - the other inputs are validated and processed

=item 3

string_replacer - replacement strings are generated by using conversions

=item 4

hunk_formatter - replacement strings in hunks are formatted

=item 5

all hunks, now strings, are recombined; this phase is just C<join>

=back

The defaults are found by calling C<default_WHATEVER> for each helper that
isn't given.  Values must be either strings (which are interpreted as method
names) or coderefs.  The semantics for each method are described in the
methods' sections, below.

=head1 HISTORY

String::Formatter is based on L<String::Format|String::Format>, written by
Darren Chamberlain.  For a history of the code, check the project's source code
repository.  All bugs should be reported to Ricardo Signes and
String::Formatter.  Very little of the original code remains.

=head1 AUTHORS

=over 4

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Darren Chamberlain <darren@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Ricardo Signes <rjbs@cpan.org>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
