use Test2::V0;

use File::Spec;
use Zuzu qw( zuzu_eval );

BEGIN {
	$INC{'Prima.pm'} = __FILE__;
}

package Prima;

our @RUN_WINDOWS;

sub import { return }

sub run {
	my $window = shift @RUN_WINDOWS;
	$window->close if defined $window;
	return;
}

package Prima::Application;

sub create {
	my ( $class, %args ) = @_;
	$::application = bless {
		%args,
		alive  => 1,
		closed => 0,
	}, $class;
	return $::application;
}

sub alive {
	return $_[0]->{alive};
}

sub close {
	$_[0]->{closed} = 1;
	return;
}

sub stop {
	$_[0]->{stopped} = 1;
	return;
}

package Prima::Window;

sub new {
	my ( $class, %args ) = @_;
	die "cannot create a new window after application close"
		if defined $::application and $::application->{closed};
	return bless {
		%args,
		alive => 1,
	}, $class;
}

sub alive {
	return $_[0]->{alive};
}

sub show {
	push @Prima::RUN_WINDOWS, $_[0];
	return;
}

sub close {
	my ( $self ) = @_;
	return if !$self->{alive};
	my $allow = 1;
	if ( my $on_close = $self->{onClose} ) {
		my $result = $on_close->($self);
		$allow = 0 if defined $result and !$result;
	}
	$self->destroy if $allow;
	return;
}

sub destroy {
	my ( $self ) = @_;
	return if !$self->{alive};
	$self->{alive} = 0;
	$self->{onDestroy}->($self) if $self->{onDestroy};
	return;
}

sub menu {
	return undef;
}

sub size {
	return ( $_[0]->{width}, $_[0]->{height} );
}

package Prima::MainWindow;

our @ISA = qw( Prima::Window );

sub destroy {
	my ( $self ) = @_;
	$::application->close if defined $::application;
	return $self->SUPER::destroy;
}

package main;

my $modules = File::Spec->rel2abs( File::Spec->catdir( 'stdlib', 'modules' ) );

is(
	zuzu_eval(
		<<'ZZS',
from std/gui import Window;

let first := Window( title: "First" );
first.call();

let second := Window( title: "Second" );
second.call();

"ok";
ZZS
		{ lib => [$modules] },
	),
	'ok',
	'sequential Window.call invocations do not close the Prima application',
);

done_testing;
