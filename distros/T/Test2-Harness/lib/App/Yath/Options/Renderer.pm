package App::Yath::Options::Renderer;
use strict;
use warnings;

our $VERSION = '2.000005';

use Test2::Harness::Util qw/mod2file fqmod/;

use Getopt::Yath;
include_options(
    'App::Yath::Options::Term',
);

option_group {group => 'renderer', category => "Renderer Options"} => sub {
    option quiet => (
        type        => 'Bool',
        short       => 'q',
        description => "Be very quiet.",
        default     => 0,
    );

    option verbose => (
        type         => 'Count',
        short        => 'v',
        description  => "Be more verbose",
        initialize   => 0,
        set_env_vars => [qw/T2_HARNESS_IS_VERBOSE HARNESS_IS_VERBOSE/],
    );

    option qvf => (
        type        => 'Bool',
        default     => 0,
        description => "Replaces App::Yath::Theme::Default with App::Yath::Theme::QVF which is quiet for passing tests and verbose for failing ones.",
    );

    option theme => (
        type => 'Scalar',
        short => 't',
        description => "Select a theme for the renderer (not all renderers use this)",
        default     => 'App::Yath::Theme::Default',
        normalize   => sub { fqmod($_[0], 'App::Yath::Theme') },
    );

    option wrap => (
        type => 'Bool',
        default => 1,
        description => "When active (default) renderers should try to wrap text in a human-friendly way. When this is turned off they should just throw text at the terminal."
    );

    option show_times => (
        type => 'Bool',
        short => 'T',
        description => 'Show the timing data for each job.',
    );

    option hide_runner_output => (
        type        => 'Bool',
        default     => 0,
        description => 'Hide output from the runner, showing only test output. (See Also truncate_runner_output)',
    );

    option truncate_runner_output => (
        type        => 'Bool',
        default     => 0,
        description => 'Only show runner output that was generated after the current command. This is only useful with a persistent runner.',
    );

    option classes => (
        type  => 'Map',
        name  => 'renderers',
        field => 'classes',
        alt   => ['renderer'],

        description => 'Specify renderers. Use "+" to give a fully qualified module name. Without "+" "App::Yath::Renderer::" will be prepended to your argument.',

        long_examples  => [' +My::Renderer', ' MyRenderer,MyOtherRenderer', ' MyRenderer=opt1,opt2', ' :{ MyRenderer :{ opt1 opt2 }: }:', '=:{ MyRenderer opt1,opt2,... }:'],
        short_examples => ['MyRenderer',     ' +My::Renderer', ' MyRenderer,MyOtherRenderer', ' MyRenderer=opt1,opt2', ' :{ MyRenderer :{ opt1 opt2 }: }:', '=:{ MyRenderer opt1,opt2,... }:'],
        initialize     => sub { {'App::Yath::Renderer::Default' => [], 'App::Yath::Renderer::Summary' => []} },

        normalize => sub { fqmod($_[0], ['App::Yath::Renderer', 'Test2::Harness::Renderer']), ref($_[1]) ? $_[1] : [split(',', $_[1] // '')] },

        mod_adds_options => 1,
    );

    option show_job_end => (
        type    => 'Bool',
        default => 1,

        description => 'Show output when a job ends. (Default: on)',
    );

    option show_job_info => (
        type    => 'Bool',
        default => sub { my $v = $_[1]->renderer->verbose // 0; $v > 1 ? 1 : 0 },

        description => 'Show the job configuration when a job starts. (Default: off, unless -vv)',
    );

    option show_job_launch => (
        type    => 'Bool',
        default => sub { my $v = $_[1]->renderer->verbose // 0; $v ? 1 : 0 },

        description => "Show output for the start of a job. (Default: off unless -v)",
    );

    option show_run_info => (
        type    => 'Bool',
        default => sub { my $v = $_[1]->renderer->verbose // 0; $v > 1 ? 1 : 0 },

        description => 'Show the run configuration when a run starts. (Default: off, unless -vv)',
    );

    option show_run_fields => (
        type    => 'Bool',
        default => sub { my $v = $_[1]->renderer->verbose // 0; $v > 1 ? 1 : 0 },

        description => 'Show run fields. (Default: off, unless -vv)',
    );

    option server => (
        type => 'Auto',
        autofill => 'Auto',
        description => "Start an ephemeral yath database and web server to view results",
    );
};

sub init_renderers {
    my $class = shift;
    my ($settings, %params) = @_;

    my $rs = $settings->renderer;

    my $theme_class = $rs->theme;
    require(mod2file($theme_class));
    my $theme = $theme_class->new(use_color => $settings->term->color);

    my $is_qvf = $rs->qvf || ($rs->verbose && $rs->quiet);
    my $r_classes = $rs->classes;

    my $term = -t STDOUT;

    $r_classes->{'App::Yath::Renderer::ResetTerm'} //= [] if $term;

    if (my $eph = $rs->server) {
        $r_classes->{'App::Yath::Renderer::Server'} //= [];
        if ($eph ne 'Auto' && $settings->check_group('server')) {
            $settings->server->option(ephemeral => $eph);
        }
    }

    my @renderers;
    for my $class (sort { $a->weight <=> $b->weight || $a cmp $b } map { require(mod2file($_)); $_ } keys %$r_classes) {
        # FIXME: Do these exist?
        $class = 'App::Yath::Theme::QVF'     if $is_qvf  && $class eq 'App::Yath::Theme::Default';
        $class = 'App::Yath::Theme::Default' if !$is_qvf && $class eq 'App::Yath::Theme::QVF';

        my $params = $r_classes->{$class};

        my $r = $class->new(
            $settings->renderer->all,
            $settings->term->all,
            @$params,
            %params,
            settings => $settings,
            theme    => $theme,
        );

        push @renderers => $r;
    }

    return \@renderers;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Options::Renderer - FIXME

=head1 DESCRIPTION

=head1 PROVIDED OPTIONS

=head2 Renderer Options

=over 4

=item --hide-runner-output

=item --no-hide-runner-output

Hide output from the runner, showing only test output. (See Also truncate_runner_output)


=item -q

=item --quiet

=item --no-quiet

Be very quiet.


=item --qvf

=item --no-qvf

Replaces App::Yath::Theme::Default with App::Yath::Theme::QVF which is quiet for passing tests and verbose for failing ones.


=item --renderer +My::Renderer

=item --renderers +My::Renderer

=item --renderer MyRenderer=opt1,opt2

=item --renderers MyRenderer=opt1,opt2

=item --renderer MyRenderer,MyOtherRenderer

=item --renderers MyRenderer,MyOtherRenderer

=item --renderer=:{ MyRenderer opt1,opt2,... }:

=item --renderers=:{ MyRenderer opt1,opt2,... }:

=item --renderer :{ MyRenderer :{ opt1 opt2 }: }:

=item --renderers :{ MyRenderer :{ opt1 opt2 }: }:

=item --no-renderers

Specify renderers. Use "+" to give a fully qualified module name. Without "+" "App::Yath::Renderer::" will be prepended to your argument.

Note: Can be specified multiple times


=item --server

=item --server=ARG

=item --no-server

Start an ephemeral yath database and web server to view results


=item --show-job-end

=item --no-show-job-end

Show output when a job ends. (Default: on)


=item --show-job-info

=item --no-show-job-info

Show the job configuration when a job starts. (Default: off, unless -vv)


=item --show-job-launch

=item --no-show-job-launch

Show output for the start of a job. (Default: off unless -v)


=item --show-run-fields

=item --no-show-run-fields

Show run fields. (Default: off, unless -vv)


=item --show-run-info

=item --no-show-run-info

Show the run configuration when a run starts. (Default: off, unless -vv)


=item -T

=item --show-times

=item --no-show-times

Show the timing data for each job.


=item -tARG

=item -t ARG

=item -t=ARG

=item --theme ARG

=item --theme=ARG

=item --no-theme

Select a theme for the renderer (not all renderers use this)


=item --truncate-runner-output

=item --no-truncate-runner-output

Only show runner output that was generated after the current command. This is only useful with a persistent runner.


=item -v

=item -vv

=item -vvv..

=item -v=COUNT

=item --verbose

=item --verbose=COUNT

=item --no-verbose

Be more verbose

The following environment variables will be set after arguments are processed: C<T2_HARNESS_IS_VERBOSE>, C<HARNESS_IS_VERBOSE>

Note: Can be specified multiple times, counter bumps each time it is used.


=item --wrap

=item --no-wrap

When active (default) renderers should try to wrap text in a human-friendly way. When this is turned off they should just throw text at the terminal.


=back

=head2 Terminal Options

=over 4

=item -c

=item --color

=item --no-color

Turn color on, default is true if STDOUT is a TTY.

Can also be set with the following environment variables: C<YATH_COLOR>, C<CLICOLOR_FORCE>

The following environment variables will be set after arguments are processed: C<YATH_COLOR>


=item --progress

=item --no-progress

Toggle progress indicators. On by default if STDOUT is a TTY. You can use --no-progress to disable the 'events seen' counter and buffered event pre-display


=item --term-size 80

=item --term-width 80

=item --term-size 200

=item --term-width 200

=item --no-term-width

Alternative to setting $TABLE_TERM_SIZE. Setting this will override the terminal width detection to the number of characters specified.

Can also be set with the following environment variables: C<TABLE_TERM_SIZE>

The following environment variables will be set after arguments are processed: C<TABLE_TERM_SIZE>


=back


=head1 SOURCE

The source code repository for Test2-Harness can be found at
L<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut

