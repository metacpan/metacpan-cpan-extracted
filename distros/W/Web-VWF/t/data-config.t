#!/usr/bin/env perl

# The <databases> setting: one <database> element for each data module, with a name,
# a description and optionally a directory, here or on <databases> as a whole.  The
# old <data_modules> string is still read.

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
	return [map { join(' ', $_->{'name'}, $_->{'module'}, $_->{'file'} // '-') } Web::VWF->_data_modules(shift)];
}

is_deeply(summary({}), ['index Web::VWF::Data::index -'], 'the default');

is_deeply(summary({ databases => { database => { name => 'states', description => 'S' } } }),
	['states Web::VWF::Data::states -'], 'one database is a hash');

is_deeply(summary({ databases => { database => [{ name => 'index' }, { name => 'Bands::Data::bands' }, { name => 'index' }] } }),
	['index Web::VWF::Data::index -', 'bands Bands::Data::bands -'],
	'several are an array, a name with :: is used as written, repeats are dropped');

is(modules({ databases => { database => { name => 'states', description => 'S' } } })->[0]{'description'}, 'S', 'description is kept');

is_deeply(summary({ data_modules => 'index, states' }),
	['index Web::VWF::Data::index -', 'states Web::VWF::Data::states -'], 'the old string form still works');
is_deeply(summary({ data_modules => '' }), [], 'an empty old setting means none');
is_deeply(summary({ data_modules => 'old', databases => { database => { name => 'new' } } }),
	['new Web::VWF::Data::new -'], '<databases> wins over <data_modules>');

# Directories: the database's own, then <databases>'s, else @INC
my $dir = File::Spec->catdir('', 'all');
my $mine = File::Spec->catdir('', 'mine');
is_deeply(summary({ databases => { directory => $dir, database => [{ name => 'a', directory => $mine }, { name => 'b' }, { name => 'X::Y::c' }] } }),
	["a Web::VWF::Data::a $mine/a.pm", "b Web::VWF::Data::b $dir/b.pm", "c X::Y::c $dir/c.pm"],
	'a database directory beats the data directory, which beats @INC; the file is named for the last part');

# <directory> alone: whatever is in it
my $scan = tempdir(CLEANUP => 1);
foreach my $name (qw(zebra apple)) {
	open(my $fh, '>', File::Spec->catfile($scan, "$name.pm")) or die "$name.pm: $!";
	close($fh);
}
is_deeply([map { $_->{'name'} } Web::VWF->_data_modules({ databases => { directory => $scan } })],
	['apple', 'zebra'], '<directory> alone: its modules, sorted');
is_deeply([map { $_->{'name'} } Web::VWF->_data_modules({ databases => { directory => $scan, database => { name => 'only' } } })],
	['only'], 'listed databases win over scanning');

done_testing();
