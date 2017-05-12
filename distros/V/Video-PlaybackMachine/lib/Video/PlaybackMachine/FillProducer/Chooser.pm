package Video::PlaybackMachine::FillProducer::Chooser;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::FillProducer::Chooser
####
#### $Revision$
####
#### Picks content in random or quasi-random order. Does not pick
#### anything twice until all have been chosen. Will preferentially display
#### new content.
####

use Moo;

with 'Video::PlaybackMachine::Logger';

use IO::Dir;
use File::stat;

############################# Attributes ###########################

has 'DIRECTORY' => (
	is => 'ro',
	required => 1
);

has 'FILTER' => (
	is => 'ro'
);

has 'SEEN' => (
	is => 'rw',
	default => sub { return {} }
);

has 'ITEMS' => (
	is => 'rw',
	default => sub { return []; }
);

############################## Class Methods ############################

##
## new()
##
## Arguments: (hash)
##   DIRECTORY: string -- Directory from which we should choose things
##   FILTER: regexp -- Regular expression matching things we should return
##

############################# Object Methods ##############################

##
## choose()
##
## Returns an item from a randomly-selected list. Items which have
## appeared during program run are played sooner.
##
sub choose
{
	my $self = shift;

	$self->_reload_items();

	return shift @{ $self->ITEMS() };

}

##
## is_available()
##
## Returns true if calling choose() would return an item.
##
sub is_available
{
	my $self = shift;

	$self->_reload_items();
	return @{ $self->ITEMS() } > 0;
}

##
## Loads any new items (i.e. files)
##
sub _reload_items
{
	my $self      = shift;
	my @new_items = $self->_get_new_items();
	$self->ITEMS( [ @new_items, @{ $self->{'ITEMS'} } ] );

	if ( @{ $self->ITEMS() } == 0 )
	{
		$self->SEEN({});
		$self->ITEMS( [ $self->_get_new_items() ] );
	}

	return 1;
}

sub _get_new_items
{
	my $self = shift;

	-d $self->DIRECTORY()
	  or do
	{
		$self->warn("Directory '", $self->DIRECTORY(), "' does not exist");
		return;
	};
	my $dh = IO::Dir->new( $self->DIRECTORY() )
	  or die "Couldn't open directory $self->DIRECTORY(): $!; stopped";
	my @files = ();
	while ( my $file = $dh->read() )
	{
		$file =~ /\.^/ and next;
		if ( $self->FILTER )
		{
			my $filter = $self->FILTER();
			$file =~ /$filter/ or next;
		}
		my $full_file = $self->DIRECTORY() . "/$file";
		-f $full_file or next;
		$self->SEEN()->{$full_file}++ and next;
		push( @files, $full_file );
	}

	return $self->_random_sort(@files);
}

sub _random_sort
{
	my $self = shift;
	my (@items) = @_;

	my %st = ();
	my $getval = sub {
		my ($x) = @_;

		if ( !exists $st{$x} )
		{
			$st{$x} = rand();
		}
		return $st{$x};
	};
	return sort { $getval->($a) <=> $getval->($b) } @items;

}

no Moo;

1;
