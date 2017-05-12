package DTS_UT;

our $VERSION = '0.01';

1;
__END__

=head1 NAME

DTS_UT - Perl distribution of modules to implement DTS packages unit testing in a MVC web application

=head1 SYNOPSIS

# no code to see here. This is only a POD!

=head1 DESCRIPTION

This module is only documentation for a series of modules and templates for a implementation of unit tests for MS SQL 
Server 2000 DTS packages.

C<DTS_UT> package is a set of Perl modules that implement a simple web application to execute tests on DTS packages and
return the results in a (hopefully) nice interface.

Tests are implemented using the L<DTS> and L<Test::More> (including related modules). In theory, anything that can 
return an output as expected by L<Test::Harness::Strap> can be used to. Tests can be executed concurrently too, but this
will depend also on what the test will do.

The web application was built with L<CGI::Application> and L<HTML::Template> modules and is expected to be executed from
a webserver that supports standard CGI, like Apache and IIS. It will not work on operational systems that do not 
support MS Windows OLE.

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over

=item *
All other modules under the package name C<DTS_UT>.

=item *
L<DTS>

=item *
L<Test::More>

=item *
L<Test::Harness::Strap>

=item *
L<CGI::Application>

=item *
L<HTML::Template>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
