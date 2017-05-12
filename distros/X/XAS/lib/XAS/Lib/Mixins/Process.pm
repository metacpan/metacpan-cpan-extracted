package XAS::Lib::Mixins::Process;

our $VERSION = '0.01';
my $mixin;

BEGIN {
    $mixin = 'XAS::Lib::Mixins::Process::Unix';
    $mixin = 'XAS::Lib::Mixins::Process::Win32' if ($^O eq 'MSWin32');
}

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  mixin   => $mixin,
  mixins  => 'proc_status',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Mixins::Process - A mixin for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   debug   => 0,
   version => '0.01',
   base    => 'XAS::Base',
   mixin   => 'XAS::Lib::Mixins::Process'
;

=head1 DESCRIPTION

This mixin provides a way to check processes on the current system.

=head1 METHODS

=head2 proc_status($pid)

Returns the status of the process id.

=over 4

=item B<$pid>

The process id to check.

=back

=head1 SEE ALSO

=over 4

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
