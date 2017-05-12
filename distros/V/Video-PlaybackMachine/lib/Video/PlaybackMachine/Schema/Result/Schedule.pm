package Video::PlaybackMachine::Schema::Result::Schedule;

our $VERSION = '0.09'; # VERSION

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('schedule');

__PACKAGE__->add_columns(
	'schedule_id' => { data_type => 'integer', is_nullable => 0},
	'name'        => { data_type => 'text', is_nullable => 0 }
);

__PACKAGE__->set_primary_key('schedule_id');

__PACKAGE__->add_unique_constraint(['name']);

__PACKAGE__->has_many(
  'schedule_entries',
  'Video::PlaybackMachine::Schema::Result::ScheduleEntry',
  { 'foreign.schedule_id' => 'self.schedule_id' },
  { cascade_copy => 1, cascade_delete => 1 },
);

sub schedule_entries_in_order {
	my $self = shift;
	
	return $self->search_related('schedule_entries', {}, { 'order_by' => 'start_time' });
}

sub movie_conflicts {
	my $self = shift;
	my ($new_start, $duration) = @_;
	
	my $new_stop = $new_start + $duration;
	
	return $self->search_related('schedule_entries',
		 [
				{ 
					'-and' => 
						[ 'start_time' => { '>=', $new_start },
				          'start_time' => { '<=', $new_stop }
				        ]
				},
				{
				  'start_time' => { '<=', $new_start },
				  'schedule_entry_end.stop_time' => { '>=', $new_start }
				}
		],
		{
			join => 'schedule_entry_end'
		}
	);
};

1;
