package install;
use 5.006;
use strict;
our $VERSION = '0.01';

1;
__END__

=head1 NAME

install - Dummy module that prevents unexpected results from the CPAN shell

=head1 DESCRIPTION

Many people at one time or another mistakenly ask the CPAN shell to install
the 'install' module:

    $ cpan install Foo

Unlike lots of package managers, the CPAN shell doesn't use commands like
'install' so this tries to install the 'install' module as well as the
'Foo' module.

This 'install' module does absolutely nothing except install and has no
prerequisites so nothing bad will happen when this mistake is made.

=head1 SEE ALSO

L<CPAN>

=head1 AUTHOR

David Golden, E<lt>dagolden@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by David Golden

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

