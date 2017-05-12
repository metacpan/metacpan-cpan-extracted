# $File: //depot/cpan/Module-Install/lib/Module/Install/Scripts.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1397 $ $DateTime: 2003/03/23 21:44:22 $ vim: expandtab shiftwidth=4

package Module::Install::Scripts;
use Module::Install::Base; @ISA = qw(Module::Install::Base);
$VERSION = '0.01';
use strict;
use File::Spec;
use File::Basename;
use Config;

sub prompt_script {
    my ($self, $script_file) = @_;
    my @script_lines = $self->_read_script($script_file);
    my $prompt = '';
    my $abstract = '';
    my $default = 'n';

    for my $line (@script_lines) {
        last unless $line =~ /^#/;
        $prompt = $1 
          if $line =~ /^#\s*prompt:\s+(.*)/;
        $abstract = $1 
          if $line =~ /^#\s*abstract:\s+(.*)/;
        $default = $1 
          if $line =~ /^#\s*default:\s+(.*)/;
    }
    if (not $prompt) {
        my $script_name = basename($script_file);
        $prompt = "Do you want to install '$script_name'";
        $prompt .= " ($abstract)" if $abstract;
        $prompt .= '?';
    }
    return unless $self->prompt($prompt, $default) =~ /^(y|yes)$/i;
    $self->install_script($script_file);
}

sub install_script {
    my ($self, $script_file) = @_;
    my @script_lines = $self->_read_script($script_file);
    if (not -d 'inc/SCRIPTS') {
        mkdir('inc/SCRIPTS', 0777)
          or die "Can't make directory 'inc/SCRIPTS'";
    }

    if ($script_lines[0] =~ /^#!/) {
        my $startperl = $Config{startperl};
        $script_lines[0] =~ s/^#!\S*/$startperl/;
    }
    else {
        push @script_lines, $Config{startperl} . " -w\n";
    }

    my $new_script = 'inc/SCRIPTS/' . basename($script_file);
    open SCRIPT, '>', $new_script
      or die "Can't open '$new_script' for output\n";
    print SCRIPT $_ for @script_lines;
    close SCRIPT;
    my $args = $self->makemaker_args;
    my $exe_files = $args->{EXE_FILES} || [];
    push @$exe_files, $new_script;

    $self->makemaker_args( EXE_FILES => $exe_files );
}

sub _read_script {
    my ($self, $script_file) = @_;
    local *SCRIPT;
    open SCRIPT, $script_file
      or die "Can't open '$script_file' for input";
    <SCRIPT>;
}

1;
