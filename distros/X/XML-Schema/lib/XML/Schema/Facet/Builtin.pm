#============================================================= -*-perl-*-
#
# XML::Schema::Facet::Builtin
#
# DESCRIPTION
#   Definitions of the various facets that are built in to XML Schema.
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
#   $Id: Builtin.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Facet::Builtin;

use strict;
use base qw( XML::Schema::Facet );
use vars qw( $VERSION $DEBUG );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;


#========================================================================
# Fixable
#   Base class which adds the optional 'fixed' attribute.
#========================================================================

package XML::Schema::Facet::Fixable;
use base qw( XML::Schema::Facet );
use vars qw( @OPTIONAL );

@OPTIONAL  = qw( fixed );

sub fixed {
    my $self = shift;
    return $self->{ fixed } ? 1 : 0;
}


#========================================================================
# length
#   The length of a string in characters, the length of binary data in 
#   octets, or the length of a list in items.
#========================================================================

package XML::Schema::Facet::length;
use base qw( XML::Schema::Facet::Fixable );
use vars qw( $ERROR );

sub valid {
    my ($self, $instance, $type) = @_;
    my $value = $instance->{ value };
    my $length;

    if (ref $value eq 'ARRAY') {
	$length = scalar @$value;
	return $length == $self->{ value }
	    || $self->invalid("list has $length elements");
    }
    else {
	$length = length $value;
	return $length == $self->{ value }
	    || $self->invalid("string has $length characters");
    }
}


#========================================================================
# minLength
#   The minimum length of a string in characters, binary data in
#   octets, or a list in items.
#========================================================================

package XML::Schema::Facet::minLength;
use base qw( XML::Schema::Facet::Fixable );
use vars qw( $ERROR );

sub valid {
    my ($self, $instance, $type) = @_;
    my $value = $instance->{ value };
    my $length;

    if (ref $value eq 'ARRAY') {
	$length = scalar @$value;
	return $length >= $self->{ value } 
	    || $self->invalid("list has $length elements");
    }
    else {
	$length = length $value;
	return $length >= $self->{ value }
	    || $self->invalid("string has $length characters");
    }
}


#========================================================================
# maxLength
#   The maximum length of a string in characters, binary data in
#   octets, or a list in items.
#========================================================================

package XML::Schema::Facet::maxLength;
use base qw( XML::Schema::Facet::Fixable );
use vars qw( $ERROR );

sub valid {
    my ($self, $instance, $type) = @_;
    my $value = $instance->{ value };
    my $length;

    if (ref $value eq 'ARRAY') {
	$length = scalar @$value;
	return $length <= $self->{ value }
	    || $self->invalid("list has $length elements");
    }
    else {
	$length = length $value;
	return $length <= $self->{ value }
	    || $self->invalid("string has $length characters");
    }
}


#========================================================================
# pattern
#   Regular expression pattern.
#========================================================================

package XML::Schema::Facet::pattern;
use base qw( XML::Schema::Facet );

sub valid {
    my ($self, $instance, $type) = @_;

    return ($instance->{ value } =~ /$self->{ value }/)
	|| $self->invalid("string mismatch");
}


#========================================================================
# enumeration
#   Note: need to do numerical/string equality match based on underlying 
#   type.
#========================================================================

package XML::Schema::Facet::enumeration;
use base qw( XML::Schema::Facet );

sub init {
    my ($self, $config) = @_;
    
    $self->SUPER::init($config)
	|| return;

    # ensure value is folded to a list reference
    my $value = $self->{ value };
    $self->{ value } = [ $value ] 
	unless ref $value eq 'ARRAY';

    return $self
}

sub valid {
    my ($self, $instance, $type) = @_;
    my $value = $instance->{ value };
    my $allow = $self->{ value };

    foreach my $v (@$allow) {
	return 1 if $value eq $v;
    }
    local $" = "', '";
    return $self->error(
	$self->{ errmsg } || "string mismatch ('$value' not in: '@$allow')"
    );
}


#========================================================================
# whiteSpace
#   Rule for whitespace normalisation.  Value should be one of:
#     preserve: leave intact
#     replace:  replace newlines, carriage returns and tabs with spaces
#     collapse: as per replace, collapsing multiple whitespace into a 
#               single and stripping leading/trailing whitespaces
#========================================================================

package XML::Schema::Facet::whiteSpace;
use base qw( XML::Schema::Facet::Fixable );
use vars qw( $ERROR );

sub init {
    my ($self, $config) = @_;

    $self->SUPER::init($config)
	|| return;

    return $self->{ value } =~ /^preserve|replace|collapse$/
	? $self
	: $self->error('value must be one of: preserve, replace, collapse')
}

sub valid {
    my ($self, $instance, $type) = @_;
    my $action = $self->{ value };
    return 1 if $action eq 'preserve';

    for ($instance->{ value }) {
	s/[\r\n\t]/ /g;
	if ($action eq 'collapse') {
	    s/ +/ /g;
	    s/^ +//;
	    s/ +$//;
	}
    }
    return 1;
}


#========================================================================
# maxInclusive
#   Constrain a value to be within an inclusive upper bound.  
#========================================================================

package XML::Schema::Facet::maxInclusive;
use base qw( XML::Schema::Facet::Fixable );
use vars qw( $ERROR );

sub valid {
    my ($self, $instance, $type) = @_;
    return $instance->{ value } <= $self->{ value }
        || $self->invalid("value is $instance->{ value }");
}


#========================================================================
# maxExclusive
#   Constrain a value to be within an exclusive upper bound.  
#========================================================================

package XML::Schema::Facet::maxExclusive;
use base qw( XML::Schema::Facet::Fixable );
use vars qw( $ERROR );

sub valid {
    my ($self, $instance, $type) = @_;
    return $instance->{ value } < $self->{ value }
        || $self->invalid("value is $instance->{ value }");
}


#========================================================================
# minInclusive
#   Constrain a value to be within an inclusive upper bound.  
#========================================================================

package XML::Schema::Facet::minInclusive;
use base qw( XML::Schema::Facet::Fixable );
use vars qw( $ERROR );

sub valid {
    my ($self, $instance, $type) = @_;
    return $instance->{ value } >= $self->{ value }
        || $self->invalid("value is $instance->{ value }");
}


#========================================================================
# minExclusive
#   Constrain a value to be within an exclusive upper bound.  
#========================================================================

package XML::Schema::Facet::minExclusive;
use base qw( XML::Schema::Facet::Fixable );
use vars qw( $ERROR );

sub valid {
    my ($self, $instance, $type) = @_;
    return $instance->{ value } > $self->{ value }
        || $self->invalid("value is $instance->{ value }");
}


#========================================================================
# precision
#========================================================================

package XML::Schema::Facet::precision;
use base qw( XML::Schema::Facet::Fixable );
use vars qw( $ERROR );

sub valid {
    my ($self, $instance, $type) = @_;
    return $instance->{ precision } <= $self->{ value }
        || $self->invalid("value is $instance->{ value }");
}


#========================================================================
# scale
#========================================================================

package XML::Schema::Facet::scale;
use base qw( XML::Schema::Facet::Fixable );
use vars qw( $ERROR );

sub valid {
    my ($self, $instance, $type) = @_;
    return $instance->{ scale } <= $self->{ value }
        || $self->invalid("value is $instance->{ value }");
}


#========================================================================
# encoding
#========================================================================

package XML::Schema::Facet::encoding;
use base qw( XML::Schema::Facet::Fixable );
use vars qw( $ERROR );

sub init {
    my ($self, $config) = @_;

    $self->SUPER::init($config)
	|| return;

    return $self->{ value } =~ /^hex|base64$/
	? $self
	: $self->error("encoding value must be 'hex' or 'base64'")
}


#========================================================================
# duration
#========================================================================

package XML::Schema::Facet::duration;
use base qw( XML::Schema::Facet::Fixable );
use vars qw( $ERROR $TYPE );

sub init {
    my ($self, $config) = @_;
    $self->SUPER::init($config)
	|| return;
    $TYPE ||= XML::Schema::Type::timeDuration->new();
    $self->{ value } = $TYPE->instance($self->{ value })
	|| return $self->error('duration ' . $TYPE->error());
    return $self;
}

# custom install method which installs duration in the facet hash but not
# the runtime list because it doesn't have validation rules.

sub install {
    my ($self, $facets, $table) = @_;
#    $self->DEBUG("partially installing $self into type as $self->{ name }\n");
    $table->{ $self->{ name } } = $self;
    return 1;
}


#========================================================================
# period
#========================================================================

package XML::Schema::Facet::period;
use base qw( XML::Schema::Facet::Fixable );
use vars qw( $ERROR $TYPE );

sub init {
    my ($self, $config) = @_;
    $self->SUPER::init($config)
	|| return;
    $TYPE ||= XML::Schema::Type::timeDuration->new();
    $self->{ value } = $TYPE->instance($self->{ value })
	|| return $self->error('period ' . $TYPE->error());
    return $self;
}

# as per duration

sub install {
    my ($self, $facets, $table) = @_;
#    $self->DEBUG("partially installing $self into type as $self->{ name }\n");
    $table->{ $self->{ name } } = $self;
    return 1;
}



1;
__END__

=head1 NAME

XML::Schema::Facet::Builtin

=head1 SYNOPSIS

    use XML::Schema::Facet::Builtin;

    my $facet = XML::Schema::Facet::length->new(value => 22);
    my $value = 'The cat sat on the mat';

    print $facet->valid(\$value) ? "valid" : "invalid";

=head1 DESCRIPTION

The XML::Schema::Facet::Builtin module defines facets which are built in
to XML Schema.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.1.1.1 $ of the XML::Schema::Facet::Builtin
distributed with version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also L<XML::Schema> and L<XML::Schema::Facet>.

