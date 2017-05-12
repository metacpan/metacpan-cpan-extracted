#============================================================= -*-perl-*-
#
# XML::Schema::Parser
#
# DESCRIPTION
#   XML parser module which is bound to a particular Schema and/or
#   Schedule.
#
# AUTHOR
#   Andy Wardley <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2001 Canon Research Centre Europe Ltd.
#   All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: Parser.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Parser;

use strict;
use XML::Parser;
use XML::Schema::Base;
use base qw( XML::Schema::Base );
use vars qw( $VERSION $DEBUG $ERROR $ETYPE @OPTIONAL $XML_PARSER_ARGS );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';
$ETYPE   = 'parser';

@OPTIONAL = qw( schema );

$XML_PARSER_ARGS = {
    ErrorContext  => 2,
    Namespaces    => 1,
    ParseParamEnt => 1,
};


#------------------------------------------------------------------------
# init(\%config)
#
# Called by new() constructor method to initialise object.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    my ($opt) = @{ $self->_baseargs( qw( @OPTIONAL ) ) };

    $self->_optional($opt, $config)
	|| return;

    return $self;
}


#------------------------------------------------------------------------
# schema($schema)
# 
# Retrieve current schema or update with new reference provided.
#------------------------------------------------------------------------

sub schema {
    my $self = shift;
    return @_ ? ($self->{ schema } = shift)
	      :  $self->{ schema };
}


#------------------------------------------------------------------------
# parsefile($file)
#
# Parse XML file.
#------------------------------------------------------------------------

sub parsefile {
    my ($self, $file) = @_;
    my $parser = $self->parser()
	|| return;
    my $result;
    eval {
	$result = $parser->parsefile($file);
    };
    if (my $error = $@) {
	$error =~ s/\s*at \S+ line \d+\s*$//s;
	return $self->error($error);
    }
    return $result;
}


#------------------------------------------------------------------------
# parse($text)
#
# Parse XML text.
#------------------------------------------------------------------------

sub parse {
    my ($self, $text) = @_;
    my $parser = $self->parser()
	|| return;
    my $result;
    eval {
	$result = $parser->parse($text);
    };
    if (my $error = $@) {
	$error =~ s/\s*at \S+ line \d+\s*$//s;
	return $self->error($error);
    }
    return $result;
}


#------------------------------------------------------------------------
# parser($schema, \%args)
#
# Return underlying XML::Parser instance (possibly cached) properly 
# configured for action.
#------------------------------------------------------------------------

sub parser {
    my $self = shift;
    my $schema = shift 
	|| $self->{ schema } 
	|| return $self->error('no schema');
    my $args = $_[0] && ref($_[0]) eq 'HASH' ? shift : { @_ };

    my $instance = $schema->instance($args)
	|| return $self->error( $schema->error() );

    my $handlers = $instance->expat_handlers()	
	|| return $self->error( $schema->error() );

    # handlers can be returned as { Init => ..., etc } or as
    # { Style => ..., Handlers => { Init => ..., etc } }; we
    # convert the former to the latter and supply instance class
    # as the default Style (i.e. recipient of parse events)

    $handlers = {
	Style    => ref $instance,
	Handlers => $handlers,
    }
    unless $handlers->{ Handlers };    

    my $xpargs = {
	%$XML_PARSER_ARGS,
	map { defined $args->{$_} ? ( $_, $args->{$_} ) : ( ) }
	keys %$XML_PARSER_ARGS
    };
    return XML::Parser->new(
	%$xpargs,
	%$handlers,
    );
}

1;

__END__

=head1 NAME

XML::Schema::Parser - Parser module for XML::Schema 

=head1 SYNOPSIS

    use XML::Schema::Parser;

=head1 DESCRIPTION

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.1.1.1 $ of the XML::Schema module, distributed with
version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

For the latest version of the W3C XML Schema specification, see
http://www.w3c.org/TR/xmlschema-0/

