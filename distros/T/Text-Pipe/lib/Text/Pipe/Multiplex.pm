package Text::Pipe::Multiplex;

use warnings;
use strict;


our $VERSION = '0.10';


use base 'Text::Pipe::Base';

    
__PACKAGE__
    ->mk_array_accessors(qw(pipes));


sub filter {
    my ($self, $input) = @_;
    [ map { $_->filter($input) } $self->pipes ];
}


sub deep_count {
    my $self = shift;
    my $count = 0;

    for my $pipe ($self->pipes) {
        if ($pipe->can('deep_count')) {
            $count += $pipe->deep_count;
        } else {
            $count++;
        }
    }

    $count;
}


1;


__END__


=head1 NAME

Text::Pipe::Multiplex - Common text filter API

=head1 SYNOPSIS

    Text::Pipe::Multiplex->new;

=head1 DESCRIPTION

Represents a multiplexing pipe segment so input gets sent to all pipes
attached to the multiplexer.

=head1 METHODS

=over 4

=item C<clear_pipes>

    $obj->clear_pipes;

Deletes all pipes that are attached to the multiplexer.

=item C<count_pipes>

    my $count = $obj->count_pipes;

Counts the number of pipes attached to the multiplexer.

=item C<deep_count>

Returns the total number of pipe segments that are attached to this segment,
computed recursively. So if the multiplexer has three pipes attached, each of
which consist of four pipes, this method will return 12.

=item C<filter>

Takes input and sends it to each attached pipe. The results are returned in an
array reference.

=item C<index_pipes>

    my $element   = $obj->index_pipes(3);
    my @elements  = $obj->index_pipes(@indices);
    my $array_ref = $obj->index_pipes(@indices);

Takes a list of indices and returns the attached pipes indicated by those
indices. If only one index is given, the corresponding pipe is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

=item C<pipes>

    my @values    = $obj->pipes;
    my $array_ref = $obj->pipes;
    $obj->pipes(@values);
    $obj->pipes($array_ref);

Get or set the attached pipes array. If called without an arguments, it
returns the array in list context, or a reference to the array in scalar
context. If called with arguments, it expands array references found therein
and sets the values.

=item C<pipes_clear>

Synonym for C<clear_pipes()>.

=item C<pipes_count>

Synonym for C<count_pipes()>.

=item C<pipes_index>

Synonym for C<index_pipes()>.

=item C<pipes_pop>

    my $value = $obj->pipes_pop;

Pops the last attached pipe off the array, returning it.

=item C<pipes_push>

    $obj->pipes_push(@values);

Pushes a pipe  onto the end of the array of attached pipes.

=item C<pipes_set>

    $obj->pipes_set(1 => $segment_1, 5 => $segment_2);

Takes a list of index/value pairs and for each pair it sets the pipe element
at the indicated index to the indicated pipe value. Returns the number of
elements that have been set.

=item C<pipes_shift>

    my $value = $obj->pipes_shift;

Shifts the first attached pipe off the array of attached pipes, returning it.

=item C<pipes_splice>

    $obj->pipes_splice(2, 1, $x, $y);
    $obj->pipes_splice(-1);
    $obj->pipes_splice(0, -1);

Takes three arguments: An offset, a length and a list.

Removes the pipes designated by the offset and the length from the array,
and replaces them with the pipe elements of the list, if any. In list context,
returns the elements removed from the array. In scalar context, returns
the last element removed, or C<undef> if no elements are removed. The
array grows or shrinks as necessary. If the offset is negative then it
starts that far from the end of the array. If the length is omitted,
removes everything from the offset onward. If the length is negative,
removes the elements from the offset onward except for -length elements at
the end of the array. If both the offset and the length are omitted,
removes everything. If the offset is past the end of the array, it issues
a warning, and splices at the end of the array.

=item C<pipes_unshift>

    $obj->pipes_unshift(@values);

Unshifts pipes onto the beginning of the array of attached pipes.

=item C<pop_pipes>

    my $value = $obj->pop_pipes;

Pops the last element off the array, returning it.

=item C<push_pipes>

Synonym for C<pipes_push()>.

=item C<set_pipes>

Synonym for C<pipes_set()>.

=item C<shift_pipes>

Synonym for C<pipes_shift()>.

=item C<splice_pipes>

Synonym for C<pipes_splice()>.

=item C<unshift_pipes>

Synonym for C<pipes_unshift()>.

=back

Text::Pipe::Multiplex inherits from L<Text::Pipe::Base>.

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

