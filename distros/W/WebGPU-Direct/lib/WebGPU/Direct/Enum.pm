package WebGPU::Direct::Enum
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  use constant 1.01;
  use Carp qw/croak/;

  sub _get_consts_ref ($class)
  {
    return eval '\%' . $class . '::CONSTANTS';
  }

  sub all_constants (
    $class,
  )
  {
    return $class->_all_names;
  }

  sub _all_names (
    $class,
      )
  {
    my @result;
    foreach my $k ( keys %constant::declared )
    {
      next
          unless $k =~ m/^${class}::/xms;
      my ($name) = $k =~ m/^${class}::(\w+)/xms;
      push @result, $name;
    }

    return @result;
  }

  sub _build_const_lut (
    $class,
      )
  {
    my $lut = $class->_get_consts_ref;
    foreach my $name ( $class->_all_names )
    {
      my $value = $class->$name;
      $lut->{$name}        = $value;
      $lut->{ $value + 0 } = $value;
      $lut->{"$value"}     = $value;
    }
  }

  our $STRICT_NEW = 1;

  sub new (
    $class,
    $enum
      )
  {
    no warnings qw/numeric uninitialized/;
    my $result = $class->_get_consts_ref->{$enum};

    if ( !defined $result && $enum == 0 )
    {
      return undef;
    }

    if ( !defined $result )
    {
      return $enum
          if !$STRICT_NEW;
      Carp::confess "Could not find '$enum' for enum class $class";
    }

    return $result;
  }

  sub _add_enum (
    $class,
    $name,
    $value,
    $enum
      )
  {
    use Scalar::Util qw/dualvar/;

    die "Cannot add new enums after the const look up is created"
        if %{ $class->_get_consts_ref };

    my $result = dualvar( $value, $enum );
    constant->import( "${class}::${name}", $result );
    return;
  }
};

1;
