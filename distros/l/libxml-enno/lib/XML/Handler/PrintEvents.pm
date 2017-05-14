#
# This PerlSAX handler prints out all the PerlSAX events/callbacks
# it receives. Very useful when debugging.
#

package XML::Handler::PrintEvents;
use strict;
use XML::Filter::SAXT;

my @EXTRA_HANDLERS = ( 'ignorable_whitespace' );

sub new
{
    my ($class, %options) = @_;
    bless \%options, $class;
}

sub print_event
{
    my ($self, $event_name, $event) = @_;

    printf "%-22s ", $event_name;
    if (defined $event)
    {
	print join (", ", map { "$_ => [" . 
				(defined $event->{$_} ? $event->{$_} : "(undef)") 
				. "]" } keys %$event);
    }
    print "\n";
}

#
# This generates the PerlSAX handler methods for PrintEvents.
# They basically forward the event to print_event() while adding the callback
# (event) name.
#
for my $cb (@EXTRA_HANDLERS, map { @{$_} } values %XML::Filter::SAXT::SAX_HANDLERS)
{
    eval "sub $cb { shift->print_event ('$cb', \@_) }";
}

1;	# package return code

__END__

=head1 NAME

XML::Handler::PrintEvents - Prints PerlSAX events (for debugging)

=head1 SYNOPSIS

use XML::Handler::PrintEvents;

my $pr = new XML::Handler::PrintEvents;

=head1 DESCRIPTION

This PerlSAX handler prints the PerlSAX events it receives to STDOUT.
It can be useful when debugging PerlSAX filters.
It supports all PerlSAX handler including ignorable_whitespace.

=head1 AUTHOR

Send bug reports, hints, tips, suggestions to Enno Derksen at
<F<enno@att.com>>. 

=cut
