package eris::schema::syslog;
# ABSTRACT: Schema for the syslog data

use Moo;
use Types::Standard qw(InstanceOf);

use namespace::autoclean;
with qw(
    eris::role::schema
);

our $VERSION = '0.008'; # VERSION


sub _build_priority { 100 }


# Match *EVERYTHING*
sub match_log { 1; }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::schema::syslog - Schema for the syslog data

=head1 VERSION

version 0.008

=head1 SYNOPSIS

Simple syslog schema.  Matches all logs and will index them into
the B<index_name> specified or C<syslog-%Y.%m.%d> if not provided.

If you'd like to enable the debugging dictionary on this schema, add the
following to your C<config.yaml>.

    ---
    schemas:
      config:
        syslog:
          dictionaries:
            config:
              eris::debug: { enabled: 1 }

This will index the fields contained in the L<eris::dictionary::eris::debug>
dictionary.

=head1 PROPERTIES

=over 2

=item B<final>

True (default)

=item B<flatten>

True (default)

=item B<priority>

100 - Try hard to be last

=item B<use_dictionary>

True - Prunes unknown fields (default)

=item B<dictionary>

See L<eris::dictionary> for the default configuration

=item B<match_log>

Matches everything

=back

=head1 SEE ALSO

L<eris::role::schema>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
