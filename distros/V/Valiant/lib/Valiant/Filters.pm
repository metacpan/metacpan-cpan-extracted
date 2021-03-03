package Valiant::Filters;

use Sub::Exporter 'build_exporter';
use Class::Method::Modifiers qw(install_modifier);
use Valiant::Util 'debug';

require Role::Tiny;

our @DEFAULT_ROLES = (qw(Valiant::Util::Ancestors Valiant::Filterable));
our @DEFAULT_EXPORTS = (qw(filters filters_with));

sub default_roles { @DEFAULT_ROLES }
sub default_exports { @DEFAULT_EXPORTS }

sub import {
  my $class = shift;
  my $target = caller;

  foreach my $default_role ($class->default_roles) {
    next if Role::Tiny::does_role($target, $default_role);
    debug 1, "Applying role '$default_role' to '$target'";
    Role::Tiny->apply_roles_to_package($target, $default_role);
  }

  my %cb = map {
    $_ => $target->can($_);
  } $class->default_exports;
  
  my $exporter = build_exporter({
    into_level => 1,
    exports => [
      map {
        my $key = $_; 
        $key => sub {
          sub { return $cb{$key}->($target, @_) };
        }
      } keys %cb,
    ],
  });

  $class->$exporter($class->default_exports);

  install_modifier $target, 'around', 'has', sub {
    my $orig = shift;
    my ($attr, %opts) = @_;

    my $method = \&{"${target}::filters"};
 
    if(my $validates = delete $opts{filters}) {
      debug 1, "Found filter in attribute '$attr'";
      $method->($attr, @$validates);
    }
      
    return $orig->($attr, %opts);
  } if $target->can('has');
} 

1;

=head1 NAME

Valiant::Filters - Adds a filter DSL and API to your Moo/se classes

=head1 SYNOPSIS

    package Local::Person;

    use Moo;
    use Valiant::Filters;

    has name => (is => 'ro');
    has age => (is => 'ro');

    filters name => (
      truncate => { max_length=>25 }
    );

    filters_with 'Trim';

Filters on specific attributes can be added to the C<has> clause if you prefer:

    package Local::Person;

    use Moo;
    use Valiant::Filters;

    has name => (is => 'ro', filters => [ truncate=>25 ] );
    has age => (is => 'ro');

    filters_with 'Trim';

Using filters on objects:

    my $person = Local::Person->new(
        name => ' Ja      ',
        age => 300,
      );

    print $person->name; # "Ja" not " Ja      ";

See L<Valiant> for overall overview and L<Valiant::Filterable> for additional API
level documentation.

=head1 DESCRIPTION

Using this package will apply the L<Valiant::Filterable> role to your current class
as well as import several class methods from that role.  It also wraps the C<has>
imported method so that you can add attribute filters as arguments to C<has> if
you find that approach to be neater than calling C<filter>.

You can override several class methods of this package if you need to create your
own custom subclass.

=head1 IMPORTS

The following subroutines are imported from L<Valiant::Filters>

=head2 filters_with

Accepts the name of a custom validator or a reference to a function, followed by a list
of arguments.  

    filter_with sub {
      my ($self, $class, $attrs) = @_;
    };

    filter_with 'SpecialFilters', arg1=>'foo', arg2=>'bar';

See C<filters_with> in L<Valiant::Filterable> for more.

=head2 filters

Create validations on an objects attributes.  Accepts the name of an attributes (or an
arrayref of names) followed by a list of validators and global options.  Validators can
be a subroutine reference, a type constraint or the name of a Validator class.

    validates name => sub {
      my ($self, $attribute, $value, $opts) = @_;
      $self->errors->add($attribute, "Invalid", $opts) if ...
    };

    validates name => (
      length => {
        maximum => 10,
        minimum => 3,
      }
    );

See C<filters> in L<Valiant::Filterable> for more.

=head1 METHODS

The following class methods are available for subclasses

=head2 default_role

Roles that are applied when using this class.  Default is L<Valiant::Filterable>.  If
you are subclassing and wish to apply more roles, or if you've made your own version
of L<Valiant::Filterable> you can override this method.

=head2 default_exports

Methods that are automatically exported into the calling package.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filterable>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
