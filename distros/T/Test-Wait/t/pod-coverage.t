#!/usr/bin/env perl
# vim:syn=perl

use strict;
use warnings;

use Test::More;

=head1 NAME

t/01pod.t

=head1 DESCRIPTION

Test Test::Wait pod coverage.

=head1 SYNOPSIS

    perl -Ilib t/01pod-coverage.t

    prove -vcfl t/01pod-coverage.t

=cut

eval 'use Test::Pod::Coverage 1.04';
plan skip_all   => 'Test::Pod::Coverage 1.04 required' if ( $@ );

all_pod_coverage_ok();


done_testing();


=head1 AUTHORS

Ben Hare <ben@benhare.com>

=head1 COPYRIGHT

Copyright (c) Ben Hare <ben@benhare.com>, 2014.

This program is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut


__END__
