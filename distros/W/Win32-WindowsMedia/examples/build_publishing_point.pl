#!/usr/bin/perl

use strict;
use Win32::WindowsMedia;

my $main =new Win32::WindowsMedia;

# Build a Server Object Instance
my $server_object = $main->Server_Create("127.0.0.1");

# Build a new publishing point , push, called 'andrew'
my $publishing_point = $main->
		Publishing_Point_Create( 
			$server_object, 
			"andrew",
			"push:*",
			"broadcast"
			);

