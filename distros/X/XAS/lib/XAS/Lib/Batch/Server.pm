package XAS::Lib::Batch::Server;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Lib::Batch',
  utils   => ':validation',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub qstat {
    my $self = shift;
    my $p = validate_params(\@_, {
        -queue => { optional => 1, default => undef },
        -host  => { optional => 1, default => undef },
    });

    return $self->do_server_stat($p);

}

sub qenable {
    my $self = shift;
    my $p = validate_params(\@_, {
        -queue => { optional => 1, default => undef },
        -host  => { optional => 1, default => undef },
    });

    return $self->do_server_enable($p);

}

sub qdisable {
    my $self = shift;
    my $p = validate_params(\@_, {
        -queue => { optional => 1, default => undef },
        -host  => { optional => 1, default => undef },
    });

    return $self->do_server_disable($p);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Batch::Server - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::Batch::Server;

 my $server = XAS::Lib::Batch::Server->new();

 my $stat = $server->qstat();

=head1 DESCRIPTION

This module provides an interface for manipulating servers in a Batch System. 
Each available method is a wrapper around a given command. A command line
is built, executed, and the return code is checked. If the return code is
non-zero an exception is thrown. The exception will include the return code
and the first line from stderr.

Since each method is a wrapper, there is a corresponding man page for the 
actual command. They should also be checked when problems arise.

=head1 METHODS

=head2 new

This method initializes the module and takes these parameters:

=over 4

=item B<-interface>

The command line interface to use. This defaults to 
L<XAS::Lib::Batch::Interface::Torque|XAS::Lib::Batch::Interface::Torque>.

=back

=head2 qstat(...)

This method returns that status of a server. This status will be a hash 
reference of the parsed output on stdout. It takes the following parameters:

=over 4

=item B<-host>

The optional host that the server may be on. Defaults to 'localhost'.

=back

=head2 qdisable(...)

This method will disable a queue or if the queue is not given, batch processing
at the server. It takes the following parameters:

=over 4

=item B<-queue>

The optional name of the queue.

=item B<-host>

The optional host that the queue may be on. Defaults to 'localhost'.

=back

=head2 qenable(...)

This method will enable a queue or if the queue is not given, batch processing
at the server. It takes the following parameters:

=over 4

=item B<-queue>

The optional name of the queue.

=item B<-host>

The optional host that the queue may be on. Defaults to 'localhost'.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Batch|XAS::Lib::Batch>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
