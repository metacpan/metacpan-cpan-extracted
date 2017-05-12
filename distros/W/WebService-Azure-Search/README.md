# NAME

WebService::Azure::Search - Request Azure Search API

<div>
    <a href='https://coveralls.io/github/sys-cat/WebService-Azure-Search?branch=master'><img src='https://coveralls.io/repos/github/sys-cat/WebService-Azure-Search/badge.svg?branch=master' alt='Coverage Status' /></a>

    <a href='https://travis-ci.org/sys-cat/WebService-Azure-Search'><img src='https://travis-ci.org/sys-cat/WebService-Azure-Search.svg?branch=master' alt='Travis CI'></a>

    <a href='https://gitter.im/sys-cat/WebService-Azure-Search?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge'><img src='https://badges.gitter.im/sys-cat/WebService-Azure-Search.svg' alt='Gitter'></a>
</div>

# SYNOPSIS

    use WebService::Azure::Search;
    # new Azure::Search
    my $azure = WebServise::Azure::Search->new(
      service => 'SERVICENAME',
      index   => 'INDEXNAME',
      api     => 'APIKEY',
      admin   => 'ADMINKEY',
    );
    # Select AzureSearch.Support 'search', 'searchMode', 'searchFields', 'count' contexts.
    my $select = $azure->select(
      search        => 'SEARCHSTRING',
      searchMode    => 'any',
      searchFields  => 'FIELDNAME',
      count         => 'BOOL',
      skip          => 0,
      top           => 1,
      filter        => 'OData Statement.'
    );
    $select->run; # run Select Statement. return to hash reference.
    # Run Insert request
    my $insert = $azure->insert(@values); # '@search.action' statement is 'upload'.
    my $insert_result = $insert->run; # return hash reference.
    # Run Update request
    my $update = $azure->update(@values); # '@search.action' statement is 'merge'.
    my $update_result = $update->run; # return hash reference.
    # Run Delete request
    my $delete = $azure->delete(@values); # '@search.action' statement is 'delete'.
    my $delete_result = $delete->run; # return hash reference.

# DESCRIPTION

WebService::Azure::Search is perform DML against AzureSearch.

# LICENSE

Copyright (C) sys\_cat.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

sys\_cat &lt;systemcat91@gmail.com>
