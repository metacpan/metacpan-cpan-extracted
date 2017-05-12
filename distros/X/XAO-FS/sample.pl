#!/usr/bin/perl -w
use strict;
use blib;
use XAO::Utils;
use XAO::Objects;

##
# This is not something you would normally do in your application - this
# is here purely to safely get configuration values to connect to the
# test database.
#
my %d;
if(open(F,'.config')) {
    local($/);
    my $t=<F>;
    close(F);
    eval $t;
}
die "No test configuration available (no .config)!\n" unless $d{test_dsn};

##
# Connecting to the database and completely erasing all the data in
# it.
#
my $odb=XAO::Objects->new(objname => 'FS::Glue',
                          dsn => $d{test_dsn},
                          user => $d{test_user},
                          password => $d{test_password},
                          empty_database => 'confirm');

$odb || die "Can't connect to the database";

my $global=$odb->fetch('/');

$global || die "Can't fetch Global from OS database";

$global->add_placeholder(name => 'Customers',
                         type => 'list',
                         class => 'Data::Customer',
                         key => 'customer_id');

##
# These two lines are equal:
#
my $clist=$global->get('Customers');
## my $clist=$odb->fetch('/Customers');

$clist || die "Can't get Customers from OS Global";

my $customer=$clist->get_new();
$customer || die "Can't create new customer";

$customer->add_placeholder(name => 'name',
                           type => 'text',
                           maxlength=> 100);

$customer->put('name' => 'test');

$clist->put(c1 => $customer);
$clist->put(c2 => $customer);

print "Name1: ", $customer->get('name'), "\n";
print "Name2: ", $odb->fetch('/Customers/c1/name'), "\n";
print "Name3: ", $global->get('Customers')->get('c2')->get('name'), "\n";

exit(0);
