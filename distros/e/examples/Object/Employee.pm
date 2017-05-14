
#---------------------------------------------------------------------------
package Employee;
#---------------------------------------------------------------------------
# This package uses the ObjectTemplate package to declare an Employee object
# 
# 
# It consists
use ObjectTemplate;
@ISA = qw(ObjectTemplate);
attributes qw(name age);

sub print {
    my $obj = $_[0];
    print "Employee[$$obj] ...  Free index: $_free\n";
    print "\tName   => ", $obj->name  ,"\n";
    print "\tAge    => ", $obj->age   ,"\n";
}

sub name {
    # Example of a custom accessor function
    # Allows the name attribute to be set only once
    my $obj = shift;
    my $name = $obj->get_attribute("name");
    
    if (@_) {
       if ($name) {
          die "Cannot update name \n";
       } else {
          $obj->set_attribute("name", $_[0]);
       }
    }
    $name;
}

#-----------------------------------------------------------------------
# Sample inherited Class
#-----------------------------------------------------------------------

package HourlyEmployee;
@ISA = qw (Employee);
use ObjectTemplate;
attributes qw(wage);


#-----------------------------------------------------------------------
# TESTING CODE
#    Simply invoke as "perl Employee.pm"
#-----------------------------------------------------------------------

if (! caller()) {
    
    package main;
    #-----------------------------------------------------------
    # Check create
    $e1 = Employee->new(name => 'test1', age  => 43);
    $e2 = Employee->new(name => 'test2', age  => 50);
    if ($e1->name ne 'test1' || $e2->age != 50) {
        print "ERROR. Accessors not working\n";
    } else {
        print "OK. Accessors working\n";
    }    

    #-----------------------------------------------------------
    # Check that deleting one object doesn't mess the other
    undef $e1;
    
    if ($e2->name ne 'test2' || $e2->age != 50) {
        print "ERROR ... Delete messing up other objects\n";
    } else {
        print "OK. Delete doesn't affect other objects\n";
    }

    #-----------------------------------------------------------
    # Check creation of object after delete
    $e1 = Employee->new(name => 'test1', age  => 43);
    if ($e1->name ne 'test1' || $e2->age != 50) {
        print "ERROR .... Object not created correctly after delete\n";
    } else {
        print "OK. Object created correctly after delete\n";
    }

    #-----------------------------------------------------------
    # Check if custom accessor called
    eval {$e1->name("foo")};
    if ($@ !~ /Cannot update name/) {
        print "ERROR. Custom accessor not called\n";
    } else {
        print "OK. Custom accessor called\n";
    }

    #-----------------------------------------------------------
    # Check if inherited properly
    $e2 = HourlyEmployee->new(name => 'Joe', age => 47, wage => 40);
    if ($e2->name ne 'Joe' || $e2->age != 47) {
        print "ERROR. Accessors of inherited classes not working\n";
    } else {
        print "OK. Accessors of inherited classes working\n";
    }    
    
    eval {$e2->name("foo")};
    if ($@ !~ /Cannot update name/) {
        print "ERROR. Inherited custom accessor not called\n";
    } else {
        print "OK. Inherited custom accessor works\n";
    }

   
}
1;
