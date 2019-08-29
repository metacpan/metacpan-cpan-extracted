package Test2::Plugin::DBIProfile;
use strict;
use warnings;

our $VERSION = '0.002003';

use DBI::Profile qw/dbi_profile_merge_nodes/;
use Test2::API qw/test2_add_callback_exit/;
use Test2::Util::Times qw/render_duration/;

my $ADDED_HOOK = 0;

sub import {
    my $class = shift;
    my ($path) = @_;

    if (defined $path) {
        $ENV{DBI_PROFILE} = $path;
    }
    else {
        $ENV{DBI_PROFILE} //= "!MethodClass";
    }

    return if $ADDED_HOOK++;

    $DBI::Profile::ON_DESTROY_DUMP = undef;
    $DBI::Profile::ON_FLUSH_DUMP   = undef;

    test2_add_callback_exit(\&send_profile_event);
}

sub send_profile_event {
    my ($ctx, $real, $new) = @_;

    my $p = $DBI::shared_profile or return;

    my $data = $p->{Data};
    my ($summary) = $p->format;

    my @totals;
    dbi_profile_merge_nodes(\@totals, $data);
    my ($count, $time) = @totals;

    $ctx->send_ev2(
        dbi_profile => $data,

        about => {package => __PACKAGE__, details => $summary},
        info  => [{tag => 'DBI-PROF', details => $summary}],

        harness_job_fields => [
            {name => "dbi_time",  details => render_duration($time), raw => $time},
            {name => "dbi_calls", details => $count},
        ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::DBIProfile - Plugin to enable and display DBI profiling.

=head1 DESCRIPTION

This will enable L<DBI::Profile> globally so that DBI profiling data is
collected. Once testing is complete an event will be produced which contains
and displays the profiling data.

Normal output looks like this:

    # DBI::Profile: 0.000824s (24 calls) xxx.t @ 2019-08-16 14:24:01

If you use L<Test2::Harness> aka L<App::Yath> detailed profiling data is
available in the event log.

=head1 SYNOPSIS

    use Test2::Plugin::DBIProfile;

This is also useful at the command line for 1-time use:

    $ perl -MTest2::Plugin::DBIProfile path/to/test.t

You can also specify a 'path' for DBI::Profile:

    use Test2::Plugin::DBIProfile "!MethodClass";

See L<DBI::Profile/"ENABLING A PROFILE"> for path options.

The default is to use whatever is already in C<$ENV{DBI_PROFILE}> if it is set,
and to fallback to C<"!MethodClass"> otherwise.

=head1 SOURCE

The source code repository for Test2-Suite can be found at
F<https://github.com/Test-More/Test2-Suite/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2019 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
