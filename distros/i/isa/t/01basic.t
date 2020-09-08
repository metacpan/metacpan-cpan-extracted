=pod

=encoding utf-8

=head1 PURPOSE

Test that isa works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

BEGIN { package Local::Parent };
BEGIN { package Local::Child; our @ISA = 'Local::Parent' };
BEGIN { package Local::Mock };

use isa 'Local::Parent', 'Local::Child';

ok  isa_Local_Parent( bless {}, 'Local::Parent' );
ok  isa_Local_Parent( bless {}, 'Local::Child' );
ok !isa_Local_Parent( bless {}, 'Local::Stranger' );
ok !isa_Local_Child( bless {}, 'Local::Parent' );
ok  isa_Local_Child( bless {}, 'Local::Child' );
ok !isa_Local_Child( bless {}, 'Local::Stranger' );

do {
	no warnings 'once';
	local *Local::Mock::isa = sub { 1 };
	ok isa_Local_Parent( bless {}, 'Local::Mock' );
	ok isa_Local_Child( bless {}, 'Local::Mock' );
};

ok !isa_Local_Parent( bless {}, 'Local::Mock' );
ok !isa_Local_Child( bless {}, 'Local::Mock' );

done_testing;
