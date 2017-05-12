package XAS::Lib::Pidfile::Win32;

our $VERSION = '0.01';

use Win32::OLE('in');
use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'run_cmd trim compress dotid',
  constants => 'TRUE FALSE',
  mixins    => 'is_running scan_name',
  constant => {
    wbemFlagReturnImmediately => 0x10,
    wbemFlagForwardOnly => 0x20,    
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub scan_name {
    my $self = shift;


    my $c = sprintf('perl  %s', $self->env->script);

    return compress($c);

}

sub is_running {
    my $self = shift;

    my $computer = 'localhost';
    my $pid = $self->_get_pid(); 
    my $commandline = $self->scan_name();

    if (defined($pid)) {

        # query wmi for the an existing process with this pid

        my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2") or
            $self->throw_msg(
                dotid($self->class) . '.is_running.winole',
                'unexpected',
                'WMI connection failed'
            );

        my $colItems = $objWMIService->ExecQuery(
            "SELECT * FROM Win32_Process WHERE ProcessID = $pid",
            "WQL",
            wbemFlagReturnImmediately | wbemFlagForwardOnly
        );

        foreach my $objItem (in $colItems) {

            my $line = compress($objItem->{CommandLine});
            $self->log->debug(sprintf("\"%s\" = \"%s\"", $commandline, $line));

            return $pid if ($commandline =~ /$line/);

        }

    }

    return undef;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::PidFile::Win32 - A mixin class to scan for processes on Win32

=head1 DESCRIPTION

This is a mixin class to provide process scanning on a Win32 platform. It
invokes WMI thru OLE to do the process scan.

=head1 METHODS

=head2 is_running

Please see L<XAS::Lib::PidFile|XAS::Lib::PidFile> for usage.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
