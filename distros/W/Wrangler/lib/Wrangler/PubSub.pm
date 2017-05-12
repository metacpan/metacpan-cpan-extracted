package Wrangler::PubSub;

=pod

=head1 NAME

Wrangler::PubSub - Wrangler's event hub

=head1 DESCRIPTION

A simple EventTable, or a central PublisherSubscriber hub, or a register_hook facility,
or...

The rationale: "Don't call specific functions/methods on events (otherwise we'd
have to think of all the possible subs that need to be called. Instead we emit pubsub
events ('publish' what's going on) and then, in other modules, we decide which events
are interesting for this module, and can select the events we want to listen to
(subscribe)."

In cases where events are emited from the new() method of modules - as the case in
FileBrowser for example - we have a hen and egg problem (race-condition). An event
is submitted while another module, which relies on this event, for example, to initialise
itself, is not yet "there". For these situations, we have the freeze/thaw mechnism.
When PubSub is in 'frozen'-mode, all events get "frozen" - buffered until you call
thaw(). This way we can construct widgets, in no particular order, and none of them
will miss any events potentially important for them.

=head1 CAVEATS

In cases where widgets are added and/or removed on runtime, make sure that your
widget classes add a hook with I<unsubscribe()>/ I<unsubscribe_owner()> to Destroy()
so that coderefs pointing to a non-existing class get removed from the event table.

=head1 SEE ALSO

L<Kephra::EventTable>, L<Padre::Role::PubSub>, L<Wx::Perl::PubSub>

=head1 COPYRIGHT & LICENSE

This module is part of L<Wrangler>. Please refer to the main module for further
information and licensing / usage terms.

=cut

use strict;
use warnings;

our %table;
our %owner;
our $frozen;
our @frozen;

sub subscribe {
	die "Error in ".caller().": Wrangler::PubSub::subscribe(\$event,\$coderef,\$owner) no \$owner given!" unless $_[2];
	push(@{ $table{ $_[0] } }, $_[1]);
	$owner{ $_[2] }{ $_[0] } = @{ $table{ $_[0] } } - 1; # remember pos
}

sub freeze {
	$frozen = 1;
}
sub thaw {
	$frozen = 0;
	for(@frozen){
		# Wrangler::debug("thaw: firing melted event '$_->{event}', args: @{ $_->{args} }");
		publish($_->{event}, @{ $_->{args} });
	}
	@frozen = ();
}

sub publish {
	my $event = shift;
	# use Data::Dumper;
	# print "publish: $event: ".Data::Dumper::Dumper(\%table,\%owner);
	# Wrangler::debug("publish: event '$event': @_");
	if($frozen){
		push(@frozen, { event => $event, args => \@_ });
	}else{
		if( $table{$event} ){
			for(@{ $table{$event} }){
				# print " event $event\n";
				$_->( @_ );
			}
		}
	}
}

sub unsubscribe {
	my $event = shift;
	my $owner = shift;

#	my @new;
#	for(0 .. $#{ $table{$event} }){
#		print "UNSUBSCRIBE: event:$event, owner:$owner, splice pos $_ \n" if $_ == $owner{ $owner }{ $event };
#		push(@new, ${ $table{$event} }[$_]) unless $_ == $owner{ $owner }{ $event };
#	}
#	$table{$event} = \@new;
	splice(@{ $table{$event} },$owner{ $owner }{ $event },1); # remove pos from array
	delete($owner{ $owner }{ $event });
}

sub unsubscribe_owner {
	my $owner = shift;

	for my $event (keys %{ $owner{$owner} }){
		unsubscribe($event,$owner);
	}
	delete($owner{$owner});
	# require Data::Dumper;
	# print "unsubscribe: owner:$owner: ".Data::Dumper::Dumper(\%table,\%owner);

}

1;
