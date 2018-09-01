package decorators;
# ABSTRACT: Apply decorators to your methods

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Carp            ();
use Scalar::Util    ();
use MOP             (); # this is how we do most of our work
use Module::Runtime (); # decorator provider loading

## --------------------------------------------------------
## Importers
## --------------------------------------------------------

sub import {
    my $class = shift;
    $class->import_into( scalar caller, @_ );
}

## --------------------------------------------------------
## Trait collection
## --------------------------------------------------------

sub import_into {
    my (undef, $package, @providers) = @_;

    Carp::confess('You must provide a valid package argument')
        unless $package;

    Carp::confess('The package argument cannot be a reference or blessed object')
        if ref $package;

    # convert this into a metaobject
    my $meta = MOP::Role->new( $package );

    Carp::confess('Cannot install decorator collectors, MODIFY_CODE_ATTRIBUTES method already exists')
        if $meta->has_method('MODIFY_CODE_ATTRIBUTES') || $meta->has_method_alias('MODIFY_CODE_ATTRIBUTES');

    Carp::confess('Cannot install decorator collectors, FETCH_CODE_ATTRIBUTES method already exists')
        if $meta->has_method('FETCH_CODE_ATTRIBUTES') || $meta->has_method_alias('FETCH_CODE_ATTRIBUTES');

    # now install the collectors ...

    my %accepted; # shared data between the collectors ...

    $meta->alias_method(
        FETCH_CODE_ATTRIBUTES => sub {
            my (undef, $code) = @_;
            # return just the strings, as expected by attributes ...
            return $accepted{ $code } ? @{ $accepted{ $code } } : ();
        }
    );

    $meta->alias_method(
        MODIFY_CODE_ATTRIBUTES => sub {
            my ($pkg, $code, @attrs) = @_;

            my $role       = MOP::Role->new( $pkg );    # the actual Package that Perl is talking about ...
            my $method     = MOP::Method->new( $code ); # the actual CV that Perl is talking about ...
            my @attributes = map MOP::Method::Attribute->new( $_ ), @attrs; # inflate the attributes ...

            my $decorators = _create_decorator_meta_object_for( $role->name );
            # preparing the attrbutes returns the ones that are unhandled ...
            # my @unhandled = map $_->original, $decorators->filter_unhandled( @attributes );
            my @unhandled  = map $_->original, grep !_has_decorator( $decorators, $_->name ), @attributes;

            # return the bad decorators as strings, as expected by attributes ...
            return @unhandled if @unhandled;

            # process the attributes ...
            foreach my $attribute ( @attributes ) {
                my $d = _get_decorator( $decorators, $attribute->name );

                $d or die 'This should never happen, as we have already checked this above ^^';

                # we know that this will be a no-op,
                # so, we no-op and go to the next one
                next if $d->has_code_attributes('TagMethod');

                if ( $d->has_code_attributes('CreateMethod') ) {
                    $method->is_required
                        or die 'The method ('.$method->name.') must be bodyless for a `CreateMethod` decorator ('.$d->name.') '
                              .'to be applied to it, please check the order of your decorators, `CreateMethod` decorators '
                              .'should usually be applied early in the list when possible.';
                }

                $d->body->( $role, $method, @{ $attribute->args || [] } );

                if ( $d->has_code_attributes('WrapMethod') || $d->has_code_attributes('CreateMethod') ) {
                    my $name = $method->name;
                    $method = $role->get_method( $name );
                    Carp::croak('Failed to find new overwriten method ('.$name.') in class ('.$role->name.')')
                        unless defined $method;
                }
            }

            # store the decorators we applied ...
            $accepted{ $method->body } = [ map $_->original, @attributes ];

            return;
        }
    );

    if ( @providers ) {
        # so we can use lowercase attributes ...
        warnings->unimport('reserved')
            if grep /^:/, @providers;

        # expand any tags, they should match
        # the provider names available in the
        # decorators::providers::* namespace
        @providers = map /^\:/ ? 'decorators::providers:'.$_ : $_, @providers;

        # load the providers, and then ...
        Module::Runtime::use_package_optimistically( $_ ) foreach @providers;

        _set_decorator_providers(
            _create_decorator_meta_object_for( $package ),
            @providers
        );
    }

    return;
}

## methods to deal with the internals

sub _create_decorator_meta_object_for {
    my ($namespace) = @_;
    return MOP::Role->new( $namespace.'::__DECORATORS__' );
}

sub _set_decorator_providers {
    my ($decorators, @providers) = @_;
    $decorators->set_roles( @providers );
    MOP::Util::compose_roles( $decorators );
}

# methods to deal with locating decorators

sub _has_decorator {
    my ($decorators, $name) = @_;

    return unless $decorators->has_method( $name );

    my $method = $decorators->get_method( $name );
    return 1 if $method->origin_stash eq 'decorators::providers::for_providers';
    return 1 if $method->has_code_attributes('Decorator');
    return;
}

sub _get_decorator {
    my ($decorators, $name) = @_;
    return unless _has_decorator( $decorators, $name );
    return $decorators->get_method( $name );
}

1;

__END__

=pod

=head1 NAME

decorators - Apply decorators to your methods

=head1 VERSION

version 0.01

=head1 DESCRIPTION

Decorators are subroutines that are run at compile time to modify the
behavior of a method. This can be something as drastic as replacing
the method body, or something as unintrusive as simply tagging the
method with metadata.

=head2 DECORATORS

A decorator is simply a callback which is associated with a given
subroutine and fired during compile time.

=head2 How are decorators registered?

Decorators are registered via a mapping of decorator providers, which
are just packages containing decorator subroutines, and the class in
which you intend to apply the decorators.

This is done by passing in the provider package name when using
the L<decorators> package, like so:

    package My::Class;
    use decorators 'My::Provider';

This will make available, all the decorators in F<My::Provider>
for use inside F<My::Class>.

=head2 How are decorators associated?

Decorators are associated to a subroutine using the "attribute"
feature of Perl. When the "attribute" mechanism is triggered for
a given method, we extract the name of the attribute and then
attempt to find a decorator of that name in the associated
providers.

This means that in the following code:

    package My::Class;
    use decorators 'My::Provider';

    sub foo : SomeTrait { ... }

We will encounter the C<foo> method and see that it has the
C<SomeTrait> "attribute". We will then look to see if there is a
C<SomeTrait> decorator available in the F<My::Provider> provider, and
if found, will call that decorator.

=head2 How are decorators called?

The decorators are called immediately when the "attribute" mechanism
is triggered. The decorator callbacks receieve at least two arguments,
the first being a L<MOP::Class> instance representing the
subroutine's package, the next being the L<MOP::Method> instance
representing the subroutine itself, and then, if there are any
arguments passed to the decorator, they are also passed along.

=head1 PERL VERSION COMPATIBILITY

For the moment I am going to require 5.14.4 because of the following quote
by Zefram in the L<Sub::WhenBodied> documentation:

  Prior to Perl 5.15.4, attribute handlers are executed before the body
  is attached, so see it in that intermediate state. (From Perl 5.15.4
  onwards, attribute handlers are executed after the body is attached.)
  It is otherwise unusual to see the subroutine in that intermediate
  state.

I am also using the C<${^GLOBAL_PHASE}> variable, which was introduced in
5.14.

It likely is possible using L<Devel::GlobalPhase> and C<Sub::WhenBodied>
to actually implment this all for pre-5.14 perls, but for now I am not
going to worry about that.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
