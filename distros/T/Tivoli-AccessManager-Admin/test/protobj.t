#!/usr/bin/perl 
# vim: set filetype=perl:
# COVER:ProtObject.pm
use strict;
use warnings;
use Term::ReadKey;

use Test::More tests => 89;
use Data::Dumper;

BEGIN {
    use_ok( 'Tivoli::AccessManager::Admin' );
}

ReadMode 2;
print "sec_master password: ";
my $pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd = Tivoli::AccessManager::Admin->new( password => $pswd);
my $pobj = Tivoli::AccessManager::Admin::ProtObject->new( $pd, name => '/test/horde/monkey' );
my ($resp, $create);

isa_ok( $pobj, 'Tivoli::AccessManager::Admin::ProtObject' );

print "\nTESTING new and create\n";
SKIP: {
    skip "monkey already created", 3 if $pobj->exist;

    $resp = $pobj->create;
    is( $resp->isok, 1, 'monkey created' ) or diag( $resp->messages );

    $resp = $pobj->type;
    is( $resp->value, 0, "Unknown object type" ) 
	or diag( $resp->messages );

    $resp = $pobj->description;
    is( $resp->value, '', "Empty description") or diag( $resp->messages );
}

$resp = $pobj->create;
is( $resp->iswarning, 1, "Couldn't recreate the monkey" ) 
    or diag( $resp->messages );

$resp = $pobj->create(qw/one two three/);
is($resp->isok,0,"Could not create with an odd number of parameters");

is( $pobj->name, "/test/horde/monkey", "Got the name back" );

$pobj->delete;

$resp = Tivoli::AccessManager::Admin::ProtObject->create( $pd,
				        name => '/test/horde/monkey',
					description => 'Foo, baby',
					type => 11,
				    );
is( $resp->isok, 1, "Used create as a constructor");

$pobj = $resp->value;

print "\nTESTING acl attach and detach\n";
$resp = $pobj->acl;
my $href = $resp->value;
is( $href->{effective}, 'default-root', 'Effective ACL is default-root' ) 
    or diag( Dumper($href,$resp));

$resp = $pobj->acl(attach => 'default-webseal');
$href = $resp->value;
is( $href->{attached}, 'default-webseal', 'Attached ACL' ) 
    or diag( $resp->messages );

$resp = $pobj->acl(detach => 'default-webseal');
$href = $resp->value;
is( $href->{effective}, 'default-root', 'Detached ACL' ) 
    or diag( Dumper($href));

$resp = $pobj->acl(attach => 'foobart');
is( $resp->isok, 0, "Couldn't attach a non-existent ACL" ) or 
    diag($resp->messages);

$resp = $pobj->acl(detach => 'foobart');
is( $resp->isok, 0, "Couldn't detach a non-existent ACL" ) or 
    diag($resp->messages);

print "\nTESTING authzrule\n";
$resp = $pobj->authzrule;
$href = $resp->value;
is( $href->{effective}, '', 'Effective authzrule is blank' ) 
    or diag( $resp->messages );

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

$resp = Tivoli::AccessManager::Admin::AuthzRule->create($pd, name => 'Monkey', rule => $ruletext);
my $arule = $resp->value;

$resp = $pobj->authzrule(attach => 'Monkey');
is($resp->isok, 1, "Attached an authzrule");

$resp = Tivoli::AccessManager::Admin::ProtObject->find( $pd, authzrule => 'Monkey' );
is($resp->isok, 1, "Listed by authzrule") or diag($resp->messages);

is_deeply([$resp->value],[qw#/test/horde/monkey#], "Found the right object by authzrule");

$resp = $pobj->authzrule(detach => 'Monkey');
is($resp->isok, 1, "Detached an authzrule");

$arule->delete;

print "\nTESTING pop\n";
$resp = $pobj->pop;
$href = $resp->value;
is( $href->{effective}, '', 'Effective POP is blank' ) 
    or diag( $resp->messages );

print "\nTESTING list functions\n";
$resp = $pobj->acl(attach => 'default-webseal');

my @list = qw#/WebSEAL /test/horde/monkey#;
$resp = $pobj->find( acl => 'default-webseal' );
is_deeply( [$resp->value], \@list, 'Found the monkey by ACL' )
    or diag( Dumper($resp) );

my @ospace = qw# /Management /WebSEAL /test#;
my $top = Tivoli::AccessManager::Admin::ProtObject->new( $pd, name => "/" );
$resp = $top->list;
is_deeply([$resp->value],\@ospace,'Found the monkey') or diag( $resp->value );

print "\nTESTING type calls\n";
$resp = $pobj->type(type => 11);
is( $resp->value, 11, "Type is now container" ) 
    or diag( $resp->messages );

$resp = $pobj->type('silly');
is( $resp->isok, 0, "Invalid type didn't work" ) 
    or diag( $resp->messages );

print "\nTESTING policy_attachable\n";
$resp = $pobj->policy_attachable();
is( $resp->isok, 1, 'Got the attachable bit: ' . $resp->value) 
    or diag( $resp->messages );
my $oldval = $resp->value;
my $newval = $oldval ? 0 : 1;

$resp = $pobj->policy_attachable($newval);
is ( $resp->value,  $newval, 'Flipped the attachable flag' ) 
    or diag( $resp->messages );

$resp = $pobj->policy_attachable(silly => $oldval);
is ($resp->value,$newval,'Ignored a silly parameter')
    or diag( $resp->messages );

$resp = $pobj->policy_attachable(att => $oldval);
is ( $resp->value,  $oldval, 'Unflipped the attachable flag' ) 
    or diag( $resp->messages );

print "\nTESTING description\n";
$resp = $pobj->description(description => "monkey");
is( $resp->value, 'monkey', "Monkey description" ) or diag( $resp->messages );

$resp = $pobj->description(silly => "monkey");
is( $resp->value, 'monkey', "Ignored a silly parameter" ) or 
    diag( $resp->messages );

print "\nTESTING attributes\n";
my $attr = { crack => ['smoking'], evil => [1] };
$resp = $pobj->attributes( add => $attr );
is_deeply( scalar($resp->value), $attr, "Added attributes" ) 
    or diag($resp->messages);


push @{$attr->{crack}}, 'blueberry';
$resp = $pobj->attributes( add => $attr );
is_deeply( scalar($resp->value), $attr, "Added another attributes" ) 
    or diag($resp->messages);

shift @{$attr->{crack}};
$resp = $pobj->attributes( remove => { crack => [qw/smoking/] } );
is_deeply( scalar($resp->value), $attr, "Removed smoking" ) 
    or diag($resp->messages);

push @{$attr->{crack}}, 'smoking';
$resp = $pobj->attributes( add => { crack => 'smoking' } );
is_deeply( scalar($resp->value), $attr, "Added another attribute as a singleton" ) 
    or diag($resp->messages);

shift @{$attr->{crack}};
$resp = $pobj->attributes( remove => { crack => 'blueberry' } );
is_deeply( scalar($resp->value), $attr, "Removed blueberry as a singleton" ) 
    or diag($resp->messages);

delete $attr->{crack};
$resp = $pobj->attributes( removekey => [ qw/crack/ ] );
is_deeply( scalar($resp->value), $attr, "Removed crack" ) 
    or diag($resp->messages);

$resp = $pobj->attributes;
is_deeply( scalar($resp->value), $attr, "Got the attribute key/value list back" ) 
    or diag($resp->messages);

$resp = $pobj->attributes( add => { foo => 1, bar => 1, baz => 1 } );
$resp = $pobj->attributes( removekey => [ qw/foo bar baz/ ] );
is ($resp->isok, 1, "Removed multiple keys at once");

print "\nTESTING bad attribute calls\n";
$resp = $pobj->attributes( removekey => [ qw/crack/ ] );
is( $resp->isok, 0, "Couldn't remove an undefined key" );

$resp = $pobj->attributes( remove => { evil => 'little monkey' } );
is( $resp->isok, 0, "Couldn't remove an undefined value" );

$resp = $pobj->delete;
is( $resp->isok, 1, "Monkey deleted") or diag( $resp->messages );

print "\nTESTING various create and new combinations\n";
my $obj = Tivoli::AccessManager::Admin::ProtObject->new( $pd );
isa_ok( $obj, 'Tivoli::AccessManager::Admin::ProtObject' );

$resp = $obj->create();
is( $resp->isok, 0, "Couldn't create an object w/o a name" ) 
    or diag($resp->messages );

$resp = $obj->create( name => '/test/horde/monkey1',
		      description => 'An evil monkey' );
is( $resp->isok, 1, "Created an object by sending the name to create" ) 
    or diag($resp->messages );
$resp = $obj->description;
is($resp->value, 'An evil monkey', 'Description set during create' )
    or diag( $resp->messages );

$obj->delete;

$obj = Tivoli::AccessManager::Admin::ProtObject->new( $pd,
				    name        => '/test/horde/monkey1',
				    description => 'An evil monkey',
				    type        => 11 );
isa_ok( $obj, 'Tivoli::AccessManager::Admin::ProtObject', "New worked" );
is( $obj->{name}, '/test/horde/monkey1', "It took the name" );
is( $obj->{description}, 'An evil monkey', "It took the description" );
is( $obj->{type}, 11, 'It is a container' );

$obj = Tivoli::AccessManager::Admin::ProtObject->new( $pd,
				    name        => '/test/horde/monkey1',
				    type        => 'silly' );
is( $obj, undef, "Couldn't new with a silly type" );

$obj = Tivoli::AccessManager::Admin::ProtObject->new( $pd );
$resp = $obj->create( name => '/test/horde/monkey1',
		      description => 'An evil monkey',
		      type => 'silly' );
is( $resp->isok, 0, "Couldn't create an object with a bad type" ) 
    or diag($resp->messages );

$resp = $obj->create( name => '/test/horde/monkey1',
		      description => 'An evil monkey',
		      type => 11 );
is( $resp->isok, 1, "Created an object with a type" ) 
    or diag($resp->messages );

$resp = $obj->type;
is( $resp->value, 11, "Type is correct" ) 
    or diag( $resp->messages );

$resp = $obj->type( silly => 12 );
is( $resp->value, 11, "Ignored silly parameter");

$resp = $obj->type( type => 19 );
is( $resp->isok, 0, "Ignored type > 18");

my $foo = Tivoli::AccessManager::Admin::ProtObject->new( $pd,
				    name => '/test/horde/monkey1' );
is($foo->exist, 1, "Cloned me an object") or diag($resp->messages);

$obj->delete;
$resp = $obj->delete;
is($resp->isok, 0, "Couldn't delete it again");

$obj = Tivoli::AccessManager::Admin::ProtObject->new( $pd,
				name => 'foobar',
				type => 19 );
is($obj, undef, "Couldn't create an object with a type > 18");

$obj =  Tivoli::AccessManager::Admin::ProtObject->new( $pd,
				name => 'foobar');

$resp = $obj->create( type => 19 );
is($resp->isok, 0, "Couldn't create an object with a type > 18");

print "\nTESTING empty parameter lists\n";
my $bork = Tivoli::AccessManager::Admin::ProtObject->new;
is($bork, undef, "Could not call new() with an empty parameter list");

$resp = Tivoli::AccessManager::Admin::ProtObject->create;
is($resp->isok, 0, "Could not call create() with an empty parameter list");

$resp = Tivoli::AccessManager::Admin::ProtObject->find;
is($resp->isok, 0, "Could not call find() with an empty parameter list");

print "\nTESTING invalid parameter lists\n";
$bork = Tivoli::AccessManager::Admin::ProtObject->new( qw/one/ );
is($bork, undef, "Could not call new() without a context object");

$bork = Tivoli::AccessManager::Admin::ProtObject->new( $pd, qw/two/ );
is($bork, undef, "Could not call new() with an odd number of parameters");

$resp = Tivoli::AccessManager::Admin::ProtObject->create( $pd, qw/two/ );
is($resp->isok, 0, "Could not call create() with an odd number of parameters");

$resp = Tivoli::AccessManager::Admin::ProtObject->create( qw/two/ );
is($resp->isok, 0, "Could not call create() with a non-context object");

$resp = Tivoli::AccessManager::Admin::ProtObject->find( $pd, qw/one two/);
is($resp->isok, 0, "Could not call find() with an invalid parameter list");

$bork = Tivoli::AccessManager::Admin::ProtObject->new( $pd, 
				      name => "/test/horde/evilmonkey",
				      type => 11);
$resp = $bork->type(10);
is($resp->isok, 0, "Could not set the type of a non-existent object");

$resp = $bork->description(10);
is($resp->isok, 0, "Could not set the description of a non-existent object");

$resp = $bork->policy_attachable(10);
is($resp->isok, 0, "Could not set the policy_attachable of a non-existent object");

$resp = $bork->attributes(add => { foo => 'bar' });
is($resp->isok, 0, "Could not call attributes() with a non-existent object");

$resp = $bork->create;

$resp = $bork->type(qw/one two three/);
is($resp->isok, 0, "Could not call type() with an odd number of parameters");

$resp = $bork->description(qw/one two three/);
is($resp->isok, 0, "Could not call description() with an odd number of parameters");

$resp = $bork->policy_attachable(qw/one two three/);
is($resp->isok, 0, "Could not call policy_attachable() with an odd number of parameters");

$resp = $bork->attributes(qw/one two three/);
is($resp->isok, 0, "Could not call attributes() with an odd number of parameters");

$resp = $bork->find(qw/one two three/);
is($resp->isok, 0, "Could not call find() with an odd number of parameters");

$resp = Tivoli::AccessManager::Admin::ProtObject->find(qw/one two three/);
is($resp->isok, 0, "Could not call find() without a context");

print "\nTESTING evil\n";

$bork->{exist} = 0;
$resp = $bork->create;
is($resp->isok, 0, "Could not create evil");
$bork->{exist} = 1;

$resp = $bork->delete;
$bork->{exist} = 1;

$resp = $bork->delete;
is($resp->isok, 0, "Could not delete evil");

$bork = Tivoli::AccessManager::Admin::ProtObject->new( $pd, 
				      name => "/test/horde/evilmonkey",
				      type => 11);

$bork->{exist} = 1;

$resp = $bork->type(10);
is($resp->isok, 0, "Could not set evil's type");

$resp = $bork->description('evil');
is($resp->isok, 0, "Could not set evil's description");

$resp = $bork->attributes(add => { evil => 'monkey' });
is($resp->isok, 0, "Could not add attributes to evil");

$resp = $bork->attributes(remove => { evil => 'monkey' });
is($resp->isok, 0, "Could not remove attributes from evil");

$resp = $bork->attributes(removekey => 'evil');
is($resp->isok, 0, "Could not add attributes to evil");

$resp = $bork->attributes(add => { evil => ['monkey'] });
is($resp->isok, 0, "Could not add attributes to evil, redux");

$resp = $bork->attributes(remove => { evil => ['monkey'] });
is($resp->isok, 0, "Could not remove attributes from evil, redux");

$resp = $bork->attributes(removekey => ['evil']);
is($resp->isok, 0, "Could not add attributes to evil, redux");

$resp = $bork->authzrule(attach => '/test/evil/monkey');
is($resp->isok, 0, "Could not attach evil");

$resp = $bork->authzrule(detach => '/test/evil/monkey');
is($resp->isok, 0, "Could not detach evil");

END {
    ReadMode 0;
}
