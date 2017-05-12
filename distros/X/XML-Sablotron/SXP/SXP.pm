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

package XML::Sablotron::SXP;

#require 5.005_62;
use strict;
use Carp;

use XML::Sablotron;

require Exporter;
require DynaLoader;

use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT );
@ISA = qw(Exporter DynaLoader);

# This allows declaration	
#        use XML::Sablotron::SXP ':all';
# If you do not need this, moving things directly into @EXPORT or 
# @EXPORT_OK will save memory.
my @_functions = qw ( 
		      );

my @_constants_sxp = qw ( NAMESPACE_NODE

		      SXP_NONE SXP_NUMBER SXP_STRING SXP_BOOLEAN
		      SXP_NODESET

		      SXPF_DISPOSE_NAMES SXPF_DISPOSE_VALUES
		      SXPF_SUPPORTS_UNPARSED_ENTITIES
		      );

my @_constants_dom = qw ( ELEMENT_NODE ATTRIBUTE_NODE TEXT_NODE
		      PROCESSING_INSTRUCTION_NODE COMMENT_NODE 
		      DOCUMENT_NODE
		      );

%EXPORT_TAGS = ( 'all'       => [ @_constants_dom, @_constants_sxp, @_functions ],
		 'constants' => [ @_constants_dom, @_constants_sxp ],
		 'constants_sxp' => \@_constants_sxp ,
		 'functions' => \@_functions,
		 );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw( 
	      );


#############################################################
#############################################################

# constants for node types, must match to SXP_NodeType
use constant ELEMENT_NODE                => 1;
use constant ATTRIBUTE_NODE              => 2;
use constant TEXT_NODE                   => 3;
use constant PROCESSING_INSTRUCTION_NODE => 7;
use constant COMMENT_NODE                => 8;
use constant DOCUMENT_NODE               => 9;
use constant NAMESPACE_NODE              => 13;    

# constants for expression types, must match to SXP_ExpressionType
use constant SXP_NONE                    => 0;
use constant SXP_NUMBER                  => 1;
use constant SXP_STRING                  => 2;
use constant SXP_BOOLEAN                 => 3;
use constant SXP_NODESET                 => 4;

# option constants SXPFlags
use constant SXPF_DISPOSE_NAMES              => 1;
use constant SXPF_DISPOSE_VALUES             => 2;
use constant SXPF_SUPPORTS_UNPARSED_ENTITIES => 4;

1;

############################################################





__END__
