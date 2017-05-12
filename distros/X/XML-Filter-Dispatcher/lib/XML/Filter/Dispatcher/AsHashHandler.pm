package XML::Filter::Dispatcher::AsHashHandler;

=head1 NAME

XML::Filter::Dispatcher::AsHashHandler - convert SAX stream in to simple, data-oriented structure

=head1 SYNOPSIS

    ## Ordinarily used via the XML::Filter::Dispatcher's as_data_struct()
    ## built-in extension function for XPath

=head1 DESCRIPTION

This SAX2 handler builds a simple hash from XML.  Text from each element
and attribute is stored in the hash with a key of a relative path from
the root down to the current element.

The goal is to produce a usable structure as simply and quickly as possible;
use L<XML::Simple|XML::Simple> for more sophisticated applications.

The resulting data structure has one hash per element, one scalar per
attribute, and one scalar per text string in each leaf element.

Warnings are emitted if any content other than whitespace is discarded.

The root element name is discarded.

If you are using namespaces, you must pass in the C<Namespaces> option,
otherwise not.  Using namespaces without a C<Namespaces> option or
vice versa will not work.

Only C<start_document()>, C<start_element()>, C<characters()>,
C<end_element()>, and C<end_document()> are provided; so all comments,
processing instructions etc., are discarded.

=head2 Examples

This XML:

    <root a="A">
        <a aa1="AA1" aa2="AA2">
            <b>B1</b>
            <b>B2</b>
        </a>
    </root>

with no options produces this structure:

    {
        '@a'     => 'A',
        'a/@aa1' => 'AA1',
        'a/@aa2' => 'AA2'
        'a/b'    => 'B2',
        ''       => '

        B1
        B2

',
        'a'      => '
        B1
        B2
    ',
    }

Note 1: the name of the root element is discarded.

Note 2: the contents of the first C<< <b> >> element are not directly
accessible; like standard Perl hashes, the later initialization overwrites
the former.  Much data oriented XML does not have this issue.

This XML:

    <root
        xmlns="default-ns"
        xmlns:foo="foo-ns"
        a="A"
        foo:a="FOOA"
    >
        <a aa1="AA1" foo:aa1="AA2">
            <b>B1</b>
            <foo:b>B2</foo:b>
        </a>
    </root>

With these options:

    XML::Filter::Dispatcher::AsHashHandler->new(
        Namespaces => {
            ""    => "default-ns",
            "bar" => "foo-ns",
        },
        Rules => [
            "hash( root )" => sub { Dumper xvalue },
        ],
    )

produces this structure:

    {
        '@a'     => 'A',
        '@bar:a' => 'FOOA',
        'a/@aa1' => 'AA1',
        'a/@aa2' => 'AA2'
        'a/b'    => 'B2',
        ''       => '

        B1
        B2

',
        'a'      => '
        B1
        B2
    ',
    }

=head1 Methods

=over

=cut

use strict;

## Config
    use constant PrefixesByURI => 0;  ## Calculated from that option

## Running state
    use constant PathStack     => 1;
    use constant Path          => 2;
    use constant Hash          => 3;
    use constant Characters    => 4;

use constant Names => "# #KEYS# #";  ## Should never be a valid QName or NCName

=item new

   see above.

=cut

sub new {
    my $class = ref $_[0] ? ref $_[0] : shift;
    my %options = (
        @_ == 1 ? %{$_[0]} : @_
    );
    my $self = bless [
    ], $class;
    
    $self->set_namespaces( %{ delete $options{Namespaces} } )
        if exists $options{Namespaces};

    warn __PACKAGE__, " ignoring unknown options ", join ", ", keys %options
        if keys %options;

    return $self;
}

=item set_namespaces

    $h->set_namespaces(
        prefix1 => uri1,
    );

=cut

sub set_namespaces {
    my $self = shift;
    $self->[PrefixesByURI] = @_ ? { reverse @_ } : undef;
}


sub start_document {
    my $self = shift;
    $self->[Path] = undef;
}

sub end_document   { return shift->[Hash] }

sub start_element {
    my ( $self, $elt ) = ( shift, shift );

    my $name;
    
    if ( $self->[PrefixesByURI] ) {
        my $prefix = $self->[PrefixesByURI]->{$elt->{NamespaceURI}};
        die "Unknown namespace URI '$elt->{NamespaceURI}' for $elt->{Name}\n"
            unless defined $prefix;
        $name = length $prefix
            ? join ":", $prefix, $elt->{LocalName}
            : $elt->{LocalName};
    }
    else {
        $name = $elt->{Name};
    }

    my $path;
    my $hash;
    unless ( defined $self->[Path] ) {
        ## Root elt.
        $path = $self->[Path] = "";
        $self->[PathStack] = [];
        $hash = $self->[Hash] = {};
    }
    else {
        ## Nested element
        $hash = $self->[Hash];
        $path = $self->[Path];
        $hash->{$path} .= $self->[Characters];
        push @{$self->[PathStack]}, $path;
        $path .= "/" if $path;
        $self->[Path] = $path .= $name;
    }

    $self->[Characters] = "";
    $hash->{$path} = "";
    for my $attr ( values %{$elt->{Attributes}} ) {
        my $name;
        my $apath = length $path ? "$path/@" : "@";
        if ( $self->[PrefixesByURI] ) {
            next if $attr->{Prefix} eq "xmlns" || $attr->{Name} eq "xmlns";
            my $prefix = length $attr->{NamespaceURI}
                ? $self->[PrefixesByURI]->{$attr->{NamespaceURI}}
                : "";
            die "Unknown namespace URI '$attr->{NamespaceURI}' for $elt->{Name} attribute $attr->{Name}\n"
                unless defined $prefix;

            $name = length $prefix
                ? join ":", $prefix, $attr->{LocalName}
                : $attr->{LocalName};
        }
        else {
            $name = $attr->{Name};
        }

        $hash->{"$apath$name"} = $attr->{Value};
    }
}


sub characters { $_[0]->[Characters] .= $_[1]->{Data} }


sub end_element {
    my $self = shift;
    my $p = $self->[Path];
    $self->[Hash]->{$p} .= $self->[Characters];
    if ( defined( $self->[Path] = pop @{$self->[PathStack]} ) ) {
        $self->[Hash]->{$self->[Path]} .= $self->[Hash]->{$p};
    }
    $self->[Characters] = "";
}

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

=cut


1;
