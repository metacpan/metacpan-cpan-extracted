=pod

=encoding utf-8

=head1 PURPOSE

Check Test::Modern's C<class_api_ok> function seems to work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;

BEGIN {
	package XXX;
	use base 'Exporter::Tiny';
	sub xxx { 42 }
	$INC{'XXX.pm'} = __FILE__;
};

class_api_ok('XXX' => qw/ import mkopt_hash xxx /);

done_testing;
