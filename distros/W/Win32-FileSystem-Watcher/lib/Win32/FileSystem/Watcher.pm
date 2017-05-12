package Win32::FileSystem::Watcher;

use version; our $VERSION = qv('0.1.0');

require Exporter;
our @ISA = qw(Exporter Win32::FileSystem::Watcher::SimpleAccessors);

use Win32::MMF::Shareable;
use Win32::FileSystem::Watcher::Constants;
use Win32::FileSystem::Watcher::Synchronous;
use POSIX ":sys_wait_h";
use Win32::FileSystem::Watcher::SimpleAccessors;
use Carp;
use strict;
use warnings;

our @EXPORT = ( keys %{&FILE_NOTIFICATION_CONSTANTS}, keys %{&FILE_ACTION_CONSTANTS} );

__PACKAGE__->accessor('path');
__PACKAGE__->accessor('notify_filter');
__PACKAGE__->accessor('watch_sub_tree');
__PACKAGE__->accessor('watcher');
__PACKAGE__->accessor('child_pid');
__PACKAGE__->accessor('monitoring');
__PACKAGE__->accessor('results');
__PACKAGE__->accessor('mmf_options');

sub new {
    my $pkg = shift;
    croak 'Need a path' unless @_ >= 1;
    my ( $path, ) = shift;
    my $self = {
        watch_sub_tree => 1,
        notify_filter  => FILE_NOTIFY_ALL,
        mmf_options => { size => 2 * 1024 * 1024 },
        @_,
    };
    bless $self, $pkg;
    $self->path($path);
    $self->monitoring(0);
    return $self;
}

sub start {
    my $self = shift;
    carp 'Monitoring already started' if $self->monitoring;

    $self->child_pid( fork() );
    die 'cannot fork.' unless defined( $self->child_pid );

    if ( !$self->child_pid ) {

        # Child
        $self->_init_watcher();

        $self->watcher(
            Win32::FileSystem::Watcher::Synchronous->new(
                $self->path,
                notify_filter  => $self->notify_filter,
                watch_sub_tree => $self->watch_sub_tree,
            )
        );
        while ( $self->monitoring ) {
            my @results = $self->watcher->get_results();
            if ( @results > 0 ) {
                my $r = $self->results || [];
                push @$r, $_ foreach @results;

                $self->results($r);
            }
        }
        exit;
    }

    $self->_init_watcher();
}

sub stop {
    my $self = shift;
    carp 'Not monitoring.' unless $self->monitoring;
    $self->monitoring(0);
    kill 9, $self->child_pid;
}

sub get_results {
    my $self    = shift;
    my @results = ();

    my $results = $self->results;
    if ($results) {
        push @results, $_ foreach @$results;
        $self->results(0);
    }
    return @results;
}

sub _init_watcher {
    my $self = shift;

    tie $self->{results}, "Win32::MMF::Shareable", 'results', $self->mmf_options
      or carp 'Cannot create memory mapped namespace';
    $self->results(0);
    tie $self->{monitoring}, "Win32::MMF::Shareable", 'monitoring', $self->mmf_options
      or carp 'Cannot create memory mapped namespace';
    $self->monitoring(1);

}

sub DESTROY {
    my $self = shift;
    if ( $self->monitoring ) {
        $self->stop();
    }
}

1;

__END__

=head1 NAME

Win32::FileSystem::Watcher - Watch a Win32 file system for changes (asynchronously).


=head1 SYNOPSIS

    use Win32::FileSystem::Watcher;
    
    my $watcher = Win32::FileSystem::Watcher->new( "c:\\" );

    # or

    my $watcher = Win32::FileSystem::Watcher->new(
        "c:\\",
        notify_filter  => FILE_NOTIFY_ALL,
        watch_sub_tree => 1,
    );

    $watcher->start();
    print "Monitoring started.";

    sleep(5);

    # Get a list of changes since start().
    my @entries = $watcher->get_results();

    # Get a list of changes since the last get_results()
    @entries = $watcher->get_results();

    # ... repeat as needed ...
    
    $watcher->stop(); # or undef $watcher

    foreach my $entry (@entries) {
        print $entry->action_name . " " . $entry->file_name . "\n";
    }

    # Restart monitoring
    
    # $watcher->start();
    # ...
    # $watcher->stop();
    
    


=head1 DESCRIPTION

TODO

=head1 SUBROUTINES/METHODS

TODO

=head1 DIAGNOSTICS

TODO

=head1 DEPENDENCIES

Win32::API
Win32::MMF

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Andres N. Kievsky (ank@ank.com.ar)
Patches are welcome.

=head1 AUTHOR

Andres N. Kievsky (ank@ank.com.ar)



=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008 Andres N. Kievsky (ank@ank.com.ar). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
