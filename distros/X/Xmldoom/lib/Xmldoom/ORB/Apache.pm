
package Xmldoom::ORB::Apache;

use Xmldoom::ORB::Transport;
use Xmldoom::Definition;
use Apache;
use CGI;
use strict;

use Data::Dumper;

my $DATABASE  = undef;
my $TRANSPORT = undef;

sub handler {
	my $r = shift;

	# setup our database definitions if they haven't been already
	if ( not defined $DATABASE )
	{
		# load the database/object XML files.
		$DATABASE = Xmldoom::Definition::parse_database_uri( $r->dir_config( 'XmldoomDatabaseXML' ) );
		Xmldoom::Definition::parse_object_uri( $DATABASE, $r->dir_config( 'XmldoomObjectsXML' ) );
		
		# load the connection factory
		my $conn_factory_class = $r->dir_config( 'XmldoomConnFactory' );
		$DATABASE->set_connection_factory( $conn_factory_class->new() );

		# load the transport
		my $format = $r->dir_config( 'XmldoomFormat' ) || "xml";
		$TRANSPORT = Xmldoom::ORB::Transport::get_transport($format);
		if ( not defined $TRANSPORT )
		{
			die "Unknown transport format passed to Xmldoom::ORB::Apache: ".$format;
		}
	}

	my $req_location = $r->location;
	my $req_uri      = $r->uri;
	my $req_query    = $r->args;

	my $obj_and_op;

	# attampt to determine the object type requested.
	if ( $req_uri =~ /^$req_location/ )
	{
		$obj_and_op = $req_uri;

		# remove the script name
		$obj_and_op =~ s/^$req_location//;

		# remove everything that comes after a '?' mark
		$obj_and_op =~ s/\?.*//;

		# remove beginning and trailing slashes
		$obj_and_op =~ s/^\///;
		$obj_and_op =~ s/\/$//;
	}

	my $object_name;
	my $operation;

	if ( $obj_and_op =~ /(.*)\/(.*)/ )
	{
		$object_name = $1;
		$operation   = $2;
	}

	my $definition = $DATABASE->get_object( $object_name );

	#print "uri: " . $r->uri . "\n";
	#print "location: " . $r->location . "\n";
	#print "path_info: " . $r->path_info . "\n";
	#print "object_name: " . $object_name . "\n";
	#print "operation: $operation\n";

	# read POST data from the client
	my $buffer = undef;
	if ( $r->method() eq 'POST' )
	{
		# Will this work without 'Content-Length' ?
		$r->read($buffer, $r->header_in('Content-Length'));
	}
	#print STDERR "POST: $buffer\n";

	my $cgi = CGI->new( $req_query );

	# send the format header
	$r->send_http_header( $TRANSPORT->get_mime_type() );

	if ( $operation eq 'load' )
	{
		# load the object
		my $key = { };
		foreach my $pname ( $cgi->param )
		{
			$key->{$pname} = $cgi->param( $pname );
		}
		my $data = $definition->load( $key );

		# write it!
		$TRANSPORT->write_object($data);
	}
	elsif ( $operation eq 'search' )
	{
		my $criteria = Xmldoom::Criteria::XML::parse_string($buffer, $DATABASE);
		my $rs = $definition->search_rs( $criteria );

		my $count;
		if ( $cgi->param( 'includeCount' ) )
		{
			$count = $definition->count( $criteria );
		}

		# write it!
		$TRANSPORT->write_object_list($rs, $count);
	}
	elsif ( $operation eq 'count' )
	{
		my $criteria = Xmldoom::Criteria::XML::parse_string($buffer, $DATABASE);
		my $count    = $definition->count( $criteria );

		# write it!
		$TRANSPORT->write_count($count);
	}
};

1;

