package XML::LibXSLT::Quick;

use strict;
use warnings;
use 5.010;
use autodie;

use Carp ();

use XML::LibXML  ();
use XML::LibXSLT ();

use vars qw( $VERSION );

$VERSION = '2.000000';

sub stylesheet
{
    my $self = shift;

    if (@_)
    {
        $self->{stylesheet} = shift;
    }

    return $self->{stylesheet};
}

sub xml_parser
{
    my $self = shift;

    if (@_)
    {
        $self->{xml_parser} = shift;
    }

    return $self->{xml_parser};
}

sub new
{
    my $class = shift;
    my $args  = shift;

    my $xslt       = ( $args->{xslt_parser} // XML::LibXSLT->new() );
    my $xml_parser = ( $args->{xml_parser}  // XML::LibXML->new() );

    my $style_doc = $xml_parser->load_xml(
        location => $args->{location},
        no_cdata => ( $args->{no_cdata} // 0 ),
    );
    my $stylesheet = $xslt->parse_stylesheet($style_doc);
    my $obj        = bless( +{}, $class );
    $obj->{xml_parser} = $xml_parser;
    $obj->{stylesheet} = $stylesheet;
    return $obj;
}

sub _write_utf8_file
{
    my ( $out_path, $contents ) = @_;

    open my $out_fh, '>:encoding(utf8)', $out_path;

    print {$out_fh} $contents;

    close($out_fh);

    return;
}

sub _write_raw_file
{
    my ( $out_path, $contents ) = @_;

    open my $out_fh, '>:raw', $out_path;

    print {$out_fh} $contents;

    close($out_fh);

    return;
}

sub generic_transform
{
    my $self = shift;

    my ( $dest, $source, ) = @_;
    my $xml_parser = $self->xml_parser();
    my $stylesheet = $self->stylesheet();

    my $ret;
    if ( ref($source) eq '' )
    {
        $source = $xml_parser->parse_string($source);
    }
    elsif ( ref($source) eq 'HASH' )
    {
        my $type = $source->{type};
        if (0)
        {
        }
        elsif ( $type eq "file" )
        {
            $source = $xml_parser->parse_file( $source->{path} );
        }
        else
        {
            Carp::confess("unknown source type");
        }
    }
    my $results  = $stylesheet->transform( $source, );
    my $calc_ret = sub {
        return ( $ret //= $stylesheet->output_as_chars( $results, ) );
    };
    my $destref = ref($dest);
    if ( $destref eq "SCALAR" )
    {
        if ( ref($$dest) eq "" )
        {
            $$dest .= scalar( $calc_ret->() );
        }
        else
        {
            Carp::confess(
                "\$dest as a reference to a non-string scalar is not supported!"
            );
        }
    }
    elsif ( $destref eq "HASH" )
    {
        my $type = $dest->{type};
        if (0)
        {
        }
        elsif ( $type eq "dom" )
        {
            return $results;
        }
        elsif ( $type eq "file" )
        {
            my $path = $dest->{path};
            _write_utf8_file( $path, scalar( $calc_ret->() ) );
        }
        elsif ( $type eq "return" )
        {
            return scalar( $calc_ret->() );
        }
        else
        {
            Carp::confess("unknown dest type");
        }
    }
    else
    {
        $dest->print( scalar( $calc_ret->() ) );
    }
    return scalar( $calc_ret->() );
}

sub output_as_chars
{
    my $self = shift;

    return $self->stylesheet()->output_as_chars(@_);
}

sub transform
{
    my $self = shift;

    return $self->stylesheet()->transform(@_);
}

sub transform_into_chars
{
    my $self = shift;

    return $self->stylesheet()->transform_into_chars(@_);
}

1;

__END__

=head1 NAME

XML::LibXSLT::Quick - a quicker interface to XML::LibXSLT

=head1 SYNOPSIS

    use XML::LibXSLT::Quick ();

    my $stylesheet =
        XML::LibXSLT::Quick->new( { location => 'example/1.xsl', } );
    my $xml1_text = _utf8_slurp('example/1.xml');
    my $out_fn = 'foo.xml';
    $stylesheet->generic_transform(
        +{
            type => 'file',
            path => $out_fn,
        },
        $source,
    );

=head1 DESCRIPTION

This is a module that wraps L<XML::LibXSLT> with an easier to use interface.

=head1 METHODS

=head2 XML::LibXSLT::Quick->new({ location=>"./xslt/my.xslt", });

TBD.

=head2 $obj->stylesheet()

The result of parse_stylesheet().

=head2 $obj->xml_parser()

The L<XML::LibXML> instance.

=head2 $obj->generic_transform($dest, $source)

To be discussed.

See C<t/using-quick-wrapper.t> .

=head2 $obj->output_as_chars($dom)

=head2 $obj->transform(...)

=head2 $obj->transform_into_chars(...)

Delegating from $obj->stylesheet() . See L<XML::LibXSLT> .

=head1 SEE ALSO

L<XML::LibXSLT::Easy> by Yuval Kogman - requires some MooseX modules.

L<XML::LibXSLT> - used as the backend of this module.

=cut
