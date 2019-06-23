package eris;
# ABSTRACT: Eris is the Greek Goddess of Chaos

use strict;
use warnings;

our $VERSION = '0.008'; # VERSION

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris - Eris is the Greek Goddess of Chaos

=head1 VERSION

version 0.008

=head1 SYNOPSIS

eris exists to transform unstructured, chaotic log data into structured messages.

Born out of disappointment and regret of existing solutions like Logstash,
fluentd, and their kind, eris aims to make development and debugging of
parsers easy and transparent. The goal is to provide a config that be used to
to index logging data into Elasticsearch while being flexible enough to work
with log files on the system.  This makes it friendly to approach from a
maintenance perspective as we don't need to run a massive app to figure out
how a log message will be restructured.

=head1 DESCRIPTION

eris is structured to be flexible, extensible, and visible in every component.

=head1 CONCEPTS

=head2 DECODER

Decoders are pluggable thanks to L<eris::role::pluggable> and they are searched
for in the the default namespace C<eris::log::decoder>.  To add other
namespaces, use the C<search_path> parameter in a config file:

    ---
    decoders:
      search_path:
        - 'my::app::decoder'

Decoders operate on the raw string and provide rudimentary key/value pairs for
the other contexts to operate on.  Unlike the contexts, every discovered decoder is run
for every message.

=head3 SEE ALSO

=over 4

=item L<eris::log::decoders>

Class providing access to installed and configured decoders on the system.

=item L<eris::log::contextualizer>

Class which uses the decoders to transform the raw data into structured data.

=item L<eris::role::decoder>

The abstract role which implements a decoder.

=item L<eris::log::decoder::syslog>, L<eris::log::decoder::json>

Default implementations of decoders.

=back

=head2 CONTEXT

Contexts are pluggable and are searched for in the default namespace
C<eris::log::decoder>.  To add your own namespaces, use the C<search_path>
parameter in your config file:

    ---
    contexts:
      search_path:
        - 'my::app::context'

Contexts implement the interface documented in L<eris::role::context>.  There
are 4 major things to consider when implementing a new context.

=over 2

=item B<contextualize_message>

This method is called when the context matches the event data.  This is where
you can implement your own parsing or analysis of the event data.  To add
context to an event, use the L<eris::log>'s C<add_context()> method.  That
context data will be available to future contexts.

=item B<sample_messages>

Return an array of sample messages.  This provides future developers with some
data to use in testing and enhancing your context.

=item B<field>

This specifies the field or fields that a matcher will operate on.  There are
two special fields C<*> and C<_exists_>.  The C<*> is used in conjunction with
a matcher of C<*> to match all messages.  The C<_exists_> operator is used to
check for the existence of a key in the context.  A sample use of this field
specifier is used by the L<eris::log::context::GeoIP> context with an regex
matcher to operate on any event data with field names matching C<'_ip$'>.

=item B<matcher>

Can be C<*>, a string, a regex ref, an array reference, or a code reference.
If C<matcher> and C<field> are set to C<*>, every message matches.  If a
literal string, or array reference, the literal string is checked against the
value of in the C<field> specified above and returns 1 if they are equivalent.
If a regex reference, the regex is applied to the value in the specified
C<field> and the context is applied if the regex matches.  A code reference
should return 1 if the event is relevant to the context and 0 if it doesn't
apply.

=back

The default C<field> is 'program', and the default matcher is a string with the
value equal to the context's C<name> attribute.  For instance,
L<eris::log::context::sshd> defaults it's name to 'sshd', and since it doesn't
override the field, this context is only applied to events with a 'program' key
with a value of 'sshd'.

=head3 SEE ALSO

=over 4

=item L<eris::log::contexts>

Class providing access to installed and configured contexts on the system.

=item L<eris::log::contextualizer>

Class which uses the contexts to transform the raw data into structured data.

=item L<eris::role::context>

The abstract role which implements a context.

=item L<eris::log::context::sshd>, L<eris::log::context::GeoIP>

Selected example contexts

=back

=head2 DICTIONARY

Dictionaries are used in conjunction with schemas to filter L<eris::log> contexts down to
only the keys and values we want.  This allows better control of the data headed into storage
to prevent key space explosions.

=head3 SEE ALSO

=over 4

=item L<eris::dictionary>

Class providing access to installed and configured dictionaries on the system.

=item L<eris::role::schema>

Class which uses the dictionaries to filter structured data into a document.

=item L<eris::role::dictionary>

The abstract role which implements a dictionary.

=item L<eris::dictionary::cee>, L<eris::dictionary::eris::debug>

Selected example contexts

=back

=head2 SCHEMA

Schemas perform the transformation from structured data into documents for
indexing.  They allow control of the structure and destination of the document
being indexed.

=head3 SEE ALSO

=over 4

=item L<eris::schemas>

Class providing access to installed and configured schemas on the system.

=item L<eris::role::schema>

The abstract role which implements a schema.

=item L<eris::schema::syslog>

Selected example contexts

=back

=head1 IMPLEMENTATIONS

The goal of eris is to provide a set of tools that can be glued together to
transform unstructured logging data into structured data and then rules for
taking that structured data and storing it somewhere.  That sounds cool, but
there's nothing useful about it unless you can start playing with it now.

This is why eris ships with sample implementations.

=head2 Scripts

Here's a list of the scripts installed along with eris so you can start
breaking things.

=over 4

=item B<eris-context.pl>

This script allows you to do a few useful things.  To see what happens to unstructured data,
you can try performing some simple transforms via the built-in C<sample_messages>:

    eris-context.pl --sample sshd

If you'd like to see what those samples look like as ElasticSearch build requests, you can:

    eris-context.pl --sample sshd --bulk

Without the C<--sample> argument, you can feed data to it using STDIN or a file as it'll use
the Perl magic diamond to read data until an EOF is reached.

To see what the bulk output would look like from a few sources:

Via pipe:

    tail /var/log/messages | eris-context.pl -b

Via a file:

    eris-context.pl -b /var/log/messsages

Via STDIN for testing or manually importing data:

    eris-context.pl -b

The script provides more options, pull up it's help with:

    eris-context.pl --help

=item B<eris-field-lookup.pl>

This script allows you to query the L<eris::dictionary> to see what it knows
about a particular field.

    eris-field-lookup.pl src_ip

=item B<eris-es-indexer.pl>

This is a sample implementation that performs indexing of data received over
syslog to an ElasticSearch cluster.  It will parse all messages passed to it
over STDIN and send them to an ElasticSearch cluster.  It's single threaded, so
it won't be able to keep up with a full speed log load.  See it's help output
for options and details:

    eris-es-indexer.pl --help

=item B<eris-stdin-listener.pl>

This is a wrapper around C<eris-es-indexer.pl> using L<POE::Component::WheelRun::Pool>
to provide a pool of workers for processing log data at scale.  To use it with syslog-ng:

    destination d_eris { program("/usr/local/bin/eris-stdin-listener.pl" keep-alive(); ); };
    log  { source(src_network); destination(d_eris); };

See it's help output for options:

    eris-stdin-listener.pl --help

=item B<eris-eris-client.pl>

This is a wrapper around C<eris-es-indexer.pl> for use in environments using
the L<POE::Component::Server::eris> syslog service.  This service is a simple,
stateless syslog message dispatch system used primarily for development of new
syslog parser use cases.  It transforms the syslog stream into a subscription
service any user on the local system can tap.  IF you're using that server, you
can run the C<eris-eris-client.pl> to leverage L<POE::Component::Client::eris>
to receive messages from the upstream and dispatch them to a worker pool of
C<eris-es-indexer.pl>'s.  For more information, see:

    eris-eris-client.pl --help

=back

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
