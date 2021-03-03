package Valiant::Filter::With;

use Moo;
use Valiant::Util 'throw_exception';

with 'Valiant::Filter::Each';

has cb => (is=>'ro', required=>1);
has opts => (is=>'ro', predicate=>'has_opts');

sub normalize_shortcut {
  my ($class, $arg) = @_;
  if((ref($arg)||'') eq 'CODE') {
    return +{
      cb => $arg,
    };
  }
  if((ref($arg)||'') eq 'ARRAY') {
    return +{
      cb => $arg->[0],
      opts => $arg->[1],
    };
  }

}

sub filter_each {
  my ($self, $class, $attrs, $attribute_name) = @_;
  my @args = ($class, $attrs, $attribute_name);
  push @args, $self->opts if $self->has_opts;
  return $self->cb->(@args);
}

1;

=head1 NAME

Valiant::Validator::With - Filter using a coderef and options opts

=head1 SYNOPSIS

    package Local::Test::User;

    use Moo;
    use Valiant::Filters;

    has 'name' => (is=>'ro', required=>1);

    filters name => (
      with => {
        cb => sub {
          my ($class, $attrs, $name, $opts) = @_;
          return $attrs->{$name}.$opts->{a};
        },
        opts => +{ a=>'foo' },
      },
      with => sub {
          my ($class, $attrs, $name) = @_;
          return $attrs->{$name}.'bar';
      },
      with => [sub {
          my ($class, $attrs, $name, $opts) = @_;
          return $attrs->{$name}.$opts;
      }, 'baz'],
    );

    my $user = Local::Test::User->new(name=>'john');

    print $user->name; # 'johnfoobarbaz'

=head1 DESCRIPTIONi

this filter allows you to make a custom subroutine reference into a filter, with
options options for parameterization.   You can use this when you have a very
special filter need but don't feel like writing a custom filter by subclassing
L<Valiant::Filter::Each>.

=head1 Passing parameters to $opts

You can pass parameters to the C<$opts> hashref using the C<opts> argument:

    my $filter = sub {
      my ($self, $class, $attrs, $attribute_name, $opts) = @_;
      my $old_value = $attrs->{$attribute_name};
      # ...
      return $new_value

    };

    filters my_attribute => (
      with => {
        cb => $filter,
        opts => {arg => 2000},
      },
    );


You might find this useful in creating more parametered callbacks.  However at this point
you might wish to consider just writing a custom filter class.

=head1 SHORTCUT FORM

This filter supports the follow shortcut forms:

    validates attribute => ( with => sub { my $self = shift; ... }, ... );
    validates attribute => ( with => [\&method, [1,2,3]], ... );

Which is the same as:

    validates attribute => (
      with => {
        cb => sub { ... },
      },
      ...
    );

    validates attribute => (
      with => {
        cb => \&method,
        opts => [1,2,3],
      },
      ...
    );

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filter>, L<Valiant::Filter::Each>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
