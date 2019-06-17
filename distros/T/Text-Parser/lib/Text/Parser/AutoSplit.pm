use strict;
use warnings;

package Text::Parser::AutoSplit 0.925;

# ABSTRACT: A role that adds the ability to auto-split a line into fields

use Moose::Role;
use MooseX::CoverableModifiers;
use String::Util qw(trim);
use Text::Parser::Errors;
use English;


has _fields => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    lazy     => 1,
    init_arg => undef,
    default  => sub { [] },
    traits   => ['Array'],
    writer   => '_set_fields',
    clearer  => '_clear_all_fields',
    handles  => {
        'NF'               => 'count',
        'fields'           => 'elements',
        'field'            => 'get',
        'find_field'       => 'first',
        'find_field_index' => 'first_index',
        'splice_fields'    => 'splice',
    },
);

requires '_set_this_line', 'FS', '_clear_this_line', 'this_line',
    'auto_split';

after _set_this_line => sub {
    my $self = shift;
    return if not $self->auto_split;
    $self->_set_fields( [ split $self->FS, trim( $self->this_line ) ] );
};

after _clear_this_line => sub {
    my $self = shift;
    $self->_clear_all_fields;
};


sub field_range {
    my $self = shift;
    my (@range) = $self->__validate_index_range(@_);
    $self->_sub_field_range(@range);
}

sub __validate_index_range {
    my $self = shift;

    $self->field($_) for (@_);
    map { _pos_index( $_, $self->NF ) } __set_defaults(@_);
}

sub __set_defaults {
    my ( $i, $j ) = @_;
    $i = 0  if not defined $i;
    $j = -1 if not defined $j;
    return ( $i, $j );
}

sub _pos_index {
    my ( $ind, $nf ) = ( shift, shift );
    ( $ind < 0 ) ? $ind + $nf : $ind;
}

sub _sub_field_range {
    my ( $self, $start, $end ) = ( shift, shift, shift );
    my (@range)
        = ( $start <= $end ) ? ( $start .. $end ) : reverse( $end .. $start );
    map { $self->field($_) } @range;
}


sub join_range {
    my $self = shift;
    my $sep  = ( @_ < 3 ) ? $LIST_SEPARATOR : pop;
    join $sep, $self->field_range(@_);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Parser::AutoSplit - A role that adds the ability to auto-split a line into fields

=head1 VERSION

version 0.925

=head1 SYNOPSIS

    package MyNewParser;

    use parent 'Text::Parser';

    sub new {
        my $pkg = shift;
        $pkg->SUPER::new(
            auto_split => 1,
            FS => qr/\s+\(*|\s*\)/,
            @_, 
        );
    }

    sub save_record {
        my $self = shift;
        return $self->abort_reading if $self->NF > 0 and $self->field(0) eq 'STOP_READING';
        $self->SUPER::save_record(@_) if $self->NF > 0 and $self->field(0) !~ /^[#]/;
    }

    package main;

    my $parser = MyNewParser->new();
    $parser->read(shift);
    print $parser->get_records(), "\n";

=head1 DESCRIPTION

C<Text::Parser::AutoSplit> is a role that gets automatically composed into an object of L<Text::Parser> if the C<auto_split> attribute is set during object construction. It is useful for writing complex parsers as derived classes of L<Text::Parser>, because one has access to the fields. The field separator is controlled by another attribute C<FS>, which can be accessed via an accessor method of the same name. When the C<auto_split> attribute is set to a true value, the object of C<Text::Parser> will be able to use methods described in this role.

=head1 METHODS AVAILABLE ON AUTO-SPLIT

These methods become available when C<auto_split> attribute is true. A runtime error will be thrown if they are called without C<auto_split> being set. They can used inside the subclass implementation of C<L<save_record|Text::Parser/save_record>>.

=head2 NF

The name of this method comes from the C<NF> variable in the popular L<GNU Awk program|https://www.gnu.org/software/gawk/gawk.html>. Takes no arguments, and returns the number of fields.

    sub save_record {
        my $self = shift;
        $self->save_record(@_) if $self->NF > 0;
    }

=head2 fields

Takes no argument and returns all the fields as an array.

    ## Inside your own save_record method ...
    foreach my $fld ($self->fields) {
        # do something ...
    }

=head2 field

Takes an integer argument and returns the field whose index is passed as argument.

    sub save_record {
        my $self = shift;
        $self->abort if $self->field(0) eq 'END';
    }

You can specify negative elements to start counting from the end. For example index C<-1> is the last element, C<-2> is the penultimate one, etc. Let's say the following is the text on a line in a file:

    THIS           IS          SOME           TEXT
    field(0)      field(1)    field(2)      field(3)
    field(-4)    field(-3)   field(-2)     field(-1)

=head2 field_range

Takes two optional integers C<$i> and C<$j> as arguments and returns an array, where the first element is C<field($i)>, the second C<field($i+1)>, and so on, till C<field($j)>.

    ## returns 4 elements starting with field(3) upto field(6)
    my (@flds) = $self->field_range(3, 6);  

Both C<$i> and C<$j> can be negative, as is allowed by the C<field()> method. So, for example:

    $self->field_range(-2, -1);    # Returns the last two elements

If C<$j> argument is omitted or set to C<undef>, it will be treated as C<-1> and if C<$i> is omitted, it is treated as C<0>. For example:

    $self->field_range(1);         # Returns all elements omitting the first
    $self->field_range();          # same as fields()
    $self->field_range(undef, -2); # Returns all elements omitting the last

=head2 join_range

This method essentially joins the return value of the C<field_range> method. It takes three arguments. The first argument is the joining string, and the other two are optional integer arguments C<$i> and C<$j> just like C<field_range> method.

    $self->join_range();            # Joins all fields with $" (see perlvar)
    $self->join_range(0, -1, '#');  # Joins with # separator
    $self->join_range(2);           # Joins all elements starting with index 2 to the end
                                    # with $"
    $self->join_range(1, -2);       # Joins all elements in specified range with $"

=head2 find_field

This method finds an element matching a given criterion. The match is done by a subroutine reference passed as argument to this method. The subroutine will be called against each field on the line, until one matches or all elements have been checked. Each field will be available in the subroutine as C<$_>. Its behavior is the same as the C<first> function of L<List::Util>.

    sub save_record {
        my $self = shift;
        my $param = $self->find_field(
            sub { $_ =~ /[=]/ }
        );
    }

=head2 find_field_index

This is similar to the C<L<find_field|/find_field>> method above, except that it returns the index of the element instead of the element itself.

    sub save_record {
        my $self = shift;
        my $idx = $self->find_field_index(
            sub { $_ =~ /[=]/ }
        );
    }

=head2 splice_fields

Just like Perl's built-in C<splice> function.

    ## Inside your own save_record method ...
    my (@removed1) = $self->splice_fields($offset, $length, @values);
    my (@removed2) = $self->splice_fields($offset, $length);
    my (@removed3) = $self->splice_fields($offset);

The offset above is a required argument and can be negative.

B<WARNING:> This is a destructive function. It I<will> remove elements just like Perl's built-in C<splice> does, and the removed will be returned. If you only want to get the elements in a specific range of indices, try the C<L<field_range|/field_range>> method instead.

=head1 SEE ALSO

=over 4

=item *

L<List::Util>

=item *

L<List::SomeUtils>

=item *

L<GNU Awk program|https://www.gnu.org/software/gawk/gawk.html>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://github.com/balajirama/Text-Parser/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Balaji Ramasubramanian <balajiram@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2019 by Balaji Ramasubramanian.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
