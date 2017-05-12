package TheEye::Plugin::Store::Riemann;

use Mouse::Role;
use Riemann::Client;

# ABSTRACT: Riemann plugin for TheEye
#
our $VERSION = '0.2'; # VERSION

has 'riemann' => (
    is       => 'rw',
    isa      => 'Riemann::Client',
    required => 1,
    lazy     => 1,
    default  => sub { Riemann::Client->new( host => 'localhost', port => 5555)},
);


around 'save' => sub {
    my $orig = shift;
    my ( $self, $tests ) = @_;

    my @events;
    foreach my $result (@{$tests}) {

        my @path = split(/\//, $result->{file});
        my @file = split(/\./, pop(@path));

        my $event = {
            state => 'ok',
            host   => $self->hostname,
            service => $file[0],
            time   => $result->{time},
            metric   => $result->{delta},
            description => $result->{passed} .' passed and '. $result->{failed} .' failed',
        };
        if($result->{failed}){
            $event->{state} = 'critical';
        }
        push(@events, $event);
    }
    $self->riemann->send(@events);
    return;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TheEye::Plugin::Store::Riemann - Riemann plugin for TheEye

=head1 VERSION

version 0.2

=head1 AUTHOR

Lenz Gschwendtner <lenz@springtimesoft.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by springtimesoft LTD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
