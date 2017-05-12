# $Id: 05bycol.t,v 1.1 2003/08/18 17:04:41 matt Exp $

use strict;
use Test::More;

use constant PARSER => eval { require XML::SAX };

unless (eval { require XML::SAX::Writer }) {
    plan skip_all => "XML::SAX::Writer not available";
}

unless (eval "use DBD::SQLite 0.27; 1;") {
    plan skip_all => "DBD::SQLite 0.27 not available ($@)";
}

plan tests => 5;

use XML::Generator::DBI;
use DBI;

my $output = '';
my $handler = XML::SAX::Writer->new(Output => \$output);

ok($handler);

unlink("t/test.db");
my $dbh = eval { DBI->connect("dbi:SQLite:t/test.db") };

ok($dbh);

if (!$dbh) {
	skip "Couldn't connect to database. Perhaps permissions are not correct trying to create t/test.db?", 4;
	exit(0);
}

sub rand_str { join('', map { chr(rand(26) + 97) } (1..8)) }

$dbh->do("create table TestTable ( id integer primary key, column1 varchar, column2 varchar, column3 varchar, column4 varchar )");
$dbh->do("insert into TestTable (column1, column2, column3, column4) values (?,?,?,?)", 
          {}, rand_str, rand_str, rand_str, rand_str)
    for (1..20);

my $generator = XML::Generator::DBI->new(
        Handler => $handler,
        dbh => $dbh,
    	Indent => 1,
    	ByColumnName => 1,
    	RowElement => undef,
    );
ok($generator);

my $query = "select id as 'company/number',
                    column1 as 'company/address/street',
                    column2 as 'company/address/city',
                    column3 as 'company/name',
                    column4 as 'company/a/b'
             from TestTable";

$output = '';
$generator->execute($query);
ok($output);

print $output, "\n";

if (PARSER) {
    my $p = XML::SAX::ParserFactory->parser;
    eval { $p->parse_string($output) };
    ok(!$@, "Check we can parse the output");
}
else {
    skip "XML::SAX not installed", 1;
}
