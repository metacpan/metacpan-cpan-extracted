package XAS::Lib::Spawn;

our $VERSION = '0.01';

my $mixin;

BEGIN {
    $mixin = 'XAS::Lib::Spawn::Unix';
    $mixin = 'XAS::Lib::Spawn::Win32' if ($^O eq 'MSWin32');    
}

use Hash::Merge;
use Badger::Filesystem 'Cwd File';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  mixin     => "XAS::Lib::Mixins::Process $mixin",
  utils     => 'dotid trim',
  accessors => 'merger',
  vars => {
    PARAMS => {
      -command     => 1,
      -priority    => { optional => 1, default => 0 },
      -environment => { optional => 1, default => {} },
      -umask       => { optional => 1, default => '0022' },
      -group       => { optional => 1, default => 'nobody' },
      -user        => { optional => 1, default => 'nobody' },
      -directory   => { optional => 1, default => Cwd, isa => 'Badger::Filesystem::Directory' },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'merger'} = Hash::Merge->new('RIGHT_PRECEDENT');

    return $self;

}

sub _resolve_path {
    my $self       = shift;
    my $command    = shift;
    my $extensions = shift;
    my $xpaths     = shift;

    # Make the path to the progam absolute if it isn't already.  If the
    # path is not absolute and if the path contains a directory element
    # separator, then only prepend the current working to it.  If the
    # path is not absolute, then look through the PATH environment to
    # find the executable.

    my $path = File($command);

    if ($path->is_absolute) {

        if ($path->exists) {

            return $path->absolute;

        }

    } elsif ($path->is_relative) {

        if ($path->name eq $path) {

            foreach my $xpath (@$xpaths) {

                next if ($xpath eq '');

                if ($path->extension) {

                    my $p = File($xpath, $path->name);

                    if ($p->exists) {

                        return $p->absolute;

                    }

                } else {

                    foreach my $ext (@$extensions) {

                        my $p = File($xpath, $path->basename . $ext);

                        if ($p->exists) {

                            return $p->absolute;

                        }

                    }

                }

            }

        } else {

            my $p = File($path->absoulte);

            if ($p->exists) {

                return $p->absolute;

            }

        }

    }

    $self->throw_msg(
        dotid($self->class) . '.resolve_path.path',
        'process_location',
        $command
    );

}

1;

__END__

=head1 NAME

XAS::Lib::Spawn - A class to spawn detached processes within the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::Spawn;

 my $process = XAS::Lib::Spawn->new(
    -command => 'perl test.pl'
 );
 
 $process->run();

=head1 DESCRIPTION

This class spawns a process to run in the back ground in a platform
independent way. Mixins are loaded to handle the differences between
Unix/Linux and Windows.

=head1 METHODS

=head2 new

This method initialized the module and takes the following parameters:

=over 4

=item B<-command>

The command to run.

=item B<-directory>

The optional directory to start the process in. Defaults to the current
directory of the parent process.

=item B<-environment>

Optional, addtional environmnet variables to provide to the process.
The default is none.

=item B<-group>

The group to run the process under. Defaults to 'nobody'. This group
may not be defined on your system. This option is not implemented on Windows.

=item B<-priority>

The optional priority to run the process at. Defaults to 0. This option
is not implemented on Windows.

=item B<-umask>

The optional protection mask for the process. Defaults to '0022'. This
option is not implemented on Windows.

=item B<-user>

The optional user to run the process under. Defaults to 'nobody'. This user
may not be defined on your system. This option is not implemented on Windows.

=back

=head2 run

Start the process. It returns the pid of that process.

=head2 status

Returns the status of the process. The status could be one of the follow:

=over 4

=item 6 - suspended ready

=item 5 - suspended blocked

=item 4 - blocked

=item 3 - running

=item 2 - ready

=item 1 - other

=item 0 - unknown

=back

=head2 pause

Pause the process, returns 1 on success.

=head2 resume

Resume the process, returns 1 on success.

=head2 stop

Stop the process, returns 1 on success.

=head2 kill

Kill the process, returns 1 on success.

=head2 wait

Waits for the process to finish, returns 0 when the process is done.
This method may return a -1 if the processes was reaped before the
wait is called.

=head2 errorlevel

Returns the exit code of the process, or a -1 if the exit code is not
available.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Spawn::Unix|XAS::Lib::Spawn::Unix>

=item L<XAS::Lib::Spawn::Win32|XAS::Lib::Spawn::Win32>

=item L<XAS::Lib::Process|XAS::Lib::Process>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
