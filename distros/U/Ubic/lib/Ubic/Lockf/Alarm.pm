package Ubic::Lockf::Alarm;
$Ubic::Lockf::Alarm::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: alarm guard

sub new ($$) {
    my ($class, $timeout) = @_;
    bless { 'alarm' => alarm($timeout), 'time' => time };
}

sub DESTROY ($) {
    my $self = shift;
    local $@;
    my $alarm;
    if ($self->{alarm}) {
        $alarm = $self->{alarm} + $self->{time} - time;
        $alarm = 1 if $alarm <= 0;
    } else {
        $alarm = 0;
    }
    alarm($alarm);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Lockf::Alarm - alarm guard

=head1 VERSION

version 1.60

=head1 DESCRIPTION

This module is necessary to implement timeouts in C<Ubic::Lockf> class.

=head1 METHODS

=over

=item B<< new($timeout) >>

Construct new alarm guard object.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
