=head1 DESCRIPTION

Support library for 03auto.t.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use package::compute -filename;

our $Foo = "Done.";

{
	use package::compute '.::Funky';
	our $Monkey = "Done.";
}

1;
