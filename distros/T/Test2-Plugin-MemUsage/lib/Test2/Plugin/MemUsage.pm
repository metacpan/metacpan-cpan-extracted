package Test2::Plugin::MemUsage;
use strict;
use warnings;

our $VERSION = '0.002001';

use Test2::API qw/test2_add_callback_exit/;

my $ADDED_HOOK = 0;

sub import {
    return if $ADDED_HOOK++;

    test2_add_callback_exit(\&send_mem_event);
}

sub proc_file { "/proc/$$/status" }

sub send_mem_event {
    my ($ctx, $real, $new) = @_;

    my $file = proc_file();
    return unless -f $file;

    my $stats;
    {
        open(my $fh, '<', $file) or die "Could not open file '$file' (<): $!";
        local $/;
        $stats = <$fh>;
        close($fh) or die "Could not close file '$file': $!";
    }

    return unless $stats;

    my %mem;
    $mem{peak} = [$1, $2] if $stats =~ m/VmPeak:\s+(\d+) (\S+)/;
    $mem{size} = [$1, $2] if $stats =~ m/VmSize:\s+(\d+) (\S+)/;
    $mem{rss}  = [$1, $2] if $stats =~ m/VmRSS:\s+(\d+) (\S+)/;
    $mem{details} = "rss:  $mem{rss}->[0]$mem{rss}->[1]\nsize: $mem{size}->[0]$mem{size}->[1]\npeak: $mem{peak}->[0]$mem{peak}->[1]";

    $ctx->send_ev2(
        memory => \%mem,
        about  => {package => __PACKAGE__, details => $mem{details}},
        info   => [{tag => 'MEMORY', details => $mem{details}}],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::MemUsage - Collect and display memory usage information.

=head1 CAVEAT - UNIX ONLY

Currently this only works on unix systems that provide C</proc/PID/status>
access. For all other systems this plugin is essentially a no-op.

=head1 DESCRIPTION

This plugin will collect memory usage info from C</proc/PID/status> and display
it for you when the test is done running.

=head1 SYNOPSIS

    use Test2::Plugin::MemUsage;

This is also useful at the command line for 1-time use:

    $ perl -MTest2::Plugin::MemUsage path/to/test.t

Output:

    # rss:  36708kB
    # size: 49836kB
    # peak: 49836kB

=head1 SOURCE

The source code repository for Test2-Plugin-MemUsage can be found at
F<https://github.com/Test-More/Test2-Plugin-MemUsage/>.

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
