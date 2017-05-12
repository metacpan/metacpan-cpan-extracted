package XML::CAP;

use warnings;
use strict;
use XML::LibXML;

# defined exeptions
use Exception::Class (
	"XML::CAP::Exception",

	"XML::CAP::TracedException" => {
		isa => "XML::CAP::Exception",
	},

	"XML::CAP::Exception::AbstractMethod" => {
		isa => "XML::CAP::Exception",
		alias => "throw_abstract_method",
		description => "abstract method must be overridden by a subclass",
	},
);

# define exports
use base "Exporter";
our @EXPORT = qw( &eval_wrapper );
our @EXPORT_OK = qw( &eval_wrapper );

# package globals
our $DefaultVersion = '1.1';

=head1 NAME

XML::CAP - parse or generate the XML Common Alerting Protocol (CAP)

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

XML::CAP parses and generates XML Common Alerting Protocol (CAP).

More information about CAP can be found at L<http://www.incident.com/cookbook/>

Each XML CAP structure has an "alert" section.  Each alert may contain
zero (usually one) or more "info" sections.  Each info section may contain
zero or more "resource" and/or "area" sections.  Each area section may
contain zero or more "geocode" sections.  All of these sections are
represented by subclasses of XML::CAP.

XML::CAP uses XML::LibXML.  There are accessor functions for every element.
But using the elem() method, there is also direct access to the corresponding
LibXML node.

Code sample:

    use XML::CAP;
    use XML::CAP::Parser;

    my $parser = XML::CAP::Parser->new();
    $parser->parse_file( "cap-file.xml" );
    my $alert;
    eval_wrapper ( sub { $alert = $parser->alert });

    @alert_nodes = $alert->elem->childnodes; # access to XML::libXML data
    $identifier = $alert->identifier;
    $sender = $alert->sender;
    $sent = $alert->sent;
    $status = $alert->status;
    $msgType = $alert->msgType;
    $source = $alert->source;
    $scope = $alert->scope;
    $restriction = $alert->restriction;
    $addresses = $alert->addresses;
    $code = $alert->code;
    $note = $alert->note;
    $references = $alert->references;
    $incidents = $alert->incidents;

    my @infos = $alert->infos;
    @info_nodes = $infos[0]->elem->childnodes; # access LibXML data
    my $info = $infos[0];
    $language = $info->language;
    $category = $info->category;
    $event = $info->event;
    $responseType = $info->responseType;
    $urgency = $info->urgency;
    $severity = $info->severity;
    $certainty = $info->certainty;
    $audience = $info->audience;
    $eventCode = $info->eventCode;
    $effective = $info->effective;
    $onset = $info->onset;
    $expires = $info->expires;
    $senderName = $info->senderName;
    $headline = $info->headline;
    $description = $info->description;
    $instruction = $info->instruction;
    $web = $info->web;
    $contact = $info->contact;
    $parameter = $info->parameter;

    my @resources = $info->resources;
    @resource_nodes = $resources[0]->elem->childnodes; # access LibXML data
    my $resource = $resources[0];
    $resourceDesc = $resource->resourceDesc;
    $mimeType = $resource->mimeType;
    $size = $resource->size;
    $uri = $resource->uri;
    $derefUri = $resource->derefUri;
    $digest = $resource->digest;

    my @areas = $info->areas;
    @area_nodes = $areas[0]->elem->childnodes; # access LibXML data
    my $area = $areas[0];
    $areaDesc = $area->areaDesc;
    $polygon = $area->polygon;
    $circle = $area->circle;
    $altitude = $area->altitude;

    my @geocodes = $area->geocodes;
    @geocode_nodes = $geocodes[0]->elem->childnodes; # access LibXML data
    my $geocode = $geocodes[0];
    $valueName = $geocode->valueName;
    $value = $geocode->value;


=head1 FUNCTIONS

=head2 new

=cut

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->initialize( @_ );
	return $self;
}


=head2 initialize

=cut

sub initialize {
	throw_abstract_method( "initialize() must be provided by subclass" );
}

=head2 eval_wrapper ( $code, $throw_func, [ name => value, ...] )

=cut

# eval_wrapper - catch exceptions from XML::LibXML, XML::CAP or others
sub eval_wrapper
{
	my $code = shift;
	my $throw_func = shift;
	my %params = @_;

	# run the code in an eval so we can catch exceptions
	my $result = eval { &$code; };

	# process any exception that we may have gotten
	if ( $@ ) {
		my $ex = $@;

		# determine if there's an error message available
		my $msg;
		if ( ref $ex ) {
			if ( my $ex_cap = Exception::Class->caught(
				"XML::CAP::Exception"))
			{
				warn (ref $ex_cap).": ".$ex_cap->error."\n";
				if ( $ex_cap->isa( "XML::CAP::TracedException" )) {
					warn $ex_cap->trace->as_string, "\n";
				}

				if ( $params{no_rethrow} ) {
					# it's our own exception so rethrow it
					# to maintain details
					$ex_cap->rethrow
				} else {
					$msg = $ex_cap->error;
				}
			}
			if ( $ex->can("stringify")) {
				# Error.pm, possibly others
				$msg = $ex->stringify;
			} elsif ( $ex->can("as_string")) {
				# generic - should work for many classes
				$msg = $ex->as_string;
			} else {
				$msg = "unknown exception of type ".(ref $ex);
			}
		} else {
			$msg = $@;
		}

		# use the captured error message to throw our own exception
		# or print error messages before exiting
		&$throw_func ( $msg );
	}

	# success
	return $result;
}

=head1 AUTHOR

Ian Kluft, C<< <ikluft at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-cap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-CAP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::CAP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-CAP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-CAP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-CAP>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-CAP/>

=back


=head1 ACKNOWLEDGEMENTS

The initial version was derived from XML::Atom by Benjamin Trott and
Tatsuhiko Miyagawa.


=head1 COPYRIGHT & LICENSE

Copyright 2009 Ian Kluft, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of XML::CAP
