# $Id: to_mssql.t,v 1.3 2004/10/26 17:00:09 rjbs Exp $
use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok('Time::Piece::MSSQL'); }

{
	my $time = gmtime 1073046896;
	isa_ok($time, 'Time::Piece');
	
	is($time->mssql_datetime(), "2004-01-02 12:34:56.000", "converts to mssql_datetime");
}

{
	my $time = gmtime 1073046896;
	isa_ok($time, 'Time::Piece');
	
	is($time->mssql_smalldatetime(), "2004-01-02 12:34:56", "converts to mssql_datetime");
}
