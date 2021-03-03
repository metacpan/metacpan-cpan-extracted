package Valiant::Filter::Numberize;

use Moo;
use Valiant::Util 'throw_exception';

with 'Valiant::Filter::Each';

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{ };
}

sub filter_each {
  my ($self, $class, $attrs, $attribute_name) = @_;  
  my $value = $attrs->{$attribute_name};
  return unless defined $value;

  no warnings 'numeric';
  return 0+$value;
}

1;

=head1 NAME

Valiant::Filter::Numberize - Force into number context

=head1 SYNOPSIS

  package Local::Test::User;

  use Moo;
  use Valiant::Filters;

  has 'age' => (is=>'ro', required=>1);

  filters age => (
    numberize => 1,
  );

  my $user = Local::Test::User->new(age=>'25');
  print $user->age; # 25

  my $not_a_number = Local::Test::User(age=>'aaaabbbccc');
  print $not_a_number; # 0

  
=head1 DESCRIPTION

This is a very simple filter that takes no paramters and just forces a value into
number context. Please note that this mean strings with letters and other non number
values will almost always end up as 0 without returning any validation errors.   If you
want to notice and handle this as a validation then you might want to check L<Valiant::Validator::Numericality>
instead,

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filter>, L<Valiant::Validator::Filter>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
