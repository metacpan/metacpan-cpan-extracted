=head1 PURPOSE

Check behaviour of return::thence in list and scalar context.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use Test::More;
use return::thence;

sub baz () { return::thence('a' .. 'z') };

is scalar(baz), 'z';
is_deeply [baz], ['a'..'z'];

done_testing;
