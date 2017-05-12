# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Exception;

1;

package Wombat::ConfigException;

use base qw(Servlet::Util::Exception);

__PACKAGE__->do_trace(1);

1;

package Wombat::LifecycleException;

use base qw(Servlet::Util::Exception);

__PACKAGE__->do_trace(1);

1;

package Wombat::XmlException;

use base qw(Servlet::Util::Exception);

__PACKAGE__->do_trace(1);

1;
__END__

=pod

=head1 NAME

Wombat::Exception - Wombat exception base class

=head1 SYNOPSIS

=head1 DESCRIPTION

This package provides exception types specific to Wombat. Unless
otherwise specified, all classes extend B<Servlet::Util::Exception>.

=head1 EXCEPTION SUBCLASSESS

=over

=item B<Wombat::ConfigException>

Thrown to indicate that a validity error was encountered in server or
application configuration.

=item B<Wombat::LifecycleException>

Thrown to indicate that a component cannot be started or stopped.

=item B<Wombat::XmlException>

Thrown to indicate that an error occurred during XML processing.

=back

=head1 SEE ALSO

L<Servlet::Util::Exception>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
