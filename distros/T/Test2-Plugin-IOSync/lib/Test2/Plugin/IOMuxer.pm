package Test2::Plugin::IOMuxer;
use strict;
use warnings;

our $VERSION = '0.000005';


use Test2::Plugin::OpenFixPerlIO;
use Test2::Plugin::IOMuxer::Layer;
use IO::Handle;

use Test2::API qw{
    test2_add_callback_post_load
    test2_stack
};

use Carp qw/confess/;

our @EXPORT_OK = qw/mux_handle/;

sub import {
    my $class = shift;
    my ($in) = @_;

    return unless $in;
    if ($in eq 'mux_handle') {
        my $caller = caller;
        no strict 'refs';
        *{"$caller\::mux_handle"} = \&mux_handle;
        return 1;
    }

    my $file = $in;

    test2_add_callback_post_load(sub {
        my @handles;

        my $hub = test2_stack()->top;
        my $formatter = $hub->format or next;

        for my $meth (qw/handles io/) {
            if ($formatter->can($meth)) {
                my @list = $formatter->$meth;
                @list = @{$list[0]} if @list == 1 && ref($list[0]) eq 'ARRAY';
                push @handles => @list;
            }
        }

        mux_handle($_, $file) for @handles;
    });

    mux_handle(\*STDOUT, $file);
    mux_handle(\*STDERR, $file);

    mux_handle(Test2::API::test2_stdout(), $file) if Test2::API->can('test2_stdout');
    mux_handle(Test2::API::test2_stderr(), $file) if Test2::API->can('test2_stderr');
}

sub mux_handle(*$) {
    my ($fh, $file) = @_;

    my $fileno = fileno($_[0]);
    die "Could not get fileno for handle" unless defined $fileno;

    if (my $set = $Test2::Plugin::IOMuxer::Layer::MUXED{$fileno}) {
        return if $set eq $file;
        confess "Handle (fileno: $fileno) already muxed to '$set', cannot mux to '$file'";
    }

    $Test2::Plugin::IOMuxer::Layer::MUXED{$fileno} = $file;

    unless($Test2::Plugin::IOMuxer::Layer::MUX_FILES{$file}) {
        open(my $mh, '>', $file) or die "Could not open mux file '$file': $!";
        $mh->autoflush(1);
        $Test2::Plugin::IOMuxer::Layer::MUX_FILES{$file} = $mh;
    }

    binmode($_[0], ":via(Test2::Plugin::IOMuxer::Layer)");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::IOMuxer - Send STDERR and STDOUT output to a single file in
addition to the original, including timestamp markers.

=head1 DESCRIPTION

It is essentially impossible to merge STDOUT and STDERR after the fact. It is
also impossible to split them out if they are initially written to the same
distination (redirecting STDERR to STDOUT). This plugin will have STDERR and
STDOUT go to their normal locations, but will also copy all the output to a
single combined file. The combined file will include timestamps, and everything
will be muxed together in the right order.

B<CAVEAT:> When you run a command with C<system()> the output is sent directly
to STDOUT and STDERR, so the muxing does not apply. That output needs to be
manually mixed back in if needed.

=head1 COMBINING WITH IOEVENTS

If you decide to use this plugin along with L<Test2::Plugin::IOEvents> you
should load IOMuxer first, and then IOEvents.

Or you could simply use L<Test2::Plugin::IOSync> instead of loading both
modules yourself.

=head1 SYNOPSIS

Simply loading the plugin with a path to a filename will mux STDOUT and STDERR
(as well as formatter output in most cases) into that destination file.

    use Test2::Plugin::IOMuxer '/path/to/muxed/file.txt';

You can instead manually mux the handles you are interested in:

    use Test2::Plugin::IOMuxer qw/mux_handle/;

    mux_handle(STDOUT, '/path/to/muxed/file.txt');
    mux_handle(STDERR, '/path/to/muxed/file.txt');

Please note that this will not effect the handles for most formatters.

=head1 SOURCE

The source code repository for Test2-Plugin-IOSync can be found at
F<http://github.com/Test-More/Test2-Plugin-IOSync/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2017 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
