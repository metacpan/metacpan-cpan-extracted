package Video::PlaybackMachine::Schema::Result::ScheduleEntryEnd;

our $VERSION = '0.09'; # VERSION

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("schedule_entry_end");

__PACKAGE__->add_columns(
  "schedule_entry_end_id" => { data_type => "integer", is_nullable => 0 },
  "schedule_entry_id" => { data_type => "integer", is_nullable => 0 },
  "stop_time"        => { data_type => "integer", is_nullable => 0 }
);

__PACKAGE__->set_primary_key('schedule_entry_end_id');

__PACKAGE__->belongs_to(
  "schedule_entry",
  "Video::PlaybackMachine::Schema::Result::ScheduleEntry",
  { 'foreign.schedule_entry_id' => "self.schedule_entry_id" }
);

__PACKAGE__->add_unique_constraint(['schedule_entry_end_id', 'schedule_entry_id']);
1;