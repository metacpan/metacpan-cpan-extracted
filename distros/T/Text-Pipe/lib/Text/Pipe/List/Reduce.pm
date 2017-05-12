package Text::Pipe::List::Reduce;

use warnings;
use strict;
use List::Util 'reduce';


our $VERSION = '0.10';


use base 'Text::Pipe::Base';


__PACKAGE__->mk_scalar_accessors(qw(code));


sub filter {
    my ($self, $input) = @_;
    return $input unless ref $input eq 'ARRAY';

    # kludge because of prototype requirements
    reduce { $self->code->($a, $b) } @$input;
}


1;


__END__



=head1 NAME

Text::Pipe::List::Reduce - Common text filter API

=head1 SYNOPSIS

    Text::Pipe::List::Reduce->new;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item C<clear_code>

    $obj->clear_code;

Clears the coderef.

=item C<code>

    my $value = $obj->code;
    $obj->code($value);

A basic getter/setter method for the coderef. If called without an argument,
it returns the value. If called with a single argument, it sets the value.

=item C<code_clear>

Synonym for C<clear_code()>.

=item C<filter>

If the input is an array reference, it reduces the array by calling the
coderef, in a scalar context, multiple times, setting C<$a> and C<$b> each
time. The first call will be with C<$a> and C<$b> set to the first two
elements of the list, subsequent calls will be done by setting C<$a> to the
result of the previous call and C<$b> to the next element in the list.

Returns the result of the last call to the coderef. If the list is empty then
C<undef> is returned. If the list only contains one element then that element
is returned and the coderef is not executed.

If the input is a single string, it just returns that string.

=back

Text::Pipe::List::Reduce inherits from L<Text::Pipe::Base>.

The superclass L<Text::Pipe::Base> defines these methods and functions:

    new(), bit_or(), filter_single(), init()

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

