package DTS_UT::Controller;

use strict;
use warnings;
use base qw(CGI::Application);
use CGI::Application::Plugin::Config::YAML;

sub cgiapp_init {

    my $self = shift;

    # fetchs value from $ENV{CGIAPP_CONFIG_FILE}
    $self->config_file();

}

1;
__END__

=pod

=head1 NAME

DTS_UT::Controller - Controller superclass for DTS Unit Testing

=head1 SYNOPSIS

  use DTS_UT::Controller;

=head1 DESCRIPTION

C<DTS_UT::Controller> is a MVC Controller superclass. It should be used by subclasses to have easier configuration by an
YAML file.

C<DTS_UT::Controller> will use an YAML file for configuration. The complete pathname of the YAML should be available in
the environment variable C<CGIAPP_CONFIG_FILE>. For Apache server, this must be done with a C<SetEnv> directive. For IIS, 
declaring a global environment variable will do it, just remember to restart IIS after doing that.

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over

=item *
Check out documentation of C<DTS_UT::Controller::MainController> for more information of implementation details.

=item *
L<CGI::Application::Plugin::Config::YAML>

=item *
L<CGI::Application>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
