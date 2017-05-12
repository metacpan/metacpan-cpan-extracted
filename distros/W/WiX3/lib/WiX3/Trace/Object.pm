package                                # Hide from PAUSE.
  WiX3::Trace::Object;

use 5.008003;
use MooseX::Singleton;
use WiX3::Util::StrictConstructor;
use WiX3::Types qw( Tracelevel );
use MooseX::Types::Moose qw( Bool );

our $VERSION = '0.011';

has tracelevel => (
	is      => 'rw',
	isa     => Tracelevel,
	reader  => 'get_tracelevel',
	writer  => 'set_tracelevel',
	default => 1,
);

has testing => (
	is      => 'ro',
	isa     => Bool,
	reader  => 'get_testing',
	default => 0,
);

sub trace_line {
	my $self = shift;
	my ( $level, $text ) = @_;

	# We hit this routine so many times that it accumulates
	# a minute's worth of time when building Strawberry 5.12.0
	# 64-bit. (profiling by NYTProf)
	# I would not normally break encapsulation like this.
	if ( $level <= $self->{tracelevel} ) {
		print $text;
	}

	return $text;
} ## end sub trace_line

no MooseX::Singleton;
__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;                                     # Magic true value required at end of module
