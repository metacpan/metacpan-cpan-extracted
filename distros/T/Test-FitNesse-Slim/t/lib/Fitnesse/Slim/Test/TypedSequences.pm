package Fitnesse::Slim::Test::TypedSequences;

use strict;
use warnings;
use Scalar::Util qw(refaddr);

sub slim_constructor_signature {
  return { parameters => [
    'java.lang.Integer[]',
    'java.util.List<java.lang.String>',
  ] };
}

sub new {
  my ($class, $integers, $strings) = @_;
  return bless {
    integers => $integers,
    strings => $strings,
    flags => undef,
  }, $class;
}

sub slim_method_signature {
  my ($self, $method) = @_;
  my %signature = (
    set_integers => { parameters => ['int[]'], return => 'void' },
    set_strings => { parameters => ['String[]'], return => 'void' },
    set_flags => { parameters => ['java.util.Collection<java.lang.Boolean>'], return => 'void' },
    same_integers => { parameters => ['java.lang.Integer[]'], return => 'boolean' },
    same_strings => { parameters => ['java.util.List<java.lang.String>'], return => 'boolean' },
    accepts_null => { parameters => ['java.util.Collection<java.lang.Integer>'], return => 'boolean' },
    get_integers => { return => 'java.lang.Integer[]' },
    get_strings => { return => 'java.util.List<java.lang.String>' },
    get_flags => { return => 'java.util.Collection<java.lang.Boolean>' },
    get_null_collection => { return => 'java.util.List<java.lang.Integer>' },
    get_empty_collection => { return => 'java.util.Collection<java.lang.Integer>' },
    get_empty_array => { return => 'int[]' },
  );
  return $signature{$method};
}

sub set_integers { $_[0]{integers} = $_[1]; return }
sub set_strings { $_[0]{strings} = $_[1]; return }
sub set_flags { $_[0]{flags} = $_[1]; return }
sub same_integers { refaddr($_[0]{integers}) == refaddr($_[1]) ? 1 : 0 }
sub same_strings { refaddr($_[0]{strings}) == refaddr($_[1]) ? 1 : 0 }
sub accepts_null { !defined $_[1] ? 1 : 0 }
sub get_integers { $_[0]{integers} }
sub get_strings { $_[0]{strings} }
sub get_flags { $_[0]{flags} }
sub get_null_collection { undef }
sub get_empty_collection { [] }
sub get_empty_array { [] }
sub untyped_values { [11, 12] }

1;
