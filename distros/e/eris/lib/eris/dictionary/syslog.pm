package eris::dictionary::syslog;
# ABSTRACT: Contains fields extracted from syslog messages

use Moo;
use namespace::autoclean;
with qw(
    eris::role::dictionary::hash
);

our $VERSION = '0.004'; # VERSION


sub _build_priority { 90; }


my $_hash=undef;
sub hash {
    return $_hash if defined $_hash;
    my %data;
    while(<DATA>) {
        chomp;
        my ($k,$desc) = split /\s+/, $_, 2;
        $data{lc $k} = $desc;
    }
    $_hash = \%data;
}


1;

=pod

=encoding UTF-8

=head1 NAME

eris::dictionary::syslog - Contains fields extracted from syslog messages

=head1 VERSION

version 0.004

=head1 SYNOPSIS

This dictionary contains elements extracted from the syslog header and
meta-data.

=head1 ATTRIBUTES

=head2 priority

Defaults to 90, or towards the end.

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

__DATA__
timestamp The timestamp encoded in the message
message Message contents, often truncated to relevance.
severity Syslog severity of the message
facility Syslog facility of the message
program The program name or tag that generated the message
hostname The hostname as received by the syslog server
