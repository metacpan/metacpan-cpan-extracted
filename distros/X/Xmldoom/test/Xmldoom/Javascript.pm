#!/usr/bin/perl -w

package Local::Xmldoom::Javascript;
use base qw(Test::Class);

use File::Temp qw/ tempfile /;
use Test::More;
use Xmldoom::ORB::Definition;
use strict;

use test::BookStore::Object;

use Data::Dumper;

sub new
{
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# TODO: attampt to detect these things, or get them from some kind of
	# config file or environment variables.
	$self->{rhino}          = 'jsscript-1.6';
	$self->{dojo_path}      = 'share/javascript/dojo/';
	$self->{xmlsax_path}    = 'share/javascript/xmlsax.js';
	$self->{xmlw3cdom_path} = 'share/javascript/xmlw3cdom.js';

	bless  $self, $class;
	return $self;
}

sub startup : Test(startup)
{
	my $self = shift;

	if ( not -e $self->{dojo_path} )
	{
		die "You need to download the dojo *source* (http://dojotoolkit.org) and put it at $self->{dojo_path}";
	}
	if ( not -e $self->{xmlsax_path} or not -e $self->{xmlw3cdom_path} )
	{
		die "You need to download 'XML for <SCRIPT>' (http://xmljs.sf.net) and copy xmlsax.js and xmlw3cdom.js into share/javascript";
	}

	my $definition_json = Xmldoom::ORB::Definition::generate($test::BookStore::Object::DATABASE, 'json');

	# setup our dojo bootstrap
	$self->{bootstrap_xmldoom} = << "EOF";
//
// Bootstrap dojo to run in our enviroment.
//

djConfig = {
	baseRelativePath: '$self->{dojo_path}',
	libraryScriptUri: './',
	//isDebug: true
};

load('$self->{dojo_path}/dojo.js');
load('share/javascript/xmldoom.js');

dojo.require('dojo.debug');
dojo.require('dojo.dom');
dojo.require('dojo.lang.declare');

load('$self->{xmlsax_path}');
load('$self->{xmlw3cdom_path}');

// Copied from Lingwo!
function DOMParser()
{
	this.parserFromString = function(str,mimetype)
	{
		var domimpl = new DOMImplementation();
		domimpl.namespaceAware = false;
		return domimpl.loadXML(str);
	}
}
dojo.dom.innerXML = function (node)
{
	return node.toString();
}

//
// Initialize our actual Xmldoom database
//

dojo.require('Xmldoom.Connection');
dojo.require('Xmldoom.RuntimeEngine');
dojo.require('Xmldoom.Definition.JSONParser');

// Init namespace with our definition data
BookStore = {
	'DEFINITION': $definition_json
};

// setup connection to ORB
BookStore.connection = new Xmldoom.Connection('http://localhost:8888/xmldoom/', 'json');

// parse and init the database definition
BookStore.database = Xmldoom.Definition.JSONParser.parse( BookStore.DEFINITION );
BookStore.database.set_connection( BookStore.connection );

// initialize the runtime engine
Xmldoom.RuntimeEngine.init( BookStore, BookStore.database, BookStore.connection );

//
// Our testing boilerplate ...
//

var test_counter = 0;

function ok (value, name)
{
	test_counter ++;

	if ( value )
	{
		print ("ok "+test_counter);
		//print ( "ok - #"+name );
	}
	else
	{
		print ("not ok "+test_counter);
		//print ( "not ok - #"+name );
	}
}

function is (value1, value2)
{
	var v = (value1 == value2);

	//ok(v, ""+value1+" == "+value2);
	ok(v);
	print ("got: "+value1);
	print ("expected: "+value2);
}

//
// And, finally, the actual test code:
//
EOF
}

sub run_js
{
	my $self = shift;
	my $js   = shift;

	# put the javascript in a temp file
	my ($fh, $fn) = tempfile();
	$fh->write($self->{bootstrap_xmldoom});
	$fh->write($js);
	$fh->close();

	# run it through rhino
	my $cmd = $self->{rhino} . " -f $fn";
	my $ph = IO::File->new( "$cmd|" );
	while ( my $line = <$ph> )
	{
		if ( $line =~ /^ok/ )
		{
			ok( 1 );
		}
		elsif ( $line =~ /^not ok/ )
		{
			ok( 0 );
		}
		else
		{
			print $line;
		}
	}

	# TEST:
	#system ("cat $fn");

	# remove the tempfile
	unlink $fn || die "Canot remove tempfile: $!";
}

sub setup : Test(setup)
{
	my $self = shift;
}

sub jsTest : Test(1)
{
	my $self = shift;

	my $js = << "EOF";

ok( 1 );
EOF
	
	$self->run_js ($js);
}

1;

