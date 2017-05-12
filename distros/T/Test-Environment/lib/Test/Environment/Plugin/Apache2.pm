package Test::Environment::Plugin::Apache2;

=head1 NAME

Test::Environment::Plugin::Apache2 - mock Apache2 modules to test mod_perl2 handlers

=head1 SYNOPSIS

	use Test::Environment qw{
		Apache2
	};


=head1 DESCRIPTION

This module will just sets:

	unshift @INC, File::Spec->catdir(File::Basename::dirname(__FILE__), 'Apache');

So that the mock Apache2 modules are found and loaded from there. No need to
have following modules in order to test L<mod_perl2> handlers.

L<Test::Environment::Plugin::Apache2::Apache2::Filter> (L<Apache2::Filter>),
L<Test::Environment::Plugin::Apache2::Apache2::Log> (L<Apache2::Log>),
L<Test::Environment::Plugin::Apache2::Apache2::RequestRec> (L<Apache2::RequestRec>)

=cut

use warnings;
use strict;

our $VERSION = "0.07";

use File::Basename qw();
use File::Spec qw();

unshift @INC, File::Spec->catdir(File::Basename::dirname(__FILE__), 'Apache2');

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
