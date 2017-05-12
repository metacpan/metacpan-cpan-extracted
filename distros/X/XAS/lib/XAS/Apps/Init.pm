package XAS::Apps::Init ;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Lib::App',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub main {
    my $self = shift;

    my @dirs = ('/var/run/xas', '/var/lock/xas');
    my ($login,$pass,$uid,$gid) = getpwnam('xas');

    foreach my $dir (@dirs) {

        unless ( -e $dir ) {

            mkdir $dir;
            chown $uid, $gid, $dir;
            chmod 0775, $dir;
            system("chmod g+s $dir");

        }

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Init - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Apps::Init ;

 my $app = XAS::Apps::Init->new(
     -throws   => 'xas-init',
     -priority => 'low',
     -facility => 'system',
 );

 exit $app->run;

=head1 DESCRIPTION

The procedure will check and create /var/run/xas and /var/lock/xas. This
is needed on systemd systems. On systemd systems, these directories are
mounted on filesystems the use tmpfs. So a system reboot removes them.

=head1 METHODS

=head2 main

This method will start the processing. 

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
