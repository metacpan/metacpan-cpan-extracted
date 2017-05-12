package Yahoo::Marketing::UserManagementService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Yahoo::Marketing::Service/;


=head1 NAME

Yahoo::Marketing::UserManagementService - provides operations for user, authorization, and payment method management. 

Operations that include the word "my" can be executed by any user but only to add, get, or update their own user information. User name and password are included in the SOAP header for the request. 

Operations that include the word "user" can be executed by an administrator for another user but only if the administrator has access to that user's information based on the admin's role and the account. 


=cut

=head1 SYNOPSIS

See EWS documentation online for available SOAP methods:

L<http://searchmarketing.yahoo.com/developer/docs/V7/reference/services/UserManagementService.php>

Also see perldoc Yahoo::Marketing::Service for functionality common to all service modules.




=head2 new

Creates a new instance

=cut 



1;
