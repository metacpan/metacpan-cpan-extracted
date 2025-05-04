package App::Yath::Options::Term;
use strict;
use warnings;

use Getopt::Yath::Term qw/USE_COLOR/;

our $VERSION = '2.000005';

use Getopt::Yath;

option_group {group => 'term', category => "Terminal Options"} => sub {
    option color => (
        type          => 'Bool',
        short         => 'c',
        description   => "Turn color on, default is true if STDOUT is a TTY.",
        initialize    => sub { USE_COLOR() && -t STDOUT ? 1 : 0 },
        set_env_vars  => ['YATH_COLOR'],
        from_env_vars => ['YATH_COLOR', 'CLICOLOR_FORCE'],
    );

    option progress => (
        type => 'Bool',
        default => sub { -t STDOUT ? 1 : 0 },
        description => "Toggle progress indicators. On by default if STDOUT is a TTY. You can use --no-progress to disable the 'events seen' counter and buffered event pre-display",
    );

    option term_width => (
        type          => 'Scalar',
        field         => 'width',
        alt           => ['term-size'],
        description   => 'Alternative to setting $TABLE_TERM_SIZE. Setting this will override the terminal width detection to the number of characters specified.',
        long_examples => [' 80', ' 200'],
        set_env_vars  => ['TABLE_TERM_SIZE'],
        from_env_vars => ['TABLE_TERM_SIZE'],
    );
};

option_post_process sub {
    my ($options, $state) = @_;
    my $settings = $state->{settings};

    my $term = $settings->term;

    if ($settings->check_group('tests')) {
        my $tests = $settings->tests;
        $tests->option(env_vars => {}) unless $tests->env_vars;
        $tests->env_vars->{TABLE_TERM_SIZE} = $term->width if defined $term->width;
    }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Options::Term - FIXME

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 PROVIDED OPTIONS

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

