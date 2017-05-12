#!/usr/bin/perl

use lib qw(..);

use Visio;
use Data::Dumper;

# create new visio
my $v = new Visio();

#load stencil file
#  a regular vdx file has a stencil section
#  a stencil file (.vsx) only has a stencil section
#  stencils can be found at /VisioDocument/Masters/

my $stencilFile = new Visio({fromFile=>'./golden.vsx'});

# save the router stencil in $nrRectMaster
my ($nrRectMaster,my @dummy )= 
    $stencilFile->find_master_dom({name=>'Router'});

# save connector stencil in $connectorStencil
my ($connectorStencil,my @dummy )= 
    $stencilFile->find_master_dom({name=>'Dynamic connector'});

# copy the stencils into our new vdx file 

my $master = $v->create_master({fromDom=>$nrRectMaster}); 
my $connectorMaster = $v->create_master({fromDom=>$connectorStencil}); 

# set some document properties
$v->set_title('shiert wabla wabla');
$v->set_timeCreated();
$v->set_timeSaved();

# add a new page (aka worksheet)
my $page = $v->addpage();
$page->set_name('my page');
$page->set_heightWidth(8,11);

# put a shape (from a page stencil), and assign it some text
my $shape1 = $page->create_shape({fromMaster=>$master});
$shape1->set_text('hello!!');

# add a hyperlink to the shape
$shape1->get_hyperlink({
    -Description=>'console',
    -Address=>'telnet://1.1.1.1:2014'
});

# create another router shape, and assign it some text
my $shape2 = $page->create_shape({fromMaster=>$master});
$shape2->set_text('wabala wabla');

# create a connector and set some properties
my $connector = $page->create_shape({fromMaster=>$connectorMaster});
$connector->set_text('my line');
$connector->set_LineProperty('EndArrow',2);
$connector->set_LayoutProperty('ShapeRouteStyle',16);
$connector->set_LayoutProperty('ConLineRouteExt',2);

# tell the connector to connect the two routers

$connector->connect($shape1,$shape2);

# add a second page 
my $page2 = $v->addpage();
$page2->set_name('my page2');


print $shape1->isa('Visio::Shape');;

#print $v->toString;

# save the visio file to 

$v->toFile('demo.vdx');

exit;
