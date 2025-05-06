package Test2::Plugin::DBBreak;
use strict;
use warnings;

our $VERSION = '0.200000';

our $disable = 0;

use Test2::API qw{
    test2_add_callback_post_load
    test2_stack
};

sub import {
    my $class  = shift;
    my %params = @_;

    test2_add_callback_post_load(
        sub {
            my $hub = test2_stack()->top;
            $hub->listen(\&listener, inherit => 1);
        }
    );
}

sub listener {
    my ($hub, $event) = @_;
    no warnings 'once';

    return if ($disable);

    $DB::single = 1 if ($event->causes_fail);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::DBBreak - Automatic breakpoint on failing tests for the perl debugger

=head1 DESCRIPTION

This plugin will automatically break when a test running in the perl
debugger fails.

=head1 SYNOPSIS

This test:

    use Test2::V0;
    use Test2::Plugin::DBBreak;

    ok(0, "fail");

    done_testing;

Produces the output:

    not ok 1 - fail
    Test2::Plugin::DBBreak::listener(/usr/local/lib/perl5/site_perl/5.36.1/Test2/Plugin/DBBreak.pm:29):
    29:         return;

=head1 OPTIONS

To disable the breakpoint temporarily, set the $disable variable to 1:

    $Test2::Plugin::DBBreak::disable = 1

=head1 SOURCE

The source code repository for Test2-Plugin-DBBreak can be found at
F<https://github.com/kcaran/Test2-Plugin-DBBreak/>.

=head1 MAINTAINERS

=over 4

=item Keith Carangelo <kcaran@gmail.com>

=back

=head1 AUTHORS

=over 4

=item Keith Carangelo <kcaran@gmail.com>

=back

=head1 COPYRIGHT

Copyright 2025 Keith Carangelo <kcaran@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<https://dev.perl.org/licenses/>

=cut
