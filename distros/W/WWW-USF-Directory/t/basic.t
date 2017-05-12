#!/usr/bin/perl -T

use 5.008;
use lib 't/lib';
use strict;
use warnings 'all';

use Test::More 0.94 tests => 5;
use Test::Fatal;

use MyUA;
use WWW::USF::Directory;

# Install the UserAgent overrides
my $scope = MyUA->configuration->install_in_scope;

subtest 'Constructor' => sub {
	plan tests => 1;

	is(exception { WWW::USF::Directory->new }, undef, ' Empty constructor');
};

subtest 'Listing' => sub {
	plan tests => 3;

	# Create directory object
	my $directory = WWW::USF::Directory->new;

	is_deeply([sort $directory->campus_list    ], [sort @MyUA::campus_list    ], 'Get campus list'    );
	is_deeply([sort $directory->college_list   ], [sort @MyUA::college_list   ], 'Get college list'   );
	is_deeply([sort $directory->department_list], [sort @MyUA::department_list], 'Get department list');
};

subtest 'Search Exceptions' => sub {
	plan tests => 2;

	# Create directory object
	my $directory = WWW::USF::Directory->new;

	isa_ok(exception { $directory->search(name => $MyUA::TooManyResults_Name) },
		'WWW::USF::Directory::Exception::TooManyResults', 'Too many results exception');

	isa_ok(exception { $directory->search(name => $MyUA::UnknownResponse_Name) },
		'WWW::USF::Directory::Exception::UnknownResponse', 'Unknown response');
};

subtest 'Search no results' => sub {
	plan tests => 1;

	# Create directory object
	my $directory = WWW::USF::Directory->new;

	my @results = $directory->search(name => $MyUA::ZeroMatches_Name);
	is scalar(@results), 0, 'Search returned no results';
};

subtest 'Basic search' => sub {
	plan tests => 14;

	# Create directory object
	my $directory = WWW::USF::Directory->new;

	my @results = $directory->search(name => $MyUA::Matches_Name);
	is scalar(@results), 3, 'Search returned 3 results';

	# Get the first result
	my $result = shift @results;

	is $result->family_name, 'Barber', 'Family name is correct';
	is $result->given_name, 'Holly L.', 'Given name is correct';
	is $result->middle_name, 'L.', 'Middle name is correct';
	is $result->first_name, 'Holly', 'First name is correct';
	is $result->full_name, 'Holly L. Barber', 'Full name is correct';
	is $result->email, 'hbarber@mail.usf.edu', 'Email is correct';
	is $result->campus_phone, '+1 813 972 2000', 'Campus phone is correct';
	is $result->campus_mailstop, 'MDC20', 'Campus mailstop is correct';
	is $result->college, 'Arts and Sciences', 'College is correct';
	ok !$result->has_campus, 'Does not have a campus';
	is scalar(@{$result->affiliations}), 1, 'Has 1 affiliation';
	is $result->affiliations->[0]->role, 'Sr Laboratory Animal Tech', 'Affiliation role is correct';
	is $result->affiliations->[0]->department, 'Comparative Medicine', 'Affiliation department is correct';
};
