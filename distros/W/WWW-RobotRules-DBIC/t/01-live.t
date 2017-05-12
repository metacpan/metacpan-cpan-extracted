#!perl

use Test::Base;
use FindBin qw($Bin);
use LWP::RobotUA;
use WWW::RobotRules::DBIC;
use DBI;

plan tests => (1 * blocks) + 2;

my $dbfile = "$Bin/test.db";
my $create_sql_file = "$Bin/../eg/schema_sqlite.sql";
my @connect_info = ("dbi:SQLite:dbname=$dbfile", "", "");
my $httpd = "$Bin/server.pl";
my $port = 10080;

my $dbh = DBI->connect(@connect_info) or die $DBI::errstr;
open my $fh, $create_sql_file or die "$!: $create_sql_file";
my $create_sql = join '', <$fh>;
close $fh;
for my $sql(split(/\;/, $create_sql)) {
    $dbh->do($sql);
}
$dbh->disconnect;


my $rules = WWW::RobotRules::DBIC->new(@connect_info);
my $pid = open my $s, "perl $httpd $port |";
filters { path => 'chomp', agent => 'chomp', code => 'chomp', };
run {
    my $block = shift;
    my $ua = LWP::RobotUA->new(
        agent => $block->agent,
        from => 'robot1@example.com',
        rules => $rules,
    );
    $ua->delay(0);
    my $url = "http://localhost:$port". $block->path;
    my $res = $ua->get($url);
    is($res->code, $block->code);
};

{
    my $rs = $rules->{schema}->resultset('UserAgent')->search;
    is($rs->count, 2);
}

{
    my $rs = $rules->{schema}->resultset('Netloc')->search({
        netloc => "localhost:$port",
    });
    is($rs->count, 2);
}

kill 'INT', $pid;
close $s;
unlink $dbfile;

__END__
=== / with UA1
--- path 
/
--- agent 
WWW::RobotRules::DBIC::TestUA1
--- code 
200
=== /deny_ua1 with UA1
--- path 
/deny_ua1
--- agent 
WWW::RobotRules::DBIC::TestUA1
--- code 
403
=== /deny_ua2 with UA1
--- path 
/deny_ua2
--- agent 
WWW::RobotRules::DBIC::TestUA1
--- code 
200
=== /deny_ua1 with UA2
--- path 
/deny_ua1
--- agent 
WWW::RobotRules::DBIC::TestUA2
--- code 
200
