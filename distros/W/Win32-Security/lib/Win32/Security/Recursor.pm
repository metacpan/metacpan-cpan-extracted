#############################################################################
#
# Win32::Security::Recursor - Security recursion for named objects
#
# Author: Toby Ovod-Everett
#
#############################################################################
# Copyright 2003, 2004 Toby Ovod-Everett.  All rights reserved
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
#############################################################################

=head1 NAME

C<Win32::Security::Recursor> - Security recursion for named objects

=head1 SYNOPSIS

    use Win32::Security::Recursor;

    my $recursor = Win32::Security::Recursor::SE_FILE_OBJECT->new(
      payload => sub {
        my $self = shift;
        my($node_info, $cont_info) = @_;

        print $self->node_name($node_info)."\n";
      }
    );

    $recursor->recurse($ARGV[0]);

=head1 DESCRIPTION

This module is designed to support scripts that need to recurse through a 
hierarchy of objects (i.e. a directory tree, registry hive, etc.), and 
interfacing with the security information on every node.  There are a number of 
reasons this module was developed, instead of simply reusing C<File::Find>.

=over 4

=item *

Applicability to multiple tree types.  While not currently implemented, I tried
to architect the interfaces and the internals so that it should be relatively
simple to extend the code base to support the registry, Active Directory, and
any other hierarchies of NamedObjects.

=item *

Applicability to permissions recursion.  In particular, it is very common to
compare the permissions on a node with the permissions on a parent node.  To
avoid performance-sapping duplication of effort, the system passes the payload
both the information for the node and for its parent.

=item *

General performance improvements.  Information is cached where appropriate (for 
instance, testing for whether a node is a container), thus reducing duplicate 
system calls.  System calls were further optimized.  For instance, it turns out 
that C<Win32::File::GetAttributes> is over twice as fast as the built-in C<-d> 
operator, at least under Perl 5.6.1 - this shaves roughly 0.3 ms per node on a 
Pent III Xeon 450 (or 30 seconds when scanning 100,000 files!), and even more 
given that it lets one test for JUNCTION points with almost no additional 
overhead.

=item *

Error handling.  Error handling is passed through well defined interfaces, thus
letting the developer choose how to display and/or record errors.

=back

All of this comes at a price, however, and that is complexity.  Some of that is 
because the problem itself is complex - objects fail to respond to API calls, 
JUNCTION points can complicate recursion, etc.  Some of it is because the module 
was designed to be as flexible as possible, and so code was broken up into a 
wide variety of methods, thus making granual overriding possible.  The module 
makes use of C<Class::Prototyped> to support object-level method overriding 
without the need for explicit subclassing.

=head2 Installation instructions

This installs as part of C<Win32-Security>.  See 
C<Win32::Security::NamedObject> for more information.

It depends upon the other C<Win32-Security modules and C<Class::Prototyped>.


=head1 ARCHITECTURE

The docs for this module are still under development.  The documentation present 
is correct, but to really understand the module you need to look at the source.

=head2 Subclass Organization

There are subclasses of C<Win32::Security::Recursor> for each type of supported 
C<Win32::Security::NamedObject> (i.e. C<'SE_FILE_OBJECT'> for now - 
C<'SE_REGISTRY_KEY'> is not yet supported).  The subclasses are responsible for 
implementing hierarchy specific behavior, such as enumerating child nodes, 
determining whether a node is a container, etc.

=cut

use Class::Prototyped '0.98';
use Win32::File;
use Win32::Security::NamedObject;

use strict;

BEGIN {
	Class::Prototyped->newPackage('Win32::Security::Recursor');

	package Win32::Security::Recursor; #Added to ensure presence in META.yml
}


=head1 Method Reference

=head2 C<new>

The C<new> method is entirely inherited from C<Class::Prototyped>.  A list of 
slot names and values may be passed if desired using the normal 
C<Class::Prototyped::addSlots> syntax.

=cut


=head2 C<recurse>

The C<recurse> method is the heart of C<Win32::Security::Recursor>.  It accepts 
a single object name and recurses through the tree of objects rooted by that 
object.  It does not use recursion, though, but rather a stack-based approach 
that flattens the recursion into a loop.

First, though, it creates an entirely new object to handle the call sequence.  
This object inherits from the object upon which C<recurse> was called, and has a 
C<nodes> slot that consists of an anonymous array of nodes remaining to be 
processed.  Each node is a hash consisting of a C<name> which stores the 
object-name in question, a C<parent> which is a reference to the parent node,
and keys which store cached responses for the various node information calls.

The currently "active" node is always the last one on the array.  Nodes are
pushed onto the array in reverse order so that a depth-first search is
effected.

Once the first node is on the array, basic flow through the loop looks like
this:

=over

=item * Calls C<node_filternode> on current node

Calls C<node_filternode> to filter individual node.  If C<node_filternode> 
returns true, execution proceeds through the loop.  The call to 
C<node_filternode> traps C<die> with an C<eval>, so a C<die> is treated like a 
false value.  If the call fails or C<die>s, then the node is popped off of the 
array and the loop restarted.  This happens here to that C<node_filternode> 
filters the nodes in the proper order so that any output is sorted 
appropriately.

=item * Calls C<payload> on current node

The call to C<payload> is wrapped in an C<eval> and any returned C<$@> is 
printed to C<STDERR> if C<< $self->debug() >> is true.

=item * Determines list of child nodes and pushes them onto the array

This whole procedure is wrapped in an C<eval>.  If any part of it fails, any 
returned C<$@> is printed to C<STDERR> if C<< $self->debug() >> is true and then 
the last node is popped off of the array.  The code first calls 
C<node_iscontainer>, and if false simply pops the last node off the array.  
Otherwise, C<node_enumchildren> is called to build a list of child nodes (each 
of which has a C<parent> that points to the current node).  
C<node_filterchildren> is then called, which is responsible for ordering the 
child nodes as desired and for filtering out any nodes which wouldn't result in 
any output.  Finally, the list of child nodes is reversed and used to replace 
the active node.

=back

=cut

Win32::Security::Recursor->reflect->addSlots(
	recurse => sub {
		my $parent = shift;
		my($name) = @_;

		my $nodes = [ { name => $name} ];
		my $self = Class::Prototyped->new(
			'parent*' => $parent,
			[qw(nodes constant)] => $nodes,
		);

		my $container = $self->node_container($nodes->[-1]);
		$nodes->[0]->{parent} = {name => $container} if defined $container;

		$self->_recurse();
	},

	_recurse => sub {
		my $self = shift;

		my $nodes = $self->nodes();
		while (@$nodes) {
			unless (eval { $self->node_filternode($nodes->[-1]) } ) {
				pop(@$nodes);
				next;
			}

			eval { $self->payload() };
			($@ && $self->debug()) and print STDERR $@;

			eval {
				if ($self->node_iscontainer($nodes->[-1])) {
					my(@children) = $self->node_enumchildren($nodes->[-1]);
					@children = reverse $self->node_filterchildren($nodes->[-1], @children);
					splice(@$nodes, -1, 1, @children);
				} else {
					pop(@$nodes);
				}
			};
			if (my $errmsg = $@) {
				$self->debug() and print STDERR $errmsg;
				pop(@$nodes);
			}
		}
	}
);


=head2 C<objectType>

This returns the C<objectType> for a given Recursor.  Should be overridden by
child classes.

=cut

Win32::Security::Recursor->reflect->addSlots(
	objectType => sub {
		my $self = shift;

		die "Win32::Security::Recursor::objectType needs to be overridden.";
	}
);


=head2 C<debug>

This defaults to true.  Pass in "C<< [qw(debug constant)] => 0, >>" to C<new> to 
turn C<debug> off.

=cut

Win32::Security::Recursor->reflect->addSlots(
	[qw(debug constant)] => 1
);


=head2 C<payload>

Needs to be overridden to actually do anything!

=cut

Win32::Security::Recursor->reflect->addSlots(
	payload => sub {
		my $self = shift;

		die "Win32::Security::Recursor::payload needs to be overridden.";
	},
);


=head2 C<node_getinfo>

Used to get information about a node and/or the parent node.  This accepts a 
list of "requests" and then returns the requested information.  Each request 
consists of a pair of values.  The first value should be either C<'node'>, 
C<'parent'>, or a node C<HASH>.  The second value should be either an info
name or a reference to an array of info names.  The permitted info names are:

=over

=item * name

The node object name.

=item * iscontainer

True if the node is a container object, false otherwise.

=item * namedobject

Returns the C<Win32::Security::NamedObject> object for this node.

=item * dacl

Returns the C<Win32::Security::ACL> object for the DACL of this node.

=item * ownerTrustee

Returns the owner as Trustee for this node.

=item * ownerSid

Returns the owner as SID for this node.

=item * container

Returns the name of the container that contains this object, if there is one.

=back

The information is returned in a list in the order requested.

=cut

Win32::Security::Recursor->reflect->addSlots(
	node_getinfo => sub {
		my $self = shift;
		my(@requests) = @_;

		my(@retval, $rootnode);
		while (@requests) {
			my($node, $infobj) = splice(@requests, 0, 2);
			unless (ref($node) eq 'HASH') {
				$rootnode ||= $self->nodes()->[-1];
				$node = $node eq 'node' ? $rootnode :
								$node eq 'parent' ? $rootnode->{parent} :
								die "node_getinfo can't get data for '$node'";
			}
			foreach my $info (ref($infobj) eq 'ARRAY' ? @$infobj : $infobj) {
				if (defined $node) {
					if (exists $node->{$info}) {
						push(@retval, $node->{$info});
					} else {
						my $call = "node_$info";
						push(@retval, $self->$call($node));
					}
				} else {
					push(@retval, undef);
				}
			}
		}
		if (scalar(@retval) > 1) {
			return(@retval);
		} else {
			return $retval[0];
		}
	}
);

Win32::Security::Recursor->reflect->addSlots(
	node_name => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		return $node->{name};
	}
);

Win32::Security::Recursor->reflect->addSlots(
	node_iscontainer => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		die "Win32::Security::Recursor::iscontainer needs to be overridden.";
	}
);

Win32::Security::Recursor->reflect->addSlots(
	node_namedobject => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		unless (exists $node->{namedobject}) {
			my $objectType = $self->objectType();
			$node->{namedobject} = "Win32::Security::NamedObject::$objectType"->new($node->{name});
		}
		return $node->{namedobject};
	}
);

Win32::Security::Recursor->reflect->addSlots(
	node_dacl => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		unless (exists $node->{dacl}) {
			my $namedobject = exists $node->{namedobject} ? $node->{namedobject} : $self->node_namedobject($node);
			eval { $node->{dacl} = $namedobject->dacl() };
			$@ and $self->error_node_dacl($node, $@);
		}
		return $node->{dacl};
	}
);

Win32::Security::Recursor->reflect->addSlots(
	error_node_dacl => sub {
		my $self = shift;
		my($node, $error) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		die "Unable to read DACL for '$node->{name}': $error";
	}
);

Win32::Security::Recursor->reflect->addSlots(
	node_ownerTrustee => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		eval { $node->{ownerTrustee} ||= $self->node_namedobject($node)->ownerTrustee() };
		$@ and $self->error_node_ownerTrustee($node, $@);
		return $node->{ownerTrustee};
	}
);

Win32::Security::Recursor->reflect->addSlots(
	error_node_ownerTrustee => sub {
		my $self = shift;
		my($node, $error) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		die "Unable to read ownerTrustee for '$node->{name}': $error";
	}
);

Win32::Security::Recursor->reflect->addSlots(
	node_ownerSid => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		eval { $node->{ownerSid} ||= $self->node_namedobject($node)->ownerSid() };
		$@ and $self->error_node_ownerSid($node, $@);
		return $node->{ownerSid};
	}
);

Win32::Security::Recursor->reflect->addSlots(
	error_node_ownerSid => sub {
		my $self = shift;
		my($node, $error) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		die "Unable to read ownerSid for '$node->{name}': $error";
	}
);

Win32::Security::Recursor->reflect->addSlots(
	node_container => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		die "Win32::Security::Recursor::node_container needs to be overridden.";
	}
);

Win32::Security::Recursor->reflect->addSlots(
	node_enumchildren => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		die "Win32::Security::Recursor::node_enumchildren needs to be overridden.";
	}
);

Win32::Security::Recursor->reflect->addSlots(
	node_filterchildren => sub {
		my $self = shift;
		my($node, @children) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		return @children;
	}
);

Win32::Security::Recursor->reflect->addSlots(
	node_filternode => sub {
		my $self = shift;
		my($child, $node) = @_;

		$child or return;
		return 1;
	}
);







BEGIN {
	Win32::Security::Recursor->newPackage('Win32::Security::Recursor::SE_FILE_OBJECT');
}

Win32::Security::Recursor::SE_FILE_OBJECT->reflect->addSlots(
	objectType => 'SE_FILE_OBJECT'
);

Win32::Security::Recursor::SE_FILE_OBJECT->reflect->addSlots(
	node_container => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		my $name = $node->{name};
		my $container = Win32::GetFullPathName("$name\\..");

		return Win32::GetFullPathName($name) ne $container ? $container : undef;
	}
);

Win32::Security::Recursor::SE_FILE_OBJECT->reflect->addSlots(
	node_enumchildren => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}

		my $iscontainer = exists $node->{iscontainer} ? $node->{iscontainer} : $self->node_iscontainer($node);
		$iscontainer or return;

		my $fileattribs = $node->{fileattribs} || $self->node_fileattribs($node);
		if ($fileattribs->{FILE_ATTRIBUTE_REPARSE_POINT}) {
			eval { $self->error_node_isjunction($node) };
			($@ && $self->debug()) and print STDERR $@;
			$@ and return;
		}

		my $node_name = $node->{name};
		(my $node_safe = $node_name) =~ s/\\$//g;

		my(@children);
		eval {
			opendir(TEMP, $node_name);
			@children = map { {name => "$node_safe\\$_", parent => $node} } grep {!/^\.\.?$/} readdir(TEMP);
			closedir(TEMP);
		};

		$@ and $self->error_node_enumchildren($node, $@);
		return @children;
	}
);

Win32::Security::Recursor::SE_FILE_OBJECT->reflect->addSlots(
	error_node_isjunction => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		die "Stopping recursion at JUNCTION '$node->{name}'.";
	}
);

Win32::Security::Recursor::SE_FILE_OBJECT->reflect->addSlots(
	error_node_enumchildren => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		die "Unable to enumerate chilren for '$node->{name}'.";
	}
);

Win32::Security::Recursor::SE_FILE_OBJECT->reflect->addSlots(
	node_iscontainer => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		unless (exists $node->{iscontainer}) {
			$node->{iscontainer} = $self->node_fileattribs($node)->{FILE_ATTRIBUTE_DIRECTORY};
		}
		return $node->{iscontainer};
	}
);

Win32::Security::Recursor::SE_FILE_OBJECT->reflect->addSlots(
	node_fileattribs => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		unless (exists $node->{fileattribs}) {
			my $fileattribs;
			&Win32::File::GetAttributes($node->{name}, $fileattribs);
			if ($fileattribs == -1) {
				$self->error_node_fileattribs($node);
			} else {
				$node->{fileattribs} = $self->FILE_ATTRIBUTES->break_mask($fileattribs);
			}
		}
		return $node->{fileattribs};
	}
);

Win32::Security::Recursor::SE_FILE_OBJECT->reflect->addSlots(
	error_node_fileattribs => sub {
		my $self = shift;
		my($node) = @_;

		defined $node or return;
		unless (ref($node) eq 'HASH') {
				$node = $node eq 'node' ? $self->nodes()->[-1] :
								$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
								die "node_getinfo can't get data for '$node'";
		}
		die "Unable to read file attributes for '$node->{name}'.";
	}
);


Win32::Security::Recursor::SE_FILE_OBJECT->reflect->addSlots(
	[qw(FILE_ATTRIBUTES FIELD autoload)] => sub {
		Data::BitMask->new(
			FILE_ATTRIBUTE_READONLY =>             0x00000001,
			FILE_ATTRIBUTE_HIDDEN =>               0x00000002,
			FILE_ATTRIBUTE_SYSTEM =>               0x00000004,
			FILE_ATTRIBUTE_DIRECTORY =>            0x00000010,
			FILE_ATTRIBUTE_ARCHIVE =>              0x00000020,
			FILE_ATTRIBUTE_ENCRYPTED =>            0x00000040,
			FILE_ATTRIBUTE_NORMAL =>               0x00000080,
			FILE_ATTRIBUTE_TEMPORARY =>            0x00000100,
			FILE_ATTRIBUTE_SPARSE_FILE =>          0x00000200,
			FILE_ATTRIBUTE_REPARSE_POINT =>        0x00000400,
			FILE_ATTRIBUTE_COMPRESSED =>           0x00000800,
			FILE_ATTRIBUTE_OFFLINE =>              0x00001000,
			FILE_ATTRIBUTE_NOT_CONTENT_INDEXED =>  0x00002000,
		);
	}
);


=head1 Potentially Useful Recursors

In order to make it easier to reuse some of my code, I have taken the liberty of 
putting some of my recursors into C<Win32::Security::Recursor>.

=head2 C<< Win32::Security::Recursor::SE_FILE_OBJECT::PermDump->new($options) >>

This takes a ref to an options hash and returns a recursor that implements the 
same behavior displayed by C<PermDump.pl>.  It takes an optional list of 
parameters that will be passed to C<< Win32::Security::Recursor::SE_FILE_OBJECT->new >> so 
as to override or define new methods for the recursor.

Options passable in the options hash are:

=over 4

=item * C<csv>

=item * C<dirsonly>

=item * C<inherited>

=item * C<owner>

=item * C<recurse>

=back

=cut

sub Win32::Security::Recursor::SE_FILE_OBJECT::PermDump::new {
	my $self = shift;
	my($options, @params) = @_;

	return Win32::Security::Recursor::SE_FILE_OBJECT->new(
		payload => sub {
			my $self = shift;

			$self->payload_count($self->payload_count()+1);

			my($node_name, $node_iscontainer, $node_namedobject, $node_dacl, $node_ownerTrustee,
					$cont_namedobject, $cont_dacl, $cont_ownerTrustee);
			if ($options->{owner}) {
				($node_name, $node_iscontainer, $node_namedobject, $node_dacl, $node_ownerTrustee,
						$cont_namedobject, $cont_dacl, $cont_ownerTrustee) =
					$self->node_getinfo(
						node   => [qw(name iscontainer namedobject dacl ownerTrustee)],
						parent => [qw(namedobject dacl ownerTrustee)],
					);
			} else {
				($node_name, $node_iscontainer, $node_namedobject, $node_dacl,
						$cont_namedobject, $cont_dacl) =
					$self->node_getinfo(
						node   => [qw(name iscontainer namedobject dacl)],
						parent => [qw(namedobject dacl)],
					);
			}

			my $inheritance_blocked = $node_namedobject->control()->{SE_DACL_PROTECTED};

			my $inheritable = ($cont_dacl && !$inheritance_blocked ) ?
					$cont_dacl->inheritable($node_iscontainer ? 'CONTAINER' : 'OBJECT') :
					undef;

			my(@ace_comparison) = $node_dacl->compareInherited($inheritable, 1);

			if ($options->{owner}) {
				if ($options->{inherited} || $cont_ownerTrustee ne $node_ownerTrustee) {
					$self->dump_line(name => $node_name, trustee => $node_ownerTrustee, accessMask => 'OWNER', desc => $node_iscontainer ? 'DO' : 'FO');
				}
			}

			if ($cont_namedobject && $inheritance_blocked) {
				$self->dump_line(name => $node_name, accessMask => 'INHERITANCE_BLOCKED', desc => $node_iscontainer ? 'DB' : 'FB');
			}

			if ( $node_dacl->isNullAcl() && ( $options->{inherited} || !$cont_namedobject || $inheritance_blocked || !$cont_dacl->isNullAcl() ) ) {
				$self->dump_line(name => $node_name, accessMask => 'NULL_DACL', desc => $node_iscontainer ? 'DN' : 'FN');
			}

			foreach my $i (0..scalar(@ace_comparison)/2-1) {
				($options->{inherited} || $ace_comparison[$i*2+1] ne 'I') or next;
				$self->dump_ace($node_name, $node_iscontainer, $ace_comparison[$i*2], $ace_comparison[$i*2+1]);
			}
		},

		payload_count => 0,

		node_filterchildren => sub {
			my $self = shift;
			my($node, @children) = @_;

			return () unless $options->{recurse};
			return sort { lc($a->{name}) cmp lc($b->{name}) } @children;
		},

		node_filternode => sub {
			my $self = shift;
			my($child, $node) = @_;

			return 1 unless $options->{dirsonly};
			return exists $child->{iscontainer} ? $child->{iscontainer} : $self->node_iscontainer($child);
		},

		print => sub {
			my $self = shift;
			print @_;
		},

		print_header => sub {
			my $self = shift;
			$self->dump_line(name => 'Path', trustee => 'Trustee', accessMask => 'Mask', aceFlags => 'Inheritance', desc => 'Desc');
		},

		dump_line => sub {
			my $self = shift;
			my(%data) = @_;

			local($^W) = 0; #Clear warnings about uninitialized values.

			$self->print(join($options->{csv} ? "," : "\t",
							map {my $x = $_; $x =~ s/\"/\"\"/g; $x = '"'.$x.'"' if $x =~ /[\"\', ]/; $x}
							$data{name}, $data{trustee}, $data{accessMask}, $data{aceFlags}, $data{desc}
						)."\n");
		},

		dump_ace => sub {
			my $self = shift;
			my($node_name, $node_iscontainer, $ace, $IMWX) = @_;

			my $aceType = $ace->aceType();
			$aceType =~ /^ACCESS_(?:ALLOWED|DENIED)_ACE_TYPE$/ or return;

			my $accessMask =  ($aceType eq 'ACCESS_DENIED_ACE_TYPE' ? 'DENY:' : '').
					join("|", sort keys %{$ace->explainAccessMask()});

			my $aceFlags = join("|", sort grep {$_ ne 'INHERITED_ACE'} keys %{$ace->explainAceFlags()});
			$aceFlags ||= 'THIS_FOLDER_ONLY' unless !$node_iscontainer;

			$self->dump_line( name => $node_name, trustee => $ace->trustee(), accessMask => $accessMask, aceFlags => $aceFlags,
					desc => ($node_iscontainer ? 'D' : 'F').($IMWX || ($ace->aceFlags()->{INHERITED_ACE}?'I':'X')) );
		},

		debug => 0,

		error_node_enumchildren => sub {
			my $self = shift;
			my($node) = @_;

			defined $node or return;
			unless (ref($node) eq 'HASH') {
					$node = $node eq 'node' ? $self->nodes()->[-1] :
									$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
									die "node_getinfo can't get data for '$node'";
			}

			$self->dump_line( name => $node->{name}, accessMask => 'ERROR_ENUM_CHILDREN',
					desc => ($node->{iscontainer} ? 'D' : 'F').'E' );
			die;
		},

		error_node_fileattribs => sub {
			my $self = shift;
			my($node) = @_;

			defined $node or return;
			unless (ref($node) eq 'HASH') {
					$node = $node eq 'node' ? $self->nodes()->[-1] :
									$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
									die "node_getinfo can't get data for '$node'";
			}

			$self->dump_line( name => $node->{name}, accessMask => 'ERROR_READ_FILEATTRIBS',
					desc => '?E' );
			die;
		},

		error_node_ownerTrustee => sub {
			my $self = shift;
			my($node, $error) = @_;

			defined $node or return;
			unless (ref($node) eq 'HASH') {
					$node = $node eq 'node' ? $self->nodes()->[-1] :
									$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
									die "node_getinfo can't get data for '$node'";
			}

			$error =~ s/\. at.+//s;
			$self->dump_line( name => $node->{name}, accessMask => 'ERROR_READ_OWNER', aceFlags => $error,
					desc => ($node->{iscontainer} ? 'D' : 'F').'E' );
			die;
		},

		error_node_ownerSid => sub {
			my $self = shift;
			my($node, $error) = @_;

			defined $node or return;
			unless (ref($node) eq 'HASH') {
					$node = $node eq 'node' ? $self->nodes()->[-1] :
									$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
									die "node_getinfo can't get data for '$node'";
			}

			$error =~ s/\. at.+//s;
			$self->dump_line( name => $node->{name}, accessMask => 'ERROR_READ_OWNER', aceFlags => $error,
					desc => ($node->{iscontainer} ? 'D' : 'F').'E' );
			die;
		},

		error_node_dacl => sub {
			my $self = shift;
			my($node, $error) = @_;

			defined $node or return;
			unless (ref($node) eq 'HASH') {
					$node = $node eq 'node' ? $self->nodes()->[-1] :
									$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
									die "node_getinfo can't get data for '$node'";
			}

			$error =~ s/\. at.+//s;
			$self->dump_line( name => $node->{name}, accessMask => 'ERROR_READ_DACL', aceFlags => $error,
					desc => ($node->{iscontainer} ? 'D' : 'F').'E' );
			die;
		},

		error_node_isjunction => sub {
			my $self = shift;
			my($node) = @_;

			defined $node or return;
			unless (ref($node) eq 'HASH') {
					$node = $node eq 'node' ? $self->nodes()->[-1] :
									$node eq 'parent' ? $self->nodes()->[-1]->{parent} :
									die "node_getinfo can't get data for '$node'";
			}

			$self->dump_line(name => $node->{name}, trustee => 'JUNCTION', desc => 'DJ');
			die;
		},

		@params,
	);
}


=head1 AUTHOR

Toby Ovod-Everett, toby@ovod-everett.org

=cut

1;