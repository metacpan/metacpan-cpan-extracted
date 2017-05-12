package WebService::GlucoseBuddy::Log;
{
  $WebService::GlucoseBuddy::Log::VERSION = '1.113540';
}
# ABSTRACT: A log from a glucosebuddy logfile

use Moose 1.24;
use namespace::autoclean 0.13;


has reading => (
    is  => 'ro',
    isa => 'WebService::GlucoseBuddy::Log::Reading',
);


has name => (
    is  => 'ro',
    isa => 'Str',
);


has event => (
    is  => 'ro',
    isa => 'Str',
);


has time => (
    is  => 'ro',
    isa => 'DateTime',
);


has notes => (
    is  => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

WebService::GlucoseBuddy::Log - A log from a glucosebuddy logfile

=head1 VERSION

version 1.113540

=head1 ATTRIBUTES

=head2 reading

A L<WebService::GlucoseBuddy::Log::Reading> object for the reading

=head2 name

The name given for the log entry

=head2 event

The event name for the log entry

=head2 time

A L<DateTime> object for the time of the reading. This has a floating timezone as glucosebuddy.com
does not provide one.

=head2 notes

Notes for the log entry

=head1 AUTHOR

Pete Smith <pete@cubabit.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Pete Smith.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

