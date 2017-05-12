#!/usr/bin/perl
# vim: set filetype=perl:
# COVER:AuthzRule.pm
use strict;
use warnings;

use Data::Dumper;
use Term::ReadKey;
use Test::More tests => 74;

BEGIN {
    use_ok( 'Tivoli::AccessManager::Admin' );
}

ReadMode 2;
print "sec_master password: ";
my $pswd = <STDIN>;
ReadMode 0;
chomp $pswd;
print "\n";

my $ruletext = <<"EOR";
<xsl:choose>
    <xsl:when test="contains(azn_cred_registry_id,'ou=people') and
                  not (azn_cred_principal_name = 'mikfire')">
        !TRUE!
    </xsl:when>

    <xsl:when test="anz_cred_principal_name = 'wasadmin'">
        !TRUE!
    </xsl:when>

    <xsl:otherwise>
        !INDIFFERENT!
    </xsl:otherwise>

</xsl:choose>
EOR
# Create an authzrule text file
open FOO, ">authzrule.txt" or die "Couldn't open authzrule.txt for writing: $!\n";
print FOO $ruletext;
close FOO;

my (@temp);
my $pd = Tivoli::AccessManager::Admin->new( password => $pswd);

# Create the authzrule 
my $rule = Tivoli::AccessManager::Admin::AuthzRule->new($pd);
isa_ok( $rule, 'Tivoli::AccessManager::Admin::AuthzRule' );
is( $rule->exist, 0, 'The test rule does not exist' ) or diag(Dumper($rule));

$rule = Tivoli::AccessManager::Admin::AuthzRule->new( $pd, name => 'Test' );
isa_ok( $rule, 'Tivoli::AccessManager::Admin::AuthzRule' );
is( $rule->exist, 0, 'The test rule does not exist' ) or diag(Dumper($rule));

print "\nTesting creation\n";

my $resp = Tivoli::AccessManager::Admin::AuthzRule->create($pd, name => 'Test', rule => $ruletext);
is( $resp->isok, 1, "Used create as a constructor" );
isa_ok( $resp->value, "Tivoli::AccessManager::Admin::AuthzRule", "and got the right object class");
$rule = $resp->value;

$resp = $rule->delete;
is( $resp->isok, 1, "Deleted new authzrule") or diag($resp->messages);

$resp = $rule->create( rule => $ruletext, description => 'Test authzrule', failreason => 'warning' );
is( $resp->isok, 1, "Created new authzrule with all the options" ) 
    or diag($resp->messages);
$resp = $rule->description();
is( $resp->value, 'Test authzrule', "Retrieved the description" ) 
    or diag($resp->messages);

$resp = $rule->failreason();
is( $resp->value, 'warning', "Retrieved fail reason" ) 
    or diag($resp->messages);
$resp = $rule->ruletext();
is( $resp->value, $ruletext, "Got the rule text back" ) or diag(Dumper($resp));

$resp = $rule->delete;

# Create with a rule file
$resp = $rule->create( file => "authzrule.txt", 
		       description => 'Test authzrule', 
		       failreason => 'warning' );
is( $resp->isok, 1, "Created new authzrule with a file" );
$resp = $rule->ruletext();
is( $resp->value, $ruletext, "Got the rule text back" ) or diag(Dumper($resp));
$resp = $rule->delete;

# Create with the rule only, then add the description and fail reason in
$resp = $rule->create( rule => $ruletext );
is( $resp->isok, 1, "Create a rule with the ruletext only" );

print "\nTesting the get/set calls\n";
$resp = $rule->description;
is($resp->value,'',"Got an empty description");

$resp = $rule->description( description => 'Test authzrule' );
is( $resp->isok, 1, "Set the description" );
is( $resp->value, 'Test authzrule', "and got it back" );

$resp = $rule->description( 'Alternate Test authzrule' );
is( $resp->isok, 1, "Set the description differently" );
is( $resp->value, 'Alternate Test authzrule', "and got it back" );

$resp = $rule->failreason;
is($resp->value,'',"Got an empty description");

$resp = $rule->failreason( reason => 'warning' );
is( $resp->isok, 1, "Set the failreason" );
is( $resp->value, 'warning', "and got it back" );

$resp = $rule->failreason( 'red card' );
is( $resp->isok, 1, "Set the failreason differently" );
is( $resp->value, 'red card', "and got it back" );

my $newtext = $ruletext;
$newtext =~ s/mikfire/sec_master/g;
$resp = $rule->ruletext( rule => $newtext );
is( $resp->isok, 1, "Changed the rule text" );
is( $resp->value, $newtext, "and got it back" );

$resp = $rule->ruletext( file => 'authzrule.txt' );
is( $resp->isok, 1, "Changed the rule text using a file" );
is( $resp->value, $ruletext, "and got it back" );

print "\nTesting list and find\n";

# Create a few more authzrules
my (@list,@rules);
for ( 0 ... 4 ) {
    my $temp = sprintf("Test%d", $_ );
    $resp = Tivoli::AccessManager::Admin::AuthzRule->create($pd,name => $temp ,rule => $ruletext);
    $rules[$_] = $resp->value;
}

$resp = Tivoli::AccessManager::Admin::AuthzRule->list($pd);
@temp = $resp->value;
is_deeply( \@temp, [qw/Test Test0 Test1 Test2 Test3 Test4/], "Listed all five authzrules (class method)");
$resp = $rule->list;
@temp = $resp->value;
is_deeply( \@temp, [qw/Test Test0 Test1 Test2 Test3 Test4/], "Listed all five authzrules (instance method)");

$resp = Tivoli::AccessManager::Admin::AuthzRule->list($pd, pattern => '*\d$');
@temp = $resp->value;
is_deeply( \@temp, [qw/Test0 Test1 Test2 Test3 Test4/], "Pattern match worked");

# Clean up
for ( 0 ... 4 ) {
    $resp = $rules[$_]->delete();
    die $resp->messages unless $resp->isok;
}

$resp = $rule->attach("/WebSEAL");
is($resp->isok, 1, "Attached " . $rule->name . " to /WebSEAL");

$resp = $rule->find;
is( ($resp->value)[0], "/WebSEAL", "found it there too" );

$resp = $rule->detach;
is( $resp->isok, 1, "Detached the authzrule (no parameters)" );
is( ($resp->value)[0], "/WebSEAL", "and detached it from where it was attached" );

$resp = $rule->attach("/WebSEAL");
$resp = $rule->detach("/WebSEAL");
is( $resp->isok, 1, "Detached the authzrule (parameters)" );
is( ($resp->value)[0], "/WebSEAL", "and detached it from where it was attached" );

print "\nTesting some alternates\n";
my $newrule = Tivoli::AccessManager::Admin::AuthzRule->new($pd, name => 'Test');
is($rule->exist,1,"Create an authzrule object for an existing rule");

$resp = $newrule->description( silly => 'Borked description' );
is($resp->isok,1, 'Could call description with a nonsense hash');

$resp = $newrule->failreason( silly => 'Borked description' );
is($resp->isok,1, 'Could call failreason with a nonsense hash');

print "\nTesting breakages\n";
$resp = $rule->delete;
$resp = $rule->delete;
is( $resp->isok, 0, "Couldn't delete a non-existent rule" );

$resp = $rule->create;
is($resp->isok, 0, "Couldn't create a rule without rule text");

$resp = $rule->create( file => '/var/tmp/wikiwikiwik' );
is($resp->isok, 0, "Couldn't create a rule with a file that doesn't exist");

$resp = $rule->description( description => 'nonexistent' );
is($resp->isok,0, "Couldn't set the description of a rule that doesn't exist");

$resp = $rule->description;
is($resp->isok,0, "Couldn't get the description of a rule that doesn't exist");

$resp = $rule->failreason( reason => 'warning' );
is($resp->isok,0, "Couldn't set the failreason of a rule that doesn't exist");

$resp = $rule->failreason;
is($resp->isok,0, "Couldn't get the failreason of a rule that doesn't exist");

$resp = $rule->ruletext( rule => $ruletext );
is($resp->isok,0, "Couldn't set the rule text of a rule that doesn't exist");

$resp = $rule->attach( qw#/path/to/nowhere# );
is($resp->isok,0, "Couldn't attach a rule that doesn't exist");

$resp = $rule->ruletext;
is($resp->isok,0, "Couldn't retrieve the rule text from a nonrule");

$resp = $rule->create( rule => $ruletext );
is( $resp->isok, 1, "Created a rule" );
$resp = $rule->create;
is( $resp->iswarning,1,"and was warned about creating it twice" );

$resp = $rule->ruletext( file =>  '/var/tmp/wikiwikiwik' );
is( $resp->isok, 0, "Could not set the ruletext from a non-existent file" );

print "\nTESTING invalid calls\n";

my $foo = Tivoli::AccessManager::Admin::AuthzRule->new( name => 'borked' );
is($foo, undef, "Couldn't call new w/o the context");

$foo = Tivoli::AccessManager::Admin::AuthzRule->new( undef, name => 'borked' );
is($foo, undef, "Couldn't call new with an undefined context");

$resp = Tivoli::AccessManager::Admin::AuthzRule->list(undef, 'w00t');
is($resp->isok, 0, "Couldn't call list with an undefined context");

$foo = Tivoli::AccessManager::Admin::AuthzRule->new( $rule, name => 'borked' );
is($foo, undef, "Couldn't call new with something that wasn't a context");

$foo = Tivoli::AccessManager::Admin::AuthzRule->new( $pd, 'borked', 'borked', 'borked' );
is($foo, undef, "Odd number of parameters to new failed");

$resp = Tivoli::AccessManager::Admin::AuthzRule->list($rule, name => 'borked');
is($resp->isok, 0, "Couldn't call list with something that wasn't a context");

$resp = Tivoli::AccessManager::Admin::AuthzRule->list($pd, 'w00t');
is($resp->isok, 0, "Odd number of parameters to list failed");

$foo = Tivoli::AccessManager::Admin::AuthzRule->new( $pd, 'borked' );
$resp = $foo->create( 'wiki' );
is($resp->isok, 0, "Odd number of parameters to create failed");

$resp = $foo->description( 'work', 'work', 'work' );
is( $resp->isok, 0, "Odd number of parameters to description failed");

$resp = $foo->ruletext( 'work', 'work', 'work' );
is( $resp->isok, 0, "Odd number of parameters to ruletext failed");

$resp = $foo->failreason( 'work', 'work', 'work' );
is( $resp->isok, 0, "Odd number of parameters to failreason failed");

$resp = $foo->detach;
is($resp->isok,0,"Could not detach a non-existant rule");

$foo = Tivoli::AccessManager::Admin::AuthzRule->new($pd, silly => 'borked' );
is( $foo->exist, 0, "Bad hash key worked");

print "\nTESTing evil\n";

$rule->{exist} = 0;
$resp = $rule->create(rule => $ruletext );
is($resp->isok,0,"Could not create an evil rule");
$rule->{exist} = 1;

$foo->{exist} = 1;
$resp = $foo->attach("/test");
is($resp->isok,0,"Could not attach an evil rule");

$resp = $foo->detach("/test");
is($resp->isok,0,"Could not detach an evil rule");

$resp = $foo->delete;
is($resp->isok,0,"Could not delete an evil rule");

$resp = $foo->description('Evil');
is($resp->isok,0,"Could not describe an evil rule");

$resp = $foo->ruletext(rule => $ruletext);
is($resp->isok,0,"Could not set the ruletext for an evil rule");

$resp = $foo->failreason("Ooops");
is($resp->isok,0,"Could not set the failreason for an evil rule");

$foo->{exist} = 0;

# Clean up
print "\nCleaning up\n";
$resp = $rule->delete;

unlink "authzrule.txt";
