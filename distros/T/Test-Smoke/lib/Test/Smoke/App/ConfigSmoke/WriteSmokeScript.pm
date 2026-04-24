package Test::Smoke::App::ConfigSmoke::WriteSmokeScript;
use warnings;
use strict;

our $VERSION = '0.002';

use Exporter 'import';
our @EXPORT = qw/ write_smoke_script write_as_shell write_as_cmd /;

use Cwd;
use File::Spec;
use POSIX qw/ strftime /;
use Test::Smoke::App::Options;
use Test::Smoke::Util::FindHelpers qw/ whereis /;

=head1 NAME

Test::Smoke::App::ConfigSmoke::WriteSmokeScript - Mixin for L<Test::Smoke::App::ConfigSmoke>

=head1 DESCRIPTION

These methods will be added to the L<Test::Smoke::App::ConfigSmoke> class.

=head2 write_smoke_script

General method to write the smoke-script for different "shells".

=cut

sub write_smoke_script {
    my $self = shift;
    my ($cronbin, $crontime) = @_;

    if ($^O eq 'MSWin32') {
        $self->{_smoke_script} = $self->prefix . '.cmd';
        $self->{_smoke_script_abs} = Cwd::abs_path($self->smoke_script);
        $self->write_as_cmd($cronbin, $crontime);
    }
    elsif ($^O eq 'VMS') {
        $self->{_smoke_script} = $self->prefix . '.com';
        $self->{_smoke_script_abs} = Cwd::abs_path($self->smoke_script);
        print "$^O not (fully) supported yet.\n";
    }
    else {
        $self->{_smoke_script} = $self->prefix . '.sh';
        $self->{_smoke_script_abs} = Cwd::abs_path($self->smoke_script);
        $self->write_as_shell($cronbin, $crontime);
    }
}

=head2 write_as_shell

Configure options C<makeopt>, C<testmake>, C<harnessonly>, C<hasharness3> and C<harness3opts>.

=cut

sub write_as_shell {
    my $self = shift;
    my ($cronbin, $crontime) = @_;

    print "\n-- Write shell script --\n";

    $crontime ||= '22:25';
    my $cronline = $self->schedule_entry_crontab($cronbin, $crontime);

    my $p5env = '';
    for my $env (qw/ PERL5LIB PERL5OPT /) {
        if (my $value = $self->current_values->{lc($env)}) {
            $p5env = "$env='$value'\nexport $env\n";
            delete($self->current_values->{lc($env)});
        }
    }

    my $handle_lock = '    echo "We seem to be running (or remove $LOCKFILE)" >& 2'
                    . "\n    exit 200";
    if ($self->current_values->{killtime}) {
        $handle_lock = "    # Not sure about this, so I will keep the old behaviour\n"
                     . "    # tssmokeperl.pl will exit(42) on timeout\n"
                     . "    # continue='--continue'\n"
                     . $handle_lock;
    }
    my @template_vars = (
        $self->smoke_script, $0, $self->VERSION,
        strftime("%Y-%m-%dT%H:%M:%S%z", localtime),
        $self->dollar_0,
        $cronline,
        ($self->current_values->{renice} ? "" : "# ") . "renice " . $self->current_values->{renice} . " \$\$",
        Cwd::abs_path(File::Spec->curdir),
        $self->configfile,
        ($self->current_values->{qfile} ? $^X : "# $^X"),
        File::Spec->catfile($FindBin::Bin, 'tshandlequeue.pl'),
        $self->prefix. ".lck",
        $handle_lock,
        $p5env,
        $self->current_values->{umask},
        $FindBin::Bin, $ENV{PATH},
        $^X, File::Spec->catfile($FindBin::Bin, 'tssmokeperl.pl'), $self->current_values->{lfile},
    );

    my $smoke_script = sprintf(<<'EO_SH', @template_vars);
#! /bin/sh
#
# %s: written by %s v%s
# on %s
# NOTE: Changes made in this file will be *lost*
#       after rerunning %s
#
# cron: %s
%s
cd %s
CFGNAME=${CFGNAME:-%s}
%s %s - "$CFGNAME"
LOCKFILE=${LOCKFILE:-%s}
continue=''
if test -f "$LOCKFILE" && test -s "$LOCKFILE" ; then
%s
fi
echo "$CFGNAME" > "$LOCKFILE"

%s
umask %s
PATH=%s:%s
export PATH
%s %s -c "$CFGNAME" $continue $* > "%s" 2>&1

rm "$LOCKFILE"
EO_SH

    my $jcl = $self->smoke_script;
    if (open(my $fh, '>', $jcl)) {
        print {$fh} $smoke_script;
        close($fh) or do {
            print "!!!!!\nProblem: cannot close($jcl): $!\n!!!!!\n";
            die "Please, fix yourself.\n";
        };

        chmod(0755, $jcl) or warn "Cannot chmod 0755 $jcl: $!";
        print "  >> Created '$jcl'\n";
    }
    else {
        print "!!!!!\nProblem: cannot create($jcl): $!\n!!!!!\n";
        die "Please, fix yourself.\n";
    }
}

=head2 write_as_cmd

Write the smoke-script as a MS-cmd script.

=cut

sub write_as_cmd {
    my $self = shift;
    my ($cronbin, $crontime) = @_;

    $crontime ||= '22:25';
    my $cronline = $cronbin =~ m/schtasks/
        ? $self->query_entry_ms_schtasks($cronbin)
        : $self->schedule_entry_ms_at($cronbin, $crontime);

    my $p5env = '';
    for my $env (qw/ PERL5LIB PERL5OPT /) {
        if (my $value = $self->current_values->{lc($env)}) {
            $p5env = "set $env=$value\n";
            delete($self->current_values->{lc($env)});
        }
    }

    my @template_vars = (
        $self->smoke_script, $0, $self->VERSION,
        strftime("%Y-%m-%dT%H:%M:%S%z", localtime),
        $self->dollar_0,
        $p5env,
        $cronline,
        Cwd::abs_path(File::Spec->curdir),
        $self->configfile,
        ($self->current_values->{qfile} ? qq["$^X"] : qq[REM "$^X"]),
        File::Spec->catfile($FindBin::Bin, 'tshandlequeue.pl'),
        $self->prefix. ".lck",
        File::Spec->canonpath($FindBin::Bin), $ENV{PATH},
        $^X, File::Spec->catfile($FindBin::Bin, 'tssmokeperl.pl'), $self->current_values->{lfile},
    );

    my $smoke_script = sprintf(<<'EO_BAT', @template_vars);
@echo off
setlocal
REM .
REM %s: written by %s v%s
REM on %s
REM NOTE: Changes made in this file will be \*lost\*
REM       after rerunning %s
REM . 
REM If you find hanging XCOPY during smoking, uncomenting
REM the next line might fix it?
REM set COPYCMD=/Y %%COPYCMD%%
REM .
%s
REM query scheduler: %s

set WD=%s\
REM Change drive-Letter, then directory
for %%%%L in ( "%%WD%%" ) do %%%%~dL
cd "%%WD%%"
if "%%CFGNAME%%"  == "" set CFGNAME=%s
%s %s -c "%CFGNAME%"
if "%%LOCKFILE%%" == "" set LOCKFILE=%s
if NOT EXIST %%LOCKFILE%% goto START_SMOKE
    FIND "%%CFGNAME%%" %%LOCKFILE%% > NUL:
    if ERRORLEVEL 1 goto START_SMOKE
    echo We seem to be running [or remove %%LOCKFILE%%]>&2
    goto :EOF

:START_SMOKE
    echo %%CFGNAME%% > %%LOCKFILE%%
    set OLD_PATH=%%PATH%%
    set PATH=%s;%s
    %s %s -c "%%CFGNAME%%" %%* > "%s" 2>&1
    set PATH=%%OLD_PATH%%

del %%LOCKFILE%%
EO_BAT

    my $jcl = $self->smoke_script;
    if (open(my $fh, '>', $jcl)) {
        print {$fh} $smoke_script;
        close($fh) or do {
            print "!!!!!\nProblem: cannot close($jcl): $!\n!!!!!\n";
            die "Please, fix yourself.\n";
        };

        chmod(0755, $jcl) or warn "Cannot chmod 0755 $jcl: $!";
        print "  >> Created '$jcl'\n";
    }
    else {
        print "!!!!!\nProblem: cannot create($jcl): $!\n!!!!!\n";
        die "Please, fix yourself.\n";
    }
}

=head2 schedule_entry

Returns a string that can be used to add the entry to the scheduler.

=cut

sub schedule_entry {
    my( $script, $cron, $crontime ) = @_;

    return '' unless $crontime;
    my ($hour, $min) = $crontime =~ /(\d+):(\d+)/;

    my $entry;
    if ($^O eq 'MSWin32') {
        $entry = sprintf(
            qq[$cron %02d:%02d /EVERY:M,T,W,Th,F,S,Su "%s"],
            $hour, $min, $script
        );
    } else {
        $entry = sprintf(qq[%02d %02d * * * '%s'], $min, $hour, $script);
    }
    return $entry;
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

