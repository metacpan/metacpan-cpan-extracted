package Test::Perl::Critic::Git;

use Cwd;
use utf8;
use 5.018;
use strict;
use warnings;
use Git::Diff;
use Perl::Critic;
use Test::Builder;
use Perl::Critic::Utils;
use Perl::Critic::Violation;

$Test::Perl::Critic::Git::VERSION     = '0.000104';
$Test::Perl::Critic::Git::TEST        = Test::Builder->new;
%Test::Perl::Critic::Git::CRITIC_ARGS = ();
%Test::Perl::Critic::Git::GIT_ARGS    = ();

sub _matching_files {
    my ( $ar_dirs, $hr_changed_files ) = @_;
    my @a_perlfiles = Perl::Critic::Utils::all_perl_files( @{$ar_dirs} );

    require File::Spec;
    my $s_current_dir = Cwd::cwd;

    my @a_files = ();
    for my $s_file (@a_perlfiles) {
        for ( keys %{$hr_changed_files} ) {
            push @a_files, $_ if ( $s_file eq File::Spec->catfile( $s_current_dir, $_ ) || $s_file eq $_ );
        }
    }
    return \@a_files;
}

sub _run_builder {
    my ( $b_switch, $hr_files, $s_message ) = @_;
    my $i_files_to_test = 0;
    for my $s_file ( sort keys %{$hr_files} ) {
        my $hr_file = $hr_files->{$s_file};
        next if scalar @{ $hr_file->{violations} } == 0;
        $i_files_to_test++;
        my @a_violations = grep { exists $hr_file->{addition}->{ $_->line_number } } @{ $hr_file->{violations} };
        if ( scalar @a_violations > 0 ) {
            $Test::Perl::Critic::Git::TEST->diag(qq{Perl::Critic had errors in "$s_file":});
            $Test::Perl::Critic::Git::TEST->diag($_) for @a_violations;
            $Test::Perl::Critic::Git::TEST->ok( $b_switch, $s_message // '' );
            next;
        }
        $Test::Perl::Critic::Git::TEST->ok( !$b_switch, ( $s_message . ' ' ) . $s_file );
        $i_files_to_test--;
    }
    return $Test::Perl::Critic::Git::TEST->ok( ( ( !$b_switch && !$i_files_to_test ) || ( $b_switch && $i_files_to_test ) ) ? 1 : 0, $s_message // '' );
}

sub import {
    my ( $self, $hr_critic_args, $hr_git_args ) = @_;
    my $s_caller = caller;
    {
        no strict 'refs';    ## no critic qw(ProhibitNoStrict)
        *{ $s_caller . '::critic_on_changed_ok' }     = \&critic_on_changed_ok;
        *{ $s_caller . '::critic_on_changed_not_ok' } = \&critic_on_changed_not_ok;
    }

    # -format is supported for backward compatibility.
    $hr_critic_args->{-verbose} = $hr_critic_args->{-format} if exists $hr_critic_args->{-format};
    %Test::Perl::Critic::Git::CRITIC_ARGS = %{$hr_critic_args};
    %Test::Perl::Critic::Git::GIT_ARGS = $hr_git_args ? %{$hr_git_args} : ();
    return $Test::Perl::Critic::Git::TEST->exported_to($s_caller);
}

sub critic_on_changed_ok {
    my ( $ar_dirs, $s_message ) = @_;
    $ar_dirs = [Cwd::cwd] if !$ar_dirs || scalar @{$ar_dirs} == 0;
    my $hr_files = Git::Diff->new(%Test::Perl::Critic::Git::GIT_ARGS)->changes_by_line;
    $hr_files = { map { ( $hr_files->{$_} ? ( $_, $hr_files->{$_} ) : () ) } @{ _matching_files( $ar_dirs, $hr_files ) } };

    my $o_critic = Perl::Critic->new(%Test::Perl::Critic::Git::CRITIC_ARGS);
    Perl::Critic::Violation::set_format( $o_critic->config->verbose );
    $hr_files->{$_}->{violations} = [ $o_critic->critique($_) ] for keys %{$hr_files};

    return _run_builder( 0, $hr_files, $s_message );
}

sub critic_on_changed_not_ok {
    my ( $ar_dirs, $s_message ) = @_;
    $ar_dirs = [Cwd::cwd] if !$ar_dirs || scalar @{$ar_dirs} == 0;
    my $hr_files = Git::Diff->new(%Test::Perl::Critic::Git::GIT_ARGS)->changes_by_line;
    $hr_files = { map { ( $hr_files->{$_} ? ( $_, $hr_files->{$_} ) : () ) } @{ _matching_files( $ar_dirs, $hr_files ) } };

    my $o_critic = Perl::Critic->new(%Test::Perl::Critic::Git::CRITIC_ARGS);
    Perl::Critic::Violation::set_format( $o_critic->config->verbose );
    $hr_files->{$_}->{violations} = [ $o_critic->critique($_) ] for keys %{$hr_files};

    return _run_builder( 1, $hr_files, $s_message );
}

1;

__END__

=encoding utf8

=head1 NAME

Test::Perl::Critic::Git - Test module to run perl critic on changed git files

=head1 VERSION

Version 0.000104

=head1 SUBROUTINES/METHODS

=head2 critic_on_changed_ok

Params:

$hr_critic_args - direct import params for L<Perl::Critic|Perl::Critic>

$hr_git_args - direct import params for L<Git|Git>

=head2 critic_on_changed_ok

Run perl critic on changed files and and raises errors, or even not :-D

=head2 critic_on_changed_not_ok

Same as critic_on_changed_ok but vice versa

=head1 SYNOPSIS

    eval "use Test::Perl::Critic::Git";
    plan skip_all => "Test::Perl::Critic::Git required for testing perl critic" if $@;

    Test::Perl::Critic::Git->import({
          -severity => 'brutal',
          -profile => File::Spec->catfile($Bin, 'critic', 'profilerc'),
          ...
    });

    critic_on_changed_ok([
        '.',
        ...
    ]);

=head1 DIAGNOSTICS

=head1 DEPENDENCIES

=over 4

=item * Internal usage

L<Carp|Carp>, L<Git::Diff|Git::Diff>, L<Perl::Critic|Perl::Critic>, L<Test::Builder|Test::Builder>,
L<Perl::Critic::Utils|Perl::Critic::Utils>, L<Perl::Critic::Violation|Perl::Critic::Violation>

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

A list of current bugs and issues can be found at the CPAN site

   https://gitlab.com/mziescha/test-perl-critic-git/issues

To report a new bug or problem, use the link on this page.

=head1 DESCRIPTION

Test module to run perl critic on changed git files

=head1 CONFIGURATION AND ENVIRONMENT

configurable by import sub

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

=cut
