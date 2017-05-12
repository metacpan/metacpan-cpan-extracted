package Timestamp::Simple;

use 5.006;

use strict;
use warnings;

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw(stamp);
our $VERSION   = 1.01;

sub stamp {
    my $i;
    join( q{},
        map { sprintf "%02d", $_ + ( 1900, 1, 0, 0, 0, 0 )[ $i++ ] }
            reverse( (localtime)[ 0 .. 5 ] ) );
}

1;

__END__

=head1 NAME

Timestamp::Simple - Simple methods for timestamping

=head1 SYNOPSIS

    use Timestamp::Simple qw(stamp);
    print stamp, "\n";

=head1 DESCRIPTION

This module provides a simple method for returning a stamp to mark
when an event occurs.

=head1 METHODS

=over 4

=item stamp()

This method returns a timestamp in the form yyyymmddHHMMSS.

=back

=head1 AUTHOR

Steve Shoopak <shoop@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Steve Shoopak

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
