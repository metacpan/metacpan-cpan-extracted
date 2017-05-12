package Video::PlaybackMachine::Logger;

our $VERSION = '0.09'; # VERSION

use Moo::Role;
use Log::Log4perl;

has 'logger' => (
	'is' => 'lazy',
	'handles' => [ qw/ trace debug info warn error fatal
						is_trace is_debug is_info is_warn is_error is_fatal
						logwarn logdie logconfess
		/ ]
);

sub _build_logger {
	my $self = shift;
	
	return Log::Log4perl->get_logger( ref $self );
}

no Moo::Role;

1;