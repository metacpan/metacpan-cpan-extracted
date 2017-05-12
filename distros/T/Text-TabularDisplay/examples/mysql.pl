#!/usr/bin/perl

# ----------------------------------------------------------------------
# Example usage of Text::TabularDisplay to implement a low-functionality
# version of the mysql text monitor.
# ----------------------------------------------------------------------

use strict;
use vars qw(%opts $prog $histfile);

use Carp qw(carp);
use DBI;
use File::Basename qw(basename);
use File::Spec;
use Getopt::Long;
use Term::ReadLine;
use Text::TabularDisplay;

$prog = basename $0;
$histfile = File::Spec->catfile($ENV{'HOME'}, ".mysql_history");

eval {
    require MySQL::Config;
    my %defaults = MySQL::Config::parse_defaults("my", [ qw(client) ]);

    for (qw(user password host)) {
        $opts{$_} = $defaults{$_};
    }
};

GetOptions(\%opts,
    "user|u=s",
    "password|p=s",
    "help|?!",
    "host=s");

$opts{'host'} ||= "localhost";
if (defined $opts{'help'}) {
    print STDERR "$prog - mysql command line client emulation\n",
                 "Usage: $prog [OPTIONS] DB_NAME\n\n",
                 "OPTIONS include:\n",
                 "  --user=\$username      Username to connect as\n",
                 "  --password=\$password  Password for \$user\n",
                 "  --host=\$host          Host on which DB_NAME can be found\n",
                 "  --help                You're reading it.\n\n";
    exit(1);
}


my $db = shift(@ARGV) or die "$prog: Must supply a database name!\n";

# Create the Text::TabularDisplay and Term::ReadLine instances, and
# make the database connection.
my $table = Text::TabularDisplay->new;
my $term = Term::ReadLine->new("mysql");
my $dbh = DBI->connect("dbi:mysql:database=$db;host=$opts{'host'}",
                        $opts{'user'}, $opts{'password'})
    or die "Can't connect to $db on $opts{'host'}: $DBI::errstr";

$term->ReadHistory($histfile);

while (defined (my $line = $term->readline("mysql> "))) {
    #$term->AddHistory($line);
    my $sth;

    if ($line =~ /^\s*(quit|exit)/) {
        last;
    }

    unless ($sth = $dbh->prepare($line)) {
        carp "Can't prepare line: " . $dbh->errstr;
        next;
    }

    # Reset the table
    $table->reset;

    unless ($sth->execute) {
        carp "Can't execute query: " . $sth->errstr;
        next;
    }

    # Set the columns
    my $names = $sth->{'NAME'};
    $table->columns(@$names);

    while (my $row = $sth->fetchrow_arrayref) {
        # Add data to the table
        $table->add($row);
    }
    $sth->finish;

    # Print the final version of the table
    # Note that without the trailing \n, the last line is buffered,
    # which is pretty ugly...
    printf "%s\n", $table->render;
}

$term->WriteHistory($histfile);

print "Bye!\n";
exit(0);
