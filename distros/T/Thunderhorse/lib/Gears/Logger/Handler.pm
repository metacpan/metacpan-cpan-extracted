package Gears::Logger::Handler;
$Gears::Logger::Handler::VERSION = '0.101';
use v5.40;
use Mooish::Base -standard;

use Gears::X::Logger;
use Log::Handler;

extends 'Gears::Logger';

has param 'outputs' => (
	isa => ArrayRef,
);

has field 'handler' => (
	lazy => 1,
);

sub _build_handler ($self)
{
	my @conf = $self->outputs->@*;
	if (defined $self->log_format) {
		for my $conf_key (grep { $_ % 2 } keys @conf) {
			my $name = $conf[$conf_key - 1];
			my $conf = $conf[$conf_key];

			Gears::X::Logger->raise("both message_layout and logger's log_format specified for '$name'")
				if exists $conf->{message_layout};

			$conf->{message_layout} = '%m%N';
		}
	}

	return Log::Handler->new(@conf);
}

sub _log_message ($self, $level, $message)
{
	$self->handler->log($level, $message);
}

