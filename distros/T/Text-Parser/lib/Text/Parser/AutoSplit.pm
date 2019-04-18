use strict;
use warnings;

package Text::Parser::AutoSplit 0.918;

# ABSTRACT: A role that adds the ability to auto-split a line into fields

use Exporter 'import';
our (@EXPORT_OK) = ();
our (@EXPORT)    = ();
use Moose::Role;
use MooseX::CoverableModifiers;
use String::Util qw(trim);


has _fields => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    lazy     => 1,
    init_arg => undef,
    default  => sub { [] },
    traits   => ['Array'],
    writer   => '_set_fields',
    handles  => {
        'NF'               => 'count',
        'field'            => 'get',
        'find_field'       => 'first',
        'find_field_index' => 'first_index',
        'splice_fields'    => 'splice',
        'fields'           => 'elements',
    },
);

requires 'save_record', 'FS', '__read_file_handle';

around save_record => sub {
    my ( $orig, $self ) = ( shift, shift );
    $self->_set_fields( [ split $self->FS, trim( $_[0] ) ] );
    $orig->( $self, @_ );
};

after __read_file_handle => sub {
    my $self = shift;
    $self->_set_fields( [] );
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Parser::AutoSplit - A role that adds the ability to auto-split a line into fields

=head1 VERSION

version 0.918

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
    $self->splice_fields($offset, $length, @values);
    $self->splice_fields($offset, $length);
    $self->splice_fields($offset);

The offset above is a required argument. It can be negative.

=head2 fields

Takes no argument and returns all the fields as an array.

    ## Inside your own save_record method ...
    foreach my $fld ($self->fields) {
        # do something ...
    }

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
