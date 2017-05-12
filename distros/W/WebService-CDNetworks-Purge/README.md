# NAME

WebService::CDNetworks::Purge - A client for the CDNetworks's Cache Flush Open API

# SYNOPSIS

        my $service = WebService::CDNetworks::Purge -> new(
                'username' => 'xxxxxxxx',
                'password' => 'yyyyyyyy',
        );

        my $listOfPADs = $service -> listPADs();

        my $purgeStatus = $service -> purgeItems('test.example.com', ['/a.html', '/images/b.png']);

        my $updatedStatus = $service -> status($purgeStatus -> [0] -> {'pid'}); 

# METHODS

## listPADs

Description: get the list of domains (or PADs) handled by user
Parameters: none
Returns: an array ref with the list of domains/PADs

## purgeItems

Description: Purges for a certain PAD/domain a list of paths.
If the list is two long it is split and the service is called with each chunk of paths.
Parameters: PAD/domain and an arrayref with the list of paths to purge
Returns: An array ref with the list of responses for each pack of paths.

## status

Description: Gets the current status of a certain purge request
Parameters: the purge request id
Returns: A hashref with the parsed JSON response from service

# AUTHOR

Jean Pierre Ducassou

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

# NO WARRANTY

This software is provided "as-is," without any express or implied warranty. In no event shall the author be held liable for any damages arising from the use of the software.
