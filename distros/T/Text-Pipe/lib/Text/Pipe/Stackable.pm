package Text::Pipe::Stackable;

use warnings;
use strict;


our $VERSION = '0.10';


use base 'Text::Pipe::Base';

    
__PACKAGE__->mk_array_accessors(qw(pipes));


{
    no warnings 'once';

    # aliases to make it more natural

    *pop     = *pipes_pop;
    *push    = *pipes_push;
    *shift   = *pipes_shift;
    *unshift = *pipes_unshift;
    *count   = *pipes_count;
    *clear   = *pipes_clear;
    *splice  = *pipes_splice;
}


sub new {
    my ($class, @pipes) = @_;
    my $self = ref  $class ? $class : bless {}, $class;
    $self->pipes(@pipes);
    $self;
}


sub filter {
    my ($self, $input) = @_;
    $input = $_->filter($input) for $self->pipes;
    $input;
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

Text::Pipe::Stackable - Stackable text pipes

=head1 SYNOPSIS

    my $pipe_trim    = Text::Pipe->new('Trim');
    my $pipe_uc      = Text::Pipe->new('Uppercase');
    my $pipe_repeat  = Text::Pipe->new('Repeat',
            times => 2, join => ' = ');
    my $pipe_reverse = Text::Pipe->new('Reverse');

    my $stacked_pipe = Text::Pipe::Stackable->new(
        $pipe_trim, $pipe_uc, $pipe_repeat
    );

    my $result = $stacked_pipe->filter('foo');

=head1 DESCRIPTION

This pipe segment is a container that can hold a series of stacked pipes. To
the outside it appears as a single segment. Input is sent through all pipes in
the order they were stacked.

=head1 METHODS

=over 4

=item C<clear_pipes>

    $obj->clear_pipes;

Deletes all stacked pipes.

=item C<clear>

Synonym for C<clear_pipes()>.

=item C<count_pipes>

    my $count = $obj->count_pipes;

Returns the number of stacked pipes, not recursing into possibly further
stacked or multiplexed segments.

=item C<count>

Synonym for C<count_pipes()>.

=item C<deep_count>

Returns the total number of pipe segments that are stacked in this container,
computed recursively. So if the container has three stacked pipes attached,
each of which consist of four pipes, this method will return 12.

=item C<filter>

Takes input and sends it to all stacked pipes in turn. That is, one stacked
pipe's output becomes the next stacked pipe's input. Returns the output of the
last stacked pipe.

=item C<index_pipes>

    my $element   = $obj->index_pipes(3);
    my @elements  = $obj->index_pipes(@indices);
    my $array_ref = $obj->index_pipes(@indices);

Takes a list of indices and returns the stacked pipes indicated by those
indices.  If only one index is given, the corresponding array element is
returned. If several indices are given, the result is returned as an array in
list context or as an array reference in scalar context.

=item C<new>

    my $stacked_pipe = Text::Pipe::Stackable->new(
        $pipe_trim, $pipe_uc, $pipe_repeat
    );

Takes a list of pipes and stacks them, returning the container segment.

=item C<pipes>

    my @values    = $obj->pipes;
    my $array_ref = $obj->pipes;
    $obj->pipes(@values);
    $obj->pipes($array_ref);

Get or set the array of stacked pipes. If called without an arguments, it
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

Pops the last stacked pipe off the array, returning it.

=item C<pipes_push>

    $obj->pipes_push(@values);

Pushes a pipe onto the end of the array of stacked pipes.

=item C<pipes_set>

    $obj->pipes_set(1 => $pipe_a, 5 => $pipe_b);

Takes a list of index/value pairs and for each pair it sets the pipe at the
indicated index to the indicated value. Returns the number of pipes that have
been set.

=item C<pipes_shift>

    my $value = $obj->pipes_shift;

Shifts the first stacked pipe off the array, returning it.

=item C<pipes_splice>

    $obj->pipes_splice(2, 1, $pipe_a, $pipe_b);
    $obj->pipes_splice(-1);
    $obj->pipes_splice(0, -1);

Takes three arguments: An offset, a length and a list.

Removes the stacked pipes designated by the offset and the length from the
array, and replaces them with the pipes of the list, if any. In list context,
returns the pipes removed from the array. In scalar context, returns the
last pipe removed, or C<undef> if no pipes are removed. The array grows or
shrinks as necessary. If the offset is negative then it starts that far
from the end of the array. If the length is omitted, removes everything
from the offset onward. If the length is negative, removes the pipes from
the offset onward except for -length elements at the end of the array. If
both the offset and the length are omitted, removes everything. If the
offset is past the end of the array, it issues a warning, and splices at
the end of the array.

=item C<pipes_unshift>

    $obj->pipes_unshift(@values);

Unshifts pipes onto the beginning of the array of stacked pipes.

=item C<pop>

Synonym for C<pipes_pop()>.

=item C<pop_pipes>

Synonym for C<pipes_pop()>.

=item C<push>

Synonym for C<pipes_push()>.

=item C<push_pipes>

Synonym for C<pipes_push()>.

=item C<set_pipes>

Synonym for C<pipes_set()>.

=item C<shift>

Synonym for C<pipes_shift()>.

=item C<shift_pipes>

Synonym for C<pipes_shift()>.

=item C<splice>

Synonym for C<pipes_splice()>.

=item C<splice_pipes>

Synonym for C<pipes_splice()>.

=item C<unshift>

Synonym for C<pipes_unshift()>.

=item C<unshift_pipes>

Synonym for C<pipes_unshift()>.

=back

Text::Pipe::Stackable inherits from L<Text::Pipe::Base>.

The superclass L<Text::Pipe::Base> defines these methods and functions:

    bit_or(), filter_single(), init()

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

