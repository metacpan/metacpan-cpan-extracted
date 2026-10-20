package Fitnesse::Slim::Test::DoubleValues;

use strict;
use warnings;
use Scalar::Util qw(refaddr);

sub slim_constructor_signature {
  return { parameters => ['double', 'java.lang.Double'] };
}

sub new {
  my ($class, $primitive, $boxed) = @_;
  return bless {
    primitive => $primitive,
    boxed => $boxed,
    array => [],
    list => [],
    collection => [],
  }, $class;
}

sub slim_method_signature {
  my ($self, $method) = @_;
  my %signature = (
    get_primitive => { return => 'double' },
    get_boxed => { return => 'java.lang.Double' },
    get_null => { return => 'java.lang.Double' },
    echo_primitive => { parameters => ['double'], return => 'double' },
    echo_boxed => { parameters => ['java.lang.Double'], return => 'java.lang.Double' },
    set_sequences => {
      parameters => [
        'java.lang.Double[]',
        'java.util.List<java.lang.Double>',
        'java.util.Collection<java.lang.Double>',
      ],
      return => 'void',
    },
    get_array => { return => 'java.lang.Double[]' },
    get_list => { return => 'java.util.List<java.lang.Double>' },
    get_collection => { return => 'java.util.Collection<java.lang.Double>' },
    same_array => { parameters => ['java.lang.Double[]'], return => 'boolean' },
  );
  return $signature{$method};
}

sub get_primitive { $_[0]{primitive} }
sub get_boxed { $_[0]{boxed} }
sub get_null { undef }
sub echo_primitive { $_[1] }
sub echo_boxed { $_[1] }
sub set_sequences {
  my ($self, $array, $list, $collection) = @_;
  @{$self}{qw(array list collection)} = ($array, $list, $collection);
  return;
}
sub get_array { $_[0]{array} }
sub get_list { $_[0]{list} }
sub get_collection { $_[0]{collection} }
sub same_array { refaddr($_[0]{array}) == refaddr($_[1]) ? 1 : 0 }

1;
