use strict;
use warnings;
use utf8;
use Test::More;
use WebService::Azure::Search;

my %init_params = (
  service => "service",
  index => "index",
  api => "api",
  admin => "admin",
);
my $azure = WebService::Azure::Search->new(%init_params);

subtest select => sub {
  #my $azure = WebService::Azure::Search->new(%init_params);
  my $select = $azure->select(
    search => "search strings",
    searchMode => "any",
    searchFields => "id, rid, sex",
    count => "true",
    skip => 1000,
    top => 50,
    filter => "id eq 1",
  );
  isa_ok $select, "HASH";
  my $query =  $select->{params}{query};
  is $query->{search}, "search strings";
  is $query->{searchMode}, "any";
  is $query->{searchFields}, "id, rid, sex";
  is $query->{count}, "true";
  is $query->{skip}, 1000;
  is $query->{top}, 50;
  is $query->{filter}, "id eq 1";
  is $select->{params}{url}, "https://service.search.windows.net/indexes/index/docs/search?api-version=api";
};

subtest insert => sub {
  #my $azure = WebService::Azure::Search->new(%init_params);
  my $insert = $azure->insert([
      {
        id => '1',
        rid => 'test',
      },
  ]);
  isa_ok $insert, "HASH";
  my $query = $insert->{params}{query}{value}->[0];
  is $query->{'@search.action'}, 'upload';
  is $query->{id}, '1';
  is $query->{rid}, 'test';
};

subtest update => sub {
  #my $azure = WebService::Azure::Search->new(%init_params);
  my $update = $azure->update([
      {
        id => '1',
        rid => 'test2',
      },
  ]);
  isa_ok $update, "HASH";
  my $query = $update->{params}{query}{value}->[0];
  is $query->{'@search.action'}, 'merge';
  is $query->{id}, '1';
  is $query->{rid}, 'test2';
};

subtest delete => sub {
  #my $azure = WebService::Azure::Search->new(%init_params);
  my $delete = $azure->delete([
      {
        id => '1',
        rid => 'test2',
      },
  ]);
  isa_ok $delete, "HASH";
  my $query = $delete->{params}{query}{value}->[0];
  is $query->{'@search.action'}, 'delete';
  is $query->{id}, '1';
  is $query->{rid}, 'test2';
};

done_testing();
