# $Id: ShapeFile.pm,v 1.15 2004/08/21 04:13:28 asc Exp $
use strict;

package XML::Generator::SVG::ShapeFile;
use base qw (XML::SAX::Base);

$XML::Generator::SVG::ShapeFile::VERSION = '0.2';

=head1 NAME

XML::Generator::SVG::ShapeFile - Generate SAX2 events for an SVG rendering of an ESRI shapefile.

=head1 SYNOPSIS

 use PerlIO::gzip;
 use XML::SAX::Writer;
 use XML::Generator::SVG::ShapeFile;

 # see CAVEATS below

 open SVGZ, ">:gzip", "/path/to/my/output.svgz"
    || die "do the right thing, luke";

 my $writer = XML::SAX::Writer->new(Output => \*SVGZ);
 my $svg    = XML::Generator::SVG::ShapeFile->new(Handler=>$writer);

 $svg->set_width(1024);
 $svg->set_decimals(1);

 $svg->set_title("You are here");
 $svg->set_stylesheet("foo.css");

 $svg->add_point({lat=>"123",long=>"456"});

 $svg->render("/path/to/shapefile");

=head1 DESCRIPTION

Generate SAX2 events for an SVG rendering of an ESRI shapefile.

=head1 CAVEATS

Depending on your input data, this package may generate huge
SVG files if left uncompressed.

=head1 DOCUMENT STRUCTURE

 + svg

   + metadata
     + rdf:Description [@rdf:about = '...']
       ~ dc:title
       ~ dc:description
       ~ dc:publisher
       ~ dc:language
       - dc:date
       - dc:format

   + g [@id = 'map'] 
     - rect [@id = 'canvas']
     - path                       (+)

   ~ g [@id = 'locations']

     + g [@id = '...']            (+)
       - title
       -circle

=cut

use Geo::ShapeFile;
use Date::Simple;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Inherits from XML::SAX::Base, so constructor arguments
are the same.

=cut

sub new {
    my $pkg = shift;

    my $self = $pkg->SUPER::new(@_);

    $self->{'__points'}   = [];
    $self->{'__metadata'} = {};

    $self->{'__css'}      = undef;

    $self->{'__min_x'}    = 0;
    $self->{'__max_x'}    = 0;

    $self->{'__min_y'}    = 0;
    $self->{'__max_y'}    = 0;

    $self->{'__height'}   = 0;
    $self->{'__width'}    = 0;

    $self->{'__decimals'} = 0;
    $self->{'__scale'}    = 0;

    return bless $self, $pkg;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->set_width($int)

I<Required>

=cut

sub set_width {
    my $self = shift;
    $self->{'__width'} = $_[0];
}

=head2 $obj->set_decimals($int)

I<Required>

=cut

sub set_decimals {
    my $self = shift;
    $self->{'__decimals'} = $_[0];
}

=head2 $obj->set_uri($str)

Set the URI used to identify the document in RDF metadata
section.

Default is '#'

=cut

sub set_uri {
    my $self  = shift;
    $self->{'__metadata'}->{'about'} = $_[0];
}

=head2 $obj->set_title($str)

Set the title for the document's RDF metadata section.

=cut

sub set_title {
    my $self  = shift;
    $self->{'__metadata'}->{'title'} = $_[0];
}

=head2 $obj->set_description($str)

Set the description for the document's RDF metadata section.

=cut

sub set_description {
    my $self  = shift;
    $self->{'__metadata'}->{'description'} = $_[0];
}

=head2 $obj->set_publisher($str)

Set the publisher for the document's RDF metadata section.

=cut

sub set_publisher {
    my $self = shift;
    $self->{'__metadata'}->{'publisher'} = $_[0];
}

=head2 $obj->set_language($str)

Set the language for the document's RDF metadata section.

=cut

sub set_language {
    my $self = shift;
    $self->{'__metadata'}->{'language'} = $_[0];
}

=head2 $obj->set_stylesheet($str)

Set the URI for the document's CSS stylesheet.

=cut

sub set_stylesheet {
    my $self = shift;
    $self->{'__css'} = $_[0];
}

=head2 $obj->add_point(\%args)

Points are added as SVG I<circle> elements.

Valid arguments are :

=over 4

=item * B<lat>

The latitude, in decimal form, of the point you are adding.

I<Required>

=item * B<long>

The longitude, in decimal form, of the point you are adding.

I<Required>

=item * B<id>

Default is 'id-<lat>-<long>', where decimal points are replaced
by '-'

=item * B<title>

A label for the point you are adding.

=item * B<radius>

The radius of the point you are adding.

Default is '1'

=item * B<style>

CSS stylings specific to the point you are adding.

=back 

=cut

sub add_point {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
	warn "arguments passed must be a hash reference";
	return 0;
    }

    if (! $args->{lat}) {
	warn "no latitude defined";
	return 0;
    }

    if (! $args->{long}) {
	warn "no longitude defined";
	return 0;
    }

    push @{$self->{'__points'}}, $args;
    return 1;
}

=head2 $obj->render($path)

Generate SAX2/SVG events for an ESRI shapefile.

=cut

sub render {
    my $self = shift;
    my $path = shift;

    my $shapefile = Geo::ShapeFile->new($path);

    if (! $shapefile) {

	return 0;
    }

    #

    ($self->{'__min_x'}, $self->{'__min_y'},
     $self->{'__max_x'}, $self->{'__max_y'}) = $shapefile->bounds();

    $self->{'__scale'}  = $self->{'__width'} / ($self->{'__max_x'} - $self->{'__min_x'});

    $self->{'__height'} = int((($self->{'__max_y'} - $self->{'__min_y'}) * 
			       $self->{'__scale'}) + 0.5);

    #
    
    $self->start_document();
    $self->xml_decl({Encoding=>"UTF-8",Version=>"1.0"});

    #

    if ($self->{'__css'}) {

	my $css = sprintf("href = \"%s\" type = \"text/css\"",
			  $self->{'__css'});

	$self->processing_instruction({Target => "xml-stylesheet",
				       Data   => $css});
    }

    #

    $self->start_prefix_mapping({Prefix       => "",
				 NamespaceURI => "http://www.w3.org/2000/svg"});

    $self->start_prefix_mapping({Prefix       => "xlink",
				 NamespaceURI => "http://www.w3.org/1999/xlink"});

    $self->start_prefix_mapping({Prefix       => "rdf",
				 NamespaceURI => "http://www.w3.org/1999/02/22-rdf-syntax-ns#"});

    $self->start_prefix_mapping({Prefix       => "dc",
				 NamespaceURI => "http://purl.org/dc/elements/1.1/"});
    
    $self->start_element({Name => "svg",
			  Attributes => { "{}height" => {Name  => "height",
							 Value => $self->{'__height'}},
					  "{}width"  => {Name  => "width",
							 Value => $self->{'__width'}}}});

    #

    $self->_metadata();

    #

    $self->start_element({Name => "g",
			  Attributes => {"{}id" => {Name  => "id",
						    Value => "map"}}});

    $self->start_element({Name => "rect",
			  Attributes => {"{}id"     => {Name  => "id",
							Value => "canvas"},
					 "{}height" => {Name  => "height",
							Value => $self->{'__height'}},
					 "{}width"  => {Name  => "width",
							Value => $self->{'__width'}},
				     }});
    
    $self->end_element({Name => "rect"});

    for (1 .. $shapefile->shapes()) {
	my $shape = $shapefile->get_shp_record($_);

	for(1 .. $shape->num_parts) {

	    my @points = $shape->get_segments($_);
	    my @d      = ();
	    
	    for my $i ( 0 .. $#points ) {

		# TO DO : pseudohashes are deprecated
		foreach my $xy ( keys %{$points[$i]} ) {
		    
		    # TO DO : argument $xy (e.g. "Y")
		    # isn't numeric element (see above
		    # re: pseudohashes)

		    my $coord = $points[$i][$xy]->$xy();

		    if ($xy eq "X"){
			$coord = $self->calc_x($coord);
		    } else {
			$coord = $self->calc_y($coord);
		    }
			
		    push @d, $coord;

		} 
	    }

	    $self->start_element({Name       => "path",
				  Attributes => {"{}d" => {Name => "d",
							   Value => join(" ","M",@d,"z")},
					     }});
	    $self->end_element({Name => "path"});
	}
    }

    $self->end_element({Name => "g"});

    #

    $self->_locations();

    #

    $self->end_element({Name => "svg"});

    $self->end_prefix_mapping({Prefix => ""});
    $self->end_prefix_mapping({Prefix => "rdf"});
    $self->end_prefix_mapping({Prefix => "xlink"});
    $self->end_prefix_mapping({Prefix => "dc"});

    $self->end_document();
    return 1;
}

sub _metadata {
    my $self = shift;

    my $data = $self->{'__metadata'};

    $self->start_element({Name => "metadata"});
    $self->start_element({Name => "rdf:RDF"});

    $self->start_element({Name       => "rdf:Description",
			  Attributes => {"{}about" => {Name  => "rdf:about",
						       Value => ($data->{about} || "#")}}});

    foreach my $el ("title","description","publisher","language") {
	if (exists($data->{ $el })) {
	    $self->start_element({Name => "dc:$el"});
	    $self->characters({Data    => $data->{ $el }});
	    $self->end_element({Name   => "dc:$el"});
	}
    }

    $self->start_element({Name => "dc:date"});
    $self->characters({Data=>Date::Simple->new()->format("%Y-%m-%d")});
    $self->end_element({Name => "dc:date"});

    $self->start_element({Name => "dc:format"});
    $self->characters({Data    => "image/svg+xml"});
    $self->end_element({Name   => "dc:format"});

    $self->end_element({Name => "rdf:Description"});
    $self->end_element({Name => "rdf:RDF"});
    $self->end_element({Name => "metadata"});

    return 1;
}

sub _locations {
    my $self = shift;

    if (! @{$self->{'__points'}}) {
	return 1;
    }

    $self->start_element({Name       => "g",
			  Attributes => { "{}id" => {Name  => "id",
						     Value => "locations"},}});

    map { 
	$self->_point($_);
    } @{$self->{'points'}};

    $self->end_element({Name => "g"});
    return 1;
}

sub _point {
    my $self = shift;
    my $args = shift;

    my %attrs = ("{}cx" => {Name  => "cx",
			    Value => $self->calc_x($args->{long})},
		 "{}cy" => {Name  => "cy",
			    Value => $self->calc_y($args->{lat})},
		 "{}r"  => {Name  => "r",
			    Value => ($args->{radius} || 1)});

    if ($args->{style}) {
	$attrs{ "{}style" } = {Name  => "style",
			       Value => $args->{style}};
    }

    #

    my $id = undef;

    if ($args->{'id'}) {
	$id = $args->{'id'};
    } 

    else {
	my $lat  = $args->{lat};
	my $long = $args->{long};

	$lat  =~ s/\./-/g;
	$long =~ s/\./-/g;

	$id = sprintf("id-%s-%s",$lat,$long);
    }

    #

    $self->start_element({Name       => "g",
			 Attributes => {"{}id" => {Name  => "id",
						   Value => $id}}});
    
    if ($args->{title}) {
	$self->start_element({Name => "title"});
	$self->characters({Data=>$args->{title}});
	$self->end_element({Name => "title"});
    }

    $self->start_element({Name      => "circle",
			 Attributes => \%attrs});
    $self->end_element({Name => "circle"});
    $self->end_element({Name => "g"});

    #

    return 1;
}

sub calc_x {
    my $self  = shift;
    my $coord = shift;
    
    return int(($coord - $self->{'__min_x'}) * $self->{'__scale'} *
	       (10**$self->{'__decimals'}))/ (10**$self->{'__decimals'});
}

sub calc_y {
    my $self  = shift;
    my $coord = shift;

    return int(($self->{'__max_y'} - $coord) * $self->{'__scale'} *
	       (10**$self->{'__decimals'}))/ (10**$self->{'__decimals'});
}

=head1 VERSION

0.2

=head1 DATE

$Date: 2004/08/21 04:13:28 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

http://www.webmapper.net/svg/create/ 

(these are the nice people who did most of the
 hard work for this package)

L<Geo::ShapeFile>

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
