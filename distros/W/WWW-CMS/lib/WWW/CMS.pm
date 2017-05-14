# ShellShark's CMS
#	Content Management System engine for ShellShark Networks, Inc.
#	Copyright (c)2005 ShellShark Networks, Inc. All rights reserved.

package WWW::CMS;

use warnings;
use strict;
use POSIX	qw(	strftime	);

sub new {
	# Create a new WWW::CMS instance
	# Takes a hash of arguments containing Base and Module
	# Returns an object reference on success, nothing on failure

	my $self = { };
	my ( $class, $args ) = @_;

	# Bless me father, for I have OOP'ed
	bless $self, $class;

	# Is our template basedir defined, and does it exist?
	if ( !$args->{ TemplateBase } || !-d $args->{ TemplateBase } ) {
		print STDERR "WWW::CMS: Fatal error: Template base directory not defined or does not exist!\n";
		return;
	}

	# Strip trailing slash from template basedir
	$args->{ TemplateBase } =~ s/\/$//;

	# Is our template module defined, and does it exist?
	if ( !$args->{ Module } || !-f "$args->{ TemplateBase }/$args->{ Module }" ) {
		print STDERR "WWW::CMS: Fatal error: Template module not defined or not found\n";
		return;
	}

	# Open the template and shove it in memory
	open my $fh, "<", "$args->{ TemplateBase }/$args->{ Module }" || sub {
		$self->{ ERRMSG } = "Failed to open template module '$args->{ TemplateBase }/$args->{ Module }': $!";
		return;
	};

	# Slurpy, slurpy....
	$self->{ template } = do { local $/; <$fh> };

	close $fh;

	# Stuff our arguments into our namespace
	$self->{ TemplateBase } = $args->{ TemplateBase };

	# Give this instance the template module's name for later identification, if needed
	$self->{ instance } = $args->{ Module };
	
	# Setup a heap for arbitrary variable storage for IF/ELSE operators in templates
	$self->{ heap } = { };

	return $self;
}

sub publicize {
	# Find / replace all instances of built-in tags with output of respective code
	my $self = shift;
	
	# Pass in an existing CGI object
	my $query = shift || sub {
		$self->{ ERRSTR } = 'CGI object not passed into publicize()';
		return;
	};

	# Many thanks to revdiablo for making this uberleet regex
	$self->{ template } =~ s{
		\Q^^[\E					# start operator block
			(IF|WHILE)			#   operator name
		\Q]=\E					# start condition
			([^\n]*)			#   condition expression
		\Q^^\E					# end condition
			((?:.(?!\^\^))*.)		#   contents
			(?: \Q^^[ELSE]^^\E		# start optional else block
				((?:.(?!\^\^))*.)	#   contents
			)?				# ensure it is optional
		\Q^^[END]^^\E				# end operator block
	}
	{
		$self->tempeval($1, $2, $3, $4)
	}gisex;


	$self->{ PageName } = '' unless $self->{ PageName };
	$self->{ template } =~ s/%%PAGE%%/$self->{ PageName }/gi;

	my $ts = strftime ( "%A, %B %e, %G - %I:%M%p", localtime );
	$self->{ template } =~ s/%%DATETIME%%/$ts/gi;

	if ( $self->{ content } ) {
		my $tmpcont = join ( "\n", @{ $self->{ content } } );
		$self->{ template } =~ s/%%CONTENT%%/$tmpcont/gi;
	}

	my $url = $query->url();
	$self->{ template } =~ s/%%MYURL%%/$url/gi;

	return $self->{ template };
}

sub repl_tag {
	# Find / replace all instances of a given tag with the output of a given coderef
	my ( $self, $var, $coderef ) = @_;

	# See how many find/replace operations will have to take place

	# Evaluate the code once, and cache the output to save overhead
	my $output = $coderef->();

	# In the template, find $var (CaSE sEnsiTiVE!) and replace it with $output
	$self->{ template } =~ s/$var/$output/g;

	return 1;
}

sub tempeval {
	# Many thanks again to revdiablo for creating this initially as a stub
	# to show me how the hell his funky regex works ;-)
	my ( $self, $op, $exp, $true, $false ) = @_;

	if ( $op =~ /^IF$/i ) {
		if ( $self->{heap}->{$exp} ) {
			return "<!-- $op ($exp => $self->{heap}->{$exp}) succeeded -->\n$true";
		}
		else {
			return "<!-- $op ($exp => $self->{heap}->{$exp}) failed -->\n$false";
		}
	}
}

1;
