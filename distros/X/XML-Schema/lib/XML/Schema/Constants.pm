#============================================================= -*-perl-*-
#
# XML::Schema::Constants.pm
#
# DESCRIPTION
#   Module defining constants for XML::Schema
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
#   $Id: Constants.pm,v 1.2 2001/12/20 13:26:27 abw Exp $
#
#========================================================================

package XML::Schema::Constants;

use strict;
use Exporter;
use base qw( Exporter );
use vars qw( $VERSION @EXPORT_OK %EXPORT_TAGS );

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

use constant UNBOUNDED  => 'unbounded';

use constant OPTIONAL   => 'optional';
use constant REQUIRED   => 'required';
use constant PROHIBITED => 'prohibited';

use constant FIXED      => 'fixed';
use constant DEFAULT    => 'default';

use constant SKIP       => 'skip';
use constant LAX        => 'lax';
use constant STRICT     => 'strict';

use constant ANY        => 'any';
use constant ONE        => 'one';
use constant NOT        => 'not';

my @OCCURS   = qw( UNBOUNDED ); 
my @ATTRIBS  = qw( FIXED DEFAULT OPTIONAL REQUIRED PROHIBITED );
my @PROCESS  = qw( SKIP LAX STRICT ); 
my @SELECT   = qw( ANY ONE NOT );

@EXPORT_OK   =   ( @OCCURS, @ATTRIBS, @PROCESS, @SELECT );
%EXPORT_TAGS = (
    'all'      => [ @EXPORT_OK ],
    'occurs'   => [ @OCCURS    ],
    'attribs'  => [ @ATTRIBS   ],
    'process'  => [ @PROCESS   ],
    'select'   => [ @SELECT    ],
    'wildcard' => [ @PROCESS, @SELECT ],
);


1;


