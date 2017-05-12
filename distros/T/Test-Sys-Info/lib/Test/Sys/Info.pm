package Test::Sys::Info;
use strict;
use warnings;
use vars qw( $VERSION @ISA @EXPORT );
use Carp qw( croak );
use base qw( Exporter );
use Test::More;
use Test::Builder;

BEGIN {
    my $test = Test::Builder->new;
    $test->no_plan if ! $test->has_plan;
}

$VERSION = '0.21';
@EXPORT  = qw( driver_ok );

sub driver_ok {
    require_ok('Test::Sys::Info::Driver');
    return Test::Sys::Info::Driver->new( shift )->run;
}

ok(1, 'EU::MM What a dumb module you are')
    if ! $ENV{HARNESS_ACTIVE};

1;

__END__

=pod

=head1 NAME

Test::Sys::Info - Centralized test suite for Sys::Info.

=head1 SYNOPSIS

    use Test::Sys::Info;
    driver_ok('Windows'); # or Linux, etc.

=head1 DESCRIPTION

This document describes version C<0.21> of C<Test::Sys::Info>
released on C<5 July 2016>.

This is a centralized test suite for Sys::Info Drivers.

=head1 TESTS

=head2 driver_ok OSID

Tests the driver.

=head1 SEE ALSO

L<Sys::Info>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2009 - 2016 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.
=cut
