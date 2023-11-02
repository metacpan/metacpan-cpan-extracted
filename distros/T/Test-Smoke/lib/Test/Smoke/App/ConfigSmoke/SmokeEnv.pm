package Test::Smoke::App::ConfigSmoke::SmokeEnv;
use warnings;
use strict;

our $VERSION = '0.002';

use Exporter 'import';
our @EXPORT = qw/
    config_smoke_env
    check_build_configs_file
    report_build_configs
/;

use Test::Smoke::App::AppOption;
use Test::Smoke::App::Options;
use Test::Smoke::BuildCFG;
use Test::Smoke::Util qw/ skip_config /;

=head1 NAME

Test::Smoke::App::ConfigSmoke::SmokeEnv - Mixin for Test::Smoke::App::ConfigSmoke.

=head1 DESCRIPTION

These methods will be added to the L<Test::Smoke::App::ConfigSmoke> class.

=head2 config_smoke_env

Configure options: C<v>, C<smartsmoke>, C<killtime>, C<renice>, C<umask> and C<cfg>

Also C<perl5lib> and C<perl5opt>

=cut

sub config_smoke_env {
    my $self = shift;

    print "\n-- Environment section --\n";
    my @options = qw/ v smartsmoke killtime /;
    for my $opt (@options) {
        my $option = Test::Smoke::App::Options->$opt;
        $self->handle_option($option);
    }

     unless ($^O =~ m/^(?: mswin32 | vms )$/xi) {
        $self->handle_option(renice_option());
        $self->handle_option(umask_option());
     }
     for my $env (qw/ PERL5LIB PERL5OPT /) {
        if (my $p5env = $ENV{$env}) {
            $self->handle_option(option_from_env($env));
        }
    }

    $self->handle_option(Test::Smoke::App::Options->cfg);
    $self->check_build_configs_file();
}

=head2 check_build_configs_file

This check, creates and checks a build-configs-file.

=cut

sub check_build_configs_file {
    my $self = shift;

    my $cfg;
    my $buildcfg_file = $self->current_values->{cfg};
    if (-f $buildcfg_file) {
        $cfg = Test::Smoke::BuildCFG->new($buildcfg_file);
    }
    else {
        my $dft_config = Test::Smoke::BuildCFG->os_default_buildcfg($^O);
        $cfg = Test::Smoke::BuildCFG->new(\$dft_config);
    }

    my @current_config = split(m{\n}, $cfg->source);
    my $old_config = -f $buildcfg_file
        ? join("", grep { ! m/^#/ } @current_config)
        : "";

    my @must_option = ( );
    my @no_option = ( '-Uuseperlio' );
    GIVEN: {
        local $_ = lc($self->sysinfo->_osname);

        my $os_major = $self->sysinfo->_osvers =~ m/(\d+)/ ? $1 : 0;

        /darwin/ && $os_major >= 8 and do {
            push @no_option, qw( -Duselongdouble -Dusemorebits );
            last GIVEN;
        };

        /darwin|bsd/i && do {
            push @no_option, qw( -Duselongdouble -Dusemorebits -Duse64bitall );
        };

        /linux/i && do {
            push @no_option, qw( -Duse64bitall );
        };

        /mswin32/i && do {
            my %compilers = get_avail_w32compilers();
            my $cc_info = $compilers{ $self->current_values->{w32cc} } or last GIVEN;
            # Add -DCCHOME=C:\Strawberry\c for strawberryperl-gcc
            if ($cc_info->{ccversarg} =~ /strawberryperl/i) {
                (my $cchome = $cc_info->{ccbin}) =~ s{.bin.gcc\.exe$}{}i;
                push @must_option, "-DCCHOME=$cchome";
            }
        };

        /cygwin/i && do {
            push @no_option, qw( -Duse64bitall -Duselongdouble -Dusemorebits );
        };
    }

    for my $option ( @no_option ) {
        !m/^#/ && m/\Q$option\E/ && s/^/#/ for @current_config;
    }
    for my $option ( @must_option ) {
        unshift @current_config, ("==\n", "$option\n", "==\n")
            unless grep { /^\Q$option\E/ } @current_config;
    }

    my $new_config = join("", grep { ! m/^#/ } @current_config);
    return if $old_config eq $new_config and -f $buildcfg_file;

    my $display = join("", map { chomp; "\t$_\n" } grep { ! m/^#/ } @current_config);

    print "We removed/added some Configure options.\n";
    print <<"EOT";
Some options that do not apply to your platform were found.
(Comment-lines left out below, but will be written to disk.)
$display
EOT
    printf "\n [%s]\n", $buildcfg_file;
    my $save_file = $self->handle_option(save_buildcfg_file_option());
    delete($self->current_values->{save_buildcfg});

    if (! $save_file) {
        print "!!!!!\nContents not saved.\n!!!!!\n";
        print "Please, fix yourself.\n";
        return;
    }
    BACKUP_FILE: if (-f $buildcfg_file) {
        my $backup_file = "${buildcfg_file}.bak";
        if (-f $backup_file) {
            1 while unlink $backup_file;
        }
        rename($buildcfg_file, $backup_file)
            or do {
            print "!!!!!\nProblem: cannot move to '$backup_file': $!\n!!!!!\n";
            print "Original contents will be lost.\n";
            last BACKUP_FILE;
        };
        print "  >> Created '$backup_file'\n";
    }
    SAVE_FILE: if ( open(my $fh, '>', $buildcfg_file) ) {
        print {$fh} $_ for map { chomp; "$_\n" } @current_config;
        close($fh) or do{
            print "!!!!!\nProblem: cannot close($buildcfg_file): $!\n!!!!!\n";
            print "Content might be lost.\n";
            last SAVE_FILE;
        };
        print "  >> Created '$buildcfg_file'\n";
    }
    else {
        print "!!!!!\nProblem: cannot create($buildcfg_file): $!\n!!!!!\n";
        print "Please, fix this yourself.\n";
    }
}

=head2 report_build_configs

=cut

sub report_build_configs {
    my $self = shift;
    my $bcfg = Test::Smoke::BuildCFG->new($self->current_values->{cfg});

    my $report = '';
    my( $skips, $smokes ) = ( 0, 0 );
    for my $cfg ( $bcfg->configurations ) {
        if ( skip_config( $cfg ) ) {
            $report .= " skip: '$cfg'\n";
            $skips++;
        } else {
            $report .= "smoke: '$cfg'\n";
            $smokes++;
        }
    }
    my $total = $skips + $smokes;
    $report .= "Smoke $smokes; skip $skips (total $total)\n";
    return $report;
}

=head2 renice_option

This option C<renice> is in the config-file, but only needed to write the
shell-script that runs the smoke.

=cut

sub renice_option {
    return Test::Smoke::App::AppOption->new(
        name       => 'renice',
        allow      => [0 .. 20],
        default    => 0,
        helptext   => "Unix way to set priority on processes",
        configtext => "With which value should 'renice' be run?\n"
            . "(leave '0' for no renice)",
        configalt => sub { [0 .. 20] },
        configdft => sub { 0 },
    );
}

=head2 umask_option

This option C<umask> is in the config-file, but is only needed to write the
shell-script that runs the smoke.

=cut

sub umask_option {
    return Test::Smoke::App::AppOption->new(
        name       => 'umask',
        allow      => undef,
        default    => 0,
        helptext   => "Unix way to set authorisation on files",
        configtext => "What 'umask' can be used ('0' preferred)?\n",
        configalt => sub { [] },
        configdft => sub { 0 },
    );
}

=head2 save_buildcfg_file_option

This option is not in the config-file, it's for local use only.

=cut

sub save_buildcfg_file_option {
    return Test::Smoke::App::AppOption->new(
        name       => 'save_buildcfg_file',
        default    => 1,
        helptext   => "Buildconfigurations have changed",
        configtext => "Would you like to save the file?",
        configtype => 'prompt_yn',
        configalt  => sub { [qw/ Y n /] },
        configdft  => sub {'y'},
    );
}

sub option_from_env {
    my $env = shift;
    my $opt = lc($env);
    return Test::Smoke::App::AppOption->new(
        name       => $opt,
        option     => '=s',
        default    => '',
        helptext   => "Sets $env in the smoke script.",
        configtext => "I see you have $env set. Use this value in the smoke script?
\t(Make empty, to not have $env)",
        configdft  => sub { $ENV{$env} },
    );
}

1;

=head1 COPYRIGHT

(c) 2020, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
