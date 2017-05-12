package XML::Filter::TableWrapper;

$VERSION = 0.02;

=head1 NAME

XML::Filter::TableWrapper - Wrap a table's cells in to a certain number of rows

=head1 SYNOPSIS

    use XML::Filter::TableWrapper;
    use XML::SAX::Machines qw( Pipeline );

    ## Ouput a table with 5 rows, the last row having 3 cells:
    Pipeline(
        XML::Filter::TableWrapper->new(
            Columns => 3,   # The default is 5
        ),
        \*STDOUT,
    )->parse_string( "<table>" . "<td/>" x 23 . "</table" );

=head1 DESCRIPTION

Takes a list of elements and inserts (by default) C<< <tr>...</tr> >>
elements to make an table with a specified number of columns (5 by
default).  By default, it assumes that the container element is named
"{}table" (the "{}" means it is not namespaced), but this can be changed:

    XML::Filter::TableWrapper->new(
        ListTags => "{$my_ns}rows",
        Columns  => 3,
    );

for instance.

=head1 LIMITATIONS

These can be read as possible future features:

=over

=item *

Be able to translate the container tag to some other, for instance:

    ListTags => {
        "{}ul" => {
            TableTag  => "{}table",
            RowTag    => "{}tr",
            CellTag   => "{}td",
        },
    }

=item *

Autoadapt if the user specifies empty "{}" namespaces and the events
have no NamespaceURI defined, and vice versa.

=item *

Row filling instead of column filling.

=item *

Stripping of existing row tags, for "refilling" a table.

=item *

Callbacks to allow the various tags to be built, so they can have
attributes.  This would be a decent way of allowing greybar, for
instance.

=back

=cut

use XML::SAX::Base;

@ISA = qw( XML::SAX::Base );

use strict;

sub new {
    my $self = shift->SUPER::new( @_ );

    $self->{Columns}  = 5 unless defined $self->{Columns};
    $self->{ListTags} = "{}table"
        unless $self->{ListTags};

    $self->{ListTags} = {
        map { ( $_ => undef ) } split /,\s*/, $self->{ListTags}
    } unless ref $self->{ListTags};

    return $self;
}

=item Columns

    $h->Columns( 1024 );
    my $columns = $h->Columns;

Set/get the number of columns to wrap to.

=cut

sub Columns {
    my $self = shift;

    $self->{Columns} = shift if @_;
    return $self->{Columns};
}


sub start_document {
    my $self = shift;

    $self->{Stack}    = [];
    $self->{Depth}    = 0;
    $self->{ColCount} = 0;

    $self->SUPER::start_document( {} );
}


sub _elt {
    my ( $elt, $name ) = ( shift, shift );

    return {
        NamespaceURI => $elt->{NamespaceURI},
        Prefix       => $elt->{Prefix},
        LocalName    => $name,
        Name         => $elt->{Prefix} ? "$elt->{Prefix}:$name" : $name,
    };
}


sub start_element {
    my $self = shift;
    my ( $elt ) = @_;

    if ( $self->{Depth} == 1 ) {
        if ( ! $self->{ColCount} ) {
            my $row_elt = _elt $elt, "tr";
            $self->SUPER::start_element( $row_elt );
            $self->{EndRowElt} = { %$row_elt };
        }

        ++$self->{ColCount};
    }

    ++$self->{Depth} if $self->{Depth};

    my $jc_name = $elt->{Name};
    $jc_name = "{" . ( $elt->{NamespaceURI} || "" ) . "}$jc_name";

    if ( exists $self->{ListTags}->{$jc_name} ) {
        push @{$self->{Stack}}, [ @{$self}{qw( Depth ColCount EndRowElt )} ];
        $self->{Depth}     = 1;
        $self->{ColCount}  = undef;
        $self->{EndRowElt} = undef;
    }

    $self->SUPER::start_element( @_ );
}


sub end_element {
    my $self = shift;
    my ( $elt ) = @_;

    my $end_row_elt;

    if ( $self->{Depth} ) {
        --$self->{Depth};

        if ( $self->{Depth} == 1 ) {
            if ( $self->{ColCount} >= $self->{Columns} ) {
                $end_row_elt = delete $self->{EndRowElt};
                $self->{ColCount} = 0;
            }
        }
        elsif ( ! $self->{Depth} ) {
            $self->SUPER::end_element( $self->{EndRowElt} )
                if $self->{EndRowElt};
            @{$self}{qw( Depth ColCount EndRowElt )} = @{pop @{$self->{Stack}}};
        }
    }

    $self->SUPER::end_element( @_ );

    $self->SUPER::end_element( $end_row_elt ) if $end_row_elt;
}


1;
