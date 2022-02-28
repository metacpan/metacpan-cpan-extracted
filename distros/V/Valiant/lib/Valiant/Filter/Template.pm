package Valiant::Filter::Template;

use Moo;
use Valiant::Util 'throw_exception';

with 'Valiant::Filter::Each';

has template => (is=>'ro', required=>1);

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{ template => $arg };
}

sub filter_each {
  my ($self, $class, $attrs, $attribute_name) = @_;  
  my $value = $attrs->{$attribute_name};
  return unless defined $value and ref($value) eq 'HASH';
  return my $template = process_template($self->template, %$value);
}

1;

=head1 NAME

Valiant::Filter::Template - Flatten a Hashref into a string via a template pattern

=head1 SYNOPSIS

    package Local::Test;

    use Moo;
    use Valiant::Filters;

    has 'info' => (is=>'ro', required=>1);

    filters 'info',
      template => 'Hello {{name}}, you are {{age}} years old!';

    my $object = Local::Test->new(
      info => +{
        name => 'John',
        age => '52',
      }
    );

    $object->info;  # Hello John you are 52 years old!'
  
=head1 DESCRIPTION

Given a hashref value, using a template create a string.  This isn't a very sophisticated
templating system, and it won't throw errors if hash keys are missing.

=head1 ATTRIBUTES

This filter defines the following attributes

=head2 template

The template string

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filter>, L<Valiant::Validator::Filter>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
