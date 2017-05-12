package Text::Pipe::Repeat;

use warnings;
use strict;


our $VERSION = '0.10';


use base 'Text::Pipe::Base';


__PACKAGE__->mk_scalar_accessors(qw(times join));


use constant DEFAULTS => (
    times => 2,
    join  => '',
);


sub filter_single {
    my ($self, $input) = @_;
    my $output = '';

    # temp variables in case we have to loop many times, in which case
    # repeated trips to the accessors would be inefficient.

    my $times = $self->times;
    my $join  = $self->join;

    for (1..$times) {
        $output .= $input;
        $output .= $join unless $_ eq $times;
    }
    $output;
}


1;


__END__



=head1 NAME

Text::Pipe::Repeat - Common text filter API

=head1 SYNOPSIS

    Text::Pipe::Repeat->new(times => 2, join => "\n");

=head1 DESCRIPTION

This is a pipe segment that takes input, repeats it a given number of times
(default: 2) and join the repeated strings with a given value (default: empty
string).

=head1 METHODS

=over 4

=item C<clear_join>

    $obj->clear_join;

Clears the value that indicates how the repeated input should be joined.

=item C<clear_times>

    $obj->clear_times;

Clears the value that indicates how many times the input should be repeated.

=item C<filter_single>

Implements the actual segment filter that acts upon a single string. It takes
an input string, repeats it a number of times indicated by C<times()> and
joins the repeated strings with the value of C<join()>, then returns it.

=item C<join>

    my $value = $obj->join;
    $obj->join($value);

A basic getter/setter method. The value indicates how the repeated input
should be joined. If called without an argument, it returns the value. If
called with a single argument, it sets the value.

=item C<join_clear>

Synonym for C<clear_join()>.

=item C<times>

    my $value = $obj->times;
    $obj->times($value);

A basic getter/setter method. The value indicates how many times the input
should be repeated. If called without an argument, it returns the value. If
called with a single argument, it sets the value.

=item C<times_clear>

Synonym for C<clear_times()>.

=back

Text::Pipe::Repeat inherits from L<Text::Pipe::Base>.

The superclass L<Text::Pipe::Base> defines these methods and functions:

    new(), bit_or(), filter(), init()

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

