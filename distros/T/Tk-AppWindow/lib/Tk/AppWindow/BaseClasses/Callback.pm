package Tk::AppWindow::BaseClasses::Callback;

=head1 NAME

Tk::AppWindow::BaseClasses::Callback - providing callbacks

=cut

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.02";

use Data::Compare;
use Scalar::Util qw(blessed);

=head1 SYNOPSIS

 my $cb = Tk::AppWindow::BaseClasses::Callback->new('MethodName', $owner, @options);
 my $cb = Tk::AppWindow::BaseClasses::Callback->new(sub { do whatever }, @options);
 $cb->execute(@moreoptions);
 $cb->hookBefore('some_method', $obj, @param);
 $cb->hookBefore(\&some_sub, @param);
 $cb->unhookBefore('some_method', $obj, @param);
 $cb->unhookBefore(\&some_sub, @param);
 $cb->hookAfter('some_method', $obj, @param);
 $cb->hookAfter(\&some_sub, @param);
 $cb->unhooAfter('some_method', $obj, @param);
 $cb->unhookAfter(\&some_sub, @param);

=head1 DESCRIPTION

This module provides means to create universal callbacks.

After creation it can hook and unhook other callbacks to it.
Those hooked through the B<hookBefore> method will be called before the main callback.
Those hooked through the B<hookAfter> method will be called after the main callback.
Results are passed forward through the chain.

=head1 METHODS

=over 4

=cut

=item B<new>

There are two ways to create a new callback;

 my $c = Tk::AppWindow::BaseClasses::Callback->new('MethodName', $owner, @options);

When you call B<execute> the options you pass to it will be placed after $owner and before @options

 my $c = Tk::AppWindow::BaseClasses::Callback->new(\&SomeAnonymusSub, @options);

When you call B<execute> the options you pass to it will be placed after @options

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};

	$self->{CMD} = [];
	$self->{HOOKSAFTER} = [];
	$self->{HOOKSBEFORE} = [];

	bless ($self, $class);
	$self->{CMD} = [@_]; #if $self->Check(@_);
	return $self;
}

sub Callback {
	my ($self, $cmd, @options) = @_;
	croak 'Command not defined' unless defined $cmd;
	my @call = @$cmd;
	my $sub = shift @call;
	my @opt = ();
	unless ((ref $sub) and ($sub =~/^CODE/)) {
		my $owner = shift @call;
		my $call = $owner->can($sub);
		unless (defined $call) {
			croak "Method $call not found on object $owner";
			return undef
		}
		return &$call($owner, @call,  @options);
	} else {
		return &$sub(@call, @options);
	}
}

sub Check {
	my $self = shift;
	my $call = shift;
	unless ((ref $call) and ($call =~/^CODE/)) {
		my $owner = shift;
		unless (defined $owner) {
			carp "no owner defined";
			return 0
		}
		unless ((blessed $owner) and ($owner =~ /^\S+\=/)) {
			carp "not an object";
			return 0
		}
		unless ($owner->can($call)) {
			carp "invalid method: $call";
			return 0;
		}
	}
	return 1;
}

=item B<execute>(I<@options>)

Runs the callback and returns the result. 

=cut

sub execute {
	my $self = shift;
	my @param = @_;

	my $before = $self->{HOOKSBEFORE};
	for (@$before) {
		@param = $self->Callback($_, @param);
	}
	
	my @result = $self->Callback($self->{CMD}, @param);

	my $after = $self->{HOOKSAFTER};
	for (@$after) {
		@result = $self->Callback($_, @result);
	}
	return if @result eq 0;
	return $result[0] if @result eq 1;
	return @result
}

=item B<hookAfter>I<(@callback)>

Adds a hook to the after section. The items in I<@callback> are exactly as creating a new instance.
The callback will be called after the main callback is fed what the main callback returns as parameters.

=cut

sub hookAfter {
	my $self = shift;
	my $hk = $self->{HOOKSAFTER};
	$self->Check(@_);
	push @$hk, [@_];
}

=item B<hookBefore>(I<@callback>)

Adds a hook to the before section. The items in I<@callback> are exactly as creating a new instance.
The callback will be called before the main callback and feeds it what it returns as parameters.

=cut

sub hookBefore {
	my $self = shift;
	my $hk = $self->{HOOKSBEFORE};
	$self->Check(@_);
	push @$hk, [@_];
}


=item B<unhookAfter>I<(@callback)>

Removes a hook from the after section. The items in I<@callback> are exactly as when adding the hook.
If multiple identical items are present it removes them alls.

=cut

sub unhookAfter {
	my $self = shift;
	my $hook = [ @_ ];
	my $found = 0;

	my $after = $self->{HOOKSAFTER};
	my @na = ();
	for (@$after) {
		unless (Compare($_, $hook)) {
			push @na, $_;
		} else {
			$found = 1;
# 			last;
		}
	}
	$self->{HOOKSAFTER } = \@na;
	carp "Hook not found" unless $found;
}


=item B<unhookBefore>I<(@callback)>

Removes a hook from the before section. The items in I<@callback> are exactly as when adding the hook.
If multiple identical items are present it removes them all.

=cut

sub unhookBefore {
	my $self = shift;
	my $hook = [ @_ ];
	my $found = 0;

	my $before = $self->{HOOKSBEFORE};
	my @nb = ();
	for (@$before) {
		unless (Compare($_, $hook)) {
			push @nb, $_;
		} else {
			$found = 1;
# 			last;
		}
	}
	$self->{HOOKSBEFORE } = \@nb;
	carp "Hook not found" unless $found;
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=cut

1;
__END__


