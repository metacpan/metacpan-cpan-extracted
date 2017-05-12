package Yahoo::Marketing::ConverterService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Yahoo::Marketing::Service/;


=head1 NAME

Yahoo::Marketing::ConverterService - an object that provides bulksheet converter functions.

=cut

=head1 SYNOPSIS

See EWS documentation online for available SOAP methods:

L<http://searchmarketing.yahoo.com/developer/docs/V7/reference/services/ConverterService.php>

Also see perldoc Yahoo::Marketing::Service for functionality common to all service modules.



=head2 new

Creates a new instance

=cut 


sub _add_account_to_header { return 1; } # force addition of account to header


1;
