#
# Copyright (C) 1998, 1999 Ken MacLeod
# XML::Grove::Builder is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#
# $Id: Builder.pm,v 1.5 1999/08/17 15:01:28 kmacleod Exp $
#

#
# implements these handlers:
#
# PerlSAX defined handlers
#
# start_document         -- beginning of a document
# end_document           -- end of a document
# start_element          -- beginning of an element
# end_element            -- end of an element
# characters             -- character data
# ignorable_whitespace   -- ignorable whitespace in element content
# processing_instruction -- processing instruction (PI)
#
# Additional handlers
#
# record_end             -- record_end
# ext_entity             -- external entity definition
# subdoc_entity          -- subdoc entity definition
# ext_sgml_entity        -- external SGML text entity definition
# int_entity             -- internal entity definition
# ext_entity_ref         -- external entityt reference
# int_entity_ref         -- internal entity reference
# notation               -- notation definition
# comment                -- comment
# start_subdoc           -- start of subdoc entity
# end_subdoc             -- end of subdoc entity
# appinfo                -- defined value of APPINFO
# conforming             -- document is conforming
# error                  -- error

use strict;

package XML::Grove::Builder;

use XML::Grove;

sub new {
    my $type = shift;
    my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };

    return bless $self, $type;
}

sub start_document {
    my $self = shift;
    my $document = shift;

    $self->{lists} = [];
    $self->{cur_list} = [];
    $self->{Grove} = new XML::Grove::Document (%$document,
					       Contents => $self->{cur_list});
}

sub end_document {
    my $self = shift;

    my $grove = $self->{Grove};

    delete $self->{cur_list};
    delete $self->{lists};
    delete $self->{Grove};

    return $grove;
}

sub start_element {
    my $self = shift;
    my $properties = shift;

    my $contents = [];
    $properties->{Contents} = $contents;

    my $element = new XML::Grove::Element ($properties);
    push @{ $self->{lists} }, $self->{cur_list};
    push @{ $self->{cur_list} }, $element;
    $self->{cur_list} = $contents;
}

sub end_element {
    my $self = shift;
    $self->{cur_list} = pop @{ $self->{lists} };
}

sub characters {
    my $self = shift;
    push @{ $self->{cur_list} }, new XML::Grove::Characters (@_);
}

sub ignorable_whitespace {
    my $self = shift;
    push @{ $self->{cur_list} }, new XML::Grove::Characters (@_);
}

sub processing_instruction {
    my $self = shift;
    push @{ $self->{cur_list} }, new XML::Grove::PI (@_);
}

sub record_end {
    my $self = shift;

    push @{ $self->{cur_list} }, new XML::Grove::Characters (Data => "\n");
}

sub external_entity_decl {
    my $self = shift;

    my $ext_entity = new XML::Grove::Entity::External (@_);
    my $notation = $ext_entity->{Notation};
    if (defined($notation) && !ref($notation)) {
	$ext_entity->{Notation} = $self->{Grove}{Notations}{$notation};
    }
    $self->{Grove}{Entities}{$ext_entity->{Name}} = $ext_entity;
}

sub subdoc_entity_decl {
    my $self = shift;

    my $ext_entity = new XML::Grove::Entity::SubDoc (@_);
    $self->{Grove}{Entities}{$ext_entity->{Name}} = $ext_entity;
}

sub external_sgml_entity_decl {
    my $self = shift;

    my $ext_entity = new XML::Grove::Entity::SGML (@_);
    $self->{Grove}{Entities}{$ext_entity->{Name}} = $ext_entity;
}

sub internal_entity_decl {
    my $self = shift;

    my $int_entity = new XML::Grove::Entity (@_);
    $self->{Grove}{Entities}{$int_entity->{Name}} = $int_entity;
}

sub external_entity_ref {
    my $self = shift;
    my $properties = shift;

    my $ext_entity = $self->{Grove}{Entities}{$properties->{Name}};
    if (defined $ext_entity) {
	push @{ $self->{cur_list} }, $ext_entity;
    } elsif (!defined $self->{'warn_undefined_entity'}{$properties->{Name}}) {
	$self->{'warn_undefined_entity'}{$properties->{Name}} = 1;
	$self->error ({ Message => "XML::Grove::Builder: external entity \`$properties->{Name}' not defined" });
    }
}

sub internal_entity_ref {
    my $self = shift;
    my $properties = shift;

    my $int_entity = $self->{Grove}{Entities}{$properties->{Name}};
    if (defined $int_entity) {
	push @{ $self->{cur_list} }, $int_entity;
    } elsif (!defined $self->{'warn_undefined_entity'}{$properties->{Name}}) {
	$self->{'warn_undefined_entity'}{$properties->{Name}} = 1;
	$self->error ({ Message => "XML::Grove::Builder: internal entity \`$properties->{Name}' not defined" });
    }
}

sub notation_decl {
    my $self = shift;

    my $notation = new XML::Grove::Notation (@_);
    $self->{Grove}{Notations}{$notation->{Name}} = $notation;
}

sub comment {
    my $self = shift;

    my $comment = new XML::Grove::Comment (@_);
    push @{ $self->{cur_list} }, $comment;
}

sub subdoc_start {
    my $self = shift;
    my $properties = shift;

    my $contents = [];
    $properties->{Contents} = $contents;

    my $subdoc = new XML::Grove::SubDoc ($properties);
    push @{ $self->{lists} }, $self->{cur_list};
    push @{ $self->{cur_list} }, $subdoc;
    $self->{cur_list} = $contents;
}

sub subdoc_end {
    my $self = shift;
    $self->{cur_list} = pop @{ $self->{lists} };
}

sub appinfo {
    my $self = shift;
    my $appinfo = shift;

    $self->{Grove}{AppInfo} = $appinfo->{AppInfo};
}

sub conforming {
    my $self = shift;

    $self->{Grove}{Conforming} = 1;
}

sub warning {
    my $self = shift;
    my $error = shift;

    push (@{ $self->{Grove}{Errors} }, $error);
}

sub error {
    my $self = shift;
    my $error = shift;

    push (@{ $self->{Grove}{Errors} }, $error);
}

sub fatal_error {
    my $self = shift;
    my $error = shift;

    push (@{ $self->{Grove}{Errors} }, $error);
}

1;

__END__

=head1 NAME

XML::Grove::Builder - PerlSAX handler for building an XML::Grove

=head1 SYNOPSIS

 use PerlSAXParser;
 use XML::Grove::Builder;

 $builder = XML::Grove::Builder->new();
 $parser = PerlSAXParser->new( Handler => $builder );

 $grove = $parser->parse( Source => [SOURCE] );

=head1 DESCRIPTION

C<XML::Grove::Builder> is a PerlSAX handler for building an XML::Grove.

C<XML::Grove::Builder> is used by creating a new instance of
C<XML::Grove::Builder> and providing it as the Handler for a PerlSAX
parser.  Calling `C<parse()>' on the PerlSAX parser will return the
grove built from that parse.

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), XML::Grove(3), PerlSAX.pod

Extensible Markup Language (XML) <http://www.w3c.org/XML>

=cut
