#!/usr/bin/env perl

# The <data> setting: one <driver> element for each data module, with a name,
# a description and optionally a directory, here or on <data> as a whole.  Without
# a directory the drivers are looked for in the databases directory (<databases>),
# then @INC.  The old <data_modules> string is still read.

use strict;
use warnings;

use Test::Most;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);

BEGIN {
	require lib;
	lib->import(File::Spec->catdir($Bin, File::Spec->updir(), 'lib'));
}

use Web::VWF;

sub modules
{
	return [map { { %{$_} } } Web::VWF->_data_modules(shift)];
}

sub summary
{
	return [map { join(' ', $_->{'name'}, $_->{'module'}, ($_->{'soft'} ? undef : $_->{'file'}) // '-') } Web::VWF->_data_modules(shift)];
}

# No databases directory means no data files, so no default driver
is_deeply(summary({}), [], 'no databases directory: no drivers');
is_deeply(summary({ databases => { directory => '/nonexistent/databases' } }), ['index Web::VWF::Data::index -'],
	'a named databases directory that is missing: the driver is tried, and fails loudly');
is_deeply(summary({ database_dir => '/nonexistent/databases' }), ['index Web::VWF::Data::index -'],
	'so is a named database_dir');

is_deeply(summary({ data => { driver => { name => 'states', description => 'S' } } }),
	['states Web::VWF::Data::states -'], 'one database is a hash');

is_deeply(summary({ data => { driver => [{ name => 'index' }, { name => 'Bands::Data::bands' }, { name => 'index' }] } }),
	['index Web::VWF::Data::index -', 'bands Bands::Data::bands -'],
	'several are an array, a name with :: is used as written, repeats are dropped');

is(modules({ data => { driver => { name => 'states', description => 'S' } } })->[0]{'description'}, 'S', 'description is kept');

is_deeply(summary({ data_modules => 'index, states' }),
	['index Web::VWF::Data::index -', 'states Web::VWF::Data::states -'], 'the old string form still works');
is_deeply(summary({ data_modules => '' }), [], 'an empty old setting means none');
is_deeply(summary({ data_modules => 'old', data => { driver => { name => 'new' } } }),
	['new Web::VWF::Data::new -'], '<data> wins over <data_modules>');

# Directories: the driver's own, then <data>'s
my $dir = File::Spec->catdir('', 'all');
my $mine = File::Spec->catdir('', 'mine');
is_deeply([map { $_->{'file'} } Web::VWF->_data_modules({ data => { directory => $dir, driver => [{ name => 'a', directory => $mine }, { name => 'b' }, { name => 'X::Y::c' }] } })],
	["$mine/a.pm", "$dir/b.pm", "$dir/c.pm"],
	'a driver directory beats the data directory; the file is named for the last part');

# Neither: the databases directory, which is only a first place to look
my $files = File::Spec->catdir('', 'files');
my @soft = map { $_->{'soft'} } Web::VWF->_data_modules({ databases => { directory => $files }, data => { driver => [{ name => 'a' }] } });
is_deeply([map { $_->{'file'} } Web::VWF->_data_modules({ databases => { directory => $files }, data => { driver => [{ name => 'a' }] } })],
	["$files/a.pm"], 'the default is the databases directory');
is_deeply(\@soft, [1], 'and the driver may still come from @INC');
is_deeply([map { $_->{'soft'} } Web::VWF->_data_modules({ data => { directory => $dir, driver => [{ name => 'a' }, { name => 'b', directory => $mine }] } })],
	[1, 0], 'only the directory of a driver is not optional');
is_deeply([map { $_->{'file'} } Web::VWF->_data_modules({ database_dir => $files, data => { driver => [{ name => 'a' }] } })],
	["$files/a.pm"], 'the old database_dir is the databases directory');

# No <driver>: every driver in the data directory, or the databases directory
my $scan = tempdir(CLEANUP => 1);
foreach my $name (qw(zebra apple)) {
	open(my $fh, '>', File::Spec->catfile($scan, "$name.pm")) or die "$name.pm: $!";
	close($fh);
}
is_deeply([map { $_->{'name'} } Web::VWF->_data_modules({ data => { directory => $scan } })],
	['apple', 'zebra'], '<data><directory> alone: its modules, sorted');
is_deeply([map { $_->{'name'} } Web::VWF->_data_modules({ databases => { directory => $scan } })],
	['apple', 'zebra'], '<databases><directory> alone: its modules, sorted');
is_deeply([map { $_->{'name'} } Web::VWF->_data_modules({ data => { directory => $scan, driver => { name => 'only' } } })],
	['only'], 'listed drivers win over scanning');
is_deeply(summary({ databases => { directory => tempdir(CLEANUP => 1) } }), ['index Web::VWF::Data::index -'],
	'an empty databases directory means the default');

# What is said in the log about the databases directory
package Local::Logger {
	sub new { return bless { messages => [] }, shift }
	foreach my $level (qw(debug info notice warn error)) {
		no strict 'refs';
		*{$level} = sub { my $self = shift; push @{$self->{'messages'}}, [$level, join('', grep { defined } @_)]; return };
	}
}
package main;

sub logged
{
	my $config = shift;
	my $logger = Local::Logger->new();
	my $dir = Web::VWF->_check_database_directory($config, $logger);
	return ($dir, @{$logger->{'messages'}});
}

my $present = tempdir(CLEANUP => 1);
my ($returned, @said) = logged({ databases => { directory => $present } });
is($returned, $present, 'the directory is returned');
is_deeply(\@said, [['info', "Reading databases from $present"]], 'present: info');

(undef, @said) = logged({ databases => { directory => '/nonexistent/databases' } });
is_deeply(\@said, [['error', 'The databases directory /nonexistent/databases does not exist']],
	'named but missing: error');

(undef, @said) = logged({ database_dir => '/nonexistent/databases' });
is_deeply([map { $_->[0] } @said], ['error'], 'the old database_dir, named but missing: error');

(undef, @said) = logged({});
is(scalar(@said), 1, 'default and missing: one message');
is($said[0][0], 'notice', 'default and missing: notice, not an error');
like($said[0][1], qr/\ANo databases directory .*assuming there are no data files\z/, 'and it says why');

done_testing();
