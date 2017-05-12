#============================================================= -*-perl-*-
#
# XML::Schema::Wildcard.pm
#
# DESCRIPTION
#   Module implementing an object to represent wildcards.  A wildcard
#   allows for specification and validation of items based on their
#   namespace rather than any local definition.
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
#   $Id: Wildcard.pm,v 1.1 2001/12/20 13:26:27 abw Exp $
#
#========================================================================

package XML::Schema::Wildcard;

use strict;

use XML::Schema::Base;

use base qw( XML::Schema::Base );
use XML::Schema::Constants qw( :wildcard );
use vars qw( $VERSION $DEBUG $ERROR @MANDATORY @OPTIONAL );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

# @MANDATORY = qw( name ); 
@OPTIONAL  = qw( annotation );


#------------------------------------------------------------------------
# build regexen to match valid process values
#------------------------------------------------------------------------

my @PROCESS_OPTS  = ( SKIP, LAX, STRICT );
my $PROCESS_REGEX = join('|', @PROCESS_OPTS);
   $PROCESS_REGEX = qr/^$PROCESS_REGEX$/;



#------------------------------------------------------------------------
# init()
#
# Initiliasation method called by base class new() constructor.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    my ($namespace, $select, $process);

    $self->init_mandopt($config)
	|| return;

    # look for the various options which can be used to specify
    # the namespace(s)

    if ($config->{ any } || $config->{ namespace } 
	                 && $config->{ namespace } eq ANY) {
	$select = ANY;
    }
    elsif ($namespace = $config->{ not }) {
	$select = NOT;
    }
    elsif ($namespace = $config->{ namespace }) {
	$namespace = [ $namespace ] unless ref $namespace eq 'ARRAY';
	if ($namespace->[0] eq NOT) {
	    ($select, $namespace) = @$namespace;
	}
	else {
	    $select = ONE;
	    $namespace = { map { ($_, 1) } @$namespace };
	}
    }
    else {
        return $self->error('no namespace specified');
    }

    # determine or default the process mode
    $process = $config->{ process } || SKIP;
    return $self->error_value('wildcard process', $process, @PROCESS_OPTS)
	    unless $process =~ $PROCESS_REGEX;

    $self->{ select    } = $select;
    $self->{ process   } = $process;
    $self->{ namespace } = $namespace;

    $self->DEBUG("wildcard [$select] [$namespace] [$process]\n") if $DEBUG;

    return $self;
}


sub select {
    my $self = shift;
    return $self->{ select };
}

sub process {
    my $self = shift;
    return $self->{ process };
}


sub namespace {
    my $self = shift;
    return $self->{ namespace };
}


#------------------------------------------------------------------------
# accept($value)
#
# Return a true (1) or false (0) value depending on whether or not the
# namespace of the item passed as $value is acceptable according to the 
# defined namespace contraints for the wildcard.
#------------------------------------------------------------------------

sub accept {
    my ($self, $value) = @_;
    my $namespace;

    # anything goes?
    my $select = $self->{ select };
    return 1 if $select eq ANY;

    # extract namespace from candidate
    $value =~ s/^(?:([a-zA-Z_][\w\-.]*):)?(.*)$/$2/;
    $namespace = $1;

    # denied?
    if ($select eq NOT) {
	my $own = $self->{ namespace };
	if ($own) {
	    return 1 if ! $namespace || $namespace ne $own;
	    return 0;
	}
	else {
	    return defined $namespace ? 1 : 0;
	}
    }
	    
    # assume select = ONE
    return 0 unless $namespace;

    $self->DEBUG("matching [$namespace] against [", 
		 join(', ', keys %{ $self->{ namespace } }), "]\n")
	if $DEBUG;

    return $self->{ namespace }->{ $namespace } ? 1 : 0;
}

    


1;

__END__

