use Module::Build::Compat;
Module::Build::Compat->run_build_pl(args => \@ARGV);
Module::Build::Compat->write_makefile();


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2010, Carlos Vicente <cvicente@cpan.org>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

