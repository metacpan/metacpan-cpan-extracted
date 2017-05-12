=pod

=encoding utf-8

=head1 PURPOSE

Test C<ExpandPrefix> using example from documentation.

Also checks C<ClassIsa>, C<ClassDoes>, and C<ClassCan>.

=head1 DEPENDENCIES

Requires Moose 2.0600; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires { Moose => '2.0600' };
use Test::Fatal;

{
	package MyApp::Role::Plugin;
	use Moose::Role;
	sub xyz { 42 }
}

{
	package MyApp::Plugin::Foo;
	use Moose;
	with qw(MyApp::Role::Plugin);
}

{
	package MyApp::Plugin::Bar;
	use Moose;
	with qw(MyApp::Role::Plugin);
}

{
	package MyApp::Baz;
	use Moose;
	with qw(MyApp::Role::Plugin);
}

{
	package MyApp::Quux;
	use Moose;
}

{
	package MyApp;
	use Moose;
	use Types::LoadableClass qw( ClassDoes ExpandPrefix );
	use Types::Standard qw( ArrayRef StrMatch );
	
	my $plugin_class = (
		ClassDoes["MyApp::Role::Plugin"]
	) -> plus_coercions (
		ExpandPrefix[ "MyApp::Plugin" ]
	);
	
	has plugins => (
		is     => 'ro',
		isa    => ArrayRef[ $plugin_class ],
		coerce => 1,
	);
}

is_deeply(
	MyApp -> new(plugins => [qw( -Foo -Bar MyApp::Baz )]) -> plugins,
	[qw/
		MyApp::Plugin::Foo
		MyApp::Plugin::Bar
		MyApp::Baz
	/],
);

like(
	exception {
		MyApp -> new(plugins => [qw( -Foo -Bar MyApp::Quux )]) -> plugins,
	},
	qr/does not pass the type constraint/,
);

use Test::TypeTiny;
use Types::LoadableClass -types;

should_pass('MyApp::Baz', ClassCan[qw( new xyz )]);
should_fail('MyApp::Baz', ClassCan[qw( new xyz zyx )]);
should_pass('MyApp::Baz', ClassIsa[qw( Fooble Moose::Object Barble)]);
should_fail('MyApp::Baz', ClassIsa[qw( Fooble MyApp::Quux Barble)]);
should_pass('MyApp::Baz', ClassDoes[qw( MyApp::Baz Moose::Object MyApp::Role::Plugin )]);
should_fail('MyApp::Baz', ClassDoes[qw( MyApp::Quux Moose::Object MyApp::Role::Plugin )]);

should_pass('MyApp::Quux', ClassIsa['Moose::Object']);
should_pass('MyApp::Quux', ClassIsa['MyApp::Quux']);
should_fail('MyApp::Quux', ClassIsa['MyApp::Quuux']);
should_pass('MyApp::Quux', ClassCan[qw( new )]);
should_fail('MyApp::Quux', ClassCan[qw( xyz )]);

should_fail('MyApp::Quuux', ClassIsa['Moose::Object']);
should_fail('MyApp::Quuux', ClassIsa['MyApp::Quux']);
should_fail('MyApp::Quuux', ClassIsa['MyApp::Quuux']);
should_fail('MyApp::Quuux', ClassCan[qw( new )]);

should_fail('MyApp::Quux'->new, ClassIsa['Moose::Object']);
should_fail('MyApp::Quux'->new, ClassIsa['MyApp::Quux']);
should_fail('MyApp::Quux'->new, ClassIsa['MyApp::Quuux']);
should_fail('MyApp::Quux'->new, ClassCan[qw( new )]);

done_testing;
