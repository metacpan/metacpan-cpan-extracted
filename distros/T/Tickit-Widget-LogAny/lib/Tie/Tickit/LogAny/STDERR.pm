package Tie::Tickit::LogAny::STDERR;
$Tie::Tickit::LogAny::STDERR::VERSION = '0.005';
use strict;
use warnings;

use Log::Any;

sub TIEHANDLE {
	my $class = shift;
	my $self = bless {
		log => Log::Any->get_logger(category => 'STDERR')
	}, $class;
}

sub log : method { shift->{log} }

sub PRINT {
	my $self = shift;
	my $txt = join $", @_;
	s/\v+//g for $txt;
	$self->log->info($txt);
	return 1;
}

sub PRINTF {
	my ($self, $fmt, @args) = @_;
	$self->PRINT(sprintf $fmt => @args)
}

sub READ {}
sub READLINE {}
sub GETC {}
sub WRITE {}
sub FILENO {}
sub CLOSE {}
sub DESTROY {}

1;
