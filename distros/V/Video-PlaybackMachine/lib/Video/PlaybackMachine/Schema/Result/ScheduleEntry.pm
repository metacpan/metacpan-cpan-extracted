package Video::PlaybackMachine::Schema::Result::ScheduleEntry;

our $VERSION = '0.09'; # VERSION

use strict;
use warnings;

use Carp;

use base 'DBIx::Class::Core';

__PACKAGE__->table("schedule_entry");

__PACKAGE__->add_columns(
  "schedule_entry_id" => { data_type => "integer", is_nullable => 0 },
  "mrl"               => { data_type => "text", is_nullable => 0 },
  "schedule_id"       => { data_type => "text", is_nullable => 0 },
  "start_time"        => { data_type => "integer", is_nullable => 0 },
  "listed"            => { data_type => "boolean", is_nullable => 1, default => 1 }
);

__PACKAGE__->set_primary_key('schedule_entry_id');

__PACKAGE__->might_have(
  "movie_info",
  "Video::PlaybackMachine::Schema::Result::MovieInfo",
  { 'foreign.mrl' => "self.mrl" },
);

__PACKAGE__->might_have(
  "schedule_entry_end",
  "Video::PlaybackMachine::Schema::Result::ScheduleEntryEnd",
  { 'foreign.schedule_entry_id' => "self.schedule_entry_id" }
);


__PACKAGE__->belongs_to(
  "schedule",
  "Video::PlaybackMachine::Schema::Result::Schedule",
  { 'foreign.schedule_id' => "self.schedule_id" },
);

sub get_start_time {
	my $self = shift;
	
	carp "get_start_time deprecated";
	
	return $self->start_time();
}
1;
