package Test::ISBN;
use strict;

use base qw(Exporter);
use vars qw(@EXPORT $VERSION);

use Business::ISBN 2.0;
use Exporter;
use Test::Builder;

my $Test = Test::Builder->new();

$VERSION = '2.04';
@EXPORT  = qw(isbn_ok isbn_group_ok isbn_country_ok isbn_publisher_ok);

=head1 NAME

Test::ISBN - Check International Standard Book Numbers

=head1 SYNOPSIS

	use Test::More tests => 1;
	use Test::ISBN;

	isbn_ok( $isbn );

=head1 DESCRIPTION

This is the 2.x version of Test::ISBN and works with Business::ISBN 2.x.

=head2 Functions

=over 4

=item isbn_ok( STRING | ISBN )

Ok is the STRING is a valid ISBN, in any format that Business::ISBN
accepts.  This function only checks the checksum.  The publisher and
country codes might be invalid even though the checksum is valid.

If the first argument is an ISBN object, it checks that object.

=cut

sub isbn_ok {
	my $isbn = shift;
	
	my $object = _get_object( $isbn );

	my $string = ref $isbn ? eval { $isbn->as_string } : $isbn;
	
	my $ok   = ref $object && 
		( $object->is_valid_checksum( $string ) eq Business::ISBN::GOOD_ISBN );
	$Test->diag( "The argument [$string] is not a valid ISBN" ) unless $ok;

	$Test->ok( $ok );
	}

=item isbn_group_ok( STRING | ISBN, COUNTRY )

Ok is the STRING is a valid ISBN and its country code is the same as
COUNTRY. If the first argument is an ISBN object, it checks that
object.

=cut

sub isbn_group_ok {
	my $isbn    = shift;
	my $country = shift;

	my $object = _get_object( $isbn );

	my $string = ref $isbn ? eval { $isbn->as_string } : $isbn;

	unless( $object->is_valid ) {
		$Test->diag("ISBN [$string] is not valid"),
		$Test->ok(0);
		}
	elsif( $object->group_code eq $country ) {
		$Test->ok(1);
		}
	else {
		$Test->diag("ISBN [$string] group code is wrong\n",
			"\tExpected [$country]\n",
			"\tGot [" . $object->group_code . "]\n" );
		$Test->ok(0);
		}

	}

=item isbn_country_ok( STRING | ISBN, COUNTRY )

Deprecated. Use isbn_group_ok. This is still exported, though.

For now it warns and redirects to isbn_group_ok.

If the first argument is an ISBN object, it checks that
object.

=cut

sub isbn_country_ok {
	$Test->diag( "isbn_country_ok is deprecated. Use isbn_group_ok" );
	
	&isbn_group_ok;
	}
	
=item isbn_publisher_ok( STRING | ISBN, PUBLISHER )

Ok is the STRING is a valid ISBN and its publisher
code is the same as PUBLISHER.

If the first argument is an ISBN object, it checks that
object.

=cut

sub isbn_publisher_ok {
	my $isbn      = shift;
	my $publisher = shift;

	my $object = _get_object( $isbn );

	my $string = ref $isbn ? eval { $isbn->as_string } : $isbn;

	unless( $object->is_valid ) {
		$Test->diag("ISBN [$string] is not valid"),
		$Test->ok(0);
		}
	elsif( $object->publisher_code eq $publisher ) {
		$Test->ok(1);
		}
	else {
		$Test->diag("ISBN [$string] publisher code is wrong\n",
			"\tExpected [$publisher]\n",
			"\tGot [" . $object->publisher_code . "]\n" );
		$Test->ok(0);
		}
	}

sub _get_object {
	my( $arg ) = @_;

	my $object = do {
		if( eval { $arg->isa( 'Business::ISBN' ) } ) { $arg }
		else { Business::ISBN->new( $arg ) }
		};
	}

=back

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/briandfoy/Test-ISBN

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2014 brian d foy.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
