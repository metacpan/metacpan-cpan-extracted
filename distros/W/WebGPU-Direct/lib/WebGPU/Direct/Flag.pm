package WebGPU::Direct::Flag;
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  use base 'WebGPU::Direct::Enum';

  use Carp qw/croak/;

  sub _get_flags_ref (
    $class,
      )
  {
    return eval '\@' . $class . '::FLAGS';
  }

  sub _build_const_lut (
    $class,
      )
  {
    $class->SUPER::_build_const_lut;

    my $bits = $class->_get_flags_ref;
    foreach my $name ( $class->_all_names )
    {
      my $value = $class->$name;
      next
          if $value >= 0x7FFFFFFF;

      my $bitstr = sprintf( "%064b", $value + 0 );
      next
          if ( $bitstr =~ tr/1// ) > 1;

      my $exp = length( $bitstr =~ s/^0*(1?)/$1/r );

      croak "Duplicate bit flag: $value"
          if defined $bits->[$exp];

      $bits->[$exp] = $value;
    }
  }

  sub new (
    $class,
    $flag
      )
  {
    my $result = $class->_get_consts_ref->{$flag};

    if ( !defined $result && $flag == 0 )
    {
      return undef;
    }

BIT_BUILD:
    if ( !defined $result )
    {
      my @str_val;
      my $num_val = 0;
      my $bin_val = chr($flag);
      my @bits    = $class->_get_flags_ref->@*;

      foreach my $i ( keys @bits )
      {
        next
            if $i == 0;
        next
            if !vec( $bin_val, $i - 1, 1 );

        my $bit = $bits[$i];
        last BIT_BUILD
            if !defined $bit;

        push @str_val, "$bit";
        $num_val += 0 + $bit;
      }

      $result = Scalar::Util::dualvar( $num_val, join( ' | ', @str_val ) );
    }

    if ( !defined $result )
    {
      return $flag
          if !$WebGPU::Direct::Enum::STRICT_NEW;
      Carp::confess "Could not find '$flag' for enum class $class";
    }

    return $result;
  }
};

1;
