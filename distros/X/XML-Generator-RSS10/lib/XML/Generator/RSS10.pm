package XML::Generator::RSS10;
{
  $XML::Generator::RSS10::VERSION = '0.02';
}

use strict;

use vars qw($VERSION);

use base 'XML::SAX::Base';

use Params::Validate qw( validate SCALAR ARRAYREF BOOLEAN OBJECT );

use XML::Generator::RSS10::dc;
use XML::Generator::RSS10::sy;

use constant NEW_SPEC => {
    modules => {
        type    => ARRAYREF,
        default => [ 'dc', 'sy' ],
    },
    pretty  => { type => BOOLEAN, default => 0 },
    Handler => { type => OBJECT },
};

sub new {
    my $class = shift;
    my %p = validate( @_, NEW_SPEC );

    my %mod;
    foreach my $prefix ( @{ delete $p{modules} } ) {
        my $package = __PACKAGE__ . "::$prefix";

        unless ( $package->can('Prefix') ) {
            eval "require $package";
            die $@ if $@;
        }

        $mod{$prefix} = $package;
    }

    my $self = bless {
        %p,
        state   => {},
        modules => \%mod,
    };

    $self->{state}{indent} = 0;
    $self->{state}{items}  = [];

    $self->_start;

    return $self;
}

sub parse {
    die __PACKAGE__ . " does not implement RSS parsing\n";
}

sub _start {
    my $self = shift;

    $self->start_document;

    $self->processing_instruction(
        { Target => 'xml', Data => 'version="1.0"' } );

    $self->_declare_namespaces;
    $self->_newline_if_pretty;

    $self->_start_element( 'rdf', 'RDF' );
    $self->_newline_if_pretty;
}

use constant ITEM_SPEC => (
    title       => { type => SCALAR },
    link        => { type => SCALAR },
    description => { type => SCALAR, optional => 1 },
);

sub item {
    my $self = shift;
    my %p    = validate(
        @_,
        {
            ITEM_SPEC,
            map { $_ => { optional => 1 } }
                keys %{ $self->{namespace_prefixes} },
        },
    );

    $self->_start_element(
        '', 'item',
        [ 'rdf', 'about' => $p{link} ],
    );
    $self->_newline_if_pretty;

    $self->_contents( \%p, qw( title link ) );

    $self->_call_modules( \%p );

    if ( defined $p{description} ) {
        $self->_element_with_cdata( '', 'description', $p{description} );
        $self->_newline_if_pretty;
    }

    $self->_end_element( '', 'item' );
    $self->_newline_if_pretty;

    push @{ $self->{state}{items} }, $p{link};

}

use constant IMAGE_SPEC => (
    title => { type => SCALAR },
    link  => { type => SCALAR },
    url   => { type => SCALAR },
);

sub image {
    my $self = shift;
    my %p    = validate(
        @_,
        {
            IMAGE_SPEC,
            map { $_ => { optional => 1 } }
                keys %{ $self->{namespace_prefixes} },
        },
    );

    die "Cannot call image() more than once.\n"
        if $self->{state}{image};

    die "Cannot call image() after calling channel().\n"
        if $self->{state}{finished};

    $self->_start_element(
        '', 'image',
        [ 'rdf', 'about' => $p{url} ],
    );
    $self->_newline_if_pretty;

    $self->_contents( \%p, qw( title url link ) );

    $self->_call_modules( \%p );

    $self->{state}{image} = $p{url};

    $self->_end_element( '', 'image' );
    $self->_newline_if_pretty;
}

use constant TEXTINPUT_SPEC => (
    title       => { type => SCALAR },
    description => { type => SCALAR },
    name        => { type => SCALAR },
    url         => { type => SCALAR },
);

sub textinput {
    my $self = shift;
    my %p    = validate(
        @_,
        {
            TEXTINPUT_SPEC,
            map { $_ => { optional => 1 } }
                keys %{ $self->{namespace_prefixes} },
        },
    );

    die "Cannot call textinput() more than once().\n"
        if $self->{state}{textinput};

    die "Cannot call textinput() after calling channel().\n"
        if $self->{state}{finished};

    $self->_start_element(
        '', 'textinput',
        [ 'rdf', 'about' => $p{url} ],
    );
    $self->_newline_if_pretty;

    $self->_contents( \%p, qw( title description name url ) );

    $self->_call_modules( \%p );

    $self->{state}{textinput} = $p{url};

    $self->_end_element( '', 'textinput' );
    $self->_newline_if_pretty;
}

use constant CHANNEL_SPEC => (
    title       => { type => SCALAR },
    link        => { type => SCALAR },
    description => { type => SCALAR },
);

sub channel {
    my $self = shift;
    my %p    = validate(
        @_,
        {
            CHANNEL_SPEC,
            map { $_ => { optional => 1 } }
                keys %{ $self->{namespace_prefixes} },
        },
    );

    die "Cannot call channel() without any items.\n"
        unless @{ $self->{state}{items} };

    die "Cannot call channel() more than once.\n"
        if $self->{state}{finished};

    $self->_start_element(
        '', 'channel',
        [ 'rdf', 'about' => $p{link} ],
    );
    $self->_newline_if_pretty;

    $self->_contents( \%p, qw( title link ) );

    $self->_element_with_cdata( '', 'description', $p{description} );
    $self->_newline_if_pretty;

    foreach my $elt ( grep { $self->{state}{$_} } qw( image textinput ) ) {
        $self->_element(
            '', $elt,
            [ 'rdf', 'resource' => $self->{state}{$elt} ],
        );
        $self->_newline_if_pretty;
    }

    $self->_start_element( '', 'items' );
    $self->_newline_if_pretty;

    $self->_start_element( 'rdf', 'Seq' );
    $self->_newline_if_pretty;

    foreach my $i ( @{ $self->{state}{items} } ) {
        $self->_element(
            'rdf', 'li',
            [ 'rdf', 'resource' => $i ],
        );
        $self->_newline_if_pretty;
    }

    $self->_end_element( 'rdf', 'Seq' );
    $self->_newline_if_pretty;

    $self->_end_element( '', 'items' );
    $self->_newline_if_pretty;

    $self->_call_modules( \%p );

    foreach my $mod ( values %{ $self->{modules} } ) {
        $mod->channel_hook($self) if $mod->can('channel_hook');
    }

    $self->_end_element( '', 'channel' );
    $self->_newline_if_pretty;

    $self->_finish;

    $self->{state}{finished} = 1;
}

sub _finish {
    my $self = shift;

    $self->_end_element( 'rdf', 'RDF' );
    $self->_newline_if_pretty;

    $self->end_document;
}

sub _contents {
    my $self     = shift;
    my $p        = shift;
    my @required = @_;

    for my $elt (@required) {
        $self->_element_with_data( '', $elt, $p->{$elt} );
        $self->_newline_if_pretty;
    }
}

sub _call_modules {
    my $self = shift;
    my $p    = shift;

    foreach my $pre ( sort keys %{ $self->{modules} } ) {
        next unless exists $p->{$pre};

        $self->{modules}{$pre}->contents( $self, $p->{$pre} );
    }
}

sub _element {
    my $self = shift;

    $self->_start_element(@_);
    $self->_end_element(@_);
}

sub _element_with_data {
    my $self = shift;
    my $data = pop;

    $self->_start_element(@_);
    $self->characters( { Data => $data } ) if length $data;
    $self->_end_element(@_);
}

sub _element_with_cdata {
    my $self = shift;
    my $data = pop;

    $self->_start_element(@_);
    if ( length $data ) {
        $self->start_cdata;
        $self->characters( { Data => $data } );
        $self->end_cdata;
    }
    $self->_end_element(@_);
}

sub _start_element {
    my $self = shift;
    my ( $name, $prefix ) = ( shift, shift );

    my %att;
    foreach my $a ( grep { @$_ } @_ ) {
        my ( $k, $v ) = $self->_rss_att(@$a);

        $att{$k} = $v;
    }

    $self->ignorable_whitespace( { Data => ' ' x $self->{state}{indent} } )
        if $self->{pretty} && $self->{state}{indent};

    $self->start_element(
        {
            $self->_rss_name_and_prefix( $name, $prefix ),
            Attributes => \%att,
        }
    );

    $self->{state}{indent}++;
}

sub _end_element {
    my $self = shift;

    if ( $self->{pretty} ) {
        unless ( ( caller(1) )[3] =~ /(?:_element|_element_with_c?data)$/ ) {
            $self->ignorable_whitespace(
                { Data => ' ' x ( $self->{state}{indent} - 1 ) } )
                if $self->{state}{indent} > 1;
        }
    }

    $self->end_element( { $self->_rss_name_and_prefix(@_) } );

    $self->{state}{indent}--;
}

sub _newline_if_pretty {
    $_[0]->ignorable_whitespace( { Data => "\n" } ) if $_[0]->{pretty};
}

{
    my %ns = (
        ''  => 'http://purl.org/rss/1.0/',
        rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    );

    sub _declare_namespaces {
        my $self = shift;

        while ( my ( $p, $uri ) = each %ns ) {
            $self->SUPER::start_prefix_mapping(
                { Prefix => $p, NamespaceURI => $uri } );

            $self->{namespace_prefixes}{$p} = $uri;
        }

        foreach my $package ( values %{ $self->{modules} } ) {
            my $p   = $package->Prefix;
            my $uri = $package->NamespaceURI;

            $self->SUPER::start_prefix_mapping(
                { Prefix => $p, NamespaceURI => $uri } );

            $self->{namespace_prefixes}{$p} = $uri;
        }
    }

    sub _rss_name_and_prefix {
        my $self   = shift;
        my $prefix = shift;
        my $local  = shift;

        die "Invalid prefix ($prefix)"
            unless exists $self->{namespace_prefixes}{$prefix};

        my $name = $prefix ? "$prefix:$local" : $local;

        return (
            Name         => $name,
            LocalName    => $local,
            Prefix       => $prefix,
            NamespaceURI => $self->{namespace_prefixes}{$prefix}
        );
    }

    sub _rss_att {
        my $self   = shift;
        my $prefix = shift;
        my $att    = shift;
        my $value  = shift;

        die "Invalid prefix ($prefix)"
            unless exists $self->{namespace_prefixes}{$prefix};

        return (
            "{$self->{namespace_prefixes}{$prefix}}$att" => {
                $self->_rss_name_and_prefix( $prefix, $att ),
                Value => $value,
            },
        );
    }
}

1;

# ABSTRACT: Generate SAX events for RSS



=pod

=head1 NAME

XML::Generator::RSS10 - Generate SAX events for RSS

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use XML::Generator::RSS10;

    my $rss = XML::Generator::RSS10->new( Handler => $sax_handler );

    $rss->item( title => 'Exciting News About my Pants!',
                link  => 'http://pants.example.com/my/news.html',
                description => 'My pants are full of ants!',
              );

    $rss->channel( title => 'Pants',
                   link  => 'http://pants.example.com/',
                   description => 'A fascinating pants site',
                 );

=head1 DESCRIPTION

This module generates SAX events which will create an RSS 1.0
document, based on easy to use RSS-related methods like C<item()> and
C<channel()>.

=head1 METHODS

=head2 new

This is the constructor for this class.

It takes several parameters, though only one, "Handler", is required:

=over 4

=item * Handler

This should be a SAX2 handler.  If you are looking to write RSS to a
file or store it in a string, you probably want to use
C<XML::SAX::Writer>.

This parameter is required.

=item * pretty

If this is true, the generated XML document will include extra spaces
and newlines in an effort to make it look pretty.  This defaults to
false.

=item * modules

This parameter can be used to make additional RSS 1.0 modules
available when creating a feed.  It should be an array reference to a
list of module prefixes.

You can specify any prefix you like, and this module will try to load
a module named C<< XML::Generator::RSS10::<prefix> >>.

This module comes with support for the core RSS 1.0 modules, which are
Content (content), Dublin Core (dc), and Syndication (sy).  It also
include a module supporting the proposed Administrative (admin) and
Creative Commons (cc) modules.  See the docs for
C<XML::Generator::RSS10::content>, C<XML::Generator::RSS10::dc>,
C<XML::Generator::RSS10::sy>, C<XML::Generator::RSS10::admin>, and
C<XML::Generator::RSS10::cc> for details on how to use them.

The Dublin Core and Syndication modules are loaded by default if this
parameter is not specified.

=back

The constructor begins the RSS document and returns a new
C<XML::Generator::RSS10> object.

=head2 item

This method is used to add item elements to the document.  It accepts
the following parameters:

=over 4

=item * title

The item's title.  Required.

=item * link

The item's link.  Required.

=item * description

The item's link.  Optional.

This element will be formatted as CDATA since many people like to put
HTML in it.

=back

=head2 image

This method is used to add an image element to the document.  It may
only be called once.  It accepts the following parameters:

=over 4

=item * title

The image's title.  Required.

=item * link

The image's link.  Required.

=item * url

The image's URL.  Required.

=back

=head2 textinput

This method is used to add an textinput element to the document.  It
may only be called once.  It accepts the following parameters:

=over 4

=item * title

The textinput's title.  Required.

=item * description

The textinput's description.  Required.

=item * name

The textinput's name.  Required.

=item * url

The textinput's URL.  Required.

=back

=head2 channel

This method is used add the channel element to the document.  It also
finishes the document.  You must have added at least one item to the
document prior to calling this method.

B<You may not call any other methods after this one is called>.

=over 4

=item * title

The channel's title.  Required.

=item * link

The channel's link.  Required.

=item * description

The channel's description.  Required.

This element will be formatted as CDATA since many people like to put
HTML in it.

=back

=head1 RSS 1.0 MODULES

To add module output to a document, you can pass extra hash keys when
calling any of the output-generating methods.  The extra keys should
be the module prefixes, and the values should be something expected by
the relevant module.

For example, to add some Dublin Core elements to the channel element,
you can write this:

    $rss->channel( title => 'Pants',
                   link  => 'http://pants.example.com/',
                   description => 'A fascinating pants site',
                   dc    => { publisher => 'The Pants People',
                              rights    => 'Mine, all mine!',
                              date      => $date,
                            },
                 );

The values for the "dc" key will be passed to
C<XML::Generator::RSS10::dc>, which will add them to the output
stream appropriately.

=head1 XML::Generator::RSS10 VERSUS XML::RSS

This module is less flexible than C<XML::RSS> in many ways.  However,
it does have two features that C<XML::RSS> does not provide:

=over 4

=item *

Because it generates SAX events, this module can be used to write a
document to a handle as a stream.  C<XML::RSS> requires you to create
the entire document in memory first.

=item *

It has support for arbitrary RSS 1.0 modules, including ones you
create.

=back

However, if you don't need any of these features you may be better off
using C<XML::RSS> instead.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-generator-rss10@rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

