package perfSONAR_PS::OWP::DB;

require 5.005;
require Exporter;
use strict;
use warnings;

use vars qw(@ISA @EXPORT $VERSION);

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::OWP::DB

=head1 DESCRIPTION

DB utility functions

=cut

use Carp qw(cluck);
use DBI;
use Term::ReadKey;
use perfSONAR_PS::OWP;
use perfSONAR_PS::OWP::Utils;

@ISA    = qw(Exporter);
@EXPORT = qw(init_db);

#$DB::REVISION = '$Id: DB.pm 1877 2008-03-27 16:33:01Z aaron $';
#$VERSION = $DB::VERSION='1.0';

=head2 init_db()

TDB

=cut

sub init_db {
    my (%args)         = @_;
    my (@mustargnames) = qw(CONF);
    my (@argnames)     = ( @mustargnames, qw(TOOLTYPE) );
    %args = owpverify_args( \@argnames, \@mustargnames, %args );
    scalar %args || return 0;

    my $conf  = $args{"CONF"};
    my $ttype = "";
    if ( defined $args{"TOOLTYPE"} ) {
        $ttype = $args{"TOOLTYPE"};
    }

    my $adminuser;
    my $dbinit   = $conf->get_val( ATTR => 'INITDB' );
    my $dbdelete = $conf->get_val( ATTR => 'DELETEDB' );
    $adminuser = $dbdelete;
    $adminuser = $dbinit if ( defined($dbinit) );

    if ( !defined($adminuser) ) {
        return;
    }

    my $cgiuser  = $conf->must_get_val( ATTR => 'CGIDBUser',     TYPE => $ttype );
    my $cgipass  = $conf->must_get_val( ATTR => 'CGIDBPass',     TYPE => $ttype );
    my $dbuser   = $conf->must_get_val( ATTR => 'CentralDBUser', TYPE => $ttype );
    my $dbpass   = $conf->must_get_val( ATTR => 'CentralDBPass', TYPE => $ttype );
    my $dbdriver = $conf->must_get_val( ATTR => 'CentralDBType', TYPE => $ttype );
    my $dbname   = $conf->must_get_val( ATTR => 'CentralDBName', TYPE => $ttype );
    my $dbsource = $dbdriver . ":" . $dbname;
    my $dbhost = $conf->get_val( ATTR => 'CentralDBHost', TYPE => $ttype ) || "localhost";
    my $dbport = $conf->get_val( ATTR => 'CentralDBPort', TYPE => $ttype );

    if ( defined($dbport) ) {
        $dbhost .= ":" . $dbport;
    }
    $dbsource .= ":" . $dbhost;

    # Initialize the database before creating the tables.
    # Will drop/recreate the database if it already exists!
    # This will only work with mysql! If CentralDBType is not

    my $adminpass;
    my $driver;

    # some of this is only likely to work with mysql...
    # Most of it is DBI stuff that would work, but lets have each new
    # one add something to this 'if' to verify it.
    ($driver) = ( $dbdriver =~ m/DBI:(.*)/ );
    if ( !( $driver =~ m/mysql/ ) ) {
        die "Database initialization has not been tried for non-mysql";
    }

    ReadMode('noecho');
    print "Enter $adminuser password: ";
    $adminpass = ReadLine(0);
    print "\n";
    ReadMode(0);

    chomp $adminpass;

    # List out existing databases
    my %dbattr;
    $dbattr{'host'}     = $dbhost;
    $dbattr{'port'}     = $dbport if ( defined($dbport) );
    $dbattr{'user'}     = $adminuser;
    $dbattr{'password'} = $adminpass;

    my $drh = DBI->install_driver($driver);
    my @databases;
    @databases = DBI->data_sources( $driver, \%dbattr );

    my $ds;
    my $found = 0;
    foreach (@databases) {
        ($ds) = m/$dbdriver:(.*)/;
        $found = 1 if ( $dbname eq $ds );
    }

    my $createdb = 1;
    if ($found) {
        print "Existing database $dbname found. Do you really want to delete it? (y/n) ";
        my $ans = ReadLine(0);
        if ( !( $ans =~ m/^y/i ) ) {
            $createdb = 0;
        }
        else {
            print "dropping database $dbname\n";
            $drh->func( 'dropdb', $dbname, $dbhost, $adminuser, $adminpass, 'admin' )
                || die "Unable to drop database $dbname";
        }
    }

    if ( $dbinit && $createdb ) {
        print "creating new database $dbname\n";
        $drh->func( 'createdb', $dbname, $dbhost, $adminuser, $adminpass, 'admin' ) || die "Unable to create database $dbname";
    }

    # Connect to the 'mysql' table. Only a user with permissions to
    # do that can change the grants anyway.
    # TODO:Make portable for non-MySQL db's

    my $dbh = DBI->connect(
        "$dbdriver:$driver",
        $adminuser,
        $adminpass,
        {
            RaiseError => 0,
            PrintError => 1,
        }
    ) || die "Couldn't connect to database ($adminuser)";

    if ($dbinit) {
        print "Creating user account $dbuser\n";
        $dbh->do("grant usage on *.* to $dbuser\@localhost  identified by \'$dbpass\'") || die "Unable to create $dbuser\@localhost account";

        print "Granting user $dbuser\@localhost access to $dbname\n";
        $dbh->do("grant select,insert,update,delete,create,drop,index,alter,create temporary tables on $dbname.* to $dbuser\@localhost") || die "Unable to grant permissions to $dbuser for $dbname.*";

        print "Creating user account $cgiuser\n";
        print "Granting user $cgiuser\@localhost read-only access to $dbname\n";
        $dbh->do("grant select on $dbname.* to $cgiuser\@'localhost' identified by \'$cgipass\'") || die "Unable to grant permissions to $cgiuser\@localhost to $dbname.*";
        print "Granting user $cgiuser\@'%' read-only access to $dbname\n";
        $dbh->do("grant select on $dbname.* to $cgiuser\@'%' identified by \'$cgipass\'") || die "Unable to grant permissions to $cgiuser\@\% for $dbname.*";
    }

    elsif ($dbdelete) {
        print "Remove R/W user '$dbuser'? (y/n) ";
        my $ans;
        $ans = ReadLine(0);
        if ( $ans =~ m/^y/i ) {
            print "Revoking user $dbuser permissions\n";
            $dbh->do("revoke all on $dbname.* from $dbuser\@localhost")
                || warn "Unable to revoke 'all' from $dbuser\@localhost";
            $dbh->do("revoke usage on *.* from $dbuser\@localhost")
                || warn "Unable to revoke 'usage' from $dbuser\@localhost";
            print "Deleting user $dbuser\n";
            $dbh->do("drop user $dbuser\@localhost")
                || warn "Unable to drop $dbuser\@localhost: Perhaps user still has permissions for other tables?";

        }

        print "Remove R/O user '$cgiuser'? (y/n) ";
        $ans = ReadLine(0);
        if ( $ans =~ m/^y/i ) {
            print "Revoking user $cgiuser permissions\n";
            $dbh->do("revoke all on $dbname.* from $cgiuser\@localhost")
                || warn "Unable to revoke 'all' from $cgiuser\@localhost";

            $dbh->do("revoke all on $dbname.* from $cgiuser\@'%'")
                || warn "Unable to revoke 'all' from $cgiuser\@'%'";

            $dbh->do("revoke usage on *.* from $cgiuser\@localhost")
                || warn "Unable to revoke 'usage' from $cgiuser\@localhost";
            $dbh->do("revoke usage on *.* from $cgiuser\@'%'")
                || warn "Unable to revoke 'usage' from $cgiuser\@'%'";

            print "Deleting user $cgiuser\n";
            $dbh->do("drop user $cgiuser\@'%'")
                || warn "Unable to drop $cgiuser\@'%': Perhaps user still has permissions for other tables?";
            $dbh->do("drop user $cgiuser\@localhost")
                || warn "Unable to drop $cgiuser\@localhost: Perhaps user still has permissions for other tables?";

        }

        exit(0);
    }

    $dbh->disconnect;
    return;
}

1;

__END__

=head1 SEE ALSO

L<Carp>, L<DBI>, L<Term::ReadKey>, L<perfSONAR_PS::OWP>,
L<perfSONAR_PS::OWP::Utils>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id: DB.pm 1877 2008-03-27 16:33:01Z aaron $

=head1 AUTHOR

Jeff Boote, boote@internet2.edu
Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2002-2008, Internet2

All rights reserved.

=cut
