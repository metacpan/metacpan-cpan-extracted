# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the XML::Sablotron module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2000 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s): Nicolas Trebst, science+computing ag
#                 n.trebst@science-computing.de
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 
#
#############################################################
#
# Situation object. This code is moved from Sablotron.pm
# 
#############################################################

package XML::Sablotron::Situation;

use strict;
use Carp;
use vars qw( @ISA @EXPORT_OK %EXPORT_TAGS @EXPORT );

require Exporter;
require DynaLoader;

use XML::Sablotron;

@ISA = qw( Exporter DynaLoader );

# This allows declaration	
#        use XML::Sablotron::Situation ':all';
# If you do not need this, moving things directly into @EXPORT or 
# @EXPORT_OK will save memory.
my @_functions = qw ( 
		      );

my @_constants = qw ( SAB_NO_ERROR_REPORTING
		      SAB_PARSE_PUBLIC_ENTITIES
		      SAB_DISABLE_ADDING_META
		     );

%EXPORT_TAGS = ( 'all'       => [ @_constants, @_functions ],
		 'constants' => \@_constants,
		 'functions' => \@_functions,
		 );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw( 
	      );


#############################################################
#############################################################

use constant SAB_NO_ERROR_REPORTING    => 0x1;
use constant SAB_PARSE_PUBLIC_ENTITIES => 0x2;
use constant SAB_DISABLE_ADDING_META   => 0x4;

my $_unique = 0;

sub new {
    my $class = shift;
    $class = ref $class || $class;
    my $self = {};
    bless $self, $class;
    $self->{_handle} = _getNewSituationHandle($class);
    return $self;
}


# Handler code is roughly based on processor handler
# stuff. There is only one handler type (yet), but a 
# handler for every situation.
sub regDOMHandler {
    my ($self, $ref) = @_;
    my ($wrapper, $ret);
    if ((ref $ref eq "HASH")) {
	$_unique ++;
	my $classname = "sablot_DOMhandler_$_unique";
	no strict 'refs';
	foreach (keys %$ref) {
	    *{"${classname}::$_"} = $$ref{$_};
	}
	use strict;
	$wrapper = bless {},$classname;
    } else {
	$wrapper = $ref;
    }
    
    $ret = 1;
    if ( ! ref $self->{DOMHandler} ) {
	if ( $wrapper->can('PreRegDOMHandler') ) {
	  $wrapper->PreRegDOMHandler($self);
	}
	$self->{DOMHandler} = $wrapper; 
	$self->_regDOMHandler( );
	if ( $wrapper->can('PostRegDOMHandler') ) {
	  $wrapper->PostRegDOMHandler($self);
	}
	$ret = 0;
    } else {
	XML::Sablotron::Common::_report_err("Trying to register another handler for this situation.");
      }

    return $ret;
}

sub unregDOMHandler {
    my ($self) = @_;
    my $ret = 1;

    if ( ref $self->{DOMHandler} ) {
        my $wrapper = $self->{DOMHandler};
	if ( $wrapper->can('PreUnregDOMHandler') ) {
	  $wrapper->PreUnregDOMHandler($self);
	}
       	$self->_unregDOMHandler( );
	delete $self->{DOMHandler};
	if ( ref $wrapper && $wrapper->can('PostUnregDOMHandler') ) {
	  $wrapper->PostUnregDOMHandler($self);
	}
	$ret = 0;
    } else {
	XML::Sablotron::Common::_report_err("No handler registered for this situation.");
      }
}

sub DESTROY {
    my $self = shift;
    
    $self->unregDOMHandler() if ref $self->{DOMHandler};

    $self->_releaseHandle();
}


1;


__END__

#
# Documentation left in Sablotron.pm
#
