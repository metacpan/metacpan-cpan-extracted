package Yahoo::Marketing::ExcludedWordsService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Yahoo::Marketing::Service/;


=head1 NAME

Yahoo::Marketing::ExcludedWordsService - an object that provides operations for adding, deleting, and viewing excluded words at the account and ad group level. Excluded words are words or phrases that you want to exclude from the matching process when Advanced Match is enabled.

=cut

=head1 SYNOPSIS


See EWS documentation online for available SOAP methods:

http://searchmarketing.yahoo.com/developer/docs/V7/reference/services/ExcludedWordsService.php

Also see perldoc Yahoo::Marketing::Service for functionality common to all service modules.




=head2 new

Creates a new instance

=cut 

sub _add_account_to_header { return 1; } # force addition of


1;
