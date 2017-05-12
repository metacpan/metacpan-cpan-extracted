package eris::dictionary::syslog;

use Moo;
use namespace::autoclean;
with qw(
    eris::role::dictionary::hash
);
sub _build_priority { 100; }
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

eris::dictionary::syslog

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

__DATA__
severity Syslog severity of the message
facility Syslog facility of the message
program The program name or tag that generated the message
hostname The hostname as received by the syslog server
