package Valiant::Validations;

use warnings;
use strict;

use Class::Method::Modifiers;
use Valiant::Util 'debug';
use Scalar::Util;
use Moo::_Utils;

require Moo::Role;
require Sub::Util;

our @DEFAULT_ROLES = (qw(Valiant::Validates));
our @DEFAULT_EXPORTS = (qw(validates validates_with push_to_i18n_lookup));
our %Meta_Data = ();

sub default_roles { @DEFAULT_ROLES }
sub default_exports { @DEFAULT_EXPORTS }

sub import {
  my $class = shift;
  my $target = caller;

  unless (Moo::Role->is_role($target)) {
    my $orig = $target->can('with');
    Moo::_Utils::_install_tracked($target, 'with', sub {
      unless ($target->can('validations_metadata')) {
        $Meta_Data{$target}{'validations'} = \my @data;
        my $method = Sub::Util::set_subname "${target}::validations_metadata" => sub { @data };
        no strict 'refs';
        *{"${target}::validations_metadata"} = $method;
      }
      unless ($target->can('i18n_metadata')) {
        $Meta_Data{$target}{'i18n'} = \my @data;
        my $method = Sub::Util::set_subname "${target}::i18n_metadata" => sub { @data };
        no strict 'refs';
        *{"${target}::i18n_metadata"} = $method;
      }
      &$orig;
    });
  } 

  foreach my $default_role ($class->default_roles) {
    next if Role::Tiny::does_role($target, $default_role);
    debug 1, "Applying role '$default_role' to '$target'";
    Moo::Role->apply_roles_to_package($target, $default_role);
  }

  my %cb = map {
    $_ => $target->can($_);
  } $class->default_exports;

  foreach my $exported_method (keys %cb) {
    my $sub = sub {
      if(Scalar::Util::blessed($_[0])) {
        return $cb{$exported_method}->(@_);
      } else {
        return $cb{$exported_method}->($target, @_);
      }
    };
    Moo::_Utils::_install_tracked($target, $exported_method, $sub);
  }

  Class::Method::Modifiers::install_modifier $target, 'around', 'has', sub {
    my $orig = shift;
    my ($attr, %opts) = @_;

    my $method = \&{"${target}::validates"};
 
    if(my $validates = delete $opts{validates}) {
      debug 1, "Found validation in attribute '$attr'";
      $method->($attr, @$validates);
    }
      
    return $orig->($attr, %opts);
  } if $target->can('has');
} 

sub _add_metadata {
  my ($target, $type, @add) = @_;
  my $store = $Meta_Data{$target}{$type} ||= do {
    my @data;
    if (Moo::Role->is_role($target) or $target->can("${type}_metadata")) {
      $target->can('around')->("${type}_metadata", sub {
        my ($orig, $self) = (shift, shift);
        ($self->$orig(@_), @data);
      });
    } else {
      require Sub::Util;
      my $method = Sub::Util::set_subname "${target}::${type}_metadata" => sub { @data };
      no strict 'refs';
      *{"${target}::${type}_metadata"} = $method;
    }
    \@data;
  };
  push @$store, @add;
  return;
}


1;

=head1 NAME

Valiant::Validations - Addos a validation DSL and API to your Moo/se classes

=head1 SYNOPSIS

    package Local::Person;

    use Moo;
    use Valiant::Validations;

    has name => (is=>'ro');
    has age => (is=>'ro');

    validates name => (
      length => {
        maximum => 10,
        minimum => 3,
      }
    );

    validates age => (
      numericality => {
        is_integer => 1,
        less_than => 200,
      },
    );

Validators on specific attributes can be added to the C<has> clause if you prefer:

    package Local::Person;

    use Moo;
    use Valiant::Validations;

    has name => (
      is => 'ro',
      validates => [
        length => {
          maximum => 10,
          minimum => 3,
        },
      ],
    );

    has age => (
      is => 'ro',
      validates => [
        numericality => {
          is_integer => 1,
          less_than => 200,
        },
      ],
    );

Using validations on objects:

    my $person = Local::Person->new(
        name => 'Ja',
        age => 300,
      );

    $person->validate;
    $person->valid;     # FALSE
    $person->invalid;   # TRUE

    my %errors = $person->errors->to_hash(full_messages=>1);

    # \%errors = +{
    #   age => [
    #     "Age must be less than 200",
    #   ],
    #   name => [
    #     "Name is too short (minimum is 3 characters)',   
    #   ],
    # };

See L<Valiant> for overall overview and L<Valiant::Validates> for additional API
level documentation.

=head1 DESCRIPTION

Using this package will apply the L<Valiant::Validates> role to your current class
as well as import several class methods from that role.  It also wraps the C<has>
imported method so that you can add attribute validations as arguments to C<has> if
you find that approach to be neater than calling C<validates>.

You can override several class methods of this package if you need to create your
own custom subclass.

=head1 IMPORTS

The following subroutines are imported from L<Valiant::Validates>

=head2 validates_with

Accepts the name of a custom validator or a reference to a function, followed by a list
of arguments.  

    validates_with sub {
      my ($self, $opts) = @_;
    };

    valiates_with 'SpecialValidator', arg1=>'foo', arg2=>'bar';

See C<validates_with> in either L<Valiant> or L<Valiant::Validates> for more.

=head2 validates

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

See C<validates> in either L<Valiant> or L<Valiant::Validates> for more.

=head1 METHODS

The following class methods are available for subclasses

=head2 default_role

Roles that are applied when using this class.  Default is L<Valiant::Validates>.  If
you are subclassing and wish to apply more roles, or if you've made your own version
of L<Valiant::Validates> you can override this method.

=head2 default_exports

Methods that are automatically exported into the calling package.

=head1 ADDING VALIDATIONS TO OBJECTS

Generally for best performance you will want to add validations to your classes, that way
we can searching and precompile all the validations for optimized runtime.   However you
can add validations to objects after they are initialized and they will DTRT (add those
validations only to the instance and not to the class).

    my $object = Local::Test::User->new(age=>5);
    $object->validates(age => (numericality => {greater_than => 10}));

Please note that you should expect some performance hit here since we need to search for
and prepare the validation.  So don't use this in hot parts of your code.  Ideally you won't
really need this feature and can work around using validation contexts but I saw now reason
to prevent this from working for those unusual cases where it might be worth the price.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Validates>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
