###############################################################################
#List.pm
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

Data::Sofu::List - A Sofu List

=head1 DESCRIPTION

Provides a interface similar to the original SofuD (sofu.sf.net)

=head1 Synopsis 

	require Data::Sofu::List;
	my $list = Data::Sofu::List->new();
	$list->appendElement(Data::Sofu::Value->new($_)) foreach (0 .. 10);;

=head1 SYNTAX

This Module is pure OO, exports nothing

=cut


package Data::Sofu::List;
use strict;
use warnings;
require Data::Sofu::Object;
our @ISA = qw/Data::Sofu::Object/;
our $VERSION="0.29";

=head1 METHODS

Also look at C<Data::Sofu::Object> for methods, cause List inherits from it

=head2 new([DATA])
Creates a new C<Data::Sofu::List> and returns it

DATA has to be an Arrayhref

	$inc = Data::Sofu::List->new(\@INC);

=cut 

sub new {
	my $self={};
	$self->{List}=[];
	bless $self,shift;
	if (@_) {
		$self->set(@_);		
	}
	return $self;
}

=head2 set(DATA)

Sets the contents of this list (replaces the old contents).

DATA has to be an Arrayhref

	$inc->set(\@INC);

=cut

sub set {
	my $self=shift;
	local $_;
	#@{$self->{List}}=map {Data::Sofu::Object->new($_)} @_;
	my $temp=shift;
	foreach (@$temp) {
		$_=Data::Sofu::Object->new($_);
	}
	$self->{List}=$temp;
}

=head2 asList() 

Returns itself, used to make sure this List is really a List (C<Data::Sofu::Map> and C<Data::Sofu::Value> will die if called with this method)

=cut

sub asList {
	return shift;
}

=head2 asArray()

Perl only

Returns the list as a perl array.

=cut

sub asArray {
	my $self=shift;
	return @{$$self{List}};
}

=head2 isList()

Returns 1

=cut

sub isList {
	return 1;
}

=head2 object(INDEX) 

Return the object at the position INDEX in the List.

Dies if the List is shorter than INDEX.

=cut

sub object {
	my $self=shift;
	my $k=int shift;
	if (exists $self->{List}->[$k]) {
		return $self->{List}->[$k];
	}
	die "Requested object $k doesn't exists in this List";
}

=head2 hasElement(INDEX)

Deprecated!

Returns a true value if the List has an Element with the number INDEX

=cut

sub hasElement {
	my $self=shift;
	my $k=int shift;
	return exists $self->{List}->[$k];
}

=head2 hasObject(INDEX)

Returns a true value if the List has an Element with the number INDEX

=cut

sub hasObject {
	my $self=shift;
	my $k=int shift;
	return exists $self->{List}->[$k];
}

=head2 hasValue(INDEX) 

Returns 1 if this List has an Element at INDEX and this Element is a C<Data::Sofu::Value>.

	$inc->hasValue(2) === $inc->hasElement(2) and $inc->object(2)->isValue();

Note: Return 0 if the Object is not a Value and under if the Element doesn't exist at all.

=cut

sub hasValue {
	my $self=shift;
	my $k=int shift;
	return $self->{List}->[$k]->isValue() if exists $self->{List}->[$k];
	return undef;
}

=head2 hasMap(INDEX) 

Returns 1 if this List has an Element at INDEX and this Element is a C<Data::Sofu::Map>.

	$inc->hasMap(2) === $inc->hasElement(2) and $inc->object(2)->isMap();

Note: Return 0 if the Object is not a Map and under if the Element doesn't exist at all.

=cut

sub hasMap {
	my $self=shift;
	my $k=int shift;
	return $self->{List}->[$k]->isMap() if exists $self->{List}->[$k];
	return undef;
}

=head2 hasList(INDEX) 

Returns 1 if this List has an Element at INDEX and this Element is a C<Data::Sofu::List>.

	$inc->hasMap(2) === $inc->hasElement(2) and $inc->object(2)->isList();

Note: Return 0 if the Object is not a List and under if the Element doesn't exist at all.

=cut

sub hasList {
	my $self=shift;
	my $k=int shift;
	return $self->{List}->[$k]->isList() if exists $self->{List}->[$k];
	return undef;
}

=head2 list(INDEX)

Returns the Object at the postition "INDEX" as a C<Data::Sofu::List>.

Dies if the Object is not a C<Data::Sofu::List>.
	
	$inc->list(2) === $inc->object(2)->asList()

=cut

sub list {
	my $self=shift;
	return $self->object(shift(@_))->asList();
}

=head2 map(INDEX)

Returns the Object at the postition "INDEX" as a C<Data::Sofu::Map>.

Dies if the Object is not a C<Data::Sofu::Map>.
	
	$inc->map(2) === $inc->object(2)->asMap()

=cut

sub map {
	my $self=shift;
	return $self->object(shift(@_))->asMap();
}

=head2 value(INDEX)

Returns the Object at the postition "INDEX" as a C<Data::Sofu::Value>.

Dies if the Object is not a C<Data::Sofu::Value>.
	
	$inc->value(2) === $inc->object(2)->asValue()

=cut

sub value {
	my $self=shift;
	return $self->object(shift(@_))->asValue();
}

=head2 C<setElement(INDEX, VALUE)>

Perl only (for now)

Sets the Element at INDEX to VALUE

	$inc->setElement(0,Data::Sofu::Value->new("."));

=cut 

sub setElement {
	my $self=shift;
	my $key = int shift;
	$self->{List}->[$key]=Data::Sofu::Object->new(shift);
}

=head2 next()

Iterartes over the List, return the next Element on every call and undef at the end of the List.

When called in void context it just resets the iterator.

=cut

sub next {
	my $self=shift;
	$self->{Iter} = 0 unless $self->{Iter};
	unless (defined wantarray) {
		$self->{Iter}=0;
		return;
	}
	if ($self->{Iter} > $#{$self->{List}}) {
		delete $self->{Iter};
		return undef;
	}
	
	return $self->{List}->[$self->{Iter}++];
}

=head2 C<splice(OFFSET, LENGTH, REPLACEMENT)>

Perl only (for now)

Like Perl splice, replaces LENGTH Elements from OFFSET with REPLACEMENT, returns the replaced Elements.
	
	my $lib = new Data::Sofu::List();
	$inc->splice(2,0,Data::Sofu::Value->new("."),Data::Sofu::Value->new(".."),Data::Sofu::Value->new("../lib"));
		# Inserts 3 new Elements after the second Element

=cut

sub splice {
	my $self=shift;
	return CORE::splice(@{$self->{List}},@_);
}

=head2 C<spliceList(OFFSET, LENGTH, REPLACEMENT)>

Perl only (for now)

Like splice, replaces LENGTH Elements from OFFSET with REPLACEMENT, returns the replaced Elements.

REPLACEMENT is another C<Data::Sofu::List>
	
	my $lib = new Data::Sofu::List(Data::Sofu::Value->new("."),Data::Sofu::Value->new(".."),Data::Sofu::Value->new("../lib"));
	$inc->spliceList(2,0,$lib);
		# Inserts the list $lib after the second Element.

=cut

sub spliceList {
	my $self=shift;
	my $off=shift;
	my $len=shift;
	my $rep=shift;
	return CORE::splice(@{$self->{List}},$off,$len,$rep->asArray());
}

=head2 appendElement(ELEMENT)

Appends one (or multiple (Perl only)) ELEMENT to the end of this List.

	$inc->appendElement(Data::Sofu::Value->new("lib/"));

=cut

sub appendElement {
	my $self=shift;
	local $_;
	push @{$self->{List}},map {Data::Sofu::Object->new($_)} @_;
}

=head2 firstElement()

Perl only (for now)

Removes and returns the first Element of this List

=cut

sub firstElement {
	my $self=shift;
	return shift @{$self->{List}};
}

=head2 lastElement()

Perl only (for now)

Removes and returns the last Element of this List

=cut

sub lastElement {
	my $self=shift;
	return pop @{$self->{List}};
}


=head2 insertElement(ELEMENT)

Perl only (for now)

Appends one (or multiple (Perl only)) ELEMENT to the front of this List.

	$inc->insertElement(Data::Sofu::Value->new("lib/"));

=cut

sub insertElement {
	my $self=shift;
	local $_;
	unshift @{$self->{List}},map {Data::Sofu::Object->new($_)} @_;
}

=head2 appendList(LIST)

Perl only (for now)

Appends another LIST to the end of this List.

	my $lib = new Data::Sofu::List(Data::Sofu::Value->new("."),Data::Sofu::Value->new(".."),Data::Sofu::Value->new("../lib"));
	$inc->appendList($lib);

=cut

sub appendList {
	my $self=shift;
	my $other=shift;
	push @{$self->{List}},$other->asArray();

}

=head2 insertList(LIST)

Perl only (for now)

Appends another LIST to the front of this List.

	my $lib = new Data::Sofu::List(Data::Sofu::Value->new("."),Data::Sofu::Value->new(".."),Data::Sofu::Value->new("../lib"));
	$inc->insertList($lib);

=cut

sub insertList {
	my $self=shift;
	my $other=shift;
	unshift @{$self->{List}},$other->asArray();

}

=head2 elementIndex(VALUE) 

Returns the index of the first Element that machtes VALUE

=cut

sub elementIndex {
	my $self=shift;
	my $o = shift;
	for (my $i=0; $i<@{$self->{List}};$i++) {
		return $i if $self->{List}->[$i] eq $o;
	}
	return undef;
}

=head2 clear(VALUE)

Perl only (for now)

Empties this list

=cut

sub clear {
	my $self=shift;
	$self->{List}=[];
}

=head2

Perl only (for now)

Returns the length of this List.

Note: The index of the last element is length-1!

=cut

sub length {
	my $self=shift;
	return scalar @{$self->{List}};
}


=head2 opApply()

Takes a Subroutine and iterates with it over this List. Values can't be modified.

The Subroutine takes one Argument: The Value.

	$inc->opApply(sub {
		print "Element = $_[0]->asValue->toString(),"\n";
	});

Note: The Values are Objects, so they still can be changed, but not replaced.

=cut

sub opApply {
	my $self=shift;
	my $code=shift;
	croak("opApply needs a Code Reference") unless ref $code and lc ref $code eq "code";
	foreach my $e (@{$self->{Map}}) { 
		my $element=$e;
		$code->($element);
	}
}


=head2 opApplyDeluxe()

Perl only.

Takes a Subroutine and iterates with it over this List. Values can be modified.

The Subroutine takes one Argument: The Value.

	$inc->opApplyDeluxe(sub {
		$_[0]=Data::Sofu::List(split /\//,$_[0]->asValue()->toString());
	});


Note: Please make sure every replaced Value is a C<Data::Sofu::Object> or inherits from it.

=cut

sub opApplyDeluxe {
	my $self=shift;
	my $code=shift;
	croak("opApplyDeluxe needs a Code Reference") unless ref $code and lc ref $code eq "code";
	foreach my $e (@{$self->{Map}}) { 
		$code->($e);
	}
}

=head2 storeComment(TREE,COMMENT) 

Stores a comment in the Object if TREE is empty, otherwise it propagades the Comment to all its Elements

Should not be called directly, use importComments() instead.

=cut

sub storeComment {
	my $self=shift;
	my $tree=shift;
	my $comment=shift;
	#print "Tree = $tree, Comment = @{$comment}\n";
	if ($tree eq "") {
		$self->{Comment}=$comment;
	}
	else {
		my ($value,$tree) = split(/\-\>/,$tree,2);
		#$value=Sofukeyunescape($value);
		$self->{List}->[$value]->storeComment($tree,$comment);
	}

}

=head2 C<stringify(LEVEL, TREE)>

Returns a string representing this List and all its elements.

Runs string(LEVEL+1,TREE+index) on all its elements.

=cut


sub stringify {
	my $self=shift;
	my $level=shift;
	my $tree=shift;
	$level-=1 if $level < 0;
	my $str="";
	$str="Value = " unless $level;
	$str.="(";
	$str.=$self->stringComment();
	$str.="\n";
	my $i=0;
	foreach my $elem (@{$self->{List}}) {
		$str.=$self->indent($level);
		$str.=$elem->string($level+1,$tree."->".$i++);
	}
	$str.=$self->indent($level-1) if $level > 1;
	$str.=")\n";
	return $str;
}

=head2 C<binarify(TREE,BINARY DRIVER)>

Returns the binary version of this List and all its elements using the BINARY DRIVER. Don't call this one, use binaryPack instead.

=cut


sub binarify {
	my $self=shift;
	my $tree=shift;
	my $bin=shift;
	my $str=$bin->packType(2);
	$str.=$self->packComment($bin);
	$str.=$bin->packLong(scalar @{$self->{List}});
	my $i=0;
	foreach my $elem (@{$self->{List}}) {
		$str.=$elem->binary("$tree->".$i++,$bin);
	}
	return $str;
}

=head1 BUGS

Some Methods here are not included in Sofud, but they should be so their name might change (Old ones will be preserved)

=head1 SEE ALSO

L<Data::Sofu>, L<Data::Sofu::Binary>, L<Data::Sofu::Object>, L<Data::Sofu::Map>, L<Data::Sofu::Value>, L<Data::Sofu::Undefined>, L<http://sofu.sf.net>

=cut 

1;
