#!/usr/bin/perl
BEGIN
{
	use strict;
	use URI::tel;
	use Test::More tests => 199;
};

{
	## Test to implement rfc3966 https://tools.ietf.org/search/rfc3966
	my @tests = (
	{ tel => "tel:+1-201-555-0123", global => 1, subscriber => '+1-201-555-0123', ext => undef(), context => '+1', isdn => '', params => {}, country => [qw( CA US )], uri => 'tel:+1-201-555-0123', canon => 'tel:+12015550123' },
	{ tel => "tel:+1(800)555-1212", global => 1, subscriber => '+1(800)555-1212', ext => undef(), context => '+1', isdn => '', params => {}, country => [qw( CA US )], uri => 'tel:+1(800)555-1212', canon => 'tel:+18005551212' },
	{ tel => "tel:+338005551212", global => 1, subscriber => '+338005551212', ext => undef(), context => '+33', isdn => '', params => {}, country => [qw( FR )], uri => 'tel:+338005551212', canon => 'tel:+338005551212' },
	{ tel => "+18005553434;ext=123", global => 1, subscriber => '+18005553434', ext => 123, context => '+1', isdn => '', params => {}, country => [qw( CA US )], uri => 'tel:+18005553434;ext=123', canon => 'tel:+18005553434;ext=123' },
	{ tel => "tel:+1-418-656-9254;ext=102", global => 1, subscriber => '+1-418-656-9254', ext => 102, context => '+1', isdn => '', params => {}, country => [qw( CA US )], uri => 'tel:+1-418-656-9254;ext=102', canon => 'tel:+14186569254;ext=102' },
	{ tel => "tel:911;phone-context=+1", global => 0, subscriber => '911', ext => undef(), context => '+1', isdn => '', params => {}, country => [qw( CA US )], uri => 'tel:911;phone-context=+1', canon => 'tel:911;phone-context=+1' },
	{ tel => "tel:7042;phone-context=example.com", global => 0, subscriber => 7042, ext => undef(), context => 'example.com', isdn => '', params => {}, country => [], uri => 'tel:7042;phone-context=example.com', canon => 'tel:7042;phone-context=example.com' },
	{ tel => "tel:863-1234;phone-context=+1-914-555", global => 0, subscriber => '863-1234', ext => undef(), context => '+1-914-555', isdn => '', params => {}, country => [qw( CA US )], uri => 'tel:863-1234;phone-context=+1-914-555', canon => 'tel:8631234;phone-context=+1-914-555' },
	{ tel => "tel:7042;ext=42;setup=20160509;phone-context=example.com", global => 0, subscriber => 7042, ext => 42, context => 'example.com', isdn => '', params => { setup => 20160509 }, country => [], uri => 'tel:7042;ext=42;phone-context=example.com;setup=20160509', canon => 'tel:7042;ext=42;phone-context=example.com;setup=20160509' },
	{ tel => "tel:7042;phone-context=example.com;ext=42;setup=20160509;loc=NY", global => 0, subscriber => '7042', ext => 42, context => 'example.com', isdn => '', params => { loc => 'NY', setup => '20160509' }, country => [], uri => 'tel:7042;ext=42;phone-context=example.com;loc=NY;setup=20160509', canon => 'tel:7042;ext=42;phone-context=example.com;loc=NY;setup=20160509' },
	{ tel => "tel:+1-418-656-9254;ext=102;phone-context=example.com", global => 1, subscriber => '+1-418-656-9254', ext => 102, context => 'example.com', isdn => '', params => {}, country => [qw( CA US )], uri => 'tel:+1-418-656-9254;ext=102;phone-context=example.com', canon => 'tel:+14186569254;ext=102;phone-context=example.com' },
	{ tel => "tel:+1-418-656-9254;ext=102;phone-context=example.com;setup=20160509", global => 1, subscriber => '+1-418-656-9254', ext => '102', context => 'example.com', isdn => '', params => {setup => 20160509}, country => [qw( CA US )], uri => 'tel:+1-418-656-9254;ext=102;phone-context=example.com;setup=20160509', canon => 'tel:+14186569254;ext=102;phone-context=example.com;setup=20160509' },
	{ tel => "03-1234-5678", global => 0, subscriber => '03-1234-5678', ext => undef(), context => undef(), isdn => '', params => {}, country => [], uri => 'tel:03-1234-5678', canon => 'tel:0312345678' },
	{ tel => "03-1234-5678x42", global => 0, subscriber => '03-1234-5678', ext => 42, context => undef(), isdn => '', params => {}, country => [], uri => 'tel:03-1234-5678;ext=42', canon => 'tel:0312345678;ext=42' },
	{ tel => "432.555.1334", global => 0, subscriber => '432.555.1334', ext => undef(), context => undef(), isdn => '', params => {}, country => [], uri => 'tel:432.555.1334', canon => 'tel:4325551334' },
	{ tel => "(800)ABCDEFG", global => 0, subscriber => '(800)ABCDEFG', ext => undef(), context => undef(), isdn => '', params => {}, country => [], uri => 'tel:(800)ABCDEFG', canon => 'tel:8002223334' },
	{ tel => "+1-800-LAWYERS", global => 0, subscriber => '+1-800-LAWYERS', ext => undef(), context => '+1', isdn => '', params => {}, country => [qw( CA US )], uri => 'tel:+1-800-LAWYERS', canon => 'tel:+18005299377' },
	{ tel => "(999) 555-4455 ext123", global => 0, subscriber => '(999)555-4455', ext => 123, context => undef(), isdn => '', params => {}, country => [], uri => 'tel:(999)555-4455;ext=123', canon => 'tel:9995554455;ext=123' },
	{ tel => "555-555-5555, Ext. 505", global => 0, subscriber => '555-555-5555', ext => 505, context => undef(), isdn => '', params => {}, country => [], uri => 'tel:555-555-5555;ext=505', canon => 'tel:5555555555;ext=505' },
	{ tel => "416.619.0322 ext.262", global => 0, subscriber => '416.619.0322', ext => '262', context => undef(), isdn => '', params => {}, country => [], uri => 'tel:416.619.0322;ext=262', canon => 'tel:4166190322;ext=262' },
	{ tel => "notwork", global => 0, subscriber => undef(), ext => undef(), context => undef(), isdn => '', params => {}, country => [], uri => '', canon => '', has_error =~ qr/Unknown telephone number/ },
	);
	foreach my $ref ( @tests )
	{
		my $tel = URI::tel->new( $ref->{tel} );
		is( defined( $tel ), 1, $ref->{tel} );
		is( $tel->is_global, $ref->{global}, "Is global for $ref->{tel}"  );
		is( $tel->subscriber, $ref->{subscriber}, "Subscriber for $ref->{tel}" );
		is( $tel->ext, $ref->{ext}, "Extension for $ref->{tel}" );
		is( $tel->context, $ref->{context}, "Context for $ref->{tel}" );
		is( $tel->isub, $ref->{isub}, "Isub for $ref->{tel}" );
		if( scalar( keys( %{$ref->{params}} ) ) > 0 )
		{
			my $ok = 1;
			my @keys1 = sort( keys( %{$ref->{params}} ) );
			my $hash  = $tel->private;
			my @keys2 = sort( keys( %$hash ) );
			$ok = 0 unless( join( ',', @keys1 ) eq join( ',', @keys2 ) );
			$ok = 0 unless( join( ',', @{$ref->{params}}{ @keys1 } ) eq join( ',', @$hash{ @keys2 } ) );
			is( $ok, 1 );
		}
		is( $tel->canonical, $ref->{canon} );
		my $countries = $tel->country;
		#diag( sprintf( "Tel $ref->{tel} has %d countries", scalar( @$countries ) ) );
		is( join( ',', map( $_->{ 'cc' }, @$countries ) ), join( ',', @{$ref->{country}} ) );
		is( "$tel", $ref->{uri} );
	}
	## 22
	my $tel1 = URI::tel->new( '+81-03-1234-5678' );
	my $tel2 = URI::tel->new( '+81-03-1234-5678' );
	is( defined( $tel1 ), 1, '+81-03-1234-5678' );
	is( $tel1, $tel2, "checking comparison with overloaded objects" );
	## 23
	$tel2->ext( 20 );
	is( $tel2->ext, 20, "checking change of extension" );
	## 24
	isnt( $tel1, $tel2, "checking different overloaded objects" );
	# print( "Testing additional methods with 03-1234-5678\n" );
	my $tel3 = URI::tel->new( '03-1234-5678' );
	## 25
	#print( "Testing country code to context\n" );
	my $ctx = $tel3->cc2context( 'jp' );
	is( $ctx, '+81' );
	# print( "Found context for country jp: $ctx\n" );
	## 26
	$tel3->context( $ctx );
	is( $tel3, 'tel:03-1234-5678;phone-context=+81' );
	#print( "Tel is now: $tel3\n" );
	## 27
	#print( "Prepending context now.\n" );
	$tel3->prepend_context( 1 );
	is( $tel3, 'tel:+81.03-1234-5678', "Prepending context" );
}

__END__

=head1 NAME

URI::tel - Implementation of rfc3966 for tel URI

=head1 SYNOPSIS

	my $tel = URI::tel->new( 'tel:+1-418-656-9254;ext=102' );
	## or
	my $tel = URI::tel->new( 'tel:5678-1234;phone-context=+81-3' );
	## or
	my $tel = URI::tel->new( '03-5678-1234' );
	$tel->phone_context( '+81' );
	print( $tel->canonical->as_string, "\n" );
	my $tel2 = $tel->canonical;
	print( "$tel2\n" );

=head1 DESCRIPTION

C<URI::tel> is a package to implement the tel URI
as defined in rfc3966 L<https://tools.ietf.org/search/rfc3966>.

tel URI is structured as follows:

tel:I<telephone-subscriber>

I<telephone-subscriber> is either a I<global-number> or a I<local-number>

I<global-number> can be composed of the following characters:

+[0-9\-\.\(\)]*[0-9][0-9\-\.\(\)]* then followed with one or zero parameter, extension, isdn-subaddress

I<local-number> can be composed of the following characters:

[0-9A-F\*\#\-\.\(\)]* ([0-9A-F\*\#])[0-9A-F\*\#\-\.\(\)]* followed by one or zero of 
parameter, extension, isdn-subaddress, then at least one context then followed by one or zero of 
parameter, extension, isdn-subaddress.

I<parameter> is something that looks like ;[a-zA-Z0-9\-]+=[\[\]\/\:\&\+\$0-9a-zA-Z\-\_\.\!\~\*\'\(\)]+

I<extension> is something that looks like ;ext=[0-9\-\.\(\)]+

I<isdn-subaddress> is something that looks like ;isub=[\;\/\?\:\@\&\=\+\$\,a-zA-Z0-9\-\_\.\!\~\*\'\(\)%0-9A-F]+

I<context> is something that looks like 
;phone-context=([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\.)?([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])
or
;phone-context=+([0-9]+[\-\.\(\)]*)?[0-9]+([0-9]+[\-\.\(\)]*)?

=head1 METHODS

=over 4

=item B<new>( tel URI )

B<new>() is provided with a tel URI and return an instance of this package.

=back

=head1 COPYRIGHT

Copyright (c) 2016-2018 Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

