package Test::FitNesse::Slim::ConverterRegistry;

use strict;
use warnings;
use overload ();
use Scalar::Util qw(blessed);
use Test::FitNesse::Slim::MapResult;

sub _java_is_blank {
  my ($value) = @_;
  return 1 unless defined $value;
  return $value =~ /\A[\x{0009}-\x{000D}\x{001C}-\x{0020}\x{1680}\x{2000}-\x{2006}\x{2008}-\x{200A}\x{2028}\x{2029}\x{205F}\x{3000}]*\z/;
}

sub new {
  my ($class) = @_;
  my $self = bless {}, $class;
  $self->reset;
  return $self;
}

sub reset {
  my ($self) = @_;
  $self->{converters} = {
    'java.lang.String' => bless({}, 'Test::FitNesse::Slim::ConverterRegistry::String'),
    'java.lang.Boolean' => bless({}, 'Test::FitNesse::Slim::ConverterRegistry::Boolean'),
    'boolean' => bless({}, 'Test::FitNesse::Slim::ConverterRegistry::PrimitiveBoolean'),
    'java.lang.Integer' => bless({}, 'Test::FitNesse::Slim::ConverterRegistry::Integer'),
    int => bless({}, 'Test::FitNesse::Slim::ConverterRegistry::PrimitiveInteger'),
    'java.lang.Long' => bless({}, 'Test::FitNesse::Slim::ConverterRegistry::Long'),
    long => bless({}, 'Test::FitNesse::Slim::ConverterRegistry::PrimitiveLong'),
    'java.lang.Double' => bless({}, 'Test::FitNesse::Slim::ConverterRegistry::Double'),
    double => bless({}, 'Test::FitNesse::Slim::ConverterRegistry::PrimitiveDouble'),
    'java.lang.Character' => bless({}, 'Test::FitNesse::Slim::ConverterRegistry::Character'),
    char => bless({}, 'Test::FitNesse::Slim::ConverterRegistry::PrimitiveCharacter'),
    'java.util.Date' => bless({}, 'Test::FitNesse::Slim::ConverterRegistry::Date'),
    'void' => bless({}, 'Test::FitNesse::Slim::ConverterRegistry::Void'),
    'java.util.List' => Test::FitNesse::Slim::ConverterRegistry::List->new($self),
    'java.util.Collection' => Test::FitNesse::Slim::ConverterRegistry::List->new($self),
  };
  return $self;
}

sub add_converter {
  my ($self, $type, $converter) = @_;
  die "converter must implement from_string and to_string\n"
    unless ref($converter)
      && $converter->can('from_string')
      && $converter->can('to_string');
  $self->{converters}{$type} = $converter;
  $converter->set_registry($self) if $converter->can('set_registry');
  return;
}

sub remove_converter {
  my ($self, $type) = @_;
  return delete $self->{converters}{$type};
}

sub validate_arity {
  my ($self, $signature, $method, $actual, $kind, $class) = @_;
  return unless $signature && exists $signature->{parameters};

  my $parameters = $signature->{parameters};
  die "invalid parameter signature for $method\n"
    unless ref($parameters) eq 'ARRAY';
  my $expected = @$parameters;
  return if $actual == $expected;

  if ($kind eq 'constructor') {
    die "message:<<NO_CONSTRUCTOR $class\[$actual\]. Expected $expected arguments.>>\n"
      . "Tried to invoke: $method\n";
  }

  die "message:<<NO_METHOD_IN_CLASS No Method $method\[$actual\] in class $class. "
    . "Expected $expected arguments.>>\nTried to invoke: $method\n";
}

sub validate_enum_types {
  my ($self, $types) = @_;
  return {} unless defined $types;
  die "enum declarations must be a hash reference\n" unless ref($types) eq 'HASH';

  my %aliases = map { $_ => 1 } qw(
    String Boolean Character Date Double Integer Long List Collection
    ArrayList LinkedList java.util.ArrayList java.util.LinkedList
  );
  my %copy;
  for my $type (sort keys %$types) {
    die "invalid enum type name\n"
      unless length($type) && $type !~ /\s/ && $type !~ /[\[\]<>]/;
    die "enum type $type collides with a registered converter\n"
      if exists $self->{converters}{$type} || $aliases{$type};
    my $values = $types->{$type};
    die "enum constants for $type must be an array reference\n"
      unless ref($values) eq 'ARRAY';
    my %seen;
    for my $value (@$values) {
      die "invalid enum constant for $type\n"
        if !defined($value) || ref($value) || !length($value);
      die "duplicate enum constant $value for $type\n" if $seen{$value}++;
    }
    $copy{$type} = [@$values];
  }
  return \%copy;
}

sub get_converter {
  my ($self, $type, $enum_types) = @_;
  return unless defined $type;
  return $self->{converters}{$type} if exists $self->{converters}{$type};
  $type =~ s/\s+//g;
  return $self->{converters}{'java.util.List'}
    if $type =~ /\Ajava\.util\.(?:ArrayList|LinkedList|Collection)\z/;
  return $self->{converters}{'java.lang.String'} if $type eq 'String';
  return $self->{converters}{'java.util.List'} if $type eq 'List';
  my %aliases = (
    Boolean => 'java.lang.Boolean',
    Character => 'java.lang.Character',
    Date => 'java.util.Date',
    Double => 'java.lang.Double',
    Integer => 'java.lang.Integer',
    Long => 'java.lang.Long',
  );
  return $self->{converters}{$aliases{$type}} if exists $aliases{$type};

  return Test::FitNesse::Slim::ConverterRegistry::Enum->new($type, $enum_types->{$type})
    if $enum_types && exists $enum_types->{$type};

  if ($type =~ /\A(.+)\[\]\z/ && $1 !~ /[\[\]<>]/) {
    my $component = $self->get_converter($1, $enum_types) or return;
    return Test::FitNesse::Slim::ConverterRegistry::TypedSequence->new(
      $self, $component
    );
  }
  if ($type =~ /\A(?:java\.util\.)?(?:List|Collection)<([^<>]+)>\z/) {
    my $component = $self->get_converter($1, $enum_types) or return;
    return Test::FitNesse::Slim::ConverterRegistry::TypedSequence->new(
      $self, $component
    );
  }
  return;
}

sub converter_for_runtime_value {
  my ($self, $value) = @_;
  return unless ref $value;
  my $class = ref $value;
  return $self->get_converter($class) if $class ne 'ARRAY';
  return $self->get_converter('java.util.ArrayList');
}

sub element_to_string {
  my ($self, $value) = @_;
  return 'null' unless defined $value;
  return "$value" unless ref $value;

  my $converter = $self->converter_for_runtime_value($value);
  return $converter->to_string($value) if $converter;
  return Test::FitNesse::Slim::MapResult->convert($value) if ref($value) eq 'HASH';
  return $value->to_string if blessed($value) && $value->can('to_string');
  return $value->toString if blessed($value) && $value->can('toString');
  return "$value" if blessed($value) && overload::Method($value, '""');

  die 'Cannot convert reference value of type ' . ref($value);
}

sub convert_arguments {
  my ($self, $signature, $method, @args) = @_;
  my $types = $signature->{parameters} || [];
  my $enum_types = $signature->{enum_types};
  for my $index (0 .. $#args) {
    next if !defined $args[$index] || ref $args[$index];
    my $type = $types->[$index];
    next unless defined $type;
    my $converter = $self->get_converter($type, $enum_types);
    die "message:<<NO_CONVERTER_FOR_ARGUMENT_NUMBER $type.>>\nTried to invoke: $method\n"
      unless $converter;
    my $converted = eval { $converter->from_string($args[$index]) };
    if ($@) {
      my $error = $@;
      chomp $error;
      $error =~ s/\Amessage:<<//;
      $error =~ s/>>\z//;
      die "message:<<$error>>\nTried to invoke: $method\n";
    }
    $args[$index] = $converted;
  }
  return @args;
}

sub convert_result {
  my ($self, $signature, $value) = @_;
  return ($value, 0) unless $signature && defined $signature->{return};

  my $type = $signature->{return};
  return ($value, 0)
    if $type eq 'java.util.List' && ref($value) eq 'ARRAY';

  my $converter = $self->get_converter($type, $signature->{enum_types});
  $converter ||= $self->converter_for_runtime_value($value);
  return ($value, 0) unless $converter;
  return ($converter->to_string($value), 1);
}

sub is_typed_sequence {
  my ($self, $type, $enum_types) = @_;
  my $converter = $self->get_converter($type, $enum_types);
  return $converter && $converter->isa('Test::FitNesse::Slim::ConverterRegistry::TypedSequence');
}

package Test::FitNesse::Slim::ConverterRegistry::Enum;
use strict;
use warnings;
use Unicode::UCD qw(charinfo);

my %CASE_MAP;

sub new {
  my ($class, $type, $values) = @_;
  return bless { type => $type, values => $values }, $class;
}

sub _simple_case {
  my ($codepoint, $field) = @_;
  return $codepoint if $codepoint > 0xFFFF;
  return $CASE_MAP{$field}{$codepoint}
    if exists $CASE_MAP{$field}{$codepoint};
  my $info = charinfo($codepoint);
  my $mapped = $info && $info->{$field}
    ? hex($info->{$field})
    : $codepoint;
  return $CASE_MAP{$field}{$codepoint} = $mapped;
}

sub _equals_ignore_case {
  my ($left, $right) = @_;
  my @left = split //, $left;
  my @right = split //, $right;
  return 0 unless @left == @right;
  for my $index (0 .. $#left) {
    my ($a, $b) = (ord($left[$index]), ord($right[$index]));
    next if $a == $b;
    my ($upper_a, $upper_b) =
      (_simple_case($a, 'upper'), _simple_case($b, 'upper'));
    next if $upper_a == $upper_b;
    return 0 unless _simple_case($upper_a, 'lower')
      == _simple_case($upper_b, 'lower');
  }
  return 1;
}

sub _error {
  my ($self, $value) = @_;
  $value = 'reference value' if ref $value;
  $value = '' unless defined $value;
  die "message:<<Can't convert $value to enum value of type $self->{type}.>>\n";
}

sub from_string {
  my ($self, $value) = @_;
  return undef if Test::FitNesse::Slim::ConverterRegistry::_java_is_blank($value);
  $self->_error($value) if ref $value;

  for my $constant (@{$self->{values}}) {
    return $constant if $constant eq $value;
  }
  for my $constant (@{$self->{values}}) {
    return $constant if _equals_ignore_case($constant, $value);
  }
  $self->_error($value);
}

sub to_string {
  my ($self, $value) = @_;
  return undef unless defined $value;
  $self->_error($value) if ref $value;
  for my $constant (@{$self->{values}}) {
    return $constant if $constant eq $value;
  }
  for my $constant (@{$self->{values}}) {
    return $constant if _equals_ignore_case($constant, $value);
  }
  $self->_error($value);
}

package Test::FitNesse::Slim::ConverterRegistry::TypedSequence;
use strict;
use warnings;

sub new {
  my ($class, $registry, $component_converter) = @_;
  return bless {
    registry => $registry,
    component_converter => $component_converter,
  }, $class;
}

sub from_string {
  my ($self, $arg) = @_;
  return undef if Test::FitNesse::Slim::ConverterRegistry::_java_is_blank($arg);

  $arg =~ s/\A\[//;
  $arg =~ s/\]\z//;
  my @items = $arg =~ /\A\s*\z/ ? () : split /,/, $arg;
  my $converter = $self->{component_converter};
  return [ map {
    s/\A[\x00-\x20]+|[\x00-\x20]+\z//g;
    $converter->from_string($_);
  } @items ];
}

sub to_string {
  my ($self, $sequence) = @_;
  return undef unless defined $sequence;
  die 'typed array or collection result must be an array reference'
    unless ref($sequence) eq 'ARRAY';

  my $component = $self->{component_converter};
  my @items;
  for my $value (@$sequence) {
    if (!defined $value) {
      push @items, 'null';
    }
    elsif (ref $value) {
      push @items, $self->{registry}->element_to_string($value);
    }
    else {
      my $string = $component->to_string($value);
      push @items, defined($string) ? $string : 'null';
    }
  }
  return '[' . join(', ', @items) . ']';
}

package Test::FitNesse::Slim::ConverterRegistry::String;
use strict;
use warnings;
sub from_string { $_[1] }
sub to_string { $_[1] }

package Test::FitNesse::Slim::ConverterRegistry::Boolean;
use strict;
use warnings;
sub from_string {
  return undef unless defined $_[1];
  return undef if $_[1] =~ /\A\s*\z/;
  return $_[1] =~ /\A(?:true|yes)\z/i ? 1 : 0;
}
sub to_string {
  return undef unless defined $_[1];
  return $_[1] ? 'true' : 'false';
}

package Test::FitNesse::Slim::ConverterRegistry::PrimitiveBoolean;
use strict;
use warnings;
our @ISA = ('Test::FitNesse::Slim::ConverterRegistry::Boolean');
sub from_string {
  my ($self, $value) = @_;
  return $self->SUPER::from_string($value) // 0;
}
sub to_string {
  return undef unless defined $_[1];
  return $_[1] ? 'true' : 'false';
}

package Test::FitNesse::Slim::ConverterRegistry::Integer;
use strict;
use warnings;
sub from_string {
  my ($self, $value) = @_;
  return undef unless defined $value && $value !~ /\A\s*\z/;
  die "message:<<Can't convert $value to integer.>>" unless $value =~ /\A[+-]?[0-9]+\z/;
  my $digits = $value;
  $digits =~ s/\A[+-]//;
  $digits =~ s/\A0+(?=.)//;
  my $negative = $value =~ /\A-/;
  my $limit = $negative ? '2147483648' : '2147483647';
  die "message:<<Can't convert $value to integer.>>"
    if length($digits) > length($limit)
      || (length($digits) == length($limit) && $digits gt $limit);
  return 0 + $value;
}
sub to_string { defined $_[1] ? "$_[1]" : undef }

package Test::FitNesse::Slim::ConverterRegistry::PrimitiveInteger;
use strict;
use warnings;
our @ISA = ('Test::FitNesse::Slim::ConverterRegistry::Integer');
sub from_string { $_[0]->SUPER::from_string($_[1]) // 0 }

package Test::FitNesse::Slim::ConverterRegistry::Long;
use strict;
use warnings;
sub from_string {
  my ($self, $value) = @_;
  return undef unless defined $value && $value !~ /\A\s*\z/;
  die "message:<<Can't convert $value to long.>>" unless $value =~ /\A[+-]?[0-9]+\z/;
  my $digits = $value;
  $digits =~ s/\A[+-]//;
  $digits =~ s/\A0+(?=.)//;
  my $negative = $value =~ /\A-/;
  my $limit = $negative ? '9223372036854775808' : '9223372036854775807';
  die "message:<<Can't convert $value to long.>>"
    if length($digits) > length($limit)
      || (length($digits) == length($limit) && $digits gt $limit);
  return 0 + $value;
}
sub to_string { defined $_[1] ? "$_[1]" : undef }

package Test::FitNesse::Slim::ConverterRegistry::PrimitiveLong;
use strict;
use warnings;
our @ISA = ('Test::FitNesse::Slim::ConverterRegistry::Long');
sub from_string { $_[0]->SUPER::from_string($_[1]) // 0 }

package Test::FitNesse::Slim::ConverterRegistry::Double;
use strict;
use warnings;
use POSIX ();
use Scalar::Util qw(looks_like_number);

sub _valid_literal {
  my ($value) = @_;
  return $value =~ /\A[+-]?(?:NaN|Infinity)\z/
    || $value =~ /\A[+-]?(?:(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?|0[xX](?:[0-9a-fA-F]+(?:\.[0-9a-fA-F]*)?|\.[0-9a-fA-F]+)[pP][+-]?[0-9]+)[fFdD]?\z/;
}

sub _parse_literal {
  my ($value) = @_;
  return POSIX::nan(0) if $value =~ /\A[+-]?NaN\z/;
  return ($value =~ /\A-/ ? -1 : 1) * POSIX::HUGE_VAL()
    if $value =~ /\A[+-]?Infinity\z/;

  $value =~ s/[fFdD]\z//;
  my $locale = POSIX::setlocale(POSIX::LC_NUMERIC(), 'C');
  my ($number, $remainder) = POSIX::strtod($value);
  POSIX::setlocale(POSIX::LC_NUMERIC(), $locale) if defined $locale;
  die unless defined($remainder) && $remainder == 0;
  return $number;
}

sub from_string {
  my ($self, $value) = @_;
  return undef if Test::FitNesse::Slim::ConverterRegistry::_java_is_blank($value);
  my $original = $value;
  $value =~ s/\A[\x00-\x20]+|[\x00-\x20]+\z//g;
  die "message:<<Can't convert $original to double.>>"
    unless _valid_literal($value);
  my $number = eval { _parse_literal($value) };
  die "message:<<Can't convert $original to double.>>" if $@;
  return $number;
}

sub to_string {
  my ($self, $value) = @_;
  return undef unless defined $value;
  die 'message:<<Double result must be a numeric scalar.>>' if ref $value;
  if (looks_like_number($value)) {
    return 'NaN' if POSIX::isnan($value);
    return POSIX::signbit($value) ? '-Infinity' : 'Infinity'
      if POSIX::isinf($value);
    return POSIX::signbit($value) ? '-0.0' : '0.0' if $value == 0;
    return _format_finite($value);
  }
  return $self->to_string($self->from_string($value));
}

sub _format_finite {
  my ($number) = @_;
  my $negative = POSIX::signbit($number);
  my $absolute = abs($number);
  my $scientific = $absolute >= 10_000_000 || $absolute < 0.001;
  my $first_digits = $scientific ? 2 : 1;
  my ($digits, $exponent);

  my $locale = POSIX::setlocale(POSIX::LC_NUMERIC(), 'C');
  for my $significant_digits ($first_digits .. 17) {
    my $candidate = sprintf('%.*e', $significant_digits - 1, $absolute);
    my ($back, $remaining) = POSIX::strtod($candidate);
    next unless defined($remaining) && $remaining == 0;
    next unless pack('d', $back) eq pack('d', $absolute);
    my ($leading_digit, $fraction, $decimal_exponent) =
      $candidate =~ /\A([0-9])(?:\.([0-9]+))?e([+-]?[0-9]+)\z/i;
    $digits = $leading_digit . ($fraction // '');
    $exponent = 0 + $decimal_exponent;
    last;
  }
  POSIX::setlocale(POSIX::LC_NUMERIC(), $locale) if defined $locale;

  die 'Could not format finite Double as a round-trippable decimal'
    unless defined $digits;
  my $formatted;
  if ($scientific) {
    my $fraction = substr($digits, 1);
    $fraction = '0' unless length $fraction;
    $formatted = substr($digits, 0, 1) . '.' . $fraction . 'E' . $exponent;
  }
  elsif ($exponent >= 0) {
    my $point = $exponent + 1;
    if ($point >= length $digits) {
      $formatted = $digits . ('0' x ($point - length $digits)) . '.0';
    }
    else {
      $formatted = substr($digits, 0, $point) . '.' . substr($digits, $point);
    }
  }
  else {
    $formatted = '0.' . ('0' x (-$exponent - 1)) . $digits;
  }
  return ($negative ? '-' : '') . $formatted;
}

package Test::FitNesse::Slim::ConverterRegistry::PrimitiveDouble;
use strict;
use warnings;
our @ISA = ('Test::FitNesse::Slim::ConverterRegistry::Double');
sub from_string { $_[0]->SUPER::from_string($_[1]) // 0 }

package Test::FitNesse::Slim::ConverterRegistry::Character;
use strict;
use warnings;
use Encode qw(decode FB_CROAK);
sub from_string {
  my ($self, $value) = @_;
  return undef if Test::FitNesse::Slim::ConverterRegistry::_java_is_blank($value);
  my $text = utf8::is_utf8($value) ? $value : decode('UTF-8', $value, FB_CROAK);
  my $codepoint = ord substr($text, 0, 1);
  return $codepoint if $codepoint <= 0xFFFF;
  return 0xD800 + (($codepoint - 0x10000) >> 10);
}
sub to_string {
  my ($self, $value) = @_;
  return undef unless defined $value;
  die 'message:<<Character result must be a UTF-16 code unit.>>'
    unless !ref($value) && $value =~ /\A[0-9]+\z/ && $value <= 0xFFFF;
  return '?' if $value >= 0xD800 && $value <= 0xDFFF;
  return chr($value);
}

package Test::FitNesse::Slim::ConverterRegistry::PrimitiveCharacter;
use strict;
use warnings;
our @ISA = ('Test::FitNesse::Slim::ConverterRegistry::Character');
sub from_string { $_[0]->SUPER::from_string($_[1]) // 0 }

package Test::FitNesse::Slim::ConverterRegistry::Date;
use strict;
use warnings;
use Time::Local qw(timelocal);

my @MONTHS = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my %MONTH_INDEX = map { lc($MONTHS[$_]) => $_ } 0 .. $#MONTHS;
my %FULL_MONTH_INDEX = map {
  lc((qw(January February March April May June July August September October November December))[$_]) => $_
} 0 .. 11;

sub _days_in_month {
  my ($month, $year) = @_;
  return 31 if $month == 0 || $month == 2 || $month == 4 || $month == 6
    || $month == 7 || $month == 9 || $month == 11;
  return 30 if $month == 3 || $month == 5 || $month == 8 || $month == 10;
  return ($year % 4 == 0 && ($year % 100 != 0 || $year % 400 == 0)) ? 29 : 28;
}

sub from_string {
  my ($self, $value) = @_;
  return undef if Test::FitNesse::Slim::ConverterRegistry::_java_is_blank($value);
  $value =~ s/\A[\x{0009}-\x{000D}\x{001C}-\x{0020}\x{1680}\x{2000}-\x{2006}\x{2008}-\x{200A}\x{2028}\x{2029}\x{205F}\x{3000}]+//;
  my ($day, $month_name, $year) = $value =~ /\A([0-9]+)-([A-Za-z]+)-([0-9]+)/;
  my $month = defined($month_name)
    ? ($MONTH_INDEX{lc $month_name} // $FULL_MONTH_INDEX{lc $month_name})
    : undef;
  die "message:<<Can't convert $value to date.>>"
    unless defined($day) && defined($month) && defined($year)
      && $year >= 1583 && $year <= 9999 && $day <= 1_000_000;

  # SimpleDateFormat is lenient: roll day zero and overflow into adjacent months.
  while ($day < 1) {
    $month--;
    if ($month < 0) { $month = 11; $year-- }
    $day += _days_in_month($month, $year);
  }
  while ($day > _days_in_month($month, $year)) {
    $day -= _days_in_month($month, $year);
    $month++;
    if ($month > 11) { $month = 0; $year++ }
  }
  die "message:<<Can't convert $value to date.>>" if $year < 1583 || $year > 9999;

  my $seconds = eval { timelocal(0, 0, 0, $day, $month, $year) };
  die "message:<<Can't convert $value to date.>>" if $@;
  return $seconds * 1000;
}

sub to_string {
  my ($self, $milliseconds) = @_;
  return undef unless defined $milliseconds;
  die 'message:<<Date result must be epoch milliseconds.>>'
    if ref($milliseconds) || $milliseconds !~ /\A-?[0-9]+\z/;
  my $seconds = int($milliseconds / 1000);
  $seconds-- if $milliseconds < 0 && $milliseconds % 1000;
  my ($day, $month, $year) = (localtime($seconds))[3, 4, 5];
  die 'message:<<Date result is outside the supported localtime range.>>'
    unless defined($year) && $year + 1900 >= 1583 && $year + 1900 <= 9999;
  return sprintf('%02d-%s-%04d', $day, $MONTHS[$month], $year + 1900);
}

package Test::FitNesse::Slim::ConverterRegistry::Void;
use strict;
use warnings;
sub from_string { undef }
sub to_string { '/__VOID__/' }

package Test::FitNesse::Slim::ConverterRegistry::List;
use strict;
use warnings;
sub new { bless { registry => $_[1] }, $_[0] }
sub from_string {
  my ($self, $arg) = @_;
  return undef unless defined $arg && $arg !~ /\A\s*\z/;
  $arg =~ s/^\[//;
  $arg =~ s/\]$//;
  return [] if $arg =~ /\A\s*\z/;
  return [map { s/^\s+|\s+$//gr } split /,/, $arg];
}
sub to_string {
  my ($self, $list) = @_;
  return undef unless defined $list;
  return '[' . join(', ', map { $self->{registry}->element_to_string($_) } @$list) . ']';
}

1;

=head1 NAME

Test::FitNesse::Slim::ConverterRegistry - Convert declared fixture argument and result types

=head1 DESCRIPTION

The converter registry supplies the scalar and sequence conversions used
by L<Test::FitNesse::Slim::StatementExecutor>. Each executor owns a registry, so
custom converter changes are scoped to that executor. Fixtures select
converters through C<slim_constructor_signature> and
C<slim_method_signature>; undeclared arguments are not coerced.

Built-in scalar types include String, Boolean, Integer, Long, Double,
Character, Date, and void forms. One-dimensional typed arrays and generic
List/Collection declarations compose those scalar converters. Fixture
packages may declare enum domains through C<slim_enum_types>. Parsing and
result-formatting errors are thrown for the statement executor to serialize
as SLiM exceptions.

=head1 METHODS

=head2 new

Create a registry initialized with the built-in converters.

=head2 reset

Restore the built-in converter set and remove custom registrations.

=head2 add_converter

    $registry->add_converter($type_name, $converter);

Register an object implementing C<from_string> and C<to_string> under a
type name. Invalid converter objects throw an error. Re-registering a name
replaces its current converter.

=head2 remove_converter

Remove a custom or built-in converter by name and return the removed
converter, or C<undef> if no converter was registered.

=head2 get_converter

Resolve a registered scalar, enum, array, or supported generic
List/Collection converter. Return C<undef> when the type is unsupported.

=head2 validate_arity

Check an explicitly declared C<parameters> array against the supplied
argument count. Missing parameter metadata imposes no arity constraint; an
explicit empty array requires zero arguments. Mismatches throw structured
constructor or method errors before fixture invocation.

=head2 validate_enum_types

Validate and copy a fixture's enum declaration hash. Type names cannot
shadow registered converters; each value must be a list of unique,
non-empty scalar names. Invalid declarations throw an error.

=head2 convert_arguments

Convert typed scalar arguments in place order and return the converted
values. Existing references and undeclared positions are preserved.
Conversion failures include the invocation context in their exception.

=head2 convert_result

Convert a declared result to its SLiM string representation and return the
formatted value with a flag indicating whether conversion occurred.

=head2 converter_for_runtime_value

Return the suitable registered converter for a Perl runtime value, or
C<undef> when no converter applies.

=head2 element_to_string

Format a nested sequence element. Scalars, supported arrays, maps, and
objects with explicit string methods are handled; unsupported references
throw an error instead of being stringified implicitly.

=head2 is_typed_sequence

Return true when a declared type resolves to the registry's typed
array/List/Collection converter.

=head1 CONVERTER CONTRACT

Custom converters implement C<from_string($value)> and
C<to_string($value)>. They may also implement C<set_registry($registry)> to
access the owning registry. This is an executor-scoped fixture extension,
not a wire-level SLiM type system.

=cut
