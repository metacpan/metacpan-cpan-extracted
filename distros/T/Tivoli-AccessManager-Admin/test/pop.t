#!/usr/bin/perl
# vim: set filetype=perl:
# COVER:POP.pm
use strict;
use warnings;

use Data::Dumper;
use Term::ReadKey;

use Test::More tests => 169;

BEGIN {
    use_ok('Tivoli::AccessManager::Admin');
}
my ($pop,$resp,$obj);

ReadMode 2;
print "sec_master password: ";
my $pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd = Tivoli::AccessManager::Admin->new(password => $pswd);

print "\nTESTING creates\n";

$pop = Tivoli::AccessManager::Admin->new('pop', $pd, name => 'test');
$resp = $pop->create;
is($resp->isok, 1, "Created test") or diag($resp->messages);
is($pop->exist, 1, "Exist says it does too");

$resp = $pop->description;
is($resp->value, undef, "Description is empty") 
    or diag($resp->messages);

$resp = $pop->description("POP goes the monkey");
is($resp->isok, 1, "Set the description") or diag($resp->messages);

$resp = $pop->description;
is($resp->value, 'POP goes the monkey', "Got the description") 
    or diag($resp->messages);

$resp = $pop->description(description => "PUSH goes the monkey");
is($resp->isok, 1, "Set the description") or diag($resp->messages);
is($resp->value, 'PUSH goes the monkey', "Got the description");

$resp = $pop->description(junk => "PUSH goes the monkey");
is($resp->value, 'PUSH goes the monkey', "Ignored junk parameters");

$resp = $pop->delete;
is($resp->isok, 1, "Deleted the test") or diag($resp->messages);

$pop = Tivoli::AccessManager::Admin::POP->new($pd);
$resp = $pop->create;
is($resp->isok, 0, "Couldn't create nameless POP") or diag($resp->messages);

$resp = $pop->create(name => 'test');
is($resp->isok, 1, "Created test by passing the name to create") 
    or diag($resp->messages);
$resp = $pop->delete;

$pop = Tivoli::AccessManager::Admin::POP->new($pd);
$resp = $pop->create('test');
is($resp->isok, 1, "Created test by passing single parameter") 
    or diag($resp->messages);
$resp = $pop->delete;

$resp = Tivoli::AccessManager::Admin::POP->create($pd, name => 'test');
is($resp->isok, 1, "Created test using create") or diag($resp->messages);
$pop = $resp->value;

print "\nTESTING attach/detach\n";

$resp = Tivoli::AccessManager::Admin::ProtObject->create($pd, name => '/test/monkey',
				     type => 11);
if ($resp->isok) {
    $obj = $resp->value;
    $obj->policy_attachable();
}
else {
    $pop->delete;
    die "Couldn't create a test object: ", $resp->messages(), "\n";
}

$resp = $pop->objects;
is_deeply([$resp->value], [], "Got an empty list of objects") 
    or diag($resp->messages);

$resp = $pop->objects(attach => $obj);
is($resp->isok, 1, "Attached using a Tivoli::AccessManager::Admin::ProtObject")
    or diag($resp->messages);

$resp = $pop->objects;
is_deeply([$resp->value], [ '/test/monkey' ], "Got the list back")
    or diag($resp->messages);

$resp = $pop->delete;
is($resp->isok, 0, "Couldn't delete an attached pop");

$resp = $pop->objects(detach => $obj);
is($resp->isok, 1, "Detached POP using a Tivoli::AccessManager::Admin::ProtObject") 
    or diag($resp->messages);

$resp = $pop->objects(attach => [$obj]);
is($resp->isok, 1, "Attached using an array of Tivoli::AccessManager::Admin::ProtObject")
    or diag($resp->messages);

$resp = $pop->objects;
is_deeply([$resp->value], [ '/test/monkey' ], "Got the list back")
    or diag($resp->messages);

$resp = $pop->objects(detach => [$obj]);
is($resp->isok, 1, "Detached POP using an array of Tivoli::AccessManager::Admin::ProtObject") 
    or diag($resp->messages);

$resp = $pop->objects(attach => '/test/monkey');
is($resp->isok, 1, "Attached using a name")
    or diag($resp->messages);
is_deeply([$resp->value], [ '/test/monkey' ], "Got the list back");

$resp = $pop->objects(detach => '/test/monkey');
is($resp->isok, 1, "Detached POP using a name") or diag($resp->messages);
is_deeply([$resp->value], [], "Got an empty list back");

$resp = $pop->objects(attach => ['/test/monkey']);
is($resp->isok, 1, "Attached using an array") or diag($resp->messages);
is_deeply([$resp->value], [ '/test/monkey' ], "Got the list back");

$resp = $pop->objects(detach => ['/test/monkey']);
is($resp->isok, 1, "Detached POP using an array") or diag($resp->messages);
is_deeply([$resp->value], [], "Got an empty list back");

my $newpop = Tivoli::AccessManager::Admin::POP->new($pd, name => '/test/monkey1');
$resp = $newpop->objects(attach => $obj);
is($resp->isok, 0, "Couldn't attach a non-existent POP") 
    or diag($resp->messages);

$resp = $pop->attach('/test/monkey');
is($resp->isok, 1, "Called attach()");
is_deeply([$resp->value], [ '/test/monkey' ], "Got the list back");

$resp = $pop->detach('/test/monkey');
is($resp->isok, 1, "Called detach()");
is_deeply([$resp->value], [], "Got an empty list back") or diag(Dumper($resp));

$resp = $pop->attach(['/test/monkey']);
is($resp->isok, 1, "Called attach() with an array");
is_deeply([$resp->value], [ '/test/monkey' ], "Got the list back");

$resp = $pop->detach(['/test/monkey']);
is($resp->isok, 1, "Called detach() with an array");
is_deeply([$resp->value], [], "Got an empty list back") or diag(Dumper($resp));

$resp = $pop->attach;
is($resp->isok, 0, "Could not call attach with an empty list");

$resp = $pop->attach('/test/monkey');
$resp = $pop->detach;
is($resp->isok, 1, "Detached them all");
is_deeply([$resp->value], [], "And they were all detached");

print "\nTESTING find\n";

$resp = $pop->attach('/test/monkey');

$resp = $pop->find;
is_deeply([$resp->value], ['/test/monkey'], "Found the monkey") or diag($resp->messages);

$resp = $pop->detach(['/test/monkey']);

print "\nTESTING list\n";
$resp = Tivoli::AccessManager::Admin::POP->list($pd);
is_deeply([$resp->value], [ qw/test/ ], "Class method list worked")
    or diag($resp->messages);

$resp = $pop->list;
is_deeply([$resp->value], [ qw/test/ ], "Instance method list worked")
    or diag($resp->messages);

print "\nTESTING anyothernw\n";
$resp = $pop->anyothernw;
is($resp->isok, 1, "Got the current anyothernw setting: " . $resp->value)
    or diag($resp->messages);
my $oldval = $resp->value;

$resp = $pop->anyothernw(level => 2);
is($resp->isok, 1, "Set the access level for anyothernw")
    or diag($resp->messages);
is(scalar($resp->value), 2, "And set it correctly") or diag(Dumper($resp));

$resp = $pop->anyothernw(level => 'forbidden');
is($resp->isok, 1, "Set anyothernw to forbidden")
    or diag($resp->messages);
is($resp->value, 'forbidden', "Set it correctly");

$resp = $pop->anyothernw(level => 'unset');
is($resp->isok, 1, "Set anyothernw to unset")
    or diag($resp->messages);
is($resp->value, 'unset', "Set it correctly");

$resp = $pop->anyothernw(silly => 'unset');
is($resp->value, 'unset', "Ignored a silly key");

$resp = $pop->anyothernw($oldval);
is($resp->isok, 1, "Put the original anyothernw back")
    or diag($resp->messages);
is($resp->value, $oldval, "And set it correctly");

print "\nTESTING audit levels\n";
$resp = $pop->audit;
is($resp->isok, 1, "Got the current audit level") or diag($resp->messages);

$resp = $pop->audit(level => [qw/all/]);
is($resp->isok, 1, "Set the audit level") or diag($resp->messages);

$resp = $pop->audit;
is_deeply([$resp->value], ['all'], "Got the right audit level") 
    or diag($resp->messages);
is(scalar($resp->value), 15, "Got the right bitmask");

$resp = $pop->audit(8);
is($resp->isok, 1, "Set the audit level") or diag($resp->messages);

$resp = $pop->audit;
is_deeply([$resp->value], ['admin'], "Got the right audit level") 
    or diag($resp->messages);
is(scalar($resp->value), 8, "Got the right bitmask");

$resp = $pop->audit(level => 'none');
is($resp->isok, 1, "Set the audit level to none") or diag($resp->messages);

$resp = $pop->audit(level => ['permit']);
is($resp->isok, 1, "Set the audit level to permit") or diag($resp->messages);

$resp = $pop->audit;
is_deeply([$resp->value], ['permit'], "Got the right audit level") or diag($resp->messages);
is(scalar($resp->value), 1, "Got the right bitmask");

$resp = $pop->audit(silly => 10);
is(scalar($resp->value), 1, "Ignored a silly hash key");

print "\nTESTING ipauth\n";

my $network = { '192.168.8.0' => { NETMASK   => '255.255.255.0',
				   AUTHLEVEL => 1
				 },
		'192.168.9.0' => { NETMASK   => '255.255.255.0',
				   AUTHLEVEL => 2
				 }
};

$resp = $pop->ipauth(add => $network);
is($resp->isok, 1, "ipauth add worked") or diag($resp->messages);

is_deeply(scalar($resp->value),$network,"Get ipauth says it worked too") or diag(Dumper($resp));

delete($network->{'192.168.9.0'});
$resp = $pop->ipauth(remove => { '192.168.9.0' => { NETMASK => '255.255.255.0' } });
is($resp->isok, 1, "ipauth delete thinks it worked");
is_deeply(scalar($resp->value), $network, "ipauth get seems to agree");

$network->{'192.168.9.0'} = { NETMASK => '255.255.255.0',
			      AUTHLEVEL => 'forbidden' };

$resp = $pop->ipauth(forbidden => {'192.168.9.0' => {NETMASK => '255.255.255.0'}});
is($resp->isok,1,"ipauth forbidden worked");
is_deeply(scalar($resp->value),$network,"ipauth get agrees");

print "\nTesting QOP\n";
$resp = $pop->qop('integrity');
is($resp->isok,1,"Set qop");
is($resp->value,'integrity', "qop agreed");

$resp = $pop->qop(qop => 'privacy');
is($resp->isok,1,"Set qop using a hash");
is($resp->value,'privacy', "qop agreed");

$resp = $pop->qop(silly => 'none');
is($resp->value,'privacy', "Ignored a silly key");

$resp = $pop->qop('none');
is($resp->value,'none', "Set qop to none");

$resp = $pop->qop();
is($resp->value,'none', "And got it back");


print "\nTESTING tod\n";

my $answer = { days => [qw/mon wed fri/], 
	      start => '0800', end => '1800',
              reference => 'local' };

$resp = $pop->tod;

$resp = $pop->tod(days => [ qw/mon wed fri/ ],
                    start => '0800',
		    end   => '1800',
		    reference => 'local'
		 );
is_deeply(scalar($resp->value), $answer, "Setting TOD access") or diag($resp->messages);

$resp = $pop->tod(days => [ qw/mon wed fri/ ],
                    start => '0800',
		    end   => '1800',
		 );
is_deeply(scalar($resp->value), $answer, "Setting TOD access with default reference") or diag($resp->messages);

$resp = $pop->tod(days => [ qw/mon wed fri/ ],
		    end   => '1800',
		 );
$answer->{start} = '0000';
is_deeply(scalar($resp->value), $answer, "Setting TOD access with default start") or diag($resp->messages);
$resp = $pop->tod(days => [ qw/mon wed fri/ ],
		   start   => '0800',
		 );
$answer->{start} = '0800';
$answer->{end} = '2359';
is_deeply(scalar($resp->value), $answer, "Setting TOD access with default end") or diag($resp->messages);


$answer->{reference} = 'UTC';
$resp = $pop->tod(%$answer);
is_deeply(scalar($resp->value), $answer, "Setting TOD access with UTC reference") or diag($resp->messages);

$resp = $pop->tod(days => 42,  # Thats funny!
		    start => '0800',
		    end   => '1800',
		    reference => 'UTC',
		 );
$answer->{end} = '1800';
is_deeply(scalar($resp->value), $answer, "Set days as a bitmask");

$answer->{days} = [qw/any/];
$resp = $pop->tod(days => [qw/any/],
		    start => '0800',
		    end   => '1800',
		    reference => 'UTC',
		 );
is_deeply(scalar($resp->value),$answer,"Set days to any");

print "\nTESTING warnmode\n";
$resp = $pop->warnmode;
is($resp->isok, 1, "Retrieved current warn mode");

$resp = $pop->warnmode(1);
is($resp->isok, 1, "Set current warn mode");
is($resp->value, 1, "Set current warn mode to 1");

$resp = $pop->warnmode(mode => 0);
is($resp->isok, 1, "Set current warn mode using a hash");
is($resp->value, 0, "Set current warn mode to 1");

$resp = $pop->warnmode(silly => 0);
is($resp->value, 0, "Ignored a silly key");

print "\nTESTING name\n";
$resp = $pop->name;
is($resp->isok,1,"Returned well from name");
is($resp->value,'test', "And got the expected name");

print "\nTESTING attributes\n";
my $attrs = { fooly => ['cooly'] };

$resp = $pop->attributes(add => { fooly => 'cooly' });
is($resp->isok, 1, "Called attribute add");
is_deeply(scalar($resp->value),$attrs, "Added one attribute") or diag(Dumper($resp));

$resp = $pop->attributes(remove => { fooly => 'cooly' });
is($resp->isok, 1, "Called attribute remove");
is_deeply(scalar($resp->value),{}, "Removed one attribute") or diag(Dumper($resp));

$attrs->{next} = [qw/one two three/];
$resp = $pop->attributes(add => $attrs);
is($resp->isok, 1, "Called attribute add");
is_deeply(scalar($resp->value),$attrs, "Added two attributes -- one as an array");

$resp = $pop->attributes(remove => { 'next' => [qw/one three/] });
is_deeply(scalar($resp->value), { fooly => ['cooly'],
				   'next' => ['two'] }, "Removed two attribute values") or diag(Dumper($resp));

$resp = $pop->attributes(removekey => 'fooly');
is($resp->isok, 1, "Called attribute remove key");
is_deeply(scalar($resp->value),{'next' => ['two']}, "Removed one attribute by key") or diag(Dumper($resp));

$resp = $pop->attributes(add => { fooly => 'cooly' });
$resp = $pop->attributes(removekey => [qw/fooly next/]);
is($resp->isok, 1, "Called attribute remove key with a list of attributes");
is_deeply(scalar($resp->value),{}, "Removed them all") or diag(Dumper($resp));

$pop->delete;

print "\nTESTING brokeness\n";

$pop = Tivoli::AccessManager::Admin::POP->new();
is($pop, undef, "Could not call new with an empty parameter list");

$pop = Tivoli::AccessManager::Admin::POP->new(qw/one two three/);
is($pop, undef, "Could not call new with something other than a context");

$pop = Tivoli::AccessManager::Admin::POP->new($pd, qw/one two three/);
is($pop, undef, "Could not call new with an odd number of parameters");

$resp = Tivoli::AccessManager::Admin::POP->create();
is($resp->isok, 0, "Could not call create with an empty parameter list");

$resp = Tivoli::AccessManager::Admin::POP->create(qw/one two three/);
is($resp->isok, 0, "Could not call create with something other than a context");

$resp = Tivoli::AccessManager::Admin::POP->create($pd, qw/one two three/);
is($resp->isok, 0, "Could not call create poorly");

$pop = Tivoli::AccessManager::Admin->new('pop', $pd, name => 'test');
$resp = $pop->create(qw/one two three/);
is($resp->isok, 0, "Could not call create with an odd number of parameters");

$resp = $pop->delete();
is($resp->isok,0,"Could not delete an non-existent POP");

$resp = $pop->anyothernw('forbidden');
is($resp->isok,0,"Could not set anyothernw on a non-existent POP");

$resp = $pop->description('forbidden');
is($resp->isok,0,"Could not set description on a non-existent POP");

$resp = $pop->audit('forbidden');
is($resp->isok,0,"Could not set audit on a non-existent POP");

$resp = $pop->ipauth('who cares');
is($resp->isok,0,"Could not set ipauth on a non-existent POP");

$resp = $pop->qop('who cares');
is($resp->isok,0,"Could not call qop on a non-existent POP");

$resp = $pop->tod(key => 'who cares');
is($resp->isok,0,"Could not call tod on a non-existent POP");

$resp = $pop->warnmode(key => 'who cares');
is($resp->isok,0,"Could not call warnmode on a non-existent POP");

$resp = $pop->name();
is($resp->isok,0,"Could not call name on a non-existent POP");

$resp = $pop->attributes();
is($resp->isok,0,"Could not call attributes on a non-existent POP");

# THIS IS GREAT EVIL.  NEVER, EVER DO THIS YOURSELF.  You have been warned.
$pop->{exist} = 1;
$resp = $pop->objects(attach => '/test/monkey');
is($resp->isok, 0, "Could not attach evil");

$resp = $pop->objects(attach => ['/test/monkey']);
is($resp->isok, 0, "Could not attach evil, redux");

$resp = $pop->objects(attach => ['/test/monkey']);
is($resp->isok, 0, "Could not detach evil");

$resp = $pop->objects();
is($resp->isok, 0, "Could not find attached evil");

$resp = $pop->anyothernw;
is($resp->isok,0, "Could not get the anyothernw policy for evil");

$resp = $pop->anyothernw('forbidden');
is($resp->isok,0, "Could not set the anyothernw policy for evil");

$resp = $pop->description;
is($resp->value,undef,"Proper return from description for evil");

$resp = $pop->description('forbidden');
is($resp->isok,0, "Could not set the description for evil") or diag(Dumper($resp));

$resp = $pop->audit;
is($resp->value,0,"Proper return from audit for evil");

$resp = $pop->audit('admin');
is($resp->isok,0, "Could not set the audit level for evil");

$resp = $pop->ipauth;
is($resp->isok,0, "Could not get an ipauth level for evil");

$resp = $pop->ipauth(add => { '192.168.11.0' => { NETMASK => '255.255.255.0',
						   AUTHLEVEL => 2 }});
is($resp->isok,0, "Could not set the ipauth level for evil");

$resp = $pop->qop('none');
is($resp->isok,0, "Could not set the qop level for evil");

$resp = $pop->qop();
is($resp->value,undef, "Could not get a qop level for evil");

$resp = $pop->tod(days => [qw/any/],
		    start => '0800',
		    end   => '1800',
		    reference => 'UTC',
		 );
is($resp->isok,0, "Could not set the tod for evil");
$resp = $pop->tod;
is_deeply(scalar($resp->value), {days => [qw/any/], start => '0000', end => '0000', reference => 'local'},
	 "Could not get a TOD for evil") or diag(Dumper($resp));

$resp = $pop->warnmode(1);
is($resp->isok,0, "Could not set the warnmode level for evil");

$resp = $pop->warnmode;
is($resp->value,0, "Could not get a warnmode for evil");

$resp = $pop->warnmode;
is($resp->value,0, "Could not get a name for evil");

$resp = $pop->attributes(add => { fooly => 'cooly' });
is($resp->isok, 0, "Could not add attribute values for evil");

$resp = $pop->attributes(remove => { fooly => 'cooly' });
is($resp->isok, 0, "Could not remove attribute values for evil");

$resp = $pop->attributes(add => { fooly => ['cooly'] });
is($resp->isok, 0, "Could not add an array of attribute values for evil");

$resp = $pop->attributes(remove => { fooly => ['cooly'] });
is($resp->isok, 0, "Could not remove an array of attribute values for evil");

$resp = $pop->attributes(removekey => [qw/fooly next/]);
is($resp->isok, 0, "Could not remove an array of attribute keys for evil");

$resp = $pop->attributes;
is($resp->isok, 0, "Could not get any attributes for evil");

$resp = $pop->find;
is($resp->isok, 0, "Could not find the evil");

$resp = $pop->create(silly => 'bjork');
$resp = $pop->create();
is($resp->isok,0, "Could not create twice");

$resp = $pop->objects(qw/one two three/);
is($resp->isok, 0, "Could not call objects with an odd number of parameters");

$resp = $pop->anyothernw(qw/one two three/);
is($resp->isok, 0, "Could not call anyothernw with an odd number of parameters");

$resp = $pop->description(qw/one two three/);
is($resp->isok, 0, "Could not call description with an odd number of parameters");

$resp = $pop->audit(qw/one two three/);
is($resp->isok, 0, "Could not call audit with an odd number of parameters");

$resp = $pop->ipauth(qw/one two three/);
is($resp->isok, 0, "Could not call ipauth with an odd number of parameters");

$resp = $pop->qop(qw/one two three/);
is($resp->isok, 0, "Could not call qop with an odd number of parameters");

$resp = $pop->tod(qw/one two three/);
is($resp->isok, 0, "Could not call tod with an odd number of parameters");

$resp = $pop->warnmode(qw/one two three/);
is($resp->isok, 0, "Could not call warnmode with an odd number of parameters");

$resp = $pop->attributes(qw/one two three/);
is($resp->isok, 0, "Could not call attributes with an odd number of parameters");

$resp = $pop->audit('foobared');
is($resp->isok, 0, "Could not use an invalid audit level");

$resp = $pop->audit([qw/foo bar blah/]);
is($resp->isok, 0, "Could not use an invalid array of levels");

$resp = $pop->audit(-100);
is($resp->isok, 0, "Could not use a negative audit level");

$resp = $pop->audit(100);
is($resp->isok, 0, "Could not use an audit level > 15");

$resp = $pop->qop('silly');
is($resp->isok, 0, "Could not use an invalid QoP");

$resp = $pop->tod(days => 256,  # Thats funny!
		    start => '0800',
		    end   => '1800',
		    reference => 'UTC',
		 );
is($resp->isok,0, "Could not call tod with an invalid bitmask");

$resp = $pop->tod(days => [qw/fred/],
		    start => '0800',
		    end   => '1800',
		    reference => 'UTC',
		 );
is($resp->isok,0, "Could not call tod with an invalid dayname");

$resp = $pop->ipauth(add => { '192.168.10.0' => { foobar => 'baz'} });
is($resp->iswarning, 1, "Could not call ipauth without providing a netmask");

$resp = $pop->ipauth(add => {'192.168.10.0' => {NETMASK => '255.255.255.0'}});
is($resp->iswarning, 1, "Could not call ipauth add without providing an authlevel");

$resp = $pop->attributes(removekey => { two => 'three'});
is($resp->isok,0, "Could not call attributes removekey with a non-array ref");

print "\nCLEANING UP\n";
$pop->delete;


END {
    ReadMode 0;
}
