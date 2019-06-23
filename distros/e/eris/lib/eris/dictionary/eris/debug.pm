package eris::dictionary::eris::debug;
# ABSTRACT: Debugging data in the event

use Moo;
use namespace::autoclean;
with qw(
    eris::role::dictionary::hash
);

our $VERSION = '0.008'; # VERSION


sub _build_priority { 100 }


sub _build_enabled  { 0 }


sub hash {
    return {
        eris_source  => {
            type => 'keyword',
            description => 'Where the eris system contextualized this message',
        },
        timing => {
            type => 'object',
            description => 'Timing details for each step of the parsing',
            properties => {
                phase => { type => 'keyword' },
                seconds => { type => 'float' },
            }
        },
        total_time => {
            type => 'double',
            description => 'Total time to construct the log message',
        },
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::dictionary::eris::debug - Debugging data in the event

=head1 VERSION

version 0.008

=head1 SYNOPSIS

Dictionary containing the timing and raw data.  Enable this dictionary on
a schema if you'd like to evaluate the parser performance.

=head1 ATTRIBUTES

=head2 priority

Defaults to 100 to try to load last

=head2 enabled

Defaults to false, or disabled, set:

    ---
    dictionary:
      config:
        eris_debug: { enabled: 1 }

=for Pod::Coverage hash

=head1 SEE ALSO

L<eris::dictionary>, L<eris::role::dictionary>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
