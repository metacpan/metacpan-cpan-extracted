package URL::Transform::using::XML::SAX;

=head1 NAME

URL::Transform::using::XML::SAX - XML::SAX parsing of the html/xml for url transformation

=head1 SYNOPSIS

    my $urlt = URL::Transform::using::XML::SAX->new(
        'output_function'    => sub { $output .= "@_" },
        'transform_function' => sub { return (join '|', @_) },
    );
    $urlt->parse_file($Bin.'/data/URL-Transform-01.html');

=head1 DESCRIPTION

This is a helper module to set-up L<URL::Transform::SAX::Filter> for
a L<URL::Transform>.

You can set which SAX driver will be used by:

    $XML::SAX::ParserPackage = "XML::LibXML::SAX";

See: L<XML::SAX::ParserFactory>.

This module lacks the advanced features of L<URL::Transform::using::HTML::Parser>
like transforming the urls in the inside document elements types (CSS/JavaScript/Meta)
because it was used mosty to benchmark the performance of the L<HTML::Parser> vs
L<XML::SAX>. The L<HTML::Parser> turned out to be much more performant.

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use XML::SAX;
use XML::SAX::ParserFactory;
use XML::SAX::Writer;
use URL::Transform::SAX::Filter;

use HTML::Tagset ();
use Carp::Clan;


use base 'Class::Accessor::Fast';

=head1 PROPERTIES

    output_function
    transform_function

    _libxml_parser

=cut

__PACKAGE__->mk_accessors(qw{
    output_function
    transform_function

    _sax_parser
});

=head1 METHODS


=head2 new

Object constructor.

Requires:

    output_function
    transform_function 

Which are the code refs. See L<URL::Transform> for more details/example.

=cut


sub new {
    my $class = shift;
    my $self = $class->SUPER::new({ @_ });

    my $output_function    = $self->output_function;
    my $transform_function = $self->transform_function;
    
    croak 'pass output function'
        if not (ref $output_function eq 'CODE');
    
    croak 'pass transform url function'
        if not (ref $transform_function eq 'CODE');
        
    # FIXME reuse URL::Transform::using::HTML::Parser::transform_function_wrapper()
    #       for handling special "hidden" urls
        
    my $writer = XML::SAX::Writer->new( Output => sub {
        my $type = shift;
        $output_function->(@_);
    } );
    my $filter = URL::Transform::SAX::Filter->new(
        Handler            => $writer,
        transform_function => $transform_function,
    );
    
    my $sax_parser = XML::SAX::ParserFactory->parser(
        'Handler' => $filter,
    );
    
    $self->_sax_parser($sax_parser);    

    return $self;
}


=head2 parse_string($string)

Submit document as a string for parsing.

=cut

sub parse_string {
    my $self = shift;
    
    $self->_sax_parser->parse_string(@_);
}


=head2 parse_file($file_name)

Submit file for parsing.

=cut

sub parse_file {
    my $self      = shift;
    my $file_name = shift;

    open my $fh, '<', $file_name or croak 'Can not open '.$file_name.': '.$!;
    
    $self->_sax_parser->parse_file($fh);
}


1;


__END__

=head1 SEE ALSO

L<URL::Transform>, L<URL::Transform::SAX::Filter>

=head1 AUTHOR

Jozef Kutej

=cut
