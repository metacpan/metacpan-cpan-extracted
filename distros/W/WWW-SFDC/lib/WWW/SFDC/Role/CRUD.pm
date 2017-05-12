package WWW::SFDC::Role::CRUD;
# ABSTRACT: Shared methods between partner and tooling APIs

use 5.12.0;
use strict;
use warnings;

our $VERSION = '0.37'; # VERSION

use Data::Dumper;
use List::NSect 'spart';
use Log::Log4perl ':easy';
use Method::Signatures;
use Scalar::Util 'blessed';
use SOAP::Lite;

use Moo::Role;
requires qw'_prepareSObjects';


method _queryMore ($locator) {
  return $self->_call(
    'queryMore',
    SOAP::Data->name(queryLocator => $locator),
  )->result;
}

# Extract the results from a $request. This handles the case
# where there is only one result, as well as 0 or more than 1.
# They require different handling because in the 1 case, you
# can't handle it as an array
method _getQueryResults ($request) {
  TRACE Dumper $request;
  return ref $request->{records} eq 'ARRAY'
    ? map {$self->_cleanUpSObject($_)} @{$request->{records}}
    : ( $self->_cleanUpSObject($request->{records}) );
}

# Unbless an SObject, and de-duplicate the ID field - SFDC
# duplicates the ID, which is interpreted as an arrayref!
method _cleanUpSObject ($obj) {
  return () unless $obj;
  my %copy = %$obj; # strip the class from $obj
  $copy{Id} = $copy{Id}->[0] if $copy{Id} and ref $copy{Id} eq "ARRAY";
  delete $copy{Id} unless $copy{Id};

  while (my ($key, $entry) = each %copy) {
    next unless blessed $entry;
    if (blessed $entry eq 'sObject') {
      $copy{$key} = $self->_cleanUpSObject($entry);
    } elsif (blessed $entry eq 'QueryResult') {
      $entry = [
        ref $entry->{records} eq 'ARRAY'
          ? map {$self->_cleanUpSObject($_)} @{$entry->{records}}
          : $self->_cleanUpSObject($entry->{records})
      ];
    }
  }

  return \%copy;
}

# Chain together calls to _queryMore() and handle the results.
method _completeQuery (
  :$query!,
  :$method!,
  :$callback = sub {state @results; push @results, @_; return @results}
) {

  INFO "Executing SOQL query: $query";

  my $result = $self->_call(
    $method,
    SOAP::Data->name(queryString => $query)
  )->result;

  my @results = $callback->($self->_getQueryResults($result));
  until ($result->{done} eq 'true') {
    $self->_sleep();
    $result = $self->_queryMore($result->{queryLocator});
    @results = $callback->($self->_getQueryResults($result));
  }

  return @results;
}

method query ($params) {
  return $self->_completeQuery(
    ref $params
      ? %$params
      : (query => $params),
    method => 'query'
  );
}

method queryAll ($params) {
  return $self->_completeQuery(
    ref $params
      ? %$params
      : (query => $params),
    method => 'queryAll'
  );

}


method create (@_) {
  return map {
    @{$self->_call(
      'create',
      $self->_prepareSObjects(@$_)
    )->results};
  } spart 200, @_;
}


method update (@_) {

  TRACE "Objects for update" => \@_;
  INFO "Updating objects";

  return @{$self->_call(
    'update',
    $self->_prepareSObjects(@_)
   )->results};
}


method delete (@_) {

    DEBUG "IDs for deletion" => \@_;
    INFO "Deleting objects";

    return @{$self->_call(
        'delete',
        map {SOAP::Data->name('ids' => $_)} @_
    )->results};
}


method undelete (@_) {

    DEBUG "IDs for undelete" => \@_;
    INFO "Deleting objects";

    return @{$self->_call(
        'undelete',
        map {SOAP::Data->name('ids' => $_)} @_
    )->results};
}


method retrieve (@_) {

    DEBUG "IDs for retrieve" => \@_;
    INFO "Retrieving objects";

    return @{$self->_call(
        'retrieve',
        map {SOAP::Data->name('ids' => $_)} @_
    )->results};
}




## see:
# http://stackoverflow.com/questions/7070553/soapdatabuilder-remove-xsinil-true-when-no-value-provided
# http://mkweb.bcgsc.ca/intranet/perlbook/perlnut/ch14_02.htm#INDEX-1888
# http://search.cpan.org/~byrne/SOAP-Lite-0.65_5/lib/SOAP/Serializer.pm#as_TypeName_SUBROUTINE_REQUIREMENTS

method SOAP::Serializer::as_nonil ($value, $name, $type, $attr) {
    delete $attr->{'xsi:nil'};
    return [ $name, $attr, $value ];
}

method describeGlobal () {

  return $self->_call(
    SOAP::Data->name("describeGlobal")
      ->uri($self->uri)
      ->type('nonil')
  )->result;
}


method describeSObjects (@names) {

  return map {
    $self->_call(
      'describeSObjects',
      @$_
    )->result;
  } spart 100, @names;

}
1;

__END__

=pod

=head1 NAME

WWW::SFDC::Role::CRUD - Shared methods between partner and tooling APIs

=head1 VERSION

version 0.37

=head1 DESCRIPTION

WWW::SFDC::Role::CRUD provides standard SObject manipulation methods which are
shared between the Partner and Tooling APIs.

=head1 METHODS

=head2 query

If the query() API call is incomplete and returns a queryLocator, this
library will continue calling queryMore() until there are no more records to
recieve, at which point it will return the entire list:

  say $_->{Id} for WWW::SFDC->new(...)->Partner->query($queryString);

OR:

Execute a callback for each batch returned as part of a query. Useful for
reducing memory usage and increasing efficiency handling huge queries:

  WWW::SFDC->new(...)->Partner->query({
    query => $queryString,
    callback => \&myMethod
  });

This will return the result of the last call to &myMethod.

=head2 queryAll

This has the same additional behaviour as query().

=head2 create

  say "$$_{id}:\t$$_{success}" for WWW::SFDC->new(...)->Partner->create(
    {type => 'thing', Field__c => 'bar', Name => 'baz'}
    {type => 'otherthing', Field__c => 'bas', Name => 'bat'}
  );

Create chunks your SObjects into 200s before calling create(). This means that if
you have more than 200 objects, you will incur multiple API calls.

=head2 update

  say "$$_{id}:\t$$_{success}" for WWW::SFDC::Partner->instance()->update(
    {type => 'thing', Id => 'foo', Field__c => 'bar', Name => 'baz'}
    {type => 'otherthing', Id => 'bam', Field__c => 'bas', Name => 'bat'}
  );

Returns an array that looks like [{success => 1, id => 'id'}, {}...] with LOWERCASE keys.

=head2 delete

  say "$$_{id}:\t$$_{success}" for WWW::SFDC::Partner->instance()->delete(@ids);

Returns an array that looks like [{success => 1, id => 'id'}, {}...] with LOWERCASE keys.

=head2 undelete

  say "$$_{id}:\t$$_{success}" for WWW::SFDC::Partner->instance()->undelete(@ids);

Returns an array that looks like [{success => 1, id => 'id'}, {}...] with LOWERCASE keys.

=head2 retrieve

Retrieves SObjects by ID. Not to be confused with the metadata retrieve method.

=head2 describeGlobal

Lists SObjects available through this API.

=head2 describeSObjects

Unimplemented

=head1 BUGS

Please report any bugs or feature requests at
L<https://github.com/sophos/WWW-SFDC/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::SFDC::Role::CRUD

You can also look for information at L<https://github.com/sophos/WWW-SFDC>

=head1 AUTHOR

Alexander Brett <alexander.brett@sophos.com> L<http://alexander-brett.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sophos Limited L<https://www.sophos.com/>.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
