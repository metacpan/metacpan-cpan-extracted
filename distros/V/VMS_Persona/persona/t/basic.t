# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use VMS::Persona;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my ($PersonaOne, $PersonaTwo, $Username_One, $Username_Two);

$Username_One = 'ORACLE';
$Username_Two = 'SYSTEM';

# Try creating the persona of the first user
$PersonaOne = VMS::Persona::new_persona(NAME => $Username_One);
print defined($PersonaOne) ? "ok 2 # $PersonaOne\n" : "not ok 2\n";

# Try deleting it
print VMS::Persona::delete_persona($PersonaOne) ? "ok 3\n" : "not ok 3 #$^E\n";

# Set our persona to the first user 
$PersonaOne = VMS::Persona::new_persona(NAME => $Username_One);
print VMS::Persona::assume_persona(PERSONA => $PersonaOne, ASSUME_JOB_WIDE => yes, ASSUME_ACCOUNT => yes, ASSUME_SECURITY => yes) ? "ok 4\n" : "not ok 4 #$^E\n";

# What does DCL think? get the name and trim trailing blanks
chomp($DCLUsername = `write sys\$output f\$getjpi("","USERNAME")`);
$DCLUsername =~ s/ +$//;

if ($Username_One eq $DCLUsername) {
  print "ok 5\n";
} else {
  print "not ok 5 # us +$Username_One+ DCL +$DCLUsername+\n";
}

# Try deleting it while we're still using it. should fail
print VMS::Persona::delete_persona($PersonaOne) ? "not ok 6\n" : "ok 6 #$^E\n";

# Try dropping it
print VMS::Persona::drop_persona() ? "ok 7\n" : "not ok 7 #$^E\n";

# Lets reassume it
print VMS::Persona::assume_persona(PERSONA => $PersonaOne, ASSUME_JOB_WIDE => yes, ASSUME_ACCOUNT => yes, ASSUME_SECURITY => yes) ? "ok 8\n" : "not ok 8 #$^E\n";

# Drop it again. Persona one might not have privs to create a new persona,
# so we'd best drop back to our base persona, which has to to get anywhere
# in these tests.
VMS::Persona::drop_persona();

# Try creating a second persona
$PersonaTwo = VMS::Persona::new_persona(NAME => $Username_Two);
print defined($PersonaOne) ? "ok 9 # $PersonaTwo\n" : "not ok 9\n";

# Assume the second persona
print VMS::Persona::assume_persona(PERSONA => $PersonaTwo, ASSUME_JOB_WIDE => yes, ASSUME_ACCOUNT => yes, ASSUME_SECURITY => yes) ? "ok 10\n" : "not ok 10 #$^E\n";

# What does DCL think? get the name and trim trailing blanks
chomp($DCLUsername = `write sys\$output f\$getjpi("","USERNAME")`);
$DCLUsername =~ s/ +$//;

if ($Username_Two eq $DCLUsername) {
  print "ok 11\n";
} else {
  print "not ok 11 # us +$Username_Two+ DCL +$DCLUsername+\n";
}

# Drop it again, so we're back where we started
VMS::Persona::drop_persona();
