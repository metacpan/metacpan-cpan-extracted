package WebService::Azure::Search;
use 5.008001;
use strict;
use warnings;
use utf8;

use JSON;
use HTTP::Request;
use HTTP::Headers;
use LWP::UserAgent;
use URI;
use Try::Tiny;
use Carp;
use Encode 'encode';

our $VERSION = "0.04";

sub new {
  my ($class, %opts) = @_;
  my $self = bless {%opts}, $class;
  $self->_init($self);
}

sub _init {
  my ($self) = @_;
  $self->{setting} = +{
    base => undef,
    index => undef,
    api => undef,
    admin => undef,
  };

  if ($self->{service}) {
    $self->{setting}{base} = sprintf("https://%s.search.windows.net", $self->{service});
  }

  if ($self->{index}) {
    $self->{setting}{index} = $self->{index};
  }

  if ($self->{api}) {
    $self->{setting}{api} = $self->{api};
  }

  if ($self->{admin}) {
    $self->{setting}{admin} = $self->{admin};
  }

  $self->{params}{accept} = "application/json";

  try {
    $self->{params}{url} = sprintf(
      "%s/indexes/%s/docs/index?api-version=%s",
      $self->{setting}{base},
      $self->{setting}{index},
      $self->{setting}{api}
    );
    return $self;
  } catch {
    carp "can't create request url.detail : $_";
  };
}

# select, insert, update, delete Method only make parameters.
sub select {
  my ($self, %params) = @_;
  $self->{params} = {};
  $self = $self->_init($self->{setting});
  my $params = +{%params};

  # Set value
  $self->{params}{query}{search} = undef;
  if ($params->{search}) {
    $self->{params}{query}{search} = $params->{search};
  }
  $self->{params}{query}{searchMode} = "any"; # default is 'any'
  if ($params->{searchMode}) {
    $self->{params}{query}{searchMode} = $params->{searchMode};
  }
  $self->{params}{query}{searchFields} = undef;
  if ($params->{searchFields}) {
    $self->{params}{query}{searchFields} = $params->{searchFields};
  }
  $self->{params}{query}{count} = "false";
  if ($params->{count}) {
    $self->{params}{query}{count} = $params->{count};
  }
  $self->{params}{query}{skip} = 0; # default is 0
  if ($params->{skip}) {
    $self->{params}{query}{skip} = $params->{skip};
  }
  $self->{params}{query}{top} = 50; # default is 50
  if ($params->{top}) {
    $self->{params}{query}{top} = $params->{top};
  }
  if ($params->{filter}) { # filter is optional
    $self->{params}{query}{filter} = $params->{filter};
  }

  $self->{params}{url} = undef;
  try {
    # Create URL for SELECT
    $self->{params}{url} = sprintf(
      "%s/indexes/%s/docs/search?api-version=%s",
      $self->{setting}{base},
      $self->{setting}{index},
      $self->{setting}{api},
    );
  } catch {
    carp "cant't create request url for SELECT. detail : $_";
  };
  return $self;
}

sub insert {
  my ($self, $params) = @_;
  $self->{params} = {};
  $self = $self->_init($self->{setting});
  for(my $count=0;$count<@$params;$count++) {
    $params->[$count]->{'@search.action'} = 'upload';
  }
  $self->{params}{query}{value} = $params;
  return $self;
}

sub update {
  my ($self, $params) = @_;
  $self->{params} = {};
  $self = $self->_init($self->{setting});
  for(my $count=0;$count<@$params;$count++) {
    $params->[$count]->{'@search.action'} = 'merge';
  }
  $self->{params}{query}{value} = $params;
  return $self;
}

sub delete {
  my ($self, $params) = @_;
  $self->{params} = {};
  $self = $self->_init($self->{setting});
  for(my $count=0;$count<@$params;$count++) {
    $params->[$count]->{'@search.action'} = 'delete';
  }
  $self->{params}{query}{value} = $params;
  return $self;
}

# Only http request.
sub run {
  my ($self) = @_;
  my $bless_query = $self->{params}{query};
  try {
    my $hashref = {%$bless_query};
    my $json_query = JSON->new->encode($hashref);
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new('POST' => $self->{params}{url});
    $req->content_type('application/json');
    $req->header('api-key' => $self->{setting}{admin});
    $req->content($json_query);
    return JSON->new->utf8->decode($ua->request($req)->content);
  } catch {
    carp "can't access AzureSearch.detail: $_";
    return undef;
  }
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Azure::Search - Request Azure Search API

=begin html

<a href='https://coveralls.io/github/sys-cat/WebService-Azure-Search?branch=master'><img src='https://coveralls.io/repos/github/sys-cat/WebService-Azure-Search/badge.svg?branch=master' alt='Coverage Status' /></a>

<a href='https://travis-ci.org/sys-cat/WebService-Azure-Search'><img src='https://travis-ci.org/sys-cat/WebService-Azure-Search.svg?branch=master' alt='Travis CI'></a>

<a href='https://gitter.im/sys-cat/WebService-Azure-Search?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge'><img src='https://badges.gitter.im/sys-cat/WebService-Azure-Search.svg' alt='Gitter'></a>

=end html

=head1 SYNOPSIS

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

=head1 DESCRIPTION

WebService::Azure::Search is perform DML against AzureSearch.

=head1 LICENSE

Copyright (C) sys_cat.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sys_cat E<lt>systemcat91@gmail.comE<gt>

=cut

