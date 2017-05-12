=pod

=encoding utf-8

=head1 PURPOSE

Test that Test::Modern's C<< -without >> feature works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern -without => [qw(
	CGI::Push
	LWP::UserAgent
	Net::NNTP
)];

like(
	exception { require CGI::Push },
	qr/^Can't locate/,
);

like(
	exception { require LWP::UserAgent },
	qr/^Can't locate/,
);

like(
	exception { require Net::NNTP },
	qr/^Can't locate/,
);

done_testing;
