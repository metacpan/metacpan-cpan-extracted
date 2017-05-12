#!/usr/bin/perl

package XML::LibXSLT::Easy;
use Moose;

our $VERSION = "0.03";

use Carp qw(croak);

use Devel::PartialDump qw(warn dump);

use XML::LibXML;
use XML::LibXSLT;

use Path::Class;
use URI;
use URI::file;
use URI::data;

use Scope::Guard;

use MooseX::MultiMethods;
use MooseX::Types::Moose qw(Str FileHandle Item Undef);
use MooseX::Types::Path::Class qw(File);
use MooseX::Types::URI qw(Uri);

use MooseX::Types -declare => [qw(Stylesheet Document)];

BEGIN {
	class_type Stylesheet, { class => "XML::LibXSLT::StylesheetWrapper" };
	class_type Document,   { class => "XML::LibXML::Document" };
}


use namespace::clean -except => [qw(meta)];

has xml => (
    isa => "XML::LibXML",
    is  => "rw",
    lazy_build => 1,
    handles => [qw(
        parse_string
        parse_fh
        parse_file
        base_uri
    )],
);

has xml_options => (
    isa => "HashRef",
    is  => "rw",
    default => sub { {} },
);

sub _build_xml {
    my $self = shift;
    XML::LibXML->new( %{ $self->xml_options } );
}

has xslt=> (
    isa => "XML::LibXSLT",
    is  => "rw",
    lazy_build => 1,
    handles => [qw(
        parse_stylesheet
        transform
    )],
);

has xslt_options => (
    isa => "HashRef",
    is  => "rw",
    default => sub { {} },
);

sub process {
    my ( $self, %args ) = @_;

    my ( $xml, $xsl, $out, $uri ) = @args{qw(xml xsl out input_uri)};

    $uri ||= $self->get_uri($xml);

    my $doc = $self->parse($xml);

    if ( $uri ) {
        my $prev_base = $self->base_uri;
        my $sg = Scope::Guard->new(sub { $self->base_uri($prev_base) });
        $self->base_uri($uri);
    }

    unless ( defined $xsl ) {
        croak "Can't process <?xml-stylesheet> without knowing the URI of the input" unless $uri;
        $xsl = $self->get_xml_stylesheet_pi( $doc, $uri, %args );
    }

    my $stylesheet = $self->stylesheet($xsl);

    $self->output( $out, $stylesheet, $stylesheet->transform($doc) );
}

sub _build_xslt {
    my $self = shift;
    XML::LibXSLT->new( %{ $self->xslt_options } );
}

sub get_xml_stylesheet_pi {
    my ( $self, $doc, $uri, %args ) = @_;

    # from AxKit::PageKit::Content
    my @stylesheet_hrefs;
    for my $pi_node ($doc->findnodes('processing-instruction()')) {
        my $pi_str = $pi_node->getData;
        if ( $pi_str =~ m!type="text/xsl! or $pi_str !~ /type=/ ) {
            my ($stylesheet_href) = ($pi_str =~ m!href="([^"]*)"!);

            my $xsl_uri = URI->new($stylesheet_href);

            if ( $xsl_uri->scheme ) { # scheme means abs
                return $xsl_uri;
            } else {
                if ( $uri->isa("URI::data") ) {
                    croak "<?xml-stylesheet>'s href is relative but the base URI is in the 'data:' scheme and cannot be used as a base";
                }

                if ( $uri->isa("URI::file") ) {
                    my $file = file($uri->file);
                    return $file->parent->file($stylesheet_href);
                } elsif ( $uri->scheme ) {
                    return $xsl_uri->abs($uri)
                } else {
                    croak "<?xml-stylesheet>'s href is relative buit the URI base neither absolute nor a 'file:' one";
                }
            }
        }
    }

    croak "No <?xml-stylesheet> processing instruction in document, please specify stylesheet explicitly";
}

multi method get_uri ( Uri $uri ) { $uri }
multi method get_uri ( File $file ) { URI::file->new($file) }
multi method get_uri ( Str $str ) {
    if ( -f $str ) {
        URI::file->new($str);
    } else {
        URI::data->new($str);
    }
}

multi method stylesheet ( Stylesheet $s ) { $s }
multi method stylesheet ( Document $doc ) { $self->parse_stylesheet($doc) }
multi method stylesheet ( Any $thing ) {
    $self->stylesheet( $self->parse($thing) );
}

multi method parse ( Document $doc ) { $doc }
multi method parse ( FileHandle $fh ) { $self->parse_fh($fh) }
multi method parse ( File $file ) { $self->parse_file($file) }
multi method parse ( Str $thing, @args ) {
    if ( -f $thing ) {
        $self->parse_file($thing, @args);
    } else {
        $self->parse_string($thing, @args);
    }
}

# includes file URIs
multi method parse ( Uri $uri, @args ) {
    $self->parse_file( $uri, @args );
}

multi method output ( FileHandle $fh, @args ) { $self->output_fh($fh, @args) }
multi method output ( Str $file, @args ) { $self->output_file($file, @args) }
multi method output ( File $file, @args ) { $self->output_File($file, @args) }
multi method output ( Undef $x, @args ) { $self->output_string(@args) }

sub output_string {
    my ( $self, $s, $r ) = @_;
    $s->output_string($r);
}

sub output_fh {
    my ( $self, $o, $s, $r ) = @_;
    $s->output_fh($r, $o);
}

sub output_file {
    my ( $self, $o, $s, $r ) = @_;
    $s->output_file($r, $o);
}

__PACKAGE__

__END__

=pod

=head1 NAME

XML::LibXSLT::Easy - DWIM XSLT processing with L<XML::LibXSLT>

=head1 SYNOPSIS

    use XML::LibXSLT::Easy;

    my $p = XML::LibXSLT::Easy->new;

    my $output = $p->process( xml => "foo.xml", xsl => "foo.xsl" );

    # takes various types of arguments
    $p->process( xml => $doc, xsl => $filehandle, out => $filename );

=head1 DESCRIPTION

=cut


