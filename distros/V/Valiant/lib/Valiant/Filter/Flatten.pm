package Valiant::Filter::Flatten;

use Moo;

with 'Valiant::Filter::Each';

has pick => (is=>'ro', predicate=>'has_pick');
has join => (is=>'ro', predicate=>'has_join');
has sprintf => (is=>'ro', predicate=>'has_sprintf');
has pattern => (is=>'ro', predicate=>'has_pattern');

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{ };
}

sub filter_each {
  my ($self, $class, $attrs, $attribute_name) = @_;
  my $value = $attrs->{$attribute_name};
  return unless defined $value;

  if($self->has_pick) {
    return $value->[0] if $self->pick eq 'first';
    return $value->[-1] if $self->pick eq 'last';
    die '"pick" must be either "first" or "last"';
  }
  if($self->has_join) {
    return join($self->join, @$value);
  }
  if($self->has_sprintf) {
    return sprintf($self->sprintf, @$value);
  }
  if($self->has_pattern) {
    my $pattern = $self->pattern;
    $pattern =~ s/\{\{([^}]+)\}\}/ defined($value->{$1}) ? $value->{$1}: '' /gex; 
    return $pattern;
  }

  die 'Flatten filter must define one of pick, join or sprintf';
}

1;

=head1 NAME

Valiant::Filter::Flatten - Array or Hash ref to string

=head1 SYNOPSIS

    package Local::Test;

    use Moo;
    use Valiant::Filters;

    has 'pick_first' => (is=>'ro', required=>1);
    has 'pick_last' => (is=>'ro', required=>1);
    has 'join' => (is=>'ro', required=>1);
    has 'sprintf' => (is=>'ro', required=>1);
    has 'pattern' => (is=>'ro', required=>1);

    filters pick_first => (flatten => +{pick => 'first'});
    filters pick_last => (flatten => +{pick => 'last'});
    filters join => (flatten => +{join => ','});
    filters sprintf => (flatten => +{sprintf => '%s-%s-%s'});
    filters pattern => (flatten => +{pattern => 'hi {{a}} there {{b}}'});

    my $object = Local::Test->new(
      pick_first => [1,2,3],
      pick_last => [1,2,3],
      join => [1,2,3],
      sprintf => [1,2,3],
      pattern => +{ a=>'now', b=>'john' },
    );

    print $object->pick_first;  # 1
    print $object->pick_last;   # 3
    print $object->join;        # '1,2,3'
    print $object->sprintf;     # '1-2-3'
    print $object->pattern;     # 'hi now there john'

=head1 DESCRIPTION

Given an arrayref for a value, flatten to a string in various ways

=head1 ATTRIBUTES

This filter defines the following attributes

=head2 pick

Value of either 'first' or 'last' which indicates choosing either the first or
last index of the arrayref.

=head2 join

Join the arrayref into a string using the value of 'join' as the deliminator

=head2 sprintf

Use C<sprintf> formatted string to convert an arrayref.

=head2 pattern

Uses a L<Valiant> style pattern string to convert a hashref to a string.  Basically
inside the pattern string we look for "{{$key}}" and substitute $key for whatever
matches in the incoming hashref as a key value.  If there's no match we replace with
an empty string without raising warnings.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filter>, L<Valiant::Validator::Filter>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
