=head1 PURPOSE

Check package::compute loads and that C<< __RPACKAGE__ >> works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;
BEGIN { use_ok('package::compute') };

is __RPACKAGE__('..::Baz', 'Foo::Bar'), 'Foo::Baz';
is __RPACKAGE__('...::Baz', 'Foo::Bar::Baz'), 'Foo::Baz';
is __RPACKAGE__('.::Baz', 'Foo'), 'Foo::Baz';

is __RPACKAGE__('..::Quux', 'Foo::Bar::Baz'), 'Foo::Bar::Quux';
is __RPACKAGE__('...::Quux', 'Foo::Bar::Baz'), 'Foo::Quux';
is __RPACKAGE__('....::Quux', 'Foo::Bar::Baz'), 'Quux';
ok not eval { __RPACKAGE__('.....::Quux', 'Foo::Bar::Baz') };

done_testing();
