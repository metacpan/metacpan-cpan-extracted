=pod

=encoding utf-8

=head1 PURPOSE

Test that Type::Tiny::XS compiles.

Also performs some basic testing of type constraint coderefs.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 14;

use_ok('Type::Tiny::XS');

my $code = Type::Tiny::XS::get_coderef_for('ArrayRef[HashRef[Int]]');

ok $code->( [] );
ok $code->( [{}] );
ok $code->( [{foo => 1, bar => 2}] );
ok $code->( [{foo => 1, bar => 2}, {baz => 3}] );
ok $code->( [{foo => 1, bar => 2}, {baz => 3}, {}] );
ok not $code->( [{foo => 1, bar => undef}, {baz => 3}, {}] );
ok not $code->( {} );

ok Type::Tiny::XS::is_known(\&Type::Tiny::XS::Str);
ok Type::Tiny::XS::is_known($code);
ok not Type::Tiny::XS::is_known(sub { 42 });

my $code2 = Type::Tiny::XS::get_coderef_for('Any');
ok $code2->(42);
ok $code2->(undef);
ok $code2->();
