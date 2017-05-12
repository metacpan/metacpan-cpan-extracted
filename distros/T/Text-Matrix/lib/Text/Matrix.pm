package Text::Matrix;

use warnings;
use strict;

use List::Util ();
use List::MoreUtils ();
use Storable ();

our $VERSION = '1.00';

sub new
{
    my $this = shift;
    my %options = @_;
    my ( $self, $class );

    $self = {};
    $class = ref( $this ) || $this;
    bless $self, $class;

    #  Defaults.
    $self->spacer( ' ' );

    #  Nasty nasty.  But I'm lazy and it works...
    foreach my $opt ( keys( %options ) )
    {
        #  Yes, special-case new(), someone's bound to try it if they
        #  see my ugly implementation here. :P
        die "Unknown option '$opt'" if $opt eq 'new' or not $self->can( $opt );
        $self->$opt( $options{ $opt } );
    }

    return( $self );
}

sub _self_or_instance
{
    my ( $self ) = @_;

    return( ref( $self ) ? $self : $self->new() );
}

sub rows
{
    my ( $self, $rows ) = @_;

    $self = $self->_self_or_instance();

    $self->{ rows } = $rows;
    delete $self->{ _layout };

    return( $self );
}

sub columns
{
    my ( $self, $columns ) = @_;

    $self = $self->_self_or_instance();

    $self->{ columns } = $columns;
    delete $self->{ _layout };

    return( $self );
}

sub cols
{
    my ( $self, $columns ) = @_;

    return( $self->columns( $columns ) );
}

sub data
{
    my ( $self, $data ) = @_;

    $self = $self->_self_or_instance();

    $self->{ data } = $data;
    delete $self->{ _layout };
    delete $self->{ _data };
    delete $self->{ _mapped_data };

    return( $self );
}

sub mapper
{
    my ( $self, $mapper ) = @_;

    $self = $self->_self_or_instance();

    if( defined( $mapper ) )
    {
        $self->{ mapper } = $mapper;
    }
    else
    {
        delete $self->{ mapper };
    }
    delete $self->{ _layout };
    delete $self->{ _mapped_data };

    return( $self );
}

sub spacer
{
    my ( $self, $spacer ) = @_;

    $self = $self->_self_or_instance();

    $self->{ spacer } = defined( $spacer ) ? $spacer : ' ';
    delete $self->{ _layout };

    return( $self );
}

sub max_width
{
    my ( $self, $max_width ) = @_;

    $self = $self->_self_or_instance();

    if( defined( $max_width ) )
    {
        $self->{ max_width } = $max_width;
    }
    else
    {
        delete $self->{ max_width };
    }
    delete $self->{ _layout };

    return( $self );
}

sub _layout
{
    my ( $self ) = @_;
    my ( $layout, $start_column, $data );

    return( $self->{ _layout } ) if $self->{ _layout };

    $layout = {};
    $data   = $self->_mapped_data();

    $layout->{ row_label_width } =
        List::Util::max( map { length( $_ ) } @{$self->{ rows }} );

    $layout->{ data_width } =
        List::Util::max( map { List::Util::max( map { length( $_ ) } @{$_} ) }
            @{$data} );

    $start_column = 0;
    $layout->{ sections } = [];
    while( $start_column < @{$self->{ columns }} )
    {
        my ( $end_column, $previous_width, $block, $prefix );

        $previous_width = $layout->{ row_label_width } + 1;
        if( defined( $self->{ max_width } ) )
        {
            $end_column = $start_column - 1;
            while( ( $end_column + 1 < @{$self->{ columns }} ) and
                ( ( $previous_width +
                    length( $self->{ columns }->[ $end_column + 1 ] ) ) <=
                  $self->{ max_width } ) )
            {
                $end_column++;
                $previous_width +=
                    $layout->{ data_width } + length( $self->{ spacer } );
            }

            #  Can't fit even a single column... :/
            return( undef ) if $end_column < $start_column;
        }
        else
        {
            $end_column = @{$self->{ columns }} - 1;
        }

        push @{$layout->{ sections }},
            {
                start_column => $start_column,
                end_column   => $end_column,
                #  Maybe paging will be added at some point...
                start_row    => 0,
                end_row      => @{$self->{ rows }} - 1,
            };

        $start_column = $end_column + 1;
    }

    $self->{ _layout } = $layout;

#use Data::Dumper;
#print "layout: " . Data::Dumper::Dumper( $layout ) . "\n";

    return( $layout );
}

#  The data in normal form.
sub _data
{
    my ( $self ) = @_;
    my ( $data );

    return( $self->{ _data } ) if $self->{ _data };

    return( undef ) unless $self->{ data };

    $data = Storable::dclone( $self->{ data } );

    $data = [ map { $data->{ $_ } } @{$self->{ rows }} ]
        if ref( $data ) eq 'HASH';

    foreach my $row ( @{$data} )
    {
        $row = [ map { $row->{ $_ } } @{$self->{ columns }} ]
            if ref( $row ) eq 'HASH';
    }

    $self->{ _data } = $data;
    #  No need to hold on to the non-normalized form.
    delete $self->{ data };

#use Data::Dumper;
#print "data: " . Data::Dumper::Dumper( $data ) . "\n";

    return( $data );
}

sub _mapped_data
{
    my ( $self ) = @_;
    my ( $data, $mapper );

    return( $self->{ _mapped_data } ) if $self->{ _mapped_data };

    $data = $self->_data();
    return( undef ) unless defined( $data );
    return( $data ) unless $mapper = $self->{ mapper };

    $data = Storable::dclone( $data );

    foreach my $row ( @{$data} )
    {
        $row = [ map { scalar( $mapper->( $_ ) ) } @{$row} ];
    }

    $self->{ _mapped_data } = $data;

#use Data::Dumper;
#print "mapped data: " . Data::Dumper::Dumper( $data ) . "\n";

    return( $data );
}

sub head
{
    my ( $self ) = @_;
    my ( @ret, $layout, $column_width );

    $self = $self->_self_or_instance();

    return( undef ) unless $layout = $self->_layout();

    $column_width = $layout->{ data_width } + length( $self->{ spacer } );

    @ret = ();
    foreach my $section ( @{$layout->{ sections }} )
    {
        my ( $block, $prefix );

        $block  = '';
        $prefix = ' ' x ( $layout->{ row_label_width } + 1 );
        foreach my $column
            ( $section->{ start_column }..$section->{ end_column } )
        {
            $block .= $prefix . $self->{ columns }->[ $column ] . "\n";
            $prefix .= '|' . ( ' ' x ( $column_width - 1 ) );
        }
        $prefix =~ s/\s+$//;
        $block .= $prefix . "\n" .
            ( ' ' x ( $layout->{ row_label_width } + 1 ) ) .
            ( ( 'v' . ( ' ' x ( $column_width - 1 ) ) ) x
              ( $section->{ end_column } - $section->{ start_column } ) ) .
            "v\n\n";
        push @ret, $block;
    }

    return( \@ret );
}

sub body
{
    my ( $self ) = @_;
    my ( @ret, $layout, $data );

    $self = $self->_self_or_instance();

    return( undef ) unless $layout = $self->_layout();
    return( undef ) unless $data   = $self->_mapped_data();

    @ret = ();
    foreach my $section ( @{$layout->{ sections }} )
    {
        my ( $block );

        $block = '';
        foreach my $row
            ( $section->{ start_row }..$section->{ end_row } )
        {
            $block .= sprintf( '%*s ', $layout->{ row_label_width },
                $self->{ rows }->[ $row ] );
            $block .= join( $self->{ spacer },
                map { sprintf( '%-*s', $layout->{ data_width },
                    $data->[ $row ]->[ $_ ] ) }
                    ( $section->{ start_column }..$section->{ end_column } ) );
            $block .= "\n";
        }
        push @ret, $block;
    }

    return( \@ret );
}

sub foot
{
    my ( $self ) = @_;
    my ( @ret, $layout );

    $self = $self->_self_or_instance();

    $layout = $self->_layout();
    return( undef ) unless $layout;

    @ret = ( "\n" ) x scalar( @{$layout->{ sections }} );
    $ret[ $#ret ] = '';

    return( \@ret );
}

sub matrix
{
    my ( $self, $rows, $columns, $data ) = @_;
    my ( $head, $body, $foot );

    $self = $self->_self_or_instance();

    $self->rows( $rows )       if defined $rows;
    $self->columns( $columns ) if defined $columns;
    $self->data( $data )       if defined $data;

    return( undef ) unless defined( $head = $self->head() ) and
                           defined( $body = $self->body() ) and
                           defined( $foot = $self->foot() );

    return( join( '', List::MoreUtils::mesh( @$head, @$body, @$foot ) ) );
}

1;

__END__

=pod

=head1 NAME

Text::Matrix - Text table layout for matrices of short regular data.

=head1 SYNOPSIS

    use Text::Matrix;

    my $rows    = [ 'Row A', 'Row B', 'Row C', 'Row D' ];
    my $columns = [ 'Column 1', 'Column 2', 'Column 3' ];
    my $data    =
            [
                [ qw/Y Y Y/ ],
                [ qw/Y - Y/ ],
                [ qw/- Y -/ ],
                [ qw/- - -/ ],
            ];

    #  Standard OO form;
    my $matrix = Text::Matrix->new(
        rows    => $rows,
        columns => $columns,
        data    => $data,
        );
    print "Output:\n", $matrix->matrix();

    #Output:
    #      Column 1
    #      | Column 2
    #      | | Column 3
    #      | | |
    #      v v v
    #
    #Row A Y Y Y
    #Row B Y - Y
    #Row C - Y -
    #Row D - - -

    #  Anonymous chain form:
    print "Output:\n", Text::Matrix->columns( $columns )->rows( $rows )->
        data( $data )->matrix();

    #  Shorter but equivilent:
    print "Output:\n", Text::Matrix->matrix( $rows, $columns, $data );

    #  Paging by column width:
    $rows    = [ map { "Row $_" } ( 'A'..'D' ) ];
    $columns = [ map { "Column $_" } ( 1..20 ) ];
    $data    = [ ( [ ( 'Y' ) x @{$columns} ] ) x @{$rows} ];
    print "Output:\n<", ( '-' x 38 ), ">\n",
        Text::Matrix->max_width( 40 )->matrix( $rows, $columns, $data );

    #Output:
    #<-------------------------------------->
    #      Column 1
    #      | Column 2
    #      | | Column 3
    #      | | | Column 4
    #      | | | | Column 5
    #      | | | | | Column 6
    #      | | | | | | Column 7
    #      | | | | | | | Column 8
    #      | | | | | | | | Column 9
    #      | | | | | | | | | Column 10
    #      | | | | | | | | | | Column 11
    #      | | | | | | | | | | | Column 12
    #      | | | | | | | | | | | | Column 13
    #      | | | | | | | | | | | | |
    #      v v v v v v v v v v v v v
    #
    #Row A Y Y Y Y Y Y Y Y Y Y Y Y Y
    #Row B Y Y Y Y Y Y Y Y Y Y Y Y Y
    #Row C Y Y Y Y Y Y Y Y Y Y Y Y Y
    #Row D Y Y Y Y Y Y Y Y Y Y Y Y Y
    #
    #      Column 14
    #      | Column 15
    #      | | Column 16
    #      | | | Column 17
    #      | | | | Column 18
    #      | | | | | Column 19
    #      | | | | | | Column 20
    #      | | | | | | |
    #      v v v v v v v
    #
    #Row A Y Y Y Y Y Y Y
    #Row B Y Y Y Y Y Y Y
    #Row C Y Y Y Y Y Y Y
    #Row D Y Y Y Y Y Y Y

    #  Just want the body?
    my $sections = Text::Matrix->new(
        rows    => $rows,
        columns => $columns,
        data    => $data,
        )->body();
    print "Output:\n", @{$sections};

    #Output:
    #Row A Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y
    #Row B Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y
    #Row C Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y
    #Row D Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y

    #  Multi-character data with a map function.
    $matrix = Text::Matrix->new(
        rows    => [ qw/1 2/ ],
        columns => [ qw/A B/ ],
        data    =>
            [
                [ qw/A1 B1/ ],
                [ qw/A2 B2/ ],
            ],
        mapper  => sub { reverse( $_ ) },
        );
    print "Output:\n", $matrix->matrix();

    #Output:
    #  A
    #  |  B
    #  |  |
    #  v  v
    #
    #1 1A 1B
    #2 2A 2B

=head1 DESCRIPTION

L<Text::Matrix> is a specialist table display module for display of
matrices of single-character (such as Y/N for yes/no) or short
multi-character data against row and column labels that are sufficiently
longer that conventional table layouts distort the layout of the data.

The core aim is to base the layout on the tabular data concisely and
formated regularly to reflect the terseness of the underlying data,
without being forced to compensate for the longer length of the
labels for the columns and rows.

L<Text::Matrix> will also optionally split the matrix into several
sections based on width of the generated matrix, suitable for display
in situations where you don't want external line-wrapping to confuse
the layout.
(Display on an xterm, cut-n-paste into an email, etc.)

=head1 CONSTRUCTOR

=over

=item I<$matrix> = B<< Text::Matrix->new( >> I<%options> B<)>

Creates and returns a new L<Text::Matrix> object with the given options.

The options are just a wrapper around calling the method of the same name,
so any of the non-output methods listed below can be used as an option.

=back

=head1 OUTPUT METHODS

These methods all produce some part of the final output, unlike other
L<Text::Matrix> methods, these return the output rather than an instance
of L<Text::Matrix>.
This means that if you're chaining methods, these must be the final
stage of any chain they exist in.

=over

=item I<$text> = B<< $matrix->matrix() >>

=item I<$text> = B<< $matrix->matrix( >> I<$rows>, I<$columns>, I<$data> B<)>

=item I<$text> = B<< Text::Matrix->matrix( >> I<$rows>, I<$columns>, I<$data> B<)>

Returns the text of the matrix as a string, this is what you call when
you've finished configuring your matrix and want the output.

As a short-cut you can optionally specify the rows, columns and data as
arguments.

You can also call C<matrix()> as a class-method to get directly to the
output without messing around with constructing a L<Text::Matrix> object.

=item I<$sections> = B<< $matrix->body() >>

Returns an arrayref of body sections of the matrix layout.

The body is the row labels and the data matrix for the columns in that
section.

=item I<$sections> = B<< $matrix->head() >>

Returns an arrayref of head sections of the matrix layout.

A head section is the column labels for the columns in that section.

=item I<$sections> = B<< $matrix->foot() >>

Returns an arrayref of foot sections of the matrix layout.

A foot section currently only consists of newlines to space multiple
sections legibly.

=back

=head1 METHODS

Unless otherwise noted, all methods return C<undef> on failure and
a L<Text::Matrix> instance on success, this means that any method
can be used as a constructor, and the methods can be chained if
you wish to set several parameters.

=over

=item B<< $matrix->columns( >> I<$columns> B<)>

=item B<< $matrix->cols( >> I<$columns> B<)>

Sets the column labels of the matrix to the given arrayref.

=item B<< $matrix->rows( >> I<$rows> B<)>

Sets the row labels of the matrix to the given arrayref.

=item B<< $matrix->data( >> I<$data> B<)>

Sets the data for the matrix.

I<$data> may be an arrayref of arrayrefs with a value for each row
and then column in the same order as supplied to C<< $matrix->rows() >>
and C<< $matrix->columns() >>:

    my $matrix = Text::Matrix->new(
        rows    => [ qw/1 2/ ],
        columns => [ qw/A B/ ],
        data    =>
            [
                [ qw/A1 B1/ ],
                [ qw/A2 B2/ ],
            ],
        );

I<$data> may also be a hashref of hashrefs, keyed first by row
label then by column label:

    #  Same as above.
    my $matrix = Text::Matrix->new(
        rows    => [ qw/1 2/ ],
        columns => [ qw/A B/ ],
        data    =>
            {
                1 =>
                    {
                        A => 'A1',
                        B => 'B1',
                    },
                2 =>
                    {
                        A => 'A2',
                        B => 'B2',
                    },
            },
        );

You can also combine the two as a hashref of arrayrefs or arrayref of
hashrefs.

    #  Still the same as above...
    my $matrix = Text::Matrix->new(
        rows    => [ qw/1 2/ ],
        columns => [ qw/A B/ ],
        data    =>
            [
                {
                    A => 'A1',
                    B => 'B1',
                },
                {
                    A => 'A2',
                    B => 'B2',
                },
            ],
        );

    #  or...
    my $matrix = Text::Matrix->new(
        rows    => [ qw/1 2/ ],
        columns => [ qw/A B/ ],
        data    =>
            {
                1 => [ qw/A1 B1/ ],
                2 => [ qw/A2 B2/ ],
            },
        );

    #  or even this if you're insane...
    my $matrix = Text::Matrix->new(
        rows    => [ qw/1 2/ ],
        columns => [ qw/A B/ ],
        data    =>
            {
                1 => [ qw/A1 B1/ ],
                2 =>
                    {
                        A => 'A2',
                        B => 'B2',
                    },
            },
        );

=item B<< $matrix->max_width( >> I<$max_width> B<)>

=item B<< $matrix->max_width( >> C<undef> B<)>

Sets the maximum width, in characters, for the matrix layout.

If the matrix would exceeds this width, it will be split into
multiple sections.

Setting I<$max_width> to C<undef> will return to the default
behaviour of unlimited width.

=item B<< $matrix->spacer( >> I<$spacer> B<)>

=item B<< $matrix->spacer( >> C<undef> B<)>

Sets the spacer to use between matrix values.

By default a single space character is placed between values
for a clear layout.
If space is at a premium you can use the empty string C<''>
as a spacer to remove spacing between values.

You could also supply multiple characters or some other string if
you wished.

Setting I<$spacer> to C<undef> will return to the default value
of C<' '>.

=item B<< $matrix->mapper( >> I<$subref> B<)>

Sets a subroutine reference to run over each data value, substituting
the returned value for the purposes of layout and output.

The data value is accessible as both C<$_> and C<$_[ 0 ]>.

This is a convenience function in case you're sourcing your data
from L<DBI> or something external and don't want to mess with running a
C<map> across a multi-dimensional data-structure:

    my $matrix = Text::Matrix->new(
        rows    => [ qw/1 2/ ],
        columns => [ qw/A B/ ],
        data    =>
            [
                [ qw/A1 B1/ ],
                [ qw/A2 B2/ ],
            ],
        mapper  => sub { reverse( $_ ) },
        );

=back

=head1 SEE ALSO

L<Text::Table>, L<Text::TabularDisplay>, L<Data::ShowTable>.

=head1 AUTHOR

Sam Graham, C<< <libtext-matrix-perl BLAHBLAH illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-matrix at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Matrix>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Matrix


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Matrix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Matrix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Matrix>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Matrix/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Sam Graham.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
