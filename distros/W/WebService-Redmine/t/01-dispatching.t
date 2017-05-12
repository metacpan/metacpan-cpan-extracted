use strict;
use warnings;

use Test::More tests => 29;

eval 'use WebService::Redmine';

#
# Testing internal name dispatching with a dummy object
#
my $redminer = WebService::Redmine->new(
	host => '', 
	key  => '',
);

my $r;

$r = $redminer->_dispatch_name;
ok(!defined $r, 'Must fail: undefined name');

$r = $redminer->_dispatch_name('read');
ok(!defined $r, 'Must fail: malformed name, no objects given');

$r = $redminer->_dispatch_name('readproject2');
ok(!defined $r, 'Must fail: malformed name, inappropriate object naming');

$r = $redminer->_dispatch_name('project', { id => 1 });
ok(!defined $r, 'Must fail: malformed object ID');

$r = $redminer->_dispatch_name('createProject');
ok(!defined $r, 'Must fail: malformed name, missing data argument for a create/update method');

$r = $redminer->_dispatch_name('updateProject', 1);
ok(!defined $r, 'Must fail: malformed name, missing data argument for a create/update method');

$r = $redminer->_dispatch_name('createProject', 1, 'scalar');
ok(!defined $r, 'Must fail: malformed name, inappropriate data type for a create/update method');

$r = $redminer->_dispatch_name('updateProject', 1, 'scalar');
ok(!defined $r, 'Must fail: malformed name, inappropriate data type for a create/update method');

#
# Testing basic CRUD API:
# * List existing objects (possibly with extra metadata)s
# * Read an object (possibly with extra metadata)
# * Create a new object
# * Update an existing object
# * Delete an existing object
#

$r = $redminer->_dispatch_name('projects', { limit => 10, offset => 9 });
is_deeply($r, {
	method => 'GET',
	path   => 'projects',
	content => undef,
	query   => { limit => 10, offset => 9 },
}, 'projects');

# ditto
$r = $redminer->_dispatch_name('Projects', { limit => 10, offset => 9 });
is_deeply($r, {
	method => 'GET',
	path   => 'projects',
	content => undef,
	query   => { limit => 10, offset => 9 },
}, 'projects');

# ditto
$r = $redminer->_dispatch_name('getProjects', { limit => 10, offset => 9 });
is_deeply($r, {
	method => 'GET',
	path   => 'projects',
	content => undef,
	query   => { limit => 10, offset => 9 },
}, 'projects');

# ditto
$r = $redminer->_dispatch_name('getprojects', { limit => 10, offset => 9 });
is_deeply($r, {
	method => 'GET',
	path   => 'projects',
	content => undef,
	query   => { limit => 10, offset => 9 },
}, 'projects');

# ditto
$r = $redminer->_dispatch_name('readProjects', { limit => 10, offset => 9 });
is_deeply($r, {
	method => 'GET',
	path   => 'projects',
	content => undef,
	query   => { limit => 10, offset => 9 },
}, 'projects');

# ditto
$r = $redminer->_dispatch_name('readprojects', { limit => 10, offset => 9 });
is_deeply($r, {
	method => 'GET',
	path   => 'projects',
	content => undef,
	query   => { limit => 10, offset => 9 },
}, 'projects');

$r = $redminer->_dispatch_name('project', 1);
is_deeply($r, {
	method => 'GET',
	path   => 'projects/1',
	content => undef,
	query   => undef,
}, 'project');

$r = $redminer->_dispatch_name('createProject', { project => { name => 'My Project' } });
is_deeply($r, {
	method => 'POST',
	path   => 'projects',
	content => { project => { name => 'My Project' } },
	query   => undef,
}, 'createProject');

$r = $redminer->_dispatch_name('updateProject', 1, { project => { name => 'My Project' } });
is_deeply($r, {
	method => 'PUT',
	path   => 'projects/1',
	content => { project => { name => 'My Project' } },
	query   => undef,
}, 'updateProject');

$r = $redminer->_dispatch_name('deleteProject', 1);
is_deeply($r, {
	method => 'DELETE',
	path   => 'projects/1',
	content => undef,
	query   => undef,
}, 'deleteProject');

#
# Dispatching methods with more than 1 identifying object:
#

$r = $redminer->_dispatch_name('projectMemberships', 1, { limit => 10, offset => 9 });
is_deeply($r, {
	method => 'GET',
	path   => 'projects/1/memberships',
	content => undef,
	query   => { limit => 10, offset => 9 },
}, 'projectMemberships');

$r = $redminer->_dispatch_name('createProjectMembership', 1, { membership => { user_id => 1, role_ids => [ 1 ] } });
is_deeply($r, {
	method => 'POST',
	path   => 'projects/1/memberships',
	content => { membership => { user_id => 1, role_ids => [ 1 ] } },
	query   => undef,
}, 'createProjectMembership');

$r = $redminer->_dispatch_name('createIssueWatcher', 1, { watcher => { user_id => 1 } });
is_deeply($r, {
	method => 'POST',
	path   => 'issues/1/watchers',
	content => { watcher => { user_id => 1 } },
	query   => undef,
}, 'createIssueWatcher');

$r = $redminer->_dispatch_name('deleteIssueWatcher', 1, 42);
is_deeply($r, {
	method => 'DELETE',
	path   => 'issues/1/watchers/42',
	content => undef,
	query   => undef,
}, 'deleteIssueWatcher');

#
# Dispatching methods with compound object names
#

$r = $redminer->_dispatch_name('timeEntries', { limit => 10, offset => 9 });
is_deeply($r, {
	method => 'GET',
	path   => 'time_entries',
	content => undef,
	query   => { limit => 10, offset => 9 },
}, 'timeEntries');

$r = $redminer->_dispatch_name('timeEntry', 1);
is_deeply($r, {
	method => 'GET',
	path   => 'time_entries/1',
	content => undef,
	query   => undef,
}, 'timeEntry');

$r = $redminer->_dispatch_name('createTimeEntry', { time_entry => { issue_id => 42, hours => 1 } });
is_deeply($r, {
	method => 'POST',
	path   => 'time_entries',
	content => { time_entry => { issue_id => 42, hours => 1 } },
	query   => undef,
}, 'createTimeEntry');

$r = $redminer->_dispatch_name('updateTimeEntry', 1, { time_entry => { issue_id => 42, hours => 1 } });
is_deeply($r, {
	method => 'PUT',
	path   => 'time_entries/1',
	content => { time_entry => { issue_id => 42, hours => 1 } },
	query   => undef,
}, 'updateTimeEntry');

$r = $redminer->_dispatch_name('deleteTimeEntry', 1);
is_deeply($r, {
	method => 'DELETE',
	path   => 'time_entries/1',
	content => undef,
	query   => undef,
}, 'deleteTimeEntry');

#
# Dispatching methods with more than 1 identifying object *and* compound object names:
#

$r = $redminer->_dispatch_name('projectIssueCategories', 1, { limit => 10, offset => 9 });
is_deeply($r, {
	method => 'GET',
	path   => 'projects/1/issue_categories',
	content => undef,
	query   => { limit => 10, offset => 9 },
}, 'projectIssueCategories');

$r = $redminer->_dispatch_name('createProjectIssueCategory', 1, { issue_category => { name => 'My Category', assign_to_id => 1 } });
is_deeply($r, {
	method => 'POST',
	path   => 'projects/1/issue_categories',
	content => { issue_category => { name => 'My Category', assign_to_id => 1 } },
	query   => undef,
}, 'projectIssueCategories');

exit;
