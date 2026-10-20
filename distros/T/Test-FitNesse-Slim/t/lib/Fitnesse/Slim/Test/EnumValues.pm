package Fitnesse::Slim::Test::EnumValues;

use strict;
use warnings;
use Scalar::Util qw(refaddr);

sub slim_enum_types {
  return {
    Color => [qw(RED red GREEN BLUE)],
    'Fitnesse::Slim::Test::EnumValues::Mode' => [qw(FAST SAFE)],
  };
}

sub slim_constructor_signature {
  return { parameters => ['Color'] };
}

sub new {
  my ($class, $color) = @_;
  return bless { color => $color, array => [], list => [], collection => [] }, $class;
}

sub slim_method_signature {
  my ($self, $method) = @_;
  my %signature = (
    set_color => { parameters => ['Color'], return => 'void' },
    echo_color => { parameters => ['Color'], return => 'Color' },
    get_color => { return => 'Color' },
    get_null => { return => 'Color' },
    bad_result => { return => 'Color' },
    echo_mode => {
      parameters => ['Fitnesse::Slim::Test::EnumValues::Mode'],
      return => 'Fitnesse::Slim::Test::EnumValues::Mode',
    },
    set_sequences => {
      parameters => ['Color[]', 'List<Color>', 'Collection<Color>'],
      return => 'void',
    },
    get_array => { return => 'Color[]' },
    get_list => { return => 'List<Color>' },
    get_collection => { return => 'Collection<Color>' },
    same_array => { parameters => ['Color[]'], return => 'boolean' },
    same_list => { parameters => ['List<Color>'], return => 'boolean' },
  );
  return $signature{$method};
}

sub set_color { $_[0]{color} = $_[1]; return }
sub echo_color { $_[1] }
sub get_color { $_[0]{color} }
sub get_null { undef }
sub bad_result { 'PURPLE' }
sub echo_mode { $_[1] }
sub set_sequences {
  my ($self, $array, $list, $collection) = @_;
  @{$self}{qw(array list collection)} = ($array, $list, $collection);
  return;
}
sub get_array { $_[0]{array} }
sub get_list { $_[0]{list} }
sub get_collection { $_[0]{collection} }
sub same_array { refaddr($_[0]{array}) == refaddr($_[1]) ? 1 : 0 }
sub same_list { refaddr($_[0]{list}) == refaddr($_[1]) ? 1 : 0 }
sub plain_echo { $_[1] }

1;
