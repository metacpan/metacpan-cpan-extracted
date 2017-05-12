package WWW::Agent::Plugins;

=pod

=head1 NAME

WWW::Agent::Plugins - Abstract web browser, Plugin Documentation

=head1 SYNOPSIS

   # this is not a package to invoke

=head1 DESCRIPTION

=head2 Introduction

Writing plugins for the L<WWW::Agent> simply involves some the
following things:

=over

=item intercepting specific agent events

Here you hooked your plugin into the agent which will invoke you at
certain times in the request/response cycle (see L<WWW::Agent> for
this list).

=item maintaining information

You may want to hold some information about your state. This can be
initialize by intercepting the C<init> event which all plugins receive
at the very beginning.

To avoid a mixup every plugin should use a different I<namespace>
in a global data structure (the I<heap> as POE calls it). If the agent
realizes that two plugins are trying to register the same namespace,
it will raise an exception.

=item triggering additional, private events

No one can stop you to set up additional events (for the L<POE>
system).  To avoid confusion, you should name these event by prefixing
it properly.

=back

=head2 A Trivial Example

Let us write a plugin which simply makes the agent wait a certain
number of seconds after any request is made. Also, the number of
requests should be counted; if that reaches a certain number, then the
agent should terminate, whether other plugins still have business to
do.

As a convenience, we want to control the waiting time and the URL
limit with parameters from the application:

  use WWW::Agent;
  use WWW::Agent::Plugins::GoldCoasting;
  my $l = new WWW::Agent (plugins => [
                                      new WWW::Agent::Plugins::GoldCoasting (wait  => 1,
                                                                             limit => 3),
                                      ]);

Before we start the agent we send an event to fetch a page:

  use POE;
  POE::Kernel->post ('agent', 'cycle_start', 'newtab', new HTTP::Request ('GET', 'http://www.rumsti.org/'));

This will be sent as a first (almost) event to the agent, making it
run through the request/response cycle. Now we can start the agent:

  $l->run;

The plugin is simply a package with a C<new> constructor:

   package WWW::Agent::Plugins::GoldCoasting;

   use strict;
   use Data::Dumper;
   use POE;

   sub new {
       my $class   = shift;
       my %options = @_;
       return bless { .... }, $class;
   }

   1;

whereby the constructor must return an object which has the following components:

=over

=item C<namespace>

As data from all plugins will be stored into one data structure,
plugins have to register for a namespace which they will use
consistently throughout. Saying this, it is possible to access data of
other plugins. Not sure, whether this is good or bad.

=item C<hooks>

This hash reference contains your I<handlers>, i.e. the events for
which your plugin registers interest to be called back together with
anonymouse subroutines which actually do something in that case.

=back

In our example this could look like the following:

    return bless {
                  namespace => 'laziness',
                  hooks => {
                      'init' => sub {
                                my ($kernel, $heap)  = (shift, shift);
                                $heap->{laziness}->{wait}       = $options{wait}  || 10;
                                $heap->{laziness}->{limit}      = $options{limit} ||  3;
                                return 1;
                                },
                       # ... maybe more handlers
                  }, $class;

The C<init> event is actually done before anything else and it allows
plugins to initialize their private data structure first. In our case
we might not be overly interested in a reference to the POE kernel,
but the C<$heap> is the place to put the private data. Here we decide
to copy relevant configuration information so that we can access it
later. Note that we have to return 1 to indicate that everything is
fine.

When the agent has completed a request successfully, it will receive
an event C<cycle_pos_response>. Here we can add the required wait time
and here we can also increment our counter.

            # yet another event
	    'cycle_pos_response' => sub {
                my ($kernel, $heap) = (shift, shift);
                my ($tab, $response) = (shift, shift);
                my $url  = $response->request->uri;

		warn "# before $url: working very hard for some secs";
		sleep $heap->{laziness}->{wait}; # you should not use blocking...
		$heap->{laziness}->{counter}++; # we do not care which tab it is

Again we get the POE kernel and the heap as parameters. For this
event, though, we also get the tab within which the request was done
and the response as an L<HTTP::Response>.

After retrieving the original URL for this response, we wait the
necessary seconds. This is actually B<NOT> appropriate within a POE
environment as it lets the process block here without being able to
process other events.

If the counter is below our limit we simply let the agent request
the page again (and again and again) using the same tab and the
request which still sits in the response object.

		if ($heap->{laziness}->{counter} < $heap->{laziness}->{limit}) {
		    $kernel->yield ('cycle_start', $tab, $response->request);
		} else {
		    $kernel->yield ('laziness_end', $tab);
		}
                return $response;
                },

Finally the protocol with the agent requires that we return the response
object (we could have modified it).

If we have reached the limit, the we post another event to the agent, one
which is B<NOT> defined natively by the agent. Instead it is an event which
we cover ourselves:

            # yet another event
	    'laziness_end' => sub {
		my ($heap) = $_[HEAP];
		warn "# we call it a life-style to stop after ".$heap->{laziness}->{limit}." requests";
	    },

This is a fully-fledged POE event. When the plugin is configured, the
agent had realized that it does not know about this particular event
and has registered it for itself.

=head2 Event Classes

The agent distinguishes between the following kinds of events:

=over

=item native, boolean events

These events are native to the agent and require that the plugin
returns a boolean (C<1> or C<0>) value to indicate whether a
particular condition is met or not.

=over

=item C<init>

parameters: kernel, heap

=item C<cycle_consider>

parameters: kernel, heap, tab, request

=item C<cycle_complete>

parameters: kernel, heap, tab

=back

=item native filter events

These events expect that a request (or response) object is analyzed, possibly
modified and returned. Every event handler this behaves as a filter.

=over

=item C<cycle_prepare_request>

parameters: kernel, heap, tab, request

=item C<cycle_pos_response>, C<cycle_neg_response>

parameters: kernel, heap, tab, response

=back

=item private event handlers

These are POE states (POE is infamous for using misleading names).

=back

=head2 Caveats and Tips

=over

=item Blocking

By choosing POE as an external event loop and by programming the
agent to be a reactive, rather than a active one, the agent (and the
plugins) can coexist with other reactive POE components.

If this is no concern for you, then there is nothing wrong of letting
your plugin block, either doing blocking IO or by sleeping some
seconds.

=item Returning Values


In some cases a plugin might want to return values to the application
when the agent has terminated. The simplest way, probably is to memorize

@@@@

=back

=head1 SEE ALSO

L<WWW::Agent>

=head1 AUTHOR

Robert Barta, E<lt>rho@bigpond.net.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Robert Barta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

our $VERSION  = '0.01';
our $REVISION = '$Id: Plugins.pm,v 1.1 2005/03/19 10:03:35 rho Exp $';

1;
