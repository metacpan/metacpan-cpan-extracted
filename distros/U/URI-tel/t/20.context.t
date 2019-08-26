#!/usr/bin/perl
BEGIN
{
	use strict;
	use URI::tel;
	use Test::More;
};

{
	URI::tel->_load_countries();
	my @tels = ();
	foreach my $idd ( sort( keys( %$URI::tel::COUNTRIES ) ) )
	{
		my $local = join( '', map( int( rand( 9 ) ), 1..10 ) );
		my $tel = $idd . $local;
		my $i = length( $tel );
		while( $i >= length( $idd ) )
		{
			## We accidentally generated a phone number with a valid idd and it is not our current one.
			## We generate the tel again
			if( substr( $tel, 0, $i ) ne $idd && exists( $URI::tel::COUNTRIES->{ substr( $tel, 0, $i ) } ) )
			{
				$local = join( '', map( int( rand( 9 ) ), 1..10 ) );
				$tel = $idd . $local;
				## printf( STDERR "Found a number '%s' that accidentally looks like another idd than ours '$idd'\n", substr( $tel, 0, $i ) );
				$i = length( $tel );
				next;
			}
			$i--;
		}
		push( @tels, { test => "\+${idd}-${local}", expect => '+' . $idd } );
	}
	foreach my $test ( @tels )
	{
		my $t = URI::tel->new( $test->{test} );
		my $idd = $t->context;
		$idd =~ s/-//g;
		is( $idd, $test->{expect}, $test->{test} );
	}
	done_testing( scalar( @tels ) );
}

__END__
