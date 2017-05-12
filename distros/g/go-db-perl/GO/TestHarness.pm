# $Id: TestHarness.pm,v 1.12 2009/05/07 01:43:20 cmungall Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

#   @(#)$Id: TestHarness.pm,v 1.12 2009/05/07 01:43:20 cmungall Exp $
#
#   Test Harness for Gene Ontology modules
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

# Exploit this by saying "use GO::TestHarness;"

package GO::TestHarness;
use GO::Admin;

our $CONF = "t/go-test.conf";
our $admin = GO::Admin->new;
$admin->loadp($CONF);


require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
             dd
             autopass
	     memory_leak_test
	     stmt_err
	     stmt_fail
	     stmt_note
	     stmt_check
	     stmt_ok
	     n_tests
	     set_n_tests
	     get_readonly_apph
	     getapph
             get_command_line_connect_args
	     create_test_database
	     destroy_test_database
		);

use Config;


sub dd {
    use Data::Dumper;
    print Dumper(shift);
}

sub autopass {
    my $n = shift;

    if (!$n) {
        $n = $n_tests - ($ok_counter || 0);
    }
    print "AUTOMATICALLY passing $n remaining subtests (total $n_tests)\n";
#    for (my $i=0; $i<$n; $i++) {
    for (my $i=0; $i<$n_tests; $i++) {
        &stmt_ok;
    }
    exit 0;
}

sub create_test_database {
#    my $name = shift || $ENV{GO_TEST_DATABASE_NAME};
    my $name = $admin->tmpdbname;
    autopass if $ENV{GO_NODBWRITE};
    autopass unless $name;
    eval {
        require "DBIx/DBStag.pm";
    };
    if ($@) {
        print "DBIx::DBStag not installed - skipping db loading tests\n";
        autopass();
    }
    if (system("which xsltproc > /dev/null")) {
        print "xsltproc not installed - skipping db loading tests\n";
        autopass();
    }

    $admin->dbname($name);
    $admin->newdb;
    $admin->load_schema;
    $ENV{GO_TEST_CONNECT_PARAMS} =
      sprintf("%s %s %s",
              ($dbms ? "-dbms $dbms" : ""),
              ($server ? "-dbhost $server" : ""),
              "-dbname $name");
}

sub destroy_test_database {
    $admin->dbname($admin->tmpdbname);
    $admin->dropdb;
}

sub get_readonly_apph {
    $admin->loadp($CONF);
    my @params = (-dbname=>$admin->dbname,
		  -dbhost=>$admin->dbhost,
		  ($admin->dbsocket ? (-dbsocket=>$admin->dbsocket) : ()),
		  ($admin->dbuser ? (-dbuser=>$admin->dbuser) : ()),
		  ($admin->dbauth ? (-dbauth=>$admin->dbauth) : ()),
		 );
    
    require GO::AppHandle;
    my $apph = GO::AppHandle->connect(@params) || die;
    return $apph;
  }

sub getapph {
    $admin->loadp($CONF);
    $admin->dbname($admin->tmpdbname);
    my @params = (-dbname=>$admin->dbname,
		  -dbhost=>$admin->dbhost,
		  ($admin->dbsocket ? (-dbsocket=>$admin->dbsocket) : ()),
		  ($admin->dbuser ? (-dbuser=>$admin->dbuser) : ()),
		  ($admin->dbauth ? (-dbauth=>$admin->dbauth) : ()),
		 );
    require GO::AppHandle;
    my $apph;
    eval {
          $apph = GO::AppHandle->connect(@params);
      };
    if ($@) {
	print "Can't connect using @params - see $@";
	print "will skip this test\n\n";
	autopass;
    }
    return $apph;
  }

sub get_command_line_connect_args {
    $admin->loadp($CONF);
    $admin->dbname($admin->tmpdbname);
    return $admin->db_auth_string;
}

sub populate_graph_path {
    $admin->populate_graph_path;
}

our $n_tests = 0;
my $ok_counter = 0;
sub stmt_err
  {
      my ($str) = @_;
      my ($err, $state);
      $str = "Error Message" unless ($str);
      &stmt_note($str);
  }

sub stmt_ok
  {
      my ($warn) = @_;
      $ok_counter++;
      &stmt_note("ok $ok_counter\n");
      &stmt_err("Warning Message") if ($warn);
  }

sub stmt_fail
  {
      my ($warn) = @_;
      &stmt_note($warn) if ($warn);
      $ok_counter++;
      &stmt_note("not ok $ok_counter\n");
      &stmt_err("Error Message");
      die "!! Terminating Test !!\n";
  }

sub all_ok
  {
      &stmt_note("# *** Testing of GO::* complete ***\n");
      &stmt_note("# ***     You appear to be normal!      ***\n");
      exit(0);
  }

sub stmt_note
  {
      print STDOUT @_;
      print STDOUT "\n";
  }

sub n_tests
  {
      my $n = shift;
      $n_tests = $n;
      #print "n tests = $n_tests\n";
      print STDOUT "1..$n\n";
  }
sub set_n_tests
  {
      my $n = shift;
      $n_tests = $n;
  }

sub stmt_check
  {
      my $true;
      if (@_ >1) {
          $true = $_[0] eq $_[1];
          if (!$true) {
              print STDERR "Expected:$_[0], got $_[1]\n";
          }
      }
      else {
          $true = shift;
      }
      if ($true) {
	  stmt_ok;
      }
      else {
	  stmt_fail;
      }
  }

# Run a memory leak test.
# The main program will normally read:
#		use strict;
#		use DBD::Informix::TestHarness;
#		&memory_leak_test(\&test_subroutine);
#		exit;
# The remaining code in the test file will implement a test
# which shows the memory leak.  You should not connect to the
# test database before invoking memory_leak_test.
sub memory_leak_test
  {
      my($sub, $nap, $pscmd) = @_;
      use vars qw($ppid $cpid $nap);
      
      $|=1;
      print "					      # Bug is fixed if size of process stabilizes (fairly quickly!)\n";
      $ppid = $$;
      $nap  = 5 unless defined $nap;
      $pscmd = "ps -lp" unless defined $pscmd;
      $pscmd .= " $ppid";
      
      $cpid = fork();
      die "failed to fork\n" unless (defined $cpid);
      if ($cpid)
	{
	    # Parent
	    print "				      # Parent: $ppid, Child: $cpid\n";
	    # Invoke the subroutine given by reference to do the real database work.
	    &$sub();
	    # Try to ensure that the child gets a chance to report at least once more...
	    sleep ($nap * 2);
	    kill 15, $cpid;
	    exit(0);
	}
      else
	{
	    # Child -- monitor size of parent, while parent exists!
	    system "$pscmd | sed 's/^/		      # /'";
	    sleep $nap;
	    while (kill 0, $ppid)
	      {
		  system "$pscmd | sed -e 1d -e 's/^/ # /'";
		  sleep $nap;
	      }
	}
  }


1;
