#============================================================================
#
# Text::MetaText::Directive
#
# DESCRIPTION
#   A very simple MetaText directive class which is used as the default 
#   class (and is a suitable base class) for Directive objects created by 
#   the MetaText Factory object.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 1996-1998 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the terms of the Perl Artistic Licence.
#
#----------------------------------------------------------------------------
#
# $Id: Directive.pm,v 0.4 1998/09/01 12:59:37 abw Exp abw $
#
#============================================================================
 
package Text::MetaText::Directive;

use strict;
use vars qw( $VERSION $ERROR );

require 5.004;



#========================================================================
#                      -----  CONFIGURATION  -----
#========================================================================
 
$VERSION = sprintf("%d.%02d", q$Revision: 0.4 $ =~ /(\d+)\.(\d+)/);



#========================================================================
#                      -----  PUBLIC METHODS -----
#========================================================================
 
#========================================================================
#
# new(\%cfg)
#
# Module constructor.  A reference to a hash array is passed which is 
# simply blessed into the relevant class and returned.  This is an
# extremely simplistic construction process which relies on a well-
# defined relationship with the Factory class.  Derived classes may 
# easily extend the functionality of the constructor at this point.
#
# Returns a reference to a newly created Text::MetaText::Directive.
# Derived classes should return a reference to a sub-class of 
# Text::MetaText::Directive or undef on error.  If an error condition
# occurs, it should be reported using the private $self->_error() 
# method.  This makes the error message available to the calling 
# factory object via the error() package function.
#
#========================================================================

sub new {
    my $class  = shift;
    my $self   = shift;
    my %params = (
	HAS_CONDITION => [ qw( IF UNLESS ) ],
	HAS_POSTPROC  => [ qw( FORMAT FILTER ) ],
    );
    my ($key, $value);


    # check a parameter hash was supplied
    unless (defined $self) {
	$self->_error("Directive constructor expects a parameter hash");
	return undef;
    }

    # bless the hashref into the required class
    bless $self, $class;

    # the only thing we do to the new Directive is to examine its internals
    # and see which optimisation flags we need to set
    while (($key, $value) = each %params) {
	foreach (@$value) {
	    $self->{ $key } = 1, last
		if defined $self->{ $_ };
	}
    }

    $self;
}



#========================================================================
#
# error()
#
# Returns the value of the $ERROR package variable which may be undef 
# to indicate no current error condition.  May be called as a package 
# function or an object method 
#
#========================================================================

sub error {
    return $ERROR;
}



#========================================================================
#                     -----  PRIVATE METHODS -----
#========================================================================
 
#========================================================================
#
# sub _error($errmsg, @params) 
#
# Formats the error message format, $errmsg, and any additional parameters,
# @params with sprintf and sets $ERROR package variable with the resulting
# string.  The package variable, $ERROR, is used rather than an object
# member because the error reporting may have to deal with constructor
# failures where no object is returned.  May be called as a package 
# function or an object method.
#
#========================================================================

sub _error {
    my $self = shift;
    my $msg  = ref($self) ? shift : $self;

    $ERROR = defined($msg)
	? sprintf($msg, @_)
	: undef;
}



1;


=head1 NAME

Text::MetaText::Directive - MetaText Directive object class.

=head1 SYNOPSIS

    use Text::MetaText::Directive;
    my $directive = Text::MetaText::Directive->new(\%params);

=head1 DESCRIPTION

Objects of the Text::MetaText::Directive class are instantiated by the 
Text::MetaText::Factory class from within the Text::MetaText module.
The Factory and Directive classes can be sub-classed to create a more 
specific processing system.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

See also:

    http://www.kfs.org/~abw/

=head1 REVISION

$Revision: 0.4 $

=head1 COPYRIGHT

Copyright (c) 1996-1998 Andy Wardley.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify it 
under the terms of the Perl Artistic License.

=head1 SEE ALSO

For more information, see the main Text::MetaText documentation:

    perldoc Text::MetaText
    
For more information about the author and other Perl development work:

    http://www.kfs.org/~abw/
    http://www.kfs.org/~abw/perl/
    http://www.cre.canon.co.uk/perl/

For more information about Perl in general:

    http://www.perl.com/

=cut


