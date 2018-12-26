package Test::Sys::Info;
$Test::Sys::Info::VERSION = '0.23';
use strict;
use warnings;
use Carp qw( croak );
use base qw( Exporter );
use Test::More;
use Test::Builder;

BEGIN {
    my $test = Test::Builder->new;
    $test->no_plan if ! $test->has_plan;
}

our @EXPORT  = qw( driver_ok );

sub driver_ok {
    require_ok('Test::Sys::Info::Driver');
    return Test::Sys::Info::Driver->new( shift )->run;
}

ok(1, 'EU::MM What a dumb module you are')
    if ! $ENV{HARNESS_ACTIVE};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Sys::Info

=head1 VERSION

version 0.23

=head1 SYNOPSIS

    use Test::Sys::Info;
    driver_ok('Windows'); # or Linux, etc.

=head1 DESCRIPTION

This is a centralized test suite for Sys::Info Drivers.

=head1 NAME

Test::Sys::Info - Centralized test suite for Sys::Info.

=head1 TESTS

=head2 driver_ok OSID

Tests the driver.

=head1 SEE ALSO

L<Sys::Info>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
