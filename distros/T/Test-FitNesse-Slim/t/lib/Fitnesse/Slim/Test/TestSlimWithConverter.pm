package Fitnesse::Slim::Test::TestSlimWithConverter;

use strict;
use warnings;
use Test::FitNesse::Slim::ConverterRegistry;

sub new { bless { executor => undef, standard_list_converter => undef }, shift }

sub set_statement_executor { $_[0]{executor} = $_[1] }

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => [], return => 'void' }
    if $method =~ /\A(?:set_list_converter|remove_list_converter|reset_converters)\z/;
  return { parameters => [], return => 'java.lang.Object' }
    if $method eq 'get_object';
  return { parameters => [], return => 'java.util.List' }
    if $method eq 'get_list';
  return { parameters => [], return => 'java.util.ArrayList' }
    if $method eq 'get_array_list';
  return { parameters => ['java.util.List'], return => 'boolean' }
    if $method eq 'same_list';
  return;
}

sub set_list_converter {
  my ($self) = @_;
  $self->{standard_list_converter} = $self->{executor}->get_converter('java.util.List');
  $self->{executor}->add_converter('java.util.List', Fitnesse::Slim::Test::TestSlimWithConverter::BraceList->new);
}

sub remove_list_converter {
  my ($self) = @_;
  $self->{executor}->add_converter('java.util.List', $self->{standard_list_converter})
    if $self->{standard_list_converter};
}

sub reset_converters {
  $_[0]{executor}->reset_converters;
  $_[0]{standard_list_converter} = undef;
}

sub get_object { [qw(a b c)] }
sub get_list { [qw(a b c)] }
sub get_array_list { [qw(a b c)] }

sub same_list {
  my ($self, $list) = @_;
  return 0 unless ref($list) eq 'ARRAY';
  return join(',', @$list) eq 'a,b,c' ? 1 : 0;
}

package Fitnesse::Slim::Test::TestSlimWithConverter::BraceList;

use strict;
use warnings;

sub new { bless {}, shift }
sub set_registry { $_[0]{registry} = $_[1] }

sub from_string {
  my ($self, $arg) = @_;
  $arg =~ s/\A\{/[/;
  $arg =~ s/\}\z/]/;
  return Test::FitNesse::Slim::ConverterRegistry::List::from_string($self, $arg);
}

sub to_string {
  my ($self, $list) = @_;
  my $value = Test::FitNesse::Slim::ConverterRegistry::List::to_string($self, $list);
  return undef unless defined $value;
  $value =~ s/\[/\{/g;
  $value =~ s/\]/\}/g;
  return $value;
}

1;
