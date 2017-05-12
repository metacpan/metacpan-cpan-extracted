package Unix::Uptime::BSD::XS;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw(sysctl_kern_boottime sysctl_vm_loadavg);

our $VERSION='0.4000';
$VERSION = eval $VERSION;

require XSLoader;
XSLoader::load('Unix::Uptime::BSD::XS', $VERSION);

1;

__END__

=head1 NAME

Unix::Uptime::BSD::XS - XS-based BSD implementation of Unix::Uptime (for Darwin, DragonFly, and *BSD)

=head1 SEE ALSO

L<Unix::Uptime>

=cut

# vim: set ft=perl sw=4 sts=4 et :
