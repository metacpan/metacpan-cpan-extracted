=head1 PURPOSE

Check package::compute's parsing hack works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;

package Foo::Bar;  # this is a hard-coded package name

{
	use package::compute "../Quux";
	::is(__PACKAGE__, "Foo::Quux");
	::is(__RPACKAGE__("./Xyzzy"), "Foo::Quux::Xyzzy");
	
	sub hello { ::is(__PACKAGE__, "Foo::Quux") };
}

::is(__PACKAGE__, "Foo::Bar");
Foo::Quux->hello;

::done_testing();