#!/pro/bin/perl

use strict;
use warnings;

use Encode qw( encode decode );

my $data;
sub _bindata {
    $data ||= pack "LA20A*", time, "#sys", encode "UTF-8", "Value \x{20ac}";
    return $data;
    } # _bindata

my $tempdb;

sub _dsn {
    my $type = shift;

    $type eq "Pg"	and return "dbi:Pg:";

    my $rnd = sprintf "%d_%04d", $$, (time + int rand 10000) % 10000;

    if ($type eq "SQLite") {
	$tempdb = "db_$rnd.3";
	unlink $tempdb;
#	return "dbi:SQLite:dbname=:memory:";
	return "dbi:SQLite:dbname=$tempdb";
	}

    if ($type eq "CSV") {
	my $xsv = eval q{use Text::CSV_XS; $Text::CSV_XS::VERSION; } || 0;
	my $dbv = eval q{use DBD::CSV;     $DBD::CSV::VERSION;     } || 0;
	$tempdb = "csv_$rnd";
	mkdir $tempdb, 0777;
	my $dsn = "dbi:CSV:f_dir=$tempdb;f_ext=.csv/r;csv_null=1";
	$xsv > 1.01 && $dbv > 0.47     and $dsn .= ";csv_decode_utf8=0";
	$dbv > 0.29 && $]   < 5.008009 and $dsn .= ";csv_auto_diag=0";
	return $dsn;
	}

    # We assume user "0" is illegal
    my $user   = $ENV{LOGNAME} || $ENV{USER};
       $user ||= getpwuid $< unless $^O eq "MSWin32";
       $user ||= "";

    if ($type eq "Oracle") {
	my @id = split m{/} => ($ENV{ORACLE_USERID} || "/"), -1;
	$ENV{DBI_USER} = $id[0];
	$ENV{DBI_PASS} = $id[1];

	($ENV{ORACLE_SID} || $ENV{TWO_TASK}) &&
	-d ($ENV{ORACLE_HOME} || "/-..\x03") &&
	   $ENV{DBI_USER} && $ENV{DBI_PASS} or
	    plan skip_all => "Not a testable Oracle env";
	return "dbi:Oracle:";
	}

    if ($type eq "mysql" || $type eq "MariaDB") {
	my $db = $ENV{MYSQLDB} || $user or
	    plan skip_all => "Not a testable MariaDB/MySQL env";
	$ENV{DBI_USER} ||= $ENV{MYSQLUSER} || $user;
	return "dbi:$type:database=$db";
	}

    if ($type eq "Unify") {
	$ENV{DBI_USER} = $ENV{USCHEMA} || "";
	-d ($ENV{UNIFY}  || "/-..\x03") &&
	-d ($ENV{DBPATH} || "/-..\x03") or
	    plan skip_all => "Not a testable Unify env";
	return "dbi:Unify:";
	}

    if ($type eq "Firebird") {
	# use flamerobin for DB administration
	# Default pass for SYSDBA is "masterkey"
	# I gave up on this. Too hard to make it work. Connection always fails
	$ENV{ISC_USER}     ||= "SYSDBA";
	$ENV{ISC_PASSWORD} ||= "masterkey";
	$ENV{ISC_DATABASE} ||= ""; # Prevent warnings in Firebird.pm
	$ENV{DBI_USER} = $ENV{ISC_USER};
	$ENV{DBI_PASS} = $ENV{ISC_PASSWORD};
	return "dbi:Firebird:";
	}
    } # _dsn

sub dsn {
    my $type = shift;
    cleanup ($type);
    return _dsn ($type);
    } # dsn

sub plan_fail {
    my $type = shift;

    my $reason = DBI->errstr;
    $reason or ($reason = $@) =~ s/:.*//s;

    if ($type eq "Pg") {
        # could not connect to server: No such file or directory
	# \tIs the server running locally and accepting
	# \tconnections on Unix do ...
	$reason =~ s{: No such file or directory(\r?\n.*)?$}{}s;
	# could not connect to server: Connection refused (0x0000274D/10061)
	# \tIs the server running on host "pg_host" and accepting
	# \tTCP/IP connections on port 5432?
	$reason =~ s{: Connection refused \(\S+?/\S+?\)(\r?\n.*)?$}{}s;
	}
    if ($type eq "mysql") {
	# Can't connect to local MySQL server through socket '/var/run/mysql/mysql.sock' (2)
	$reason =~ s{(Can't connect to local MySQL server).*}{$1}s;
	}
    if ($type eq "Firebird") {
	# Unsuccessful execution caused by a system error that precludes successful execution of subsequent statements
	$reason =~ s{Unsuccessful execution caused by a system error.*}{Cannot connect}s;
	}

    $reason and substr $reason, 0, 0, " - ";
    plan skip_all => "DBD::$type$reason";
    } # plan_fail

sub cleanup {
    my $type = shift;

    $type eq "Pg"	and return;
    $type eq "Oracle"	and return;
    $type eq "mysql"	and return;
    $type eq "Unify"	and return;
    $type eq "Firebird"	and return;

    if ($type eq "SQLite") {
	if ($tempdb) {
	    unlink $tempdb;
	    return;
	    }
	my @db = sort glob "db*.3*" or return;
	unlink $_ for @db;
	return;
	}

    if ($type eq "CSV") {
	if ($tempdb) {
	    unlink for glob "$tempdb/*.csv";
	    rmdir $tempdb;
	    return;
	    }
	my @db = sort glob "t_tie*.csv" or return;
	unlink $_ for @db;
	return;
	}
    } # cleanup

# From Data::Serializer:
# v Bencode
#   Convert::Bencode
#   Convert::Bencode_XS
#   Config::General
#   Data::Denter
# - Data::Dumper
#   Data::Taxi
# - FreezeThaw
# v JSON
# v JSON::Syck
#   PHP::Serialization
# v Storable
# v XML::Dumper
#   XML::Simple
# v YAML
# v YAML::Syck

sub supported_serializers {
    qw( Storable
	Sereal
	JSON JSON::Syck
	YAML YAML::Syck
	XML::Dumper
	Bencode
	FreezeThaw
	Not::Supported
	);
    } # supported_serializers

# Choose a value that works for plain, uselongdouble, and usequadmath
sub PI { 3.1415926535897931 }

sub deep {
    my ($DBD, $str) = (@_, "");

    my %deep = (
	UND => undef,
	IV  => 1,
	NV  => PI (),
	PV  => "string",
	PV8 => "ab\ncd\x{20ac}\t",
	PVM => $!,
	RV  => \$DBD,
	AR  => [ 1..2 ],
	HR  => { key => "value" },
	OBJ => ( bless { auto_diag => 1 }, "Text::CSV_XS" ),
	RX  => qr{^re[gG]e?x},
	FMT => *{$::{STDOUT}}{FORMAT},
	CR  => sub { "code"; },
	GLB => *STDERR,
	IO  => *{$::{STDERR}}{IO},
	);

    $str eq ""            and delete @deep{qw( IO GLB CR RX FMT            )};
    $str eq "Storable"    and delete @deep{qw( IO GLB CR RX FMT            )};
    $str eq "Sereal"      and delete @deep{qw( IO GLB CR                   )};
    $str eq "JSON"        and delete @deep{qw( IO GLB CR RX FMT RV OBJ     )};
    $str eq "JSON::Syck"  and delete @deep{qw( IO GLB CR RX     RV     PV8 )};
    $str eq "YAML"        and delete @deep{qw( IO GLB CR               PV8 )};
    $str eq "YAML::Syck"  and delete @deep{qw( IO GLB CR RX            PV8 )};
    $str eq "XML::Dumper" and delete @deep{qw( IO GLB CR RX                )};
    $str eq "FreezeThaw"  and delete @deep{qw( IO     CR RX            PV8 )};
    $str eq "Bencode"     and delete @deep{qw( IO UND CR RX FMT RV OBJ PV8 )};

    $str =~ m/^[JYX]/ && $DBD =~ m/^(?: Pg | MariaDB )$/x and delete $deep{PV8};

    %deep;
    } # deep

1;
