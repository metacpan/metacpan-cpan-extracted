package cPanel::TaskQueue::PluginManager;
$cPanel::TaskQueue::PluginManager::VERSION = '0.850';
use strict;
use cPanel::TaskQueue ();

my %plugins_list;

sub load_all_plugins {
    my %opts = @_;

    die "No directory list supplied.\n" unless exists $opts{'directories'} and 'ARRAY' eq ref $opts{'directories'};
    die "No namespace list supplied.\n" unless exists $opts{'namespaces'}  and 'ARRAY' eq ref $opts{'namespaces'};
    foreach my $dir ( @{ $opts{'directories'} } ) {
        foreach my $ns ( @{ $opts{'namespaces'} } ) {
            load_plugins( $dir, $ns );
        }
    }
}

sub load_plugins {
    my ( $root_dir, $namespace ) = @_;

    die "No directory supplied for finding plugins.\n" unless defined $root_dir and length $root_dir;
    die "Supplied directory '$root_dir' does not exist.\n" unless -d $root_dir;
    die "Supplied directory '$root_dir' not part of Perl's include path.\n" unless grep { $_ eq $root_dir } @INC;

    die "No namespace for plugins specified.\n" unless defined $namespace and length $namespace;
    die "Namespace '$namespace' not a valid Perl namespace.\n"
      unless $namespace =~ m{^ \w+ (?: :: \w+ )* $}x;

    my $ns_dir = join( '/', $root_dir, split( '::', $namespace ) );

    # not having the namespace in that root is not an error.
    return unless -d $ns_dir;

    opendir( my $dir, $ns_dir ) or die "Unable to read directory '$ns_dir': $!\n";
    my @files = grep { !/^\.\.?$/ } readdir($dir);
    closedir($dir) or die "Failed to close directory '$ns_dir': $!\n";

    # TODO: Do we want to handle subdirectories?
    my @modules = map { ( /^(\w+)\.pm$/ and -f "$ns_dir/$_" ) ? $1 : () } @files;
    foreach my $mod (@modules) {
        load_plugin_by_name( $namespace . '::' . $mod );
    }
}

sub load_plugin_by_name {
    my ($modname) = @_;

    # Don't try to reload.
    return if exists $plugins_list{$modname};

    eval "require $modname;";    ## no critic (ProhibitStringyEval)
    if ($@) {
        warn "Failed to load '$modname' plugin: $@\n";
        return;
    }

    my $register = UNIVERSAL::can( $modname, 'to_register' );
    unless ( defined $register ) {
        warn "Plugin '$modname' not registered, no 'to_register' method.\n";
        return;
    }
    my $num_reg = 0;
    my @commands;
    foreach my $reg ( $register->() ) {
        unless ( 'ARRAY' eq ref $reg and 2 == @{$reg} ) {
            warn "Plugin '$modname': invalid registration entry\n";
            next;
        }
        eval { cPanel::TaskQueue->register_task_processor( @{$reg} ); } or do {
            warn "Plugin '$modname' register failed: $@\n";
            next;
        };
        ++$num_reg;
        push @commands, $reg->[0];    # Add command name to list.
    }

    if ($num_reg) {
        $plugins_list{$modname} = \@commands;
        return 1;
    }
    return;
}

sub list_loaded_plugins {
    return keys %plugins_list;
}

sub get_plugins_hash {
    my %clone;
    while ( my ( $module, $commands ) = each %plugins_list ) {
        $clone{$module} = [ @{$commands} ];
    }
    return \%clone;
}

1;

__END__

Copyright (c) 2010, cPanel, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

