package Text::Pipe::Base;

use warnings;
use strict;
use UNIVERSAL::require;


our $VERSION = '0.10';


use base qw(Class::Accessor::Complex Class::Accessor::Constructor);

    
use overload
    '|'      => 'bit_or',
    fallback => 1;


__PACKAGE__->mk_constructor;


# so subclasses can call SUPER::init(@_)
sub init {}


sub filter_single {
    my ($self, $input) = @_;
    $input;
}


sub filter {
    my ($self, $input) = @_;

    if (ref $input eq 'ARRAY') {
        return [ map { $self->filter_single($_) } @$input ];
    } else {
        return $self->filter_single($input);
    }

}


sub bit_or {
    my ($lhs, $rhs) = @_;

    die "can only stack pipe segments" unless
        UNIVERSAL::isa($lhs, 'Text::Pipe::Base') &&
        UNIVERSAL::isa($rhs, 'Text::Pipe::Base');
    
    # even if either side is a Text::Pipe::Stackable already, don't push or
    # unshift because we don't want to alter the original pipes. So we'd
    # rather create nested pipes.

    # don't use() it because Text::Pipe::Stackable inherits from this class
    Text::Pipe::Stackable->require;
    Text::Pipe::Stackable->new($lhs, $rhs);
}


1;


__END__



=head1 NAME

Text::Pipe::Base - Base class for text pipe segments

=head1 SYNOPSIS

    package Text::Pipe::My::Segment;

    use base 'Text::Pipe::Base';

    sub filter {
        # blah
    }

=head1 DESCRIPTION

This is the base class for all text pipe segments. It implements basic
behaviour that specific text pipe segments will want to override.

It also overloads the C<|> operator so you can create stackable pipes like
this:

    my $stackable_pipe = $pipe1 | $pipe2 | $pipe3;

=head1 METHODS

=over 4

=item C<new>

    my $obj = Text::Pipe::Base->new;
    my $obj = Text::Pipe::Base->new(%args);

Creates and returns a new object. The constructor will accept as arguments a
list of pairs, from component name to initial value. For each pair, the named
component is initialized by calling the method of the same name with the given
value. If called with a single hash reference, it is dereferenced and its
key/value pairs are set as described before.

=item C<bit_or>

This subroutine implements the pipe stacking that is invoked by using the C<|>
operator, as in:

    my $stackable_pipe = $pipe1 | $pipe2 | $pipe3;

=item C<filter>

Can filter a single string or an reference to an array of strings. Each string
is filtered using C<filter_single()>.

=item C<filter_single>

Filters a single string. In this base class this method just returns the input
string unaltered.

=item C<init>

This method is called by the constructor and passed the object so it can be
initialized. In this class the method is empty, but it exists so that
subclasses can override this method and call C<SUPER::init()>.

=back

Text::Pipe::Base inherits from L<Class::Accessor::Complex>,
L<Class::Accessor::Constructor>, and L<Class::Accessor::Constructor::Base>.

The superclass L<Class::Accessor::Complex> defines these methods and
functions:

    mk_abstract_accessors(), mk_array_accessors(), mk_boolean_accessors(),
    mk_class_array_accessors(), mk_class_hash_accessors(),
    mk_class_scalar_accessors(), mk_concat_accessors(),
    mk_forward_accessors(), mk_hash_accessors(), mk_integer_accessors(),
    mk_new(), mk_object_accessors(), mk_scalar_accessors(),
    mk_set_accessors(), mk_singleton()

The superclass L<Class::Accessor> defines these methods and functions:

    _carp(), _croak(), _mk_accessors(), accessor_name_for(),
    best_practice_accessor_name_for(), best_practice_mutator_name_for(),
    follow_best_practice(), get(), make_accessor(), make_ro_accessor(),
    make_wo_accessor(), mk_accessors(), mk_ro_accessors(),
    mk_wo_accessors(), mutator_name_for(), set()

The superclass L<Class::Accessor::Installer> defines these methods and
functions:

    install_accessor()

The superclass L<Class::Accessor::Constructor> defines these methods and
functions:

    _make_constructor(), mk_constructor(), mk_constructor_with_dirty(),
    mk_singleton_constructor()

The superclass L<Data::Inherited> defines these methods and functions:

    every_hash(), every_list(), flush_every_cache_by_key()

The superclass L<Class::Accessor::Constructor::Base> defines these methods
and functions:

    STORE(), clear_dirty(), clear_hygienic(), clear_unhygienic(),
    contains_hygienic(), contains_unhygienic(), delete_hygienic(),
    delete_unhygienic(), dirty(), dirty_clear(), dirty_set(),
    elements_hygienic(), elements_unhygienic(), hygienic(),
    hygienic_clear(), hygienic_contains(), hygienic_delete(),
    hygienic_elements(), hygienic_insert(), hygienic_is_empty(),
    hygienic_size(), insert_hygienic(), insert_unhygienic(),
    is_empty_hygienic(), is_empty_unhygienic(), set_dirty(),
    size_hygienic(), size_unhygienic(), unhygienic(), unhygienic_clear(),
    unhygienic_contains(), unhygienic_delete(), unhygienic_elements(),
    unhygienic_insert(), unhygienic_is_empty(), unhygienic_size()

The superclass L<Tie::StdHash> defines these methods and functions:

    CLEAR(), DELETE(), EXISTS(), FETCH(), FIRSTKEY(), NEXTKEY(), SCALAR(),
    TIEHASH()

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see L<http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

The development version lives at L<http://github.com/hanekomu/text-pipe/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

