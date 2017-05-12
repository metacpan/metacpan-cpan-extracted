#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Data::Dumper qw/Dumper/;
use File::ShareDir qw/dist_dir/;
use Template;
use W3C::SOAP::WSDL::Parser;
use lib path($0)->parent->child('lib').'';
use MechMock;

my $dir = path($0)->parent;

plan( skip_all => 'Test can only be run if test directory is writable' ) if !-w $dir;

# set up templates
my $template = Template->new(
    INCLUDE_PATH => dist_dir('W3C-SOAP').':'.$dir->child('../templates'),
    INTERPOLATE  => 0,
    EVAL_PERL    => 1,
);
my $ua = MechMock->new;
# create the parser object
my $parser = W3C::SOAP::WSDL::Parser->new(
    location      => $dir->child('eg.wsdl').'',
    module        => 'MyApp::WsdlEg',
    template      => $template,
    lib           => $dir->child('lib').'',
    ns_module_map => {
        'http://eg.schema.org/v1'     => 'MyApp::Eg',
        'http://parent.schema.org/v1' => 'MyApp::Parent',
        'http://other.schema.org/v1/'  => 'MyApp::Other',
    },
);

parser();
$parser->write_modules;
written_modules();
cleanup();
done_testing();
exit;

sub parser {
    ok $parser, "Got a parser object";
    is $parser->document->target_namespace, 'http://eg.schema.org/v1', "Get target namespace";
    ok scalar( @{ $parser->document->messages }      ), "Got some messages";
    ok scalar( @{ $parser->document->schemas }  ), "Got some schemas";
    ok scalar( @{ $parser->document->port_types } ), "Got some port types";
}

sub written_modules {
    push @INC, $dir->child('lib').'';
    require_ok('MyApp::WsdlEg');
    my $eg = MyApp::WsdlEg->new;
    $eg->ua($ua);

    isa_ok $eg, 'MyApp::WsdlEg', 'Create the object correctly';

    $ua->content(<<"XML");
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Body xmlns:eg="http://eg.schema.org/v1">
        <eg:el2>2</eg:el2>
    </soapenv:Body>
</soapenv:Envelope>
XML
    my $resp = $eg->first_action(first_thing => 'test');
    is $resp, 2, "get result back";
}

sub cleanup {
    unlink $dir->child('lib/MyApp/Eg/Base.pm')                 or note 'Could not remove lib/MyApp/Eg/Base.pm';
    unlink $dir->child('lib/MyApp/Eg/el5Type.pm')              or note 'Could not remove lib/MyApp/Eg/el5Type.pm';
    unlink $dir->child('lib/MyApp/Eg/el6Type.pm')              or note 'Could not remove lib/MyApp/Eg/el6Type.pm';
    unlink $dir->child('lib/MyApp/Eg/localComplexThing.pm')    or note 'Could not remove lib/MyApp/Eg/localComplexThing.pm';
    unlink $dir->child('lib/MyApp/Eg/localOther.pm')           or note 'Could not remove lib/MyApp/Eg/localOther.pm';
    unlink $dir->child('lib/MyApp/Eg.pm')                      or note 'Could not remove lib/MyApp/Eg.pm';
    unlink $dir->child('lib/MyApp/Eg/subThingType.pm')         or note 'Could not remove lib/MyApp/Eg/subThingType.pm';
    unlink $dir->child('lib/MyApp/Other/Base.pm')              or note 'Could not remove lib/MyApp/Other/Base.pm';
    unlink $dir->child('lib/MyApp/Other/el13_4Type.pm')        or note 'Could not remove lib/MyApp/Other/el13_4Type.pm';
    unlink $dir->child('lib/MyApp/Other/el13Type.pm')          or note 'Could not remove lib/MyApp/Other/el13Type.pm';
    unlink $dir->child('lib/MyApp/Other/otherComplexThing.pm') or note 'Could not remove lib/MyApp/Other/otherComplexThing.pm';
    unlink $dir->child('lib/MyApp/Other.pm')                   or note 'Could not remove lib/MyApp/Other.pm';
    unlink $dir->child('lib/MyApp/Parent/Base.pm')             or note 'Could not remove lib/MyApp/Parent/Base.pm';
    unlink $dir->child('lib/MyApp/Parent/complexThing.pm')     or note 'Could not remove lib/MyApp/Parent/complexThing.pm';
    unlink $dir->child('lib/MyApp/Parent/moreComplexThing.pm') or note 'Could not remove lib/MyApp/Parent/moreComplexThing.pm';
    unlink $dir->child('lib/MyApp/Parent.pm')                  or note 'Could not remove lib/MyApp/Parent.pm';
    unlink $dir->child('lib/MyApp/WsdlEg.pm')                  or note 'Could not remove lib/MyApp/WsdlEg.pm';

    rmdir  $dir->child('lib/MyApp/Parent') or note 'Could not remove lib/MyApp/Parent';;
    rmdir  $dir->child('lib/MyApp/Other')  or note 'Could not remove lib/MyApp/Other';
    rmdir  $dir->child('lib/MyApp/Eg')     or note 'Could not remove lib/MyApp/Eg';
    rmdir  $dir->child('lib/MyApp')        or note 'Could not remove lib/MyApp';
}
