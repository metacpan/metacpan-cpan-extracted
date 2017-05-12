#
# Copyright (C) 1998, 1999 Ken MacLeod
# XML::Grove::PerlSAX is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: PerlSAX.pm,v 1.3 1999/08/17 15:01:28 kmacleod Exp $
#

use strict;

package XML::Grove::PerlSAX;

use UNIVERSAL;
use Data::Grove::Visitor;

sub new {
    my $type = shift;
    my $self = ($#_ == 0) ? shift : { @_ };

    return bless $self, $type;
}

sub parse {
    my $self = shift;

    die "XML::Grove::PerlSAX: parser instance ($self) already parsing\n"
	if (defined $self->{ParseOptions});

    # If there's one arg and it's a subclass of Data::Grove,
    # then that's what we're parsing
    my $args;
    if (scalar (@_) == 1 && UNIVERSAL::isa($_[0], 'Data::Grove')) {
	$args = { Source => { Grove => shift } };
    } else {
	$args = (scalar (@_) == 1) ? shift : { @_ };
    }

    my $parse_options = { %$self, %$args };
    $self->{ParseOptions} = $parse_options;

    # ensure that we have at least one source
    if (!defined $parse_options->{Source}
	|| !(defined $parse_options->{Source}{Grove})) {
	die "XML::Grove::PerlSAX: no source defined for parse\n";
    }

    # assign default Handler to any undefined handlers
    if (defined $parse_options->{Handler}) {
	$parse_options->{DocumentHandler} = $parse_options->{Handler}
	    if (!defined $parse_options->{DocumentHandler});
    }

    # ensure that we have a DocumentHandler
    if (!defined $parse_options->{DocumentHandler}) {
	die "XML::Grove::PerlSAX: no Handler or DocumentHandler defined for parse\n";
    }

    # cache DocumentHandler in self for callbacks
    $self->{DocumentHandler} = $parse_options->{DocumentHandler};

    if (ref($self->{Source}{Grove}) !~ /Document/) {
	$self->{DocumentHandler}->start_document( { } );
	$parse_options->{Source}{Grove}->accept($self);
	return $self->{DocumentHandler}->end_document( { } );
    } else {
	$self->{Source}{Grove}->accept($self);
    }

    # clean up parser instance
    delete $self->{ParseOptions};
    delete $self->{DocumentHandler};
}

sub _parse_self {
    my $grove = shift;
    my $self = ($#_ == 0) ? shift : { @_ };

    bless $self, 'XML::Grove::PerlSAX';

    if (ref($grove) !~ /Document/) {
	$self->{DocumentHandler}->start_document( { } );
	$grove->accept($self);
	return $self->{DocumentHandler}->end_document( { } );
    } else {
	return $grove->accept($self);
    }
}

sub visit_document {
    my $self = shift; my $grove = shift;

    $self->{DocumentHandler}->start_document($grove);
    $grove->children_accept($self);
    return $self->{DocumentHandler}->end_document($grove);
}

sub visit_element {
    my $self = shift; my $element = shift;

    $self->{DocumentHandler}->start_element($element);
    $element->children_accept($self);
    return $self->{DocumentHandler}->end_element($element);
}

sub visit_entity {
    my $self = shift; my $entity = shift;

    return $self->{DocumentHandler}->int_entity($entity);
}

sub visit_pi {
    my $self = shift; my $pi = shift;

    return $self->{DocumentHandler}->processing_instruction($pi);
}

sub visit_comment {
    my $self = shift; my $comment = shift;

    return $self->{DocumentHandler}->comment($comment);
}

sub visit_characters {
    my $self = shift; my $characters = shift;

    return $self->{DocumentHandler}->characters($characters);
}

package XML::Grove::Document;

sub parse {
    goto &XML::Grove::PerlSAX::_parse_self;
}

package XML::Grove::Element;

sub parse {
    goto &XML::Grove::PerlSAX::_parse_self;
}

1;

__END__

=head1 NAME

XML::Grove::PerlSAX - an PerlSAX event interface for XML objects

=head1 SYNOPSIS

 use XML::Grove::PerlSAX;

 $parser = XML::Grove::PerlSAX->new( [OPTIONS] );
 $result = $parser->parse( [OPTIONS] );

 # or
 $result = $xml_object->parse( [OPTIONS] );

=head1 DESCRIPTION

C<XML::Grove::PerlSAX> is a PerlSAX parser that generates PerlSAX
events from XML::Grove objects.  This man page summarizes the specific
options, handlers, and properties supported by C<XML::Grove::PerlSAX>;
please refer to the PerlSAX standard in `C<PerlSAX.pod>' for general
usage information.

=head1 METHODS

=over 4

=item new

Creates a new parser object.  Default options for parsing, described
below, are passed as key-value pairs or as a single hash.  Options may
be changed directly in the parser object unless stated otherwise.
Options passed to `C<parse()>' override the default options in the
parser object for the duration of the parse.

=item parse

Parses a document.  Options, described below, are passed as key-value
pairs or as a single hash.  Options passed to `C<parse()>' override
default options in the parser object.

=back

=head1 OPTIONS

The following options are supported by C<XML::Grove::PerlSAX>:

 Handler          default handler to receive events
 DocumentHandler  handler to receive document events
 Source           hash containing the input source for parsing

If no handlers are provided then all events will be silently ignored.

If a single grove argument is passed to the `C<parse()>' method, it is
treated as if a `C<Source>' option was given with a `C<Grove>'
parameter.

The `C<Source>' hash may contain the following parameters:

 Grove            The grove object used to generate parse events..

=head1 HANDLERS

The following events are generated by C<XML::Grove::PerlSAX>.
XML::Grove::PerlSAX passes the corresponding grove object as it's
parameter so the properties passed to the handler are those that were
used to create or were assigned to the grove.  Please see the docs for
the parser used to create the grove for a list of properties that were
provided.

=head2 DocumentHandler methods

=over 4

=item start_document

Receive notification of the beginning of a document.  This is called
from the XML::Grove::Document object before processing any document
content.

=item end_document

Receive notification of the end of a document.  This is called from
the XML::Grove::Document object after processing all document content.

=item start_element

Receive notification of the beginning of an element.  This is called
from the XML::Grove::Element object before processing any element
content.

=item end_element

Receive notification of the end of an element.  This is called from
the XML::Grove::Element object after processing all element content.

=item characters

Receive notification of character data.  This is called from the
XML::Grove::Characters object.

=item processing_instruction

Receive notification of a processing instruction.  This is called from
the XML::Grove::PI object.

=item comment

Receive notification of a comment.  This is called from the
XML::Grove::Comment object.

=back

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), XML::Grove(3)

Extensible Markup Language (XML) <http://www.w3c.org/XML>

=cut
