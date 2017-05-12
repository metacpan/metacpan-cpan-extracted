package Zenoss::Router::Search;
use strict;

use Moose::Role;
requires '_router_request', '_check_args';

#**************************************************************************
# Attributes
#**************************************************************************
has SEARCH_LOCATION => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'zport/dmd/search_router',
    init_arg    => undef,
);

has SEARCH_ACTION => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'SearchRouter',
    init_arg    => undef,
);

#**************************************************************************
# Public Functions
#**************************************************************************
#======================================================================
# search_getLiveResults
#======================================================================
sub search_getLiveResults {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['query'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->SEARCH_LOCATION,
            action      => $self->SEARCH_ACTION,
            method      => 'getLiveResults',
            data        => [$args],
        }
    );
} # END search_getLiveResults

#======================================================================
# search_getAllResults
#======================================================================
sub search_getAllResults {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['query'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->SEARCH_LOCATION,
            action      => $self->SEARCH_ACTION,
            method      => 'getAllResults',
            data        => [$args],
        }
    );
} # END search_getAllResults

#======================================================================
# search_getSavedSearch
#======================================================================
sub search_getSavedSearch {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['searchName'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->SEARCH_LOCATION,
            action      => $self->SEARCH_ACTION,
            method      => 'getSavedSearch',
            data        => [$args],
        }
    );
} # END search_getSavedSearch

#======================================================================
# search_updateSavedSearch
#======================================================================
sub search_updateSavedSearch {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['searchName', 'queryString'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->SEARCH_LOCATION,
            action      => $self->SEARCH_ACTION,
            method      => 'updateSavedSearch',
            data        => [$args],
        }
    );
} # END search_updateSavedSearch

#======================================================================
# search_removeSavedSearch
#======================================================================
sub search_removeSavedSearch {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['searchName'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->SEARCH_LOCATION,
            action      => $self->SEARCH_ACTION,
            method      => 'removeSavedSearch',
            data        => [$args],
        }
    );
} # END search_removeSavedSearch

#======================================================================
# search_saveSearch
#======================================================================
sub search_saveSearch {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['queryString', 'searchName'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->SEARCH_LOCATION,
            action      => $self->SEARCH_ACTION,
            method      => 'saveSearch',
            data        => [$args],
        }
    );
} # END search_saveSearch

#======================================================================
# search_getAllSavedSearches
#======================================================================
sub search_getAllSavedSearches {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Route the request
    $self->_router_request(
        {
            location    => $self->SEARCH_LOCATION,
            action      => $self->SEARCH_ACTION,
            method      => 'getAllSavedSearches',
            data        => [$args],
        }
    );
} # END search_getAllSavedSearches

#**************************************************************************
# Package end
#**************************************************************************
no Moose;

1;

__END__

=head1 NAME

Zenoss::Router::Search - A JSON/ExtDirect interface to operations on searches

=head1 SYNOPSIS

    use Zenoss;
    my $api = Zenoss->connect(
        {
            username    => 'zenoss username',
            password    => 'zenoss password',
            url         => 'http://zenossinstance:8080',
        }
    );

    my $response = $api->search_getAllResults(
        {
            query   => '10.10.10.1'
        }
    );

=head1 DESCRIPTION

This module is NOT instantiated directly.  To call methods from this module create an
instance of L<Zenoss>.  This document serves as a resource of available Zenoss API
calls to L<Zenoss>.

Note, that use of this module is considered experimental!  Zenoss
hasn't documented these calls in the Public API JSON Docs, thus I've pieced together what I could
from reading their code.  Also, it would appear that this interface was
meant to be used for the UI only as some of the attributes returned are formatted
in HTML.

This module can be useful to search for meta information within a device.  For example, I couldn't
search for a specific interface (eth0) using the Zenoss::Router::Device module, but with Zenoss::Router::Search I can.

=head1 METHODS

The following is a list of available methods available for interaction with the Zenoss API.
Please take note of the argument requirements, defaults and return content.

The documentation for this module was mostly taken from the Zenoss JSON API docs.  Keep in mind
that their (Zenoss Monitoring System) programming is based around python, so descriptions such as 
dictionaries will be represented as hashes in Perl.

=head2 $obj->search_getLiveResults()

Returns IQuickSearchResultSnippets for the results of the query.

=over

=item ARGUMENTS

query (string) - Query to search.  Note this is like typing a query into the live search via the Zenoss UI.

=back

=over

=item REQUIRED ARGUMENTS

query

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

results: (dictionary) Search results

=back

=head2 $obj->search_getAllResults()

Returns ISearchResultSnippets for the results of the query.  It would appear that this returns less HTML.

=over

=item ARGUMENTS

query (string) - Query to search.  Note this is like typing a query into the live search via the Zenoss UI.

=back

=over

=item REQUIRED ARGUMENTS

query

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

total (integer): Number of results

results: (dictionary) Search results

=back

=head2 $obj->search_getSavedSearch()

Return query of saved search

=over

=item ARGUMENTS

searchName (string) - identifier of the search we are looking for

=back

=over

=item REQUIRED ARGUMENTS

searchName

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Saved Search / DirectResponse

=back

=head2 $obj->search_updateSavedSearch()

Updates the specified search with the new query

=over

=item ARGUMENTS

searchName (string) - name of the search we want to update

queryString (string) - value of the new query we are searching on

=back

=over

=item REQUIRED ARGUMENTS

searchName

queryString

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Saved Search / DirectResponse

=back

=head2 $obj->search_removeSavedSearch()

Removes the search specified by searchName

=over

=item ARGUMENTS

searchName (string) - name of the search we want to remove

=back

=over

=item REQUIRED ARGUMENTS

searchName

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Direct Response (Success/Failure?)

=back

=head2 $obj->search_saveSearch()

Adds this search to our collection of saved searches

=over

=item ARGUMENTS

searchName (string) - term we are searching for

queryString (string) - our query string's identifier

=back

=over

=item REQUIRED ARGUMENTS

searchName

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Direct Response (Success/Failure?)

=back

=head2 $obj->search_getAllSavedSearches()

Returns all the searches the logged in user can access

=over

=item ARGUMENTS

N/A

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

query = NONE

addManageSavedSearch = False

=back

=over

=item RETURNS

results: (dictionary) saved searches

=back

=head1 SEE ALSO

=over

=item *

L<Zenoss>

=item *

L<Zenoss::Response>

=back

=head1 AUTHOR

Patrick Baker E<lt>patricksbaker@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Patrick Baker E<lt>patricksbaker@gmail.comE<gt>

This module is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You can obtain the Artistic License 2.0 by either viewing the
LICENSE file provided with this distribution or by navigating
to L<http://opensource.org/licenses/artistic-license-2.0.php>.

=cut