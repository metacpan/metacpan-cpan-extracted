package ZMQ::Declare;
{
  $ZMQ::Declare::VERSION = '0.03';
}

use 5.008001;
use strict;
use warnings;

use ZeroMQ ();

require ZMQ::Declare::Constants;
require ZMQ::Declare::Types;

require ZMQ::Declare::ZDCF;
require ZMQ::Declare::Application;
require ZMQ::Declare::Device;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = @ZMQ::Declare::Constants::EXPORT_OK;
our %EXPORT_TAGS = (
  'all' => \@EXPORT_OK,
);

1;
__END__

=head1 NAME

ZMQ::Declare - Declarative 0MQ Infrastructure

=head1 SYNOPSIS

  use ZMQ::Declare;
  
  # Read the network "topology" (who talks to whom and how) from a shared
  # file or alternatively, provide an equivalent nested Perl data structure.
  my $spec = ZMQ::Declare::ZDCF->new(tree => 'mynetwork.zdcf');
  
  # Pick the device in your network that this code path is to implement
  my $broker = $spec->application("events")->device("event_broker");
  
  # Set up your main loop
  $broker->implementation( sub {
    my ($runtime) = @_;
    my $input_sock = $runtime->get_socket_by_name("event_listener");
    my $output_sock = $runtime->get_socket_by_name("work_distributor");
    while (1) {
      ... recv, send, recv, send ...
    }
  });
  
  # Kick it off. This will create the actual 0MQ objects, make
  # connections, configure them, potentially fork off many processes,
  # and then hand control to your main loop with everything set up!
  $broker->run();
  # If this was not the broker but the implementation for the event processors:
  #$worker->run(nforks => 20);

Actual, runnable examples can be found in the F<examples/>
subdirectory of the C<ZMQ::Declare> distribution.

=head1 DESCRIPTION

B<This is experimental software. Interfaces and implementation are subject to
change. If you are interested in using this in production, please get in touch
to gauge the current state of stability.>

B<One guaranteed user-visible change will be that the underlying libzmq
wrapper will be switched from ZeroMQ.pm to ZMQ.pm (with ZMQ::LibZMQ2 or 3 as backend)
when ZMQ.pm becomes stable.>

0MQ is a light-weight messaging library built on TCP.

The Perl module C<ZMQ::Declare> aims to provide a declarative and/or
configuration-driven way of establishing a network of distributed processes
that collaborate to perform a certain task.
The individual processes ("applications" in ZMQ::Declare) can each have one or
more threads ("devices" in 0MQ speak) which talk to one another
using 0MQ. For example, such a setup could be an entire event
processing stack that has many different clients producing events,
a broker, many event processing workers, and a result aggregator.

Normally using the common Perl binding, L<ZeroMQ>, requires you to
explicitly write out the code to create 0MQ context and sockets, and
to write the connect/bind logic for each socket. Since the use of
0MQ commonly implies that multiple disjunct piece of code talk
to one another, it's easy to either scatter this logic in many places
or re-invent application-specific network configurations.
(Which side of the connection is supposed to C<bind()> and which is
supposed to C<connect()> again?)
For what it's worth, I've always felt that the networked components
that I've written were simply flying in close formation instead of
being obvious parts of a single stack.

C<ZMQ::Declare> is an attempt to concentrate the information about
your I<network> of 0MQ sockets and connections in one place, to
create and connect all sockets for you, and to allow you to focus
on the actual implementation of the various devices that talk
to one another using 0MQ. It turns out that I am not the only one
who thought this would come in useful: L<http://rfc.zeromq.org>
defines a standard device configuration data structure (it does
not specify encoding format) called I<ZDCF> (ZeroMQ Device
Configuration File).

Despite the name I<ZDCF>, there's no technical need
for this information to live in a file. C<ZMQ::Declare> implements
ZDCF file reading/decoding (parsing) as well as some degree of
B<validation>. This is implemented in the L<ZMQ::Declare::ZDCF>
class which represents a single such configuration. The default
decoder/encoder assumes JSON input/output, but is pluggable.

The envisioned typical use of C<ZMQ::Declare> is that you write
a single I<ZDCF> specification file or data structure that defines
various applications and devices in your network and how they
interact with one another. This approach means that as long as
you have a library to handle I<ZDCF> files,
you can write your devices in a multitude of programming languages
and mix and match to your heart's content. For example, you might
choose to implement your tight-loop message broker in C for performance,
but prefer to write the parallelizable worker components in
Perl for ease of development.

For details on the ZDCF format, please refer to L<ZMQ::Declare::ZDCF>.
For a domain specific language for defining ZDCF structures in pure Perl,
see L<ZMQ::Declare::DSL>.

=head1 SEE ALSO

L<ZMQ::Declare::ZDCF>,
L<ZMQ::Declare::Application>,
L<ZMQ::Declare::Device>,
L<ZMQ::Declare::Device::Runtime>,
L<ZMQ::Declare::DSL>

L<ZeroMQ>

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011,2012,2014 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
