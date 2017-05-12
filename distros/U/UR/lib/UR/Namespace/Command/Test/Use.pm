
package UR::Namespace::Command::Test::Use;

use strict;
use warnings;
use UR;
our $VERSION = "0.46"; # UR $VERSION;
use Cwd;
use YAML;

class UR::Namespace::Command::Test::Use {
    is => "UR::Namespace::Command::RunsOnModulesInTree",
    has_optional => [
        verbose             => { is => 'Boolean', doc => 'List each explicitly.' },
        summarize_externals => { is => 'Boolean', doc => 'List all modules used which are outside the namespace.' },
        exec                => { is => 'Text',    doc => 'Execute the specified Perl _after_ using all of the modules.' },
    ]
};

sub help_brief {
    "Tests each module for compile errors by 'use'-ing it.  Also reports on any libs added to \@INC by any modules (bad!)."
}

sub help_synopsis {
    return <<EOS
ur test use         

ur test use Some::Module Some::Other::Module

ur test use ./Module.pm Other/Module.pm
EOS
}

sub help_detail {
    my $self = shift;
    my $text = <<EOS;

Tests each module by "use"-ing it.  Failures are reported individually.

Successes are only reported individualy if the --verbose option is specified.

A count of total successes/failures is returned as a summary in all cases.

EOS
    $text .= $self->_help_detail_footer;
    return $text;
}

sub before {
    my $self = shift;
    $self->{success} = 0;
    $self->{failure} = 0;
    $self->{used_libs} = {};
    $self->{used_mods} = {};
    $self->{failed_libs} = [];
    $self->{default_print_fh} = fileno(select);
    $self->SUPER::before(@_);
}

sub for_each_module_file {
    my $self = shift;
    my $module_file = shift;
    my $namespace_name = $self->namespace_name;
    my %libs_before = map { $_ => 1 } @INC;
    my %mods_before = %INC if $self->summarize_externals;

    local $SIG{__DIE__};
    local $ENV{UR_DBI_MONITOR_SQL} = 1;
    local $ENV{APP_DBI_MONITOR_SQL} = 1;
    local *CORE::GLOBAL::exit = sub {};

    $self->debug_message("require $module_file");
    eval "require '$module_file'";

    my %new_libs = map { $_ => 1 } grep { not $libs_before{$_} } @INC;
    my %new_mods = 
        map { $_ => $module_file } 
        grep { not $_ =~ /^$namespace_name\// } 
        grep { not $mods_before{$_} } 
        keys %INC;
    if (%new_libs) {
        $self->{used_libs}{$module_file} = \%new_libs;
    }
    if (%new_mods) {
        for my $mod (keys %new_mods) {
            $self->{used_mods}{$mod} = $module_file;
        }
    }
    if ($@) {
        print "$module_file  FAILED:\n$@\n";
        $self->{failure}++;
        push @{$self->{failed_libs}}, $module_file;
    } elsif (fileno(select) != $self->{default_print_fh}) {
        # un-steal the default file handle back
        select(STDOUT);
        print "$module_file  FAILED DUE TO IMPROPER FILEHANDLE USE\n";
        $self->{failure}++;
        push @{$self->{failed_libs}}, $module_file;
    }
    else {
        print "$module_file  OK\n" if $self->verbose;
        $self->{success}++;
    }
    return 1;
}

sub after {
    my $self = shift;
    $self->status_message("SUCCESS: $self->{success}");
    $self->status_message("FAILURE: $self->{failure}");

    if ($self->{failure} > 0) {
        $self->status_message("FAILED LIBS: " . YAML::Dump($self->{failed_libs}));
    }
    
    if (%{ $self->{used_libs} }) {
        $self->status_message(
            "ROGUE LIBS: "
            . YAML::Dump($self->{used_libs})
        )
    }
    if ($self->summarize_externals) {
        $self->status_message(
            "MODULES USED: "
            . YAML::Dump($self->{used_mods})  
        );
    }
    if (my $src = $self->exec) {
        eval $src;
        $self->error_message($@) if $@;
    }
    return if $self->{failure}; 
    return 1;
}

1;

