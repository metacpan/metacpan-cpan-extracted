###############################################################################
#Object.pm
#Last Change: 2006-11-01
#Copyright (c) 2006 Marc-Seabstian "Maluku" Lucksch
#Version 0.28
####################
#This file is part of the sofu.pm project, a parser library for an all-purpose
#ASCII file format. More information can be found on the project web site
#at http://sofu.sourceforge.net/ .
#
#sofu.pm is published under the terms of the MIT license, which basically means
#"Do with it whatever you want". For more information, see the license.txt
#file that should be enclosed with libsofu distributions. A copy of the license
#is (at the time of this writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################

=head1 NAME

Data::Sofu::Object - Sofud compatibility layer.

=head1 DESCRIPTION

Provides a interface similar to the original SofuD (sofu.sf.net)

=head1 Synopsis 

	require Data::Sofu::Object;
	my $map = Data::Sofu::Object->new({Text=>"Hello World"});
	print ref $map; # Data::Sofu::Map;
	$map->write(\*STDOUT); # Text = "Hello World"
	$map->write("file.sofu"); # Text = "Hello World"
	#You don't need Data::Sofu::Object:
	use Data::Sofu;
	$map = loadSofu("file.sofu");
	$map->write(\*STDOUT);

=head1 SYNTAX

This Module is pure OO, exports nothing

=cut

package Data::Sofu::Object;

use strict;
use warnings;
require Data::Sofu::Map;
require Data::Sofu::List;
require Data::Sofu::Value;
require Data::Sofu::Undefined;
require Data::Sofu::Reference;
our $VERSION="0.29";
my %seen;
our %OBJ;
my $indent = "\t";

use Carp qw/confess/;

=head1 METHODS

C<Data::Sofu::Object> is the base class for C<Map>, C<Value>, C<List>, C<Reference> and C<Undefined>.

All Methods in here might be overwritten, but work the same way

=head2 new(DATA)
Creates a new C<Data::Sofu::Object> and returns it

Converts DATA to appropriate Objects

B<Note>

There is no need to call C<Data::Sofu::Object> without DATA.

=cut 

sub new {
	my $self={};
	bless $self,shift;
	if (@_) {
		#print "@_\n";
		my $o = shift;
		if (ref($o) eq "HASH") {
			if (not $seen{$o}) {
				#confess "BOXXX";
				$seen{$o}=Data::Sofu::Map->new();
				$seen{$o}->set($o);
				return $seen{$o};
			}
			else {
				return Data::Sofu::Reference->new($seen{$o});
			}
		}
		elsif (ref($o) eq "ARRAY") {
			if (not $seen{$o}) {
				#confess "BOXXX";
				$seen{$o}= Data::Sofu::List->new();
				$seen{$o}->set($o);
				return $seen{$o};
			}
			else {
				return Data::Sofu::Reference->new($seen{$o});
			}
		}
		elsif (ref($o) eq "SCALAR") {
			#confess "BOXXX";
			return Data::Sofu::Value->new($$o);
		}
		elsif (ref($o)) {
			return $o;
		}
		else {
			#confess "BOXXX";
			return Data::Sofu::Value->new($o) if defined $o;
			return Data::Sofu::Undefined->new()
		}

	}
	return $self;
}
=head2 indent(LEVEL)

Internal Function to create indentation during write()

LEVEL is the amount of indentation requested

Returns Indentation x LEVEL as a string

=cut

sub indent {
	my $self=shift;
	my $l=shift;
	return "" unless $l;
	return "" if $l < 0;
	return $indent x $l;
}

=head2 setIndent([NewIndent]) 

Allows different indentations to be used (default is "\t")

Returns the current indentation

=cut

sub setIndent {
	my $self=shift;
	if (@_) {
		$indent=shift;
	}
	return $indent;
}

=head2 clear()

Clears the Buffer of seen Objects only used during the old C<Data::Sofu::from()> and C<Data::Sofu::toObjects()>

=cut

sub clear {
	%seen=();
}

=head2 asValue()

Returns the Object as a C>Data::Sofu::Value> or throws an error if it can't be converted

=cut

sub asValue {
	confess "Object assumed to be a Value, but it is ".ref shift;
	return;
}

=head2 asList()

Returns the Object as a C<Data::Sofu::List> or throws an error if it can't be converted

=cut

sub asList {
	confess "Object assumed to be a List, but it is ".ref shift;
	return;
}

=head2 asMap()

Returns the Object as a C<Data::Sofu::Map> or throws an error if it can't be converted

=cut

sub asMap {
	confess "Object assumed to be a Map, but it is ".ref shift;
	return;
}

=head2 asReference()

Returns the Object as a C<Data::Sofu::Reference> or throws an error if it can't be converted

=cut

sub asReference {
	confess "Object assumed to be a Reference, but it is ".ref shift;
	return;
}

=head2 C<stringify(LEVEL, TREE)>

Returns a string representation of the Object, used during write(), should not be called alone

LEVEL is the current indentation level.

TREE is the current position in the TREE (used for Reference building)

=cut 

sub stringify {
	confess "Error can't stringify an Object which is nothing but an Object";
}

=head2 C<binarify(TREE, BINARY DRIVER)>

Returns a binary representation of the Object, used during writeBinary(), should never be called alone.

TREE is the current position in the TREE (used for Reference building)

BINARY DRIVER is a C<Data::Sofu::Binary> instance which is initialized with a Encoding, ByteOrder and Sofumark properties.

=cut 

sub binarify {
	confess "Error can't binarify an Object which is nothing but an Object";
}

=head2 C<storeComment(TREE, COMMENT)>

Recursivly stores a comment identified by TREE, is used to store a single comment of the hash returned by C<Data::Sofu::getSofucomments()>;

=cut

sub storeComment {
	my $self=shift;
	my $tree=shift;
	my $comment=shift;
	$self->{Comment}=$comment;

}

=head2 importComments(COMMENTS) 

Takes a Hashref (as returned by C<Data::Sofu::getSofucomments())> and gives every Object its fitting Comment

COMMENTS is a reference to a Hash

Normally Data::Sofu->new->toObjects($data,$comments) should have done this.

=cut

sub importComments {
	my $self=shift;
	my $comment=shift;
	foreach my $key (keys %$comment) {
		my $wkey=$key;
		$wkey=~s/^->//;
		$wkey="" if $key eq "=";
		$self->storeComment($wkey,$comment->{$key});
	}
	
}

=head2 isValue() 

Return 1 if this Object is a C<Data::Sofu::Value> instance, 0 otherwise.

=cut

sub isValue {
	return 0;
}

=head2 isList()

Return 1 if this Object is a C<Data::Sofu::List> instance, 0 otherwise.

=cut

sub isList {
	return 0;
}

=head2 isMap()

Return 1 if this Object is a C<Data::Sofu::Map> instance, 0 otherwise.

=cut

sub isMap {
	return 0;
}

=head2 stringComment()

Returns the current Objects comment as a string (inculding the # sign)

=cut

sub stringComment {
	my $self=shift;
	return " #".join("\n#",@{$self->{Comment}}) if $self->{Comment};
	return "";
}

=head2 getComment()

Returns the current comment as an arrayref (One string for each line)

=cut
sub getComment {
	my $self=shift;
	return $self->{Comment};
}

=head2 hasComment()

Returns the amount of comment lines.

=cut 

sub hasComment {
	my $self=shift;
	return 0 unless $self->{Comment};
	return scalar @{$self->{Comment}};
}

=head2 setComment(COMMENT)
 
Sets the comments for this Object.

COMMENT should be a reference to an Array

=cut

sub setComment {
	my $self=shift;
	my $c = shift;
	delete $self->{Comment};
	next unless $c;
	if (ref $c) {
		if (ref $c eq "ARRAY") {
			$self->{Comment}=$c;
		}
		else {
			die "Unknown Comment Format, has to be an Arrayref or Scalar";
		}
	}
	else {
		$self->{Comment}=[$c,@_];
	}
}

=head2 appendComment(COMMENT)

Appends to the comments for this Object.

COMMENT should be a reference to an Array

=cut

sub appendComment {
	my $self=shift;
	my $c = shift;
	$self->{Comment}=[] unless $self->{Comment};
	next unless $c;
	if (ref $c) {
		if (ref $c eq "ARRAY") {
			push @{$self->{Comment}},@{$c};
		}
		else {
			die "Unknown Comment Format, has to be an Arrayref or Scalar";
		}
	}
	else {
		push @{$self->{Comment}},$c,@_;
	}
}

=head2 isDefined()

Returns 1 if the Object is not an instance of C<Data::Sofu::Undefined>

=cut

sub isDefined {
	return 1;
}

=head2 isReference()

Returns 0 if the Object is not an instance of C<Data::Sofu::Reference>

=cut

sub isReference {
	return 0;
}

=head2 pack()

Returns a string representation of the current Object and all Objects it might include

=cut

sub pack {
	my $self=shift;
	%OBJ=();
	return $self->string(-1,"");
	#confess "You can only Pack Maps";
}

=head2 binaryPack()

Returns a string of that represents the current Object according the the Binary Sofu specification.

Only works on C<Data::Sofu::Map>'s other Objects are getting boxed in a Map

=cut

sub binaryPack {
	my $x = new Data::Sofu::Map;
	$x->setAttribute("Value",shift); #$self
	%OBJ=($x=>"->");
	$x->binaryPack(@_);
}

=head2 C<string(LEVEL,TREE)>

A helper function to detect multiple references and convert them to Sofu References, calls stringify with its arguments

	$o->string(-1,"") === $o->pack();
	print $map->string(0,"") === $o->write(\*STDOUT);

=cut

sub string { #Helper function to detect multiple References
	my $self=shift;
	my $level=shift;
	my $tree=shift;
	my $oself=$self;
	if ($self->isReference()) {
		if ($self->valid()) {
			$self=$self->follow();
		}
		else {
			#confess ($self->follow());
			return "@".$self->follow().$self->stringComment()."\n";
		}
	}
	if ($OBJ{$self}) {
		return "@".$OBJ{$self}.$oself->stringComment()."\n";
	}
	$OBJ{$self}=$tree || "->";
	return $self->stringify($level,$tree);
}

=head2 C<packComment(BINARY DRIVER)>

Returns the Objects Comments packed by a BINARY DRIVER, used by binaryPack() and writeBinary()

Never call this one alone.

=cut

sub packComment {
	my $self=shift;
	my $bin=shift;
	return $bin->packText("") unless $self->{Comment};
	return $bin->packText(join("\n",@{$self->{Comment}}));
}


=head2 C<binary(TREE, BINARY DRIVER)>

A helper function to detect multiple references and convert them to Sofu References, calls stringify with its arguments. Should never be called alone, because the result will miss its header.

=cut
sub binary { #Helper function to detect multiple References
	my $self=shift;
	my $tree=shift;
	my $bin=shift;
	my $oself=$self;
	if ($self->isReference()) {
		if ($self->valid()) {
			$self=$self->follow();
		}
		else {
			return $bin->packType(4).$self->packComment($bin).$bin->packText("@".$self->follow());
		}
	}
	if ($OBJ{$self}) {
		return $bin->packType(4).$oself->packComment($bin).$bin->packText("@".$OBJ{$self});
	}
	$OBJ{$self}=$tree || "->";
	return $self->binarify($tree,$bin);
}

=head2 write(FILE) 

Writes the string representation of this Object to a file

File can be:

A filename,

a filehandle or

a reference to a scalar.

=cut

sub write {
	my $self=shift;
	my $file=shift;
	my $fh;
	%OBJ=();
	unless (ref $file) {
		open $fh,">:raw:encoding(UTF-16)",$file or die "Sofu error open: $$self{CurFile} file: $!";
	}
	elsif (ref $file eq "SCALAR") {
		utf8::upgrade($$file);
		open $fh,">:utf8",$file or die "Can't open perlIO: $!";
	}
	elsif (ref $file eq "GLOB") {
		$fh=$file;
	}
	else {
		$self->warn("The argument to load or loadfile has to be a filename, reference to a scalar or filehandle");
		return;
	}
	print $fh $self->string(0,"");
	#$fh goes out of scope here!
}
=head2 C<writeBinary(FILE,ENCODING,BYTEORDER,SOFUMARK)>

Writes the binary representation of this Object to a file

File can be:

A filename,

a filehandle or

a reference to a scalar.

Note: the filehandle will be set to binmode

Uses C<Data::Sofu::Binary::Bin0200> as driver.

=cut

sub writeBinary {
	my $self=shift;
	my $file=shift;
	my $fh;
	%OBJ=($self=>"->");
	unless (ref $file) {
		open $fh,">:raw",$file or die "Sofu error open: $$self{CurFile} file: $!";
	}
	elsif (ref $file eq "SCALAR") {
		open $fh,">",$file or die "Can't open perlIO: $!";
	}
	elsif (ref $file eq "GLOB") {
		$fh=$file;
	}
	else {
		$self->warn("The argument to load or loadfile has to be a filename, reference to a scalar or filehandle");
		return;
	}
	binmode $fh;
	print $fh $self->binaryPack(@_);
	#$fh goes out of scope here!
}

=head1 BUGS

Comment and Binary Modes are not really sofud complient, might change in the future

=head1 SEE ALSO

L<Data::Sofu>, L<Data::Sofu::Binary>, L<Data::Sofu::Map>, L<Data::Sofu::List>, L<Data::Sofu::Value>, L<Data::Sofu::Undefined>, L<http://sofu.sf.net>

=cut

1;
