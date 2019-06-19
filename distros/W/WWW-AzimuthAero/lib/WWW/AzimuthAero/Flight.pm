package WWW::AzimuthAero::Flight;
$WWW::AzimuthAero::Flight::VERSION = '0.2';

# ABSTRACT: Flight representation

use Class::Tiny
  qw(from to date departure arrival flight_num duration fares has_stops hours_bf);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::AzimuthAero::Flight - Flight representation

=head1 VERSION

version 0.2

=head1 SYNOPSIS

    my $az = WWW::AzimuthAero::Flight->new(date => '16.06.2019', from => 'ROV', to => 'KLF');

=head1 DESCRIPTION

    Object representation of data on pages like https://booking.azimuth.aero/!/ROV/LED/21.06.2019/1-0-0/

=head1 new

    my $az = WWW::AzimuthAero::Flight->new(date => '16.06.2019', from => 'ROV', to => 'KLF');

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
