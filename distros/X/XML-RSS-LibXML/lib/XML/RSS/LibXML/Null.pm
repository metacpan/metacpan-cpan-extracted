# $Id$
#
# Copyright (c) 2005-2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package XML::RSS::LibXML::Null;
use strict;
use warnings;
use base qw(XML::RSS::LibXML::ImplBase);

sub definition { +{} }

1;
