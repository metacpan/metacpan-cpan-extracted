package Test2::Plugin::IOEvents;
use strict;
use warnings;

our $VERSION = '0.001001';

use Test2::Plugin::IOEvents::Tie;
use Test2::API qw/ test2_add_callback_post_load /;

my $LOADED = 0;

sub import {
    my $class = shift;

    return if $LOADED++; # do not add multiple hooks

    test2_add_callback_post_load(sub {
        tie(*STDOUT, 'Test2::Plugin::IOEvents::Tie', 'STDOUT');
        tie(*STDERR, 'Test2::Plugin::IOEvents::Tie', 'STDERR');
    });
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::IOEvents - Turn STDOUT and STDERR into Test2 events.

=head1 DESCRIPTION

This plugin turns prints to STDOUT and STDERR (including warnings) into proper
Test2 events.

=head1 SYNOPSIS

    use Test2::Plugin::IOEvents;

This is also useful at the command line for 1-time use:

    $ perl -MTest2::Plugin::IOEvents path/to/test.t

=head1 CAVEATS

The magic of this module is achieved via tied variables.

=head1 SOURCE

The source code repository for Test2-Plugin-IOEvents can be found at
F<https://github.com/Test-More/Test2-Plugin-IOEvents/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
1;
