package Valiant::Filter::Lower;

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
  return lc $value;
}

1;

=head1 NAME

Valiant::Filter::Lower - lower case a string

=head1 SYNOPSIS

  package Local::Test::User;

  use Moo;
  use Valiant::Filters;

  has 'name' => (is=>'ro', required=>1);

  filters name => (
    lower => 1,
  );

  my $user = Local::Test::User->new(name=>'JOHN');

  print $user->name; # 'john'
  
=head1 DESCRIPTION

This is a very simple filter that takes no paramters and just does a 'lc' on the
value of the attribute.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filter>, L<Valiant::Validator::Filter>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
