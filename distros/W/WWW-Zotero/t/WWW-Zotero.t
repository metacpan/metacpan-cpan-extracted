#!perl

use strict;
use warnings;
use Test::More;

my $key = $ENV{ZOTERO_API_KEY};

#	use Log::Any::Adapter;
#	use Log::Log4perl;
#	Log::Any::Adapter->set('Log4perl');
#	Log::Log4perl::init('./log4perl.conf');

BEGIN {
    use_ok 'WWW::Zotero';
}

require_ok 'WWW::Zotero';

my $client = WWW::Zotero->new(modified_since => time, key => $key);

ok $client , 'got a client';

if ($ENV{RELEASE_TESTING}) {
	{
		my $userID = $client->username2userID('hochstenbach');
		is $userID , '686898', 'username2userID - got an ID';
	}

	{
		my $data = $client->itemTypes();

		is ref($data), 'ARRAY' , 'itemTypes - got an array';
		ok @$data > 0 , 'itemTypes - got an array > 0';
	}

	sleep 1;

	{
		my $data = $client->itemFields();

		is ref($data), 'ARRAY' , 'itemFields - got an array';
		ok @$data > 0 , 'itemFields - got an array > 0';
	}

	sleep 1;

	{
		my $data = $client->itemTypeFields('book');

		is ref($data), 'ARRAY' , 'itemTypeFields - got an array';
		ok @$data > 0 , 'itemTypeFields - got an array > 0';
	}

	sleep 1;

	{
		my $data = $client->itemTypeCreatorTypes('book');

		is ref($data), 'ARRAY' , 'itemTypeCreatorTypes - got an array';
		ok @$data > 0 , 'itemTypeCreatorTypes - got an array > 0';
	}

	sleep 1;

	{
		my $data = $client->creatorFields();

		is ref($data), 'ARRAY' , 'creatorFields - got an array';
		ok @$data > 0 , 'creatorFields - got an array > 0';
	}

	sleep 1;

	{
		my $data = $client->itemTemplate('book');

		is ref($data), 'HASH' , 'itemTemplate - got a hash';
		ok keys %$data > 0 , 'itemTemplate - got a hash with content';
	}

	sleep 1;
	
    if ($ENV{ZOTERO_API_KEY}) {
		my $key = $client->keyPermissions();

		is ref($key), 'HASH' , 'keyPermissions - got a hash';
		ok keys %$key > 0 , 'keyPermissions - got a hash with content';

		my $userID = $key->{userID};

		ok $userID , 'got a userid';

		my $groups = $client->userGroups($userID);

		is ref($groups), 'ARRAY' , 'userGroups - got an array';
		ok @$groups > 0 , 'userGroups - got a array with content';
	}

	sleep 1;

	{
		my $data = $client->listItems(user => '475425', limit => 5);

		is ref($data) , 'HASH' , 'listItems - got a hash';
		ok $data->{total} , 'listItems - got a total';
		ok @{$data->{results}} > 0 , 'listItems - got a result';
	}

	sleep 1;

	{
		my $data = $client->listItems(user => '475425', format => 'atom');

		is ref($data) , 'HASH' , 'listItems - got a hash';
		ok $data->{total} , 'listItems - got a total';
		like $data->{results} , qr/.*<\?xml version="1.0" encoding="UTF-8"\?>.*/ , 'atom reponse';
	}

	sleep 1;

	{
		my $generator = $client->listItems(user => '475425', generator => 1);

		is ref($generator) , 'CODE' , 'listItems - got a generator';

		my $result = $generator->();

		is ref($result) , 'HASH' , 'listItems - read one from the generator';

		ok $result->{_id} , 'result has an _id';
	}

	sleep 1;

	{
		my $data = $client->listItemsTop(user => '475425', limit => 5);

		is ref($data) , 'HASH' , 'listItems - got a hash';
		ok $data->{total} , 'listItems - got a total';
		ok @{$data->{results}} > 0 , 'listItems - got a result';
	}

	sleep 1;

	{
		my $data = $client->listItemsTrash(user => '475425');

		is ref($data) , 'HASH' , 'listItems - got a hash';
		ok $data->{total} >= 0 , 'listItems - got a total';
	}

	sleep 1;

	{
		my $data = $client->getItem(user => '475425', itemKey => 'TTJFTW87');

		is ref($data) , 'HASH' , 'getItem - got a hash';
	}

	sleep 1;

	{
		my $data = $client->getItemTags(user => '475425', itemKey => 'X42A7DEE');

		is ref($data) , 'ARRAY' , 'getItemTags - got an array';
	}

	sleep 1;

	{
		my $data = $client->listTags(user => '475425');

		is ref($data) , 'HASH' , 'listTags - got a hash';
		ok $data->{total} , 'listTags - got a total';
		ok @{$data->{results}} > 0 , 'listTags - got a result';
	}

	sleep 1;

	{
		my $data = $client->listTags(user => '475425', tag => 'Biography');

		is ref($data) , 'HASH' , 'listTags(Biography) - got a hash';
		ok $data->{total} , 'listTags(Biography) - got a total';
		ok @{$data->{results}} > 0 , 'listTags(Biography) - got a result';
	}

	sleep 1;

	{
		my $data = $client->listCollections(user => '475425');

		is ref($data) , 'HASH' , 'listCollections - got a hash';
		ok $data->{total} , 'listCollections - got a total';
		ok @{$data->{results}} > 0 , 'listCollections - got a result';
	}

	sleep 1;

	{
		my $data = $client->listCollectionsTop(user => '475425');

		is ref($data) , 'HASH' , 'listCollectionsTop - got a hash';
		ok $data->{total} , 'listCollectionsTop - got a total';
		ok @{$data->{results}} > 0 , 'listCollectionsTop - got a result';
	}

	sleep 1;

	{
		my $data = $client->getCollection(user => '475425', collectionKey => 'A5G9W6AX');

		is ref($data) , 'HASH' , 'getCollection - got a hash';
	}

	sleep 1;

	{
		my $data = $client->listSubCollections(user => '475425', collectionKey => 'QM6T3KHX');

		is ref($data) , 'HASH' , 'listSubCollections - got a hash';
		ok $data->{total} , 'listCollectionsTop - got a total';
		ok @{$data->{results}} > 0 , 'listCollectionsTop - got a result';
	}

	sleep 1;

	{
		my $data = $client->listCollectionItems(user => '475425', collectionKey => 'QM6T3KHX');

		is ref($data) , 'HASH' , 'listCollectionItems - got a hash';
		ok $data->{total} , 'listCollectionItems - got a total';
		ok @{$data->{results}} > 0 , 'listCollectionItems - got a result';
	}

	sleep 1;

	{
		my $data = $client->listCollectionItemsTop(user => '475425', collectionKey => 'QM6T3KHX');

		is ref($data) , 'HASH' , 'listCollectionItemsTop - got a hash';
		ok $data->{total} , 'listCollectionItemsTop - got a total';
		ok @{$data->{results}} > 0 , 'listCollectionItemsTop - got a result';
	}

	sleep 1;

	{
		my $data = $client->listCollectionItemsTags(user => '475425', collectionKey => 'QM6T3KHX');

		is ref($data) , 'HASH' , 'listCollectionItemsTags - got a hash';
		ok $data->{total} , 'listCollectionItemsTags - got a total';
		ok @{$data->{results}} > 0 , 'listCollectionItemsTags - got a result';
	}

	sleep 1;

	{
		my $data = $client->listSearches(user => '475425');

		is ref($data) , 'HASH' , 'listSearches - got a hash';
		ok $data->{total} , 'listSearches - got a total';
		ok @{$data->{results}} > 0 , 'listSearches - got a result';
	}

	sleep 1;
}

done_testing;