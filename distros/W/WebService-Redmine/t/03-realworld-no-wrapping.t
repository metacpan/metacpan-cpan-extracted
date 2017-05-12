use strict;
use warnings;

use Test::More;
use JSON::XS qw/encode_json/;

if ($ENV{REDMINER_DEVEL}) {
	plan tests => 5;
} else{
	plan skip_all => 'Development tests (REDMINER_DEVEL not set)';
}

eval 'use WebService::Redmine';

#
# Read API key from a simple config file in the format 'host;key'
#
my $host = '';
my $key  = '';
my $key_fname = $ENV{HOME} . '/.redminer/key';

if (!-e $key_fname) {
	BAIL_OUT('REDMINER_DEVEL set, but key file is not accessible');
}

open my $FH_key, '<', $key_fname;
my $key_data  = <$FH_key>;
($host, $key) = split /\s*;\s*/, $key_data;
chomp $key_data;
close $FH_key;

my $redminer = WebService::Redmine->new(
	host => $host,
	key  => $key,
	no_wrapper_object => 1,
);

my $project = $redminer->createProject({
	identifier => 'redminer-api-test',
	name       => 'RedMiner API test',
});
my $project_id = $project->{id};
ok(defined $project_id, 'New project created with internal ID ' . $project_id);

ok(!defined $redminer->createProject({
	identifier => 'redminer-api-test',
	name       => 'RedMiner API test',
}), 'Project already exists, error object is ' . JSON::XS::encode_json($redminer->errorDetails));

ok($redminer->updateProject($project_id, { inherit_members => 1 }), 'Project updated');

my $issue = $redminer->createIssue({
	project_id  => $project_id,
	subject     => 'Test issue for WebService::Redmine',
	description => 'Test description',
});
ok(defined $issue->{id}, 'Issue created with ID #' . $issue->{id});

ok($redminer->deleteProject($project_id), 'Project deleted');

exit;
