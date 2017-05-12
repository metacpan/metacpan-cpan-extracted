package Video::PlaybackMachine::ScheduleTable::DB;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::ScheduleTable::DB
####
#### This module is used to access the ScheduleTable.
####

use Moo;

use Carp;

use Video::PlaybackMachine::Config;
use Video::PlaybackMachine::DB;

############################## Class Methods #######################################

##
## new()
##
## Creates a new ScheduleTable::DB object.
##
sub new {
    my $type = shift;
    my (%in) = @_;
    
    my $self = {
        schedule_name => $in{'schedule_name'} // Video::PlaybackMachine::Config->config->schedule(),
        schema        => $in{'schema'} // Video::PlaybackMachine::DB->schema(),
    };
    bless $self, $type;
}

has 'schedule_name' => ( is => 'ro' );

has 'schema' => ( is => 'lazy' );

sub _build_schema {
	my $self = shift;
	
	return Video::PlaybackMachine::DB->schema();
}

############################## Object Methods ######################################

sub getDbh { return Video::PlaybackMachine::DB->db(); }

##
## get_entries_between()
##
## Arguments:
##    BEGIN_TIME: scalar -- UNIX raw time
##    END_TIME: scalar -- UNIX raw time
##
## Returns all entries which start or end between BEGIN_TIME and END_TIME.
##
sub get_entries_between {
    my $self = shift;
    my ( $begin_time, $end_time ) = @_;

    my $schema = $self->schema();

    my $entries_rs = $schema->resultset('ScheduleEntry')->search(
        {
            [
                { 'start_time' => { '>', $begin_time } },
                { 'stop_time'  => { '>', $begin_time } },
            ],
            'start_time' => { '<', $end_time },
            'schedule'   => $self->{'schedule_name'}
        },
        {
            'order_by' => 'start_time',
            join => 'schedule_entry_end'
        }
    );

    return $entries_rs->all();

}

##
## get_entries_after()
##
## Arguments:
##    TIME: scalar -- UNIX raw time
##    NUM_ENTRIES: int -- number of entries afterwards
##
## Returns all entries which start after a given time. In scalar context,
## returns the first entry after the given time. Returns undef if nothing left.
##
sub get_entries_after {
    my $self = shift;
    my ( $time, $num_entries ) = @_;

    defined $num_entries
      or $num_entries = 1;

    # Get next content_schedule entry
    
 	my $schema = $self->schema();   
 
	my $entries_rs = $schema->resultset('ScheduleEntry')->search(
		{
			'start_time' => { '>', $time },
			'schedule.name'   => $self->schedule_name(),
		},
		{
			'limit' => $num_entries,
			'order_by' => 'start_time',
			'join' => 'schedule'
		}
	);

    if (wantarray) {
        return $entries_rs->all();
    }
    else {
        return $entries_rs->first();
    }
}

##
## get_entry_during()
##
## Arguments:
##    TIME: scalar -- UNIX raw time
##
## Returns the schedule entry in which TIME takes place.
## Returns an empty list / undef if there is no scheduled program taking place
## at the given time.
##
sub get_entry_during {
    my $self = shift;
    my ($time) = @_;
    
    return $self->schema()->resultset('ScheduleEntry')
    	->find(
    		{
				'schedule.name' => $self->schedule_name(),
				'start_time'    => { '>=', $time },
				'schedule_entry_end.stop_time'      => { '<', $time }
    		},
			{
				'join' => ['schedule_entry_end', 'schedule']
			}
    	);

}

##
## get_first_entry()
##
## Returns:
##   First entry in schedule table
sub get_first_entry {
	my $self = shift;
	
	return $self->schema()->resultset('ScheduleEntry')
		->search({
			'schedule.name' => $self->schedule_name()
		},
			{
				'join'     => 'schedule',
				'order_by' => 'start_time'
			}
		)->first();
}

1;

no Moo;

__END__
