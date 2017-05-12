package Test::Story::Tutorial;

1; # Wuuuuut?

__END__

=head1 NAME

Test::Story::Tutorial -- How to write automation tests

=head1 WRITING A TESTCASE

=head2 FOR EVERYONE

Writing a test should not be a difficult part of creating an application. The
more difficult writing tests is, the less likely they will be written.

To solve this, Test::Story makes it possible to write tests using natural 
language (with some special formatting so that it can be parsed by the system).

Here is an example testcase:

 ---
 NAME: Test Updating a User Profile
 ID: admin_profile
 SUMMARY: Update a user's profile through the admin user
 TAGS: admin, profile
 PRECONDITIONS:
    - ensure user is: Admin
    - ensure user exists: TestUser
 INSTRUCTIONS:
    - goto profile for: TestUser
    - verify form value:
        username:   TestUser
    - change username to: TestedUser
    - save form
    - verify user exists: TestedUser
 POSTCONDITIONS:
    - delete user: TestedUser

The NAME, ID, SUMMARY, and TAGS all describe this testcase. Using ID and 
TAGS we can pick out the particular testcase we want to run. Try to be 
descriptive but brief.

The PRECONDITIONS section allows us to set up for the test. For this test, 
we make sure the user performing the actions is Admin, and we make sure that
a user called "TestUser" exists for us to test against. 

The INSTRUCTIONS section is where we run our test. The first thing we do
is go to the TestUser's profile. We verify that the form contains a field 
named "username" that has the value of "TestUser". Then we change their 
username to TestedUser. Finally we verify that the username was changed.

The POSTCONDITIONS section allows us to clean up after our test. For this test,
all we need to do is remove the TestedUser we created as TestUser before the
test.

=head2 FOR PROGRAMMERS

The testcase is a YAML document with the format shown above, which results in 
the following data structure:

 {
    "NAME"              => 'Test Updating a User Profile',
    "ID"                => 'admin_profile',
    "SUMMARY"           => q{Update a user's profile through the admin user},
    "TAGS"              => [ "admin", "profile" ],
    "PRECONDITIONS"     => [
        {
            "ensure user is" => "Admin",
        },
        {
            "ensure user exists" => "TestUser",
        },
    ],
    "INSTRUCTIONS"      => [
        {
            "goto profile for" => "TestUser",
        },
        {
            "verify form value" => {
                "username"      => "TestUser",
            },
        },
        {
            "change username to" => "TestedUser",
        },
        {
            "save form" => undef,
        },
        {
            "verify user exists" => "TestedUser",
        },
    ],
    "POSTCONDITIONS"    => [
        {
            "delete user" => "TestedUser",
        },
    ],
 }

For each key in the PRECONDITIONS, INSTRUCTIONS, and POSTCONDITIONS hashrefs, 
there must be a method in your fixture. This method will be passed the value
as an argument.

=head1 CREATING A FIXTURE

A fixture performs the actions described in the testcase. A fixture inherits
from L<Test::FITesque::Fixture> and implements the methods required by the
testcases to be run.

 package MyFixture;
 use strict;
 use base qw( Test::FITesque::Fixture );

The first methods we'll implement will manage our preconditions. The method
name is the same as the hash key (from above) with the spaces changed to 
underscores. The method is run on an instance of your fixture and is passed 
the hash value as the argument.

 sub ensure_user_is {
     my ( $self, $username ) = @_;

     # Log in as $username
 }

 sub ensure_user_exists {
     my ( $self, $username ) = @_;

     # Create $username if necessary
 }

Next we'll create some methods for testing. Test methods have the "Test" 
attribute. If the method has more than one test inside, the "Plan" attribute
can specify exactly how many.

 sub verify_form_value : Test : Plan(2) {
     my ( $self, $verify ) = @_;

     ok( ); # Test that the field exists
     ok( ); # Test that the value is what we expect
 }

 sub verify_user_exists : Test {
     my ( $self, $username ) = @_;

     ok( ); # $username exists
 }

Test::Story will calculate the correct number of tests to plan, and then it 
will run the tests.

=head2 CHOOSING GOOD METHOD NAMES

... TODO ...

=head1 RUNNING THE TESTCASE

Once we have a testcase and a fixture, we can run it. 

To run our testcase named "cases/profile.tc" using our fixture "MyFixture", we
do the following:

 #!/usr/bin/perl
 # profile.t -- Run the tests in profile.tc
 
 use strict;
 use Test::Story;

 my $runner = Test::Story->new(
    file_root       => 'cases',
    fixture_base    => 'MyFixture',
 );
 $runner->run_tests;


... TODO ...


