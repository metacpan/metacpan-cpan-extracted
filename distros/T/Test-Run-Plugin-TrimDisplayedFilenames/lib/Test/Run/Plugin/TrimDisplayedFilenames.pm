package Test::Run::Plugin::TrimDisplayedFilenames;

use warnings;
use strict;

use 5.008;

use Moose;

use MRO::Compat;
use File::Spec;
use File::Basename;
use List::MoreUtils ();

extends ('Test::Run::Base');

=head1 NAME

Test::Run::Plugin::TrimDisplayedFilenames - trim the first components
of the displayed filename to deal with excessively long ones.

=head1 VERSION

Version 0.0125

=cut

our $VERSION = '0.0125';

has 'trim_displayed_filenames_query' => (is => "rw", isa => "Str");


sub _process_filename_dirs
{
    my ($self, $fn, $callback) = @_;

    my $basename = basename($fn);
    my $dirpath  = dirname($fn);

    my ($volume, $directories, $filename) = File::Spec->splitpath($dirpath, 1);

    # The actual manipulation.
    my $dirs = $callback->([File::Spec->splitdir($directories)]);

    my $final_dir =
        File::Spec->catpath(
            $volume, File::Spec->catdir(@$dirs), $filename
        );

    if ($final_dir eq "")
    {
        return $basename;
    }
    else
    {
        return File::Spec->catfile(
            $final_dir, $basename
        );
    }
}

sub _get_search_from_callback
{
    my ($self, $options) = @_;

    return
        +($options->{search_from} eq "start")
            ? \&List::MoreUtils::firstidx
            : \&List::MoreUtils::lasttidx
            ;
}

sub _get_array_portion
{
    my ($self, $options, $dirs, $idx) = @_;

    my @copy = @$dirs;

    return
    [
        +($options->{keep_from} eq "start")
            ? splice(@copy, 0, $idx)
            : splice(@copy, $idx+1)
    ];
}

sub _trim_filename_dir_components
{
    my ($self, $filename, $component_callback, $options) = @_;

    $options ||= { 'search_from' => "start", 'keep_from' => "end" };

    return $self->_process_filename_dirs(
        $filename,
        sub {
            my $dirs = shift;

            my $idx =
                $self->_get_search_from_callback($options)
                     ->($component_callback, @$dirs)
                ;

            if (!defined($idx))
            {
                return $dirs
            }

            return $self->_get_array_portion($options, $dirs, $idx);
        },
    );
}

sub _process_output_leader_fn
{
    my ($self, $fn) = @_;

    my $query = $self->trim_displayed_filenames_query();

    if (!defined($query))
    {
        return $fn;
    }

    if ($query =~ m{\A(fromre|keep):(.*)}ms)
    {
        my ($cmd, $arg) = ($1, $2);

        if ($cmd eq "fromre")
        {
            my $re = qr{$arg};

            return
                $self->_trim_filename_dir_components(
                    $fn,
                    sub { $_ =~ m{$re} },
                    +{ search_from => "start", keep_from => "end" }
                );
        }
        else # $cmd eq "keep"
        {
            # We need to decrement 1 because there's also the filename.
            my $num_keep = int($arg);
            return
                $self->_process_filename_dirs(
                    $fn,
                    sub {
                        my @dirs = @{shift()};
                        return
                            +($num_keep <= 1)
                                ? []
                                : [splice(@dirs, -($num_keep-1))]
                                ;
                    },
                );
        }
    }
    else
    {
        # TODO - Replace with an exception object.
        die "Unrecognized trim_displayed_filename_query."
    }
}

sub _calc_test_file_data_display_path
{
    my ($self, $idx, $test_file) = @_;

    return $self->_process_output_leader_fn($test_file);
}

=head1 SYNOPSIS

    package MyTestRun;

    use Moose;

    extends('Test::Run::Plugin::TrimDisplayedFilenames');

=head1 FUNCTIONS

=cut

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-plugin-alternateinterpreters at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test::Run::Plugin::TrimDisplayedFilenames>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::Plugin::TrimDisplayedFilenames

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test::Run::Plugin::TrimDisplayedFilenames>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Run::Plugin::TrimDisplayedFilenames>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Run::Plugin::TrimDisplayedFilenames>

=item * MetaCPAN

L<http://metacpan.org/release/Test-Run-Plugin-TrimDisplayedFilenames>

=back

=head1 ACKNOWLEDGEMENTS

Curtis "Ovid" Poe ( L<http://search.cpan.org/~ovid/> ) who gave the idea
of testing several tests from several interpreters in one go here:

L<http://use.perl.org/~Ovid/journal/32092>

=head1 SEE ALSO

L<Test::Run>, L<Test::Run::CmdLine>, L<TAP::Parser>,
L<Test::Run::CmdLine::Plugin::TrimDisplayedFilenames>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1; # End of Test::Run::Plugin::TrimDisplayedFilenames
