package XDI;

our $VERSION = '0.05';

use strict;
use warnings;

use Carp;
use Log::Log4perl qw(get_logger :levels);
use JSON::XS;
use Data::Dumper;
use Data::UUID;
use Storable qw(dclone);
use Clone qw(clone);

use XDI::Connection;

require Exporter;
use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);


@ISA         = qw(Exporter);
@EXPORT      = qw(
	pick_xdi_tuple
	tuples
	get_literal
	get_equivalent
	get_property
	get_context
);
%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

# your exported package globals go here,
# as well as any optionally exported functions
#@EXPORT_OK   = qw($Var1 %Hashit &func3);
#use vars qw($Var1 %Hashit);

@EXPORT_OK   = qw(&s_debug);
use vars qw();

# non-exported package globals go here
#use vars      qw(@more $stuff);
use vars      qw();

# file-private lexicals go here
my %fields = (
	from_graph => undef,
	from => undef,
);

our $AUTOLOAD;
our $USE_LOCAL_MESSAGE = 1;


sub new {
	my $class  = shift;
	my $self = {%fields,};
	bless($self,$class);
	my ($var_hash) = @_;
	if (defined $var_hash  ) {
		if (ref $var_hash eq "HASH"){
			foreach my $varkey (keys %{$var_hash}) {
				if (exists $self->{$varkey}) {
					$self->{$varkey} = $var_hash->{$varkey};
				}
			}
		} elsif (ref $var_hash eq "") {
			#TODO: resolve iname into iname/inumber
			$self->{'from'} = $var_hash;
			$self->{'from_graph'} = $var_hash;
		} else {
		croak "Initialization failed: parameters not passed as hash reference or iname string";
		}
	} 
	return $self;
}


sub AUTOLOAD {
	my $self   = shift;
	my $type   = ref($self)
	  or croak "($AUTOLOAD): $self is not an object";
	my $name = $AUTOLOAD;
	$name =~ s/.*://;
	unless ( exists $self->{$name} ) {
		carp "$name not permitted in class $type";
		return;
	}

	if (@_) {
		my $obj = shift;
		if ( ref $obj ne "" ) {
			return $self->{$name} = dclone $obj;
		}
		else {
			return $self->{$name} = $obj;
		}

	}
	else {
		return $self->{$name};
	}
}

sub connect {
	my $self = shift;
	my $connector = XDI::Connection->new($self,@_);
	return $connector;
}


sub tuples {
	my ($graph,$match) = @_;
	my @matches = ();
	foreach my $key (sort keys %{$graph}) {
		my ($subject,$predicate,$value);
		if ($key =~ m/^(.+)\/(.+)$/) {
			$subject = $1;
			$predicate = $2;			
			if (scalar(@{$graph->{$key}}) == 1) {

				$value = $graph->{$key}->[0];
			} else {
				$value = $graph->{$key};
			}

			if (defined $match->[0]) {
				if (ref $match->[0] eq "Regexp") {
					next unless ($subject =~ m/$match->[0]/);
				} elsif ($subject ne $match->[0]) {
					next;
				} 
			}
			

			if (defined $match->[1]) {
				if (ref $match->[1] eq "Regexp") {
					next unless ($predicate =~ m/$match->[1]/);
				} elsif ($predicate ne $match->[1]) {
					next;
				} 
			}

			if (defined $match->[2]) {
				if (ref $match->[2] eq "Regexp") {
					next unless ($value =~ m/$match->[2]/);
				} elsif ($value ne $match->[2]) {
					next;
				} 
			}
			push(@matches, [$subject,$predicate,$value]);
		}
	}
	return \@matches;	
}

sub pick_xdi_tuple {
	my ($graph,$match) = @_;
	my $logger = get_logger();#	$logger->debug("Match: ", sub {Dumper($match)});
	foreach my $key (keys %{$graph}) {
		my ($subject,$predicate,$value);
		if ($key =~ m/^(.+)\/(.+)$/) {
			$subject = $1;
			$predicate = $2;			
			if (scalar(@{$graph->{$key}}) == 1) {

				$value = $graph->{$key}->[0];
			} else {
				$value = $graph->{$key};
			}
			
			my $ret = 1;
			if (defined $match->[0] && $match->[0] ne $subject) {
				$ret = 0;
			}
			if ($ret && defined $match->[1] && $match->[1] ne $predicate) {
				$ret = 0
			}
			if ($ret && defined $match->[2] && $match->[2] ne $value) {
				$ret = 0;
			}
			if ($ret) {
				return [$subject,$predicate,$value];
			}
		}
	}
	return undef;
	
}

sub get_literal {
	my ($graph,$keys) = @_;
	my $logger= get_logger();
	my @results = ();
	if (ref $keys eq "ARRAY") {
		foreach	my $key (@$keys) {
			my $values = tuples($graph,[$key,'!',undef]);
			if (defined $values) {
				foreach my $element (@{$values}) {
					push(@results,$element->[2]);
				}
			}
			
		}	
	} elsif (ref $keys eq '') {
		my $values = tuples($graph,[$keys,'!',undef]);
		if (defined $values) {
			foreach my $element (@{$values}) {
				push(@results,$element->[2]);
			}
		}
	}
	if (scalar(@results) == 1) {
		return $results[0];
	} elsif (scalar(@results) > 1) {
		return \@results;
	} 		
	return undef;
}

sub get_equivalent {
	my ($graph,$key) = @_;
	my @results = ();
	my $values = tuples($graph,[$key,'$is',undef]);
	if (defined $values) {
		foreach my $element (@{$values}) {
			push(@results,$element->[2]);
		}
		return \@results;
	}
	return undef;
}

sub get_property {
	my ($graph,$key) = @_;
	my @results = ();
	my $values = tuples($graph,[$key,'()',undef]);
	if (defined $values) {
		foreach my $element (@{$values}) {
			foreach my $m (@{$element->[2]}){
				push(@results,$m);
			}			
		}
		return \@results;
	}
	return undef;	
}

sub get_context {
	my ($graph,$key) = @_;
	my @results = ();
	my $values = tuples($graph,[$key,'$is()',undef]);
	if (defined $values) {
		foreach my $element (@{$values}) {
			foreach my $cl (@{$element->[2]}) {
				push(@results,$cl);
			}
		}
		return \@results;
	}
	return undef;	
}


# Hopefully this will get more sophisticated
sub is_inumber {
	my ($xdi) = @_;
	return $xdi =~ m/!/;
}



sub s_debug {
	my $parent = (caller(0))[0];
	my $sub = (caller(1))[3];
	return ($parent,$sub);
}

sub _decode {
	my ($string) = @_;
	my $logger = get_logger();
	my $struct;
	eval {
		$struct = JSON::XS::->new->pretty(1)->decode($string);
	};
	if ($@ && not defined $struct) {
		carp("Not a valid JSON string");
		carp($@);
		return undef;
	} else {
		return $struct;
	}
}


sub DESTROY { }

END { }       # module clean-up code here (global destructor)



1; # End of XDI

=head1 NAME

XDI - Messaging client for XDI servers

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS
	
	use XDI;
	
	my $xdi = new XDI;
	
	..
	
	my $iname = '=tester';
	my $xdi = XDI->new($iname);
	
	..
	
	my $hash = {
		'from' => '=tester',
		'from_graph' => '@xdiserver'
	};
	
	my $xdi = XDI->new($hash);
	
=head1 EXPORTS

	pick_xdi_tuple

=head1 XDI

XDI is an open standard semantic graph model, data sharing format, and protocol.

Details on XDI can be found at L<https://wiki.oasis-open.org/xdi/FrontPage>

XDI graphs are addressed via inames/inumbers which conform to the generic URI syntax 
as defined in IETF RFC 3986.  inames resolve to inumbers.  inames can be re-assigned
while inumbers are permanent identifiers

=head2 inames/inumbers

	=markus 			# individual context
	=!91F2.8153.F600.AE24
	
	@xdi				# institutional context
	@!3D12.8C35.6FB3.E89C

An experimental service to provide XDI iname/inumber resolution is L<http://xri2xdi.net/index.html>

CRUD permissions to an XDI database are defined by link contracts.  Link contracts define a
permission ($get,$add,$mod,$del) for a graph node and who has that permission

=head1 DESCRIPTION

The XDI perl module provides a client for communicating with XDI servers.

=head2 Notation and Conventions

	$xdi	Root object defining identity of querier
	$c	Connection object defining graph target and permissions
	$msg	Message object for XDI messages
	$hash	Reference to a hash of key/attribute values
	
=head2 Usage Outline

All XDI communications are between two graph entities, these are defined by inames/inumbers
Identity verification and authority are still being developed under the XDI specification
so this module allows the user to self-assert

	use XDI;
	
	$xdi = XDI->new('=tester');
	
This constructor assumes that the user making the query I<from> is the same as the graph 
from which the query is being made I<from_graph>.  If you were implementing an XDI service
that mediated queries on behalf of a user, it would be appropriate to set the I<from_graph> 
to the identity of the service

	$xdi = XDI->new({from => '=tester', from_graph => '@kynetx' });
	
To specify the graph to which you would like to query, you create a L<XDI::Connection>

	$c = $xdi->connect();
	
This is the primary method for creating a Connection object so that it can access the fields 
of the XDI object.  

You can pass any XDI::Connection initialization parameters to C<connect()>

	$hash = {
		target => E<lt>iname|inumberE<gt>,  # eg: =my_personal_cloud
		secret => $secret
	};
	
	$c = $xdi->connect($hash);
	
Given an I<iname>, the default behavior for XDI is to attempt to resolve the iname to it's 
corresponding inumber using the iname resolution service at xri2xdi.net. This service
also returns the URI to the graph that is authoritative for said I<iname>, during testing and
development that often proves inconvenient so you can override this behavior

	$c->resolve(0);
	
Of course, if you do that, you will have to specify the URI of the graph to which you are
sending a query

	$c->server("http://example/=my_personal_cloud");
	
You may have noticed that we haven't actually I<connected> to anything yet.  I reserve the right
to make checking the target graph for a valid link contract part of the connection process

=head3 secret

=over 2

XDI security policy is currently under discussion by the XDI Technical Committee so the placeholder for a more robust policy is to use a shared secret. Please note that the policy allows for arbitrarily complex expressions and Javascript is proposed for the expression syntax.  L<https://wiki.oasis-open.org/xdi/XdiPolicyExpression> As the policy matures, I expect to need to update the client

=back

Next step is to create an L<XDI::Message> object 

	$msg = $c->message();
	
As usual, you can pass valid message constructor parameters to XDI::Connection::message

	$hash = {
		link_contract => '=!1111'
	};

The C<link_contract> is the address of the node to which you have permissions.  Note that you
not only have to have permission to that node, but you have to have permission to execute your 
operation S<($get,$mod,$add,$del,$all)>

The process of a external party negotiating a link contract is still under development so 
an XDI server has the option of not enforcing link contracts.  In such case, leave the 
C<link_contract> parameter undefined and that statement will not be included as part of the
message. More information on link contracts can be found at L<XDI::Message>

Compose the message that you intend to send to the target graph

	$msg->get('=!1111+tel');
	
An XDI message can only contain one type of operation, so it is an error to try to mix operations
in a message, but it is possible to send multiple statements of the same operation

	$msg->get('=!1111+tel');
	$msg->get('=!1111+email');
	$msg->get('=!1111+birthdate');
	
Each one of these operations composes an XDI statement.  There is no order of execution for statements
in a message.  This has little consequence for $get operations, but needs to be taken into consideration
for $add and $mod operations

Once the message is composed, use the XDI::Connection object to C<post> the message to the target graph
C<post> performs an http post request to the server with the XDI message in the body.

	$graph = $c->post($msg);
	
The result is a JSON encoded representation of the nodes requested in the $get operation.  Other
operations will return an empty hash {} upon success.  Default behavior is to automatically convert
the JSON to a perl hash object

=head1 SUBROUTINES/METHODS

XDI and it's members support the common PERL OO-style syntax via AUTOLOAD

=head2 Constructor

	$xdi = XDI->new($iname);

	$xdi = XDI->new({
		'from' => '=tester,
		'from_graph' => '@server'
	});

	$xdi = XDI->new($ref);

Constructs a new XDI object.  Optional arguments consist of either a single iname|inumber string or a list of field => value pairs.  The single argument will default values of from and from_graph to the same value.

	$xdi->from()
	
	$xdi->from($val)

Get/set C<from> value.  C<from> is the identity of the entity making the XDI request

	$xdi->from_graph()

	$xdi->from_graph($val)

Get/set C<from_graph> value. C<from_graph> is the identity of the B<graph> that is making the
XDI request.  In the case of a PERL client, the distinction between C<from> and C<from_graph>
may be negligible, but could be significant when issues of authorized access via signed messages
are implemented

=head2 connect

	$c = $xdi->connect()

	$c = $xdi->connect($hash)

This method returns a XDI::Connection object. Any parameters passed to the method will be used to invoke the
XDI::Connection constructor.

=head2 pick_xdi_tuple

	$tuple = pick_xdi_tuple($graph,[I<$subject>,I<$predicate>,I<$object>])

C<$graph> is a perl hash object as returned by C<$c->post($msg)>

I<$subject>,I<$predicate>,I<$object> are optional matching arguments (strings) used to match the returned tuple
Any one or two of the parameters may be C<undef>.  Only the first matching tuple is returned

pick_xdi_tuple returns an array reference [I<$subject>,I<$predicate>,I<$object>]

=head2 tuples

	$tuples = tuples($graph,[I<$subject> | I<regex>,I<$predicate> | I<regex>,I<$object> | I<regex>])

tuples returns an array of array references.  Any of the match elements can be substituted with a regular expression.

Usually the third element of the tuple is an array. If there is only 1 element to the array, the element is substituted for the array of 1 element

=head2 get_literal

	get_literal($graph,I<$key>)
	get_literal($graph,I<@key>)
	
get_literal is a convenience function to pull literals (I<subject>/!/I<literal>) from the graph. A single key or an array of keys is a valid parameter

If an array of keys I<@key> is used, all of the values are placed into a single array that is returned

=head2 get_equivalent

	get_equivalent($graph,$key)
	
get_equivalent is a convenience function to pull equivalance expressions (I<subject>/$is/I<equivalent>) from the graph.

=head2 get_property

	get_property($graph,$key)
	
get_property is a convenience function to pull properties of I<subject> (I<subject>/()/I<property>) from the graph.

=head2 get_context

	get_context($graph,$key)
	
get_context is a convenience function to pull the contexts of definitions (I<+(+def)>/$is()/[...]]) from the graph.

=head1 AUTHOR

	Mark Horstmeier <solargroovey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2012 Kynetx, Inc. 

The perl XDI client is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of
the License, or (at your option) any later version.

This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public
License along with this program; if not, write to the Free
Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
MA 02111-1307 USA




