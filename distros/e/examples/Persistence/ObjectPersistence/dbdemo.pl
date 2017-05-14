#-----------------------------------------------------------------
# Invoke as perl -I../../Object demodb.pl {Adaptor::File|Adaptor::DBI}
# When program exits or transaction is committed, the data is flushed
# file.
#-----------------------------------------------------------------

# class Employee {
#     int _id; String name; int age;
# };
package Employee;
use ObjectTemplate;
@ISA = qw(ObjectTemplate);
attributes qw(_id name age);

sub print {
    my $obj = $_[0];
    foreach $attr (qw(_id name age)) {
        print $attr, " .... ", $obj->$attr(), "\n";
    }
    print "\n";
}

#-----------------------------------------------------------------
package main;
#-----------------------------------------------------------------

$dbname = 'DEMO732'; $user = 'scott'; 
$password = 'tiger'; $dbd = 'Oracle';

$adaptor = "Adaptor::File";
$adaptor = shift if (@ARGV);
if ($adaptor eq "Adaptor::DBI") {
    require Adaptor::DBI;
    $db = Adaptor::DBI->new($dbname, $user, $password, $dbd,
			    'empdb.cfg');
} elsif ($adaptor eq "Adaptor::File") {
    require Adaptor::File;
    $db = Adaptor::File->new('empfile.dat', 'empfile.cfg');
} else {
    die "Sorry. No support for $adaptor\n";
}
print "Loaded $adaptor\n";
#-----------------------------------------------------------------
$line = " ";
$auto_name = "aaa";  # Automatic name given for employee, for bulk create
do {
    my $obj; 
    if ($line =~ /^(exit|quit)/) {
        $db->flush() if ($1 eq "exit");
	exit(0);
    }
    if (($name,$age) = ($line =~ /^c (\w+) (\d+)/)) {
	$obj = Employee->new('name' => $name, 'age' => $age);
	$key = $db->store($obj);
	print "Employee $key created \n";
    } elsif (($key) = ($line =~ /^p (\d+)/)) {
	$obj = $db->retrieve("Employee", $key);
	if ($obj) {
	    $obj->print( );
	} else {
	    print "Object $key does not exist\n";
	}
    } elsif (($key, $name, $age) = ($line =~ /^m (\d+) (\w+) (\d+)/)) {
	$obj = $db->retrieve("Employee", $key);
	if ($obj) {
	    $obj->set_attributes(name => $name, age => $age);
           $db->store($obj);
	} else {
	    print "Object $key does not exist\n";
	}
    } elsif (($key) = ($line =~ /^d (\d+)/)) {
	$db->delete("Employee", $1);
    } elsif (($query) = ($line =~ /^qd(.*$)/)) {
	foreach $obj ($db->retrieve_where("Employee", $query)) {
	    $db->delete($obj);
	}
    } elsif (($query) = ($line =~ /^q(.*$)/)) {
	foreach $obj ($db->retrieve_where("Employee", $query)) {
	    $obj->print();
	}
    } elsif (($num_objects, $starting_age) = ($line =~ /^bc (\d+) (\d+)/)) {
	for ($i = 0; $i < $num_objects; $i++) {
	    $db->store(Employee->new ('name' => ++$auto_name, 
                                      'age' => $starting_age++));

	}
    } elsif ($line =~ /\btb\b/) {
	$db->begin_transaction();
	$in_transaction = 1;
    } elsif ($line =~ /\btc\b/) {
	$db->commit_transaction();
	$in_transaction = 0;
    } elsif ($line =~ /\btr\b/) {
	$db->rollback_transaction();
	$in_transaction = 0;
    } else {
	print "\n--------Error-------------\n" if ($line =~ /\S/);
	help();
    }
	     
    prompt();
} while (defined ($line = <STDIN>));
    
sub prompt {
    if ($in_transaction) {
	print "tx >> ";
    } else {
	print ">> ";
    }
}

sub help {
    print "\nType one of the following commands\n";
    print "bc <count> <age>    -- Bulk Create <count> employees, starting from <age>\n";
    print "c <name> <age>      -- Create a new employee, returns object id\n" ;
    print "d <id>              -- Delete employee\n" ;
    print "m <id> <name> <age> -- Modify employee\n";
    print "tb                  -- Transaction begin\n";
    print "tr                  -- Transaction rollback\n";
    print "tc                  -- Transaction commit \n";
    print "p <id>              -- Print employee details\n";
    print "q <query>           -- Print all employees that match query\n";
    print "                     e.g. name = 'sriram' || age > 30\n";
    print "qd <query>          -- Delete all employees that match query\n";
    print "quit                -- Quit, without saving changes \n";
    print "exit                -- Exit, after flushing changes \n";
}

