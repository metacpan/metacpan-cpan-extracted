package Video::PlaybackMachine::Schema::Result::MovieInfo;

our $VERSION = '0.09'; # VERSION

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('movie_info');

__PACKAGE__->add_columns(
	'movie_info_id' => { data_type => 'integer', is_nullable => 0 },
	'mrl' => { data_type => 'text', is_nullable => 0 },
	'duration' => { data_type => 'integer', is_nullable => 0 },
	'file_size' => { data_type => 'integer', is_nullable => 1 },
	'title' => { 'data_type' => 'text', 'is_nullable' => 1 },
);

__PACKAGE__->set_primary_key('movie_info_id');

__PACKAGE__->add_unique_constraint(['mrl']);

__PACKAGE__->has_many(
  'schedule_entries',
  'Video::PlaybackMachine::Schema::Result::ScheduleEntry',
  { 'foreign.mrl' => 'self.mrl' }
);

1;
