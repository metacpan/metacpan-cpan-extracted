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

$Test::Perl::Critic::Git::VERSION     = '0.000103';
$Test::Perl::Critic::Git::TEST        = Test::Builder->new;
%Test::Perl::Critic::Git::CRITIC_ARGS = ();
%Test::Perl::Critic::Git::GIT_ARGS    = ();

sub _matching_files{
    my ($ar_dirs, $hr_changed_files) = @_;
    my @a_given_perlfiles = Perl::Critic::Utils::all_perl_files( @{$ar_dirs} );
   
    require File::Spec;
    my $s_current_dir    = Cwd::cwd;

    my @a_matching_files = ();
    for my $s_given_perlfile (@a_given_perlfiles) {
        for ( keys %{$hr_changed_files} ) {
            push @a_matching_files, $_ if (
                     $s_given_perlfile eq File::Spec->catfile( $s_current_dir, $_ ) 
                  || $s_given_perlfile eq $_
               );
        }
    }
    return \@a_matching_files;
}

sub import {
    my ($self, $critic_args, $git_args ) = @_;
    my $caller = caller;
    {
        no strict 'refs';    ## no critic qw(ProhibitNoStrict)
        *{ $caller . '::critic_on_changed_ok' } = \&critic_on_changed_ok;
    }

    # -format is supported for backward compatibility.
    $critic_args->{-verbose} = $critic_args->{-format} if exists $critic_args->{-format};

    %Test::Perl::Critic::Git::CRITIC_ARGS = %{$critic_args};
    %Test::Perl::Critic::Git::GIT_ARGS    = (
        ( $ENV{GIT_DIR}       ? ( directory   => $ENV{GIT_DIR} )       : () ),
        ( $ENV{GIT_WORK_TREE} ? ( worktree    => $ENV{GIT_WORK_TREE} ) : () ),
        ( $ENV{BASE_BRANCH}   ? ( base_branch => $ENV{BASE_BRANCH} )   : () ),
    );
    return $Test::Perl::Critic::Git::TEST->exported_to($caller);
}

sub critic_on_changed_ok {
    my ($ar_dirs)         = @_;
    $ar_dirs = [Cwd::cwd] if !$ar_dirs || scalar @{$ar_dirs} == 0;
    my $hr_changed_files  = Git::Diff->new(%Test::Perl::Critic::Git::GIT_ARGS)->changes_by_line;
    my $ar_matching_files = _matching_files($ar_dirs, $hr_changed_files);
    $hr_changed_files     = { map { ( $hr_changed_files->{$_} ? ( $_, $hr_changed_files->{$_} ) : () ) } @{$ar_matching_files} };
    my $o_critic = Perl::Critic->new(%Test::Perl::Critic::Git::CRITIC_ARGS);
    Perl::Critic::Violation::set_format( $o_critic->config->verbose );

    $hr_changed_files->{$_}->{violations} = [ $o_critic->critique($_) ] for keys %{$hr_changed_files};
    my @a_changed_files = sort keys %{$hr_changed_files};
    my $i_tests_ok      = 0;
    my $i_files_to_test = 0;

    for my $s_file_name (@a_changed_files) {
        my $hr_changed_file = $hr_changed_files->{$s_file_name};
        next if scalar @{ $hr_changed_file->{violations} } == 0;
        $i_files_to_test++;
        my @a_violations = grep { exists $hr_changed_file->{addition}->{ $_->line_number } } @{ $hr_changed_file->{violations} };
        if ( scalar @a_violations == 0 ) {
            $Test::Perl::Critic::Git::TEST->ok( 1, $s_file_name . ' changes from master critic test' );
            $i_tests_ok++;
            next;
        }
        $Test::Perl::Critic::Git::TEST->ok( 0, $s_file_name . ' changes from master critic test' );
        $Test::Perl::Critic::Git::TEST->diag(qq{\n  Perl::Critic had errors in "$s_file_name":\n});
        $Test::Perl::Critic::Git::TEST->diag( q{  } . $_ ) for @a_violations;
    }
    return $Test::Perl::Critic::Git::TEST->ok( 1, 'No files to check' ) if !$i_files_to_test;
    return $i_files_to_test == $i_tests_ok;
}

1;

__END__

=encoding utf8

=head1 NAME

Test::Perl::Critic::Git - Test module to run perl critic on changed git files

=head1 VERSION

Version 0.000103

=head1 SUBROUTINES/METHODS

=head2 critic_on_changed_ok

Run perl critic on changed files and and raises errors, or even not :-D

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

L<Git::Diff|Git::Diff>,L<Perl::Critic|Perl::Critic>,L<Test::Builder|Test::Builder>,
L<Perl::Critic::Utils|Perl::Critic::Utils>,L<Perl::Critic::Violation|Perl::Critic::Violation>

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
