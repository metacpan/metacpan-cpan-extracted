package Test::Env;
use strict;

use vars qw(@EXPORT $VERSION);

use Exporter qw(import);

@EXPORT  = qw(env_ok);
$VERSION = '1.087';

use Test::Builder;

my $Test = Test::Builder->new();

=encoding utf8

=head1 NAME

Test::Env - test the environment

=head1 SYNOPSIS

	use Test::More tests => 1;
	use Test::Env;

	env_ok( 'PERL5LIB', "./blib/lib" );

=head1 DESCRIPTION

=head2 Functions

=over 4

=item env_ok( NAME, VALUE )

Ok if the environment variable NAME is VALUE.

=cut

sub env_ok($$) {
	my $name  = shift;
	my $value = shift;

	unless( exists $ENV{$name} ) {
		$Test->ok(0);
		$Test->diag( "Environment variable [$name] missing!\n",
			"\tExpected [$value]\n" );
		}
	elsif( $ENV{$name} ne $value ) {
		$Test->ok(0);
		$Test->diag( "Environment variable [$name] has wrong value!\n",
			"\tExpected [$value]\n",
			"\tGot [$ENV{$name}]\n" );
		}
	else
		{
		$Test->ok(1);
		}
	}

=back

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/briandfoy/test-env

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut


"Roscoe";
