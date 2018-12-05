package Text::Trac::Context;
use strict;
use warnings;
use base qw (Class::Accessor::Fast);

our $VERSION = '0.20';

__PACKAGE__->mk_accessors(qw( ul ol min_heading_level permalink in_block_of trac_url ));

my %Defaults = (
	text          => '',
	html          => '',
	htmllines     => [],
	ul            => {},
	ol            => {},
	shift_count   => 0,
	in_block_of   => [],
	disable_links => [],
	enable_links  => [],
);

sub new {
	my ( $class, $args ) = @_;

	my $self = { %Defaults, %$args, };

	bless $self, $class;
	$self->init;
	return $self;
}

sub init {
	my $self = shift;
	$self->{text} =~ s/\r//g;
	@{ $self->{lines} } = split( '\n', $self->{text} );
	$self->{index}     = -1;
	$self->{htmllines} = [];
}

sub hasnext {
	my $self = shift;
	defined( $self->{lines}->[ $self->{index} + 1 ] );
}

sub nextline {
	my $self = shift;
	$self->{lines}->[ $self->{index} + 1 ];
}

sub shiftline {
	my $self = shift;
	$self->{lines}->[ ++$self->{index} ];
}

sub unshiftline {
	my $self = shift;
	$self->{lines}->[ --$self->{index} ];
}

sub currentline {
	my $self = shift;
	$self->{lines}->[ $self->{index} ];
}

sub html {
	my $self = shift;
	join( "\n", @{ $self->{htmllines} } );
}

sub htmllines {
	my $self = shift;
	push @{ $self->{htmllines} }, $_[0] if defined $_[0];
	$self->{htmllines};
}

sub lasthtmlline { $_[0]->{htmllines}->[-1]; }

sub list_level {
	my $self = shift;
}

1;
