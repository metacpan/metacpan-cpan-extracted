#!/usr/bin/perl

use DBI;
use Getopt::Long;
use Data::Dumper;

my ($dbhost, $dbport, $dbname, $dbuser, $dbpass, $dbschema, $help, $libdir, $outdir, $ns);

$dbhost = "localhost";
$dbport = 5432;
$outdir = ".";

GetOptions(
    "host=s"    => \$dbhost,
    "port=i"    => \$dbport,
    "db=s"      => \$dbname,
    "user=s"    => \$dbuser,
    "pass=s"    => \$dbpass,
    "schema=s"  => \$dbschema,
    "libdir=s"  => \$libdir,
    "outdir=s"  => \$outdir,
    "ns=s"      => \$ns,
    "help"      => sub { $help++ }
);

if ( $help ) {
    print "$0\n";
    print "\t-host <host>       postgres host (default: localhost)\n";
    print "\t-port <port>       postgres port (default: 5432)\n";
    print "\t-db <dbname>       database name\n";
    print "\t-user <user>       username\n";
    print "\t-pass <pass>       password\n";
    print "\t-schema <schema>   schema to use (optional)\n";
    print "\t-libdir <DIR>      adds use lib <DIR> to modules\n";
    print "\t-outdir <DIR>      where to output to (default: .)\n";
    print "\t-ns <namespace>    namespace for your modules, i.e. Foo, Foo::Bar\n";
    print "\t-help              this dialog\n";
    exit 0;
}

my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport", $dbuser, $dbpass);
if ( ! $dbh || ! $dbh->ping ) {
    die "Could not connect to DB dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport, $dbuser, $dbpass\n";
}

if ( $dbschema ) {
    $dbh->do("set serach_path = $dbschema");
}

my $sth;
my %tables;
eval {
    $sth = $dbh->prepare("
        SELECT
            c.relname, c.oid
        FROM pg_catalog.pg_class c
            LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind IN ('r','')
            AND n.nspname <> 'pg_catalog'
            AND n.nspname <> 'information_schema'
            AND n.nspname !~ '^pg_toast'
            AND pg_catalog.pg_table_is_visible(c.oid)
    ");
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref() ) {
        $tables{$row->{'relname'}} = $row->{'oid'};
    }
};
die "Could not query for tables: $@\n" if ( $@ );

foreach my $table ( keys %tables ) {
    my %columns;
    eval {
        $sth = $dbh->prepare("
            SELECT
              a.attname,
              (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
               FROM pg_catalog.pg_attrdef d
               WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef) as default_value,
              a.attnotnull as not_null
            FROM pg_catalog.pg_attribute a
            WHERE a.attrelid = ? AND a.attnum > 0 AND NOT a.attisdropped
        ");
        $sth->execute($tables{$table});
        while ( my $row = $sth->fetchrow_hashref() ) {
            $columns{$row->{'attname'}} = {
                nulls   => ($row->{'not_null'}) ? 0 : 1,
                default => $row->{'default_value'},
                perms   => 'rw'
            };
        }
    };
    die "Could not query column data for $table : $@\n" if ( $@ );

    eval {
        $sth = $dbh->prepare("
            SELECT pg_catalog.pg_get_constraintdef(con.oid, true)
            FROM pg_catalog.pg_class c, pg_catalog.pg_class c2, pg_catalog.pg_index i
                LEFT JOIN pg_catalog.pg_constraint con ON (conrelid = i.indrelid AND conindid = i.indexrelid AND contype IN ('p'))
            WHERE c.oid = ? AND c.oid = i.indrelid AND i.indexrelid = c2.oid and i.indisprimary
        ");
        $sth->execute($tables{$table});
        while ( my $row = $sth->fetchrow_hashref() ) {
            $row->{'pg_get_constraintdef'} =~ /PRIMARY KEY \(([^\)]+)\)/;
            my $pks = $1;
            my @keys = split(/,/, $pks);
            foreach my $key ( @keys ) {
                $key =~ s/\s//g;
                $columns{$key}{'PK'} = 1;
                $columns{$key}{'perms'} = 'r';
            }
        }
    };
    die "Could not query primary key information for $table : $@\n" if ( $@ );

    eval {
        $sth = $dbh->prepare("
            SELECT
              pg_catalog.pg_get_constraintdef(r.oid, true) as condef
            FROM pg_catalog.pg_constraint r
            WHERE r.conrelid = ? AND r.contype = 'f' ORDER BY 1
        ");
        $sth->execute($tables{$table});
        while ( my $row = $sth->fetchrow_hashref() ) {
            $row->{'condef'} =~ /FOREIGN KEY \(([^\)]+)\) REFERENCES ([^\(]+)(([^\)]+))/;
            my ($col, $table, $fkcol) = ($1, $2, $3);
            $columns{$col}{'FK'} = lc($2);
        }
    };

    &output_module($table, \%columns);
}

print "You should verify the permissions on your columns now.  Enjoy.\n";
exit 0;

sub output_module {
    my $table = shift;
    my $cols = shift;

    my $module = lc($table);
    my $package = ($ns) ? $ns . "::" . $module : $module;
    open OUT,">$outdir/$module.pm";
    print OUT "package $package;\n";
    print OUT "use lib '$libdir';\n" if ( $libdir );
    print OUT "our " . Data::Dumper->Dump([$cols],['*columns']) . "\n";
    print OUT "use base 'fytwORM';\n1;";
    close OUT;
    return;
}
