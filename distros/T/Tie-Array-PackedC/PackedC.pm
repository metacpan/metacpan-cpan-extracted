package Tie::Array::PackedC;
use constant ALLOC=>1024;
use constant PACK=>'l!*';
no warnings;
use constant NULL=>pack PACK,"";
use constant SIZE=>length NULL;
use base qw(Tie::Array);
use strict;
use warnings;
our $DEBUG;

sub import {
	if (@_>1 and $_[1]=~/[A-Z]/ and $_[0] eq __PACKAGE__) {
		my ($class,$name,$format,%args)=@_;
		$format.="*" unless $format=~/\*$/;
		my $new=$class."::".$name;
                open my $f,"<",__FILE__ or die __FILE__ . "$!";
		local $_=do {local $/="\n__END__\n"; scalar <$f>};
		close $f;
		s/(?<=package )\w+(::\w+)*;/$new;/;
		s/(?<=PACK)\s*=>'.+';/=>'$format';/;
		s/(?<=ALLOC)\s*=>.+;/=>$args{ALLOC};/ if $args{ALLOC};
		s/(?<=SIZE)\s*=>.+;/=>$args{SIZE};/ if $args{SIZE};
		eval "no warnings; $_";
		warn $_ if $args{DEBUG};
		$@ and die "Failed to build package $new!\n$@\n$_"
	} else {
		__PACKAGE__->export_to_level(1,@_);
	}
}


our @ISA=qw(Exporter);
our $VERSION=0.03;
our @EXPORT_OK=qw(packed_array packed_array_string $DEBUG);

my %count;
my %type;

sub packed_array {
	my (@a,$s);
	tie @a,__PACKAGE__,$s,@_;
	return \@a;
}

sub packed_array_string {
	my @a;
	tie @a,__PACKAGE__,@_;
	return \@a;
}


sub string     { return substr ${$_[0]},0,$count{$_[0]}*SIZE };

sub trim       {
                 #printf STDERR "%d %d %d\n",$count{$_[0]},$count{$_[0]}*SIZE,length(${$_[0]});
                 substr ${$_[0]}, $count{$_[0]}*SIZE, length(${$_[0]}) - ($count{$_[0]}*SIZE), "";
                 return $_[0];
               }

sub reallen    { return $count{$_[0]}*SIZE };

sub hex_dump {
	my @words=map { sprintf "%02x " x SIZE,unpack "C*",pack PACK,$_; }  unpack PACK,${$_[0]};
	for (my $ofs=0;$ofs<@words;$ofs+=4) {
		printf "#%4d : %5d : %s\n",$ofs,$ofs*SIZE,join"| ",grep defined $_,@words[$ofs..$ofs+3]
	}
}


sub DESTROY {
	my $self=shift;
	delete $count{$self};
	delete $type{$self};
}

sub _alloc {
	my ($self,$size)=@_;
	return if $size<$count{$self};
	my $before=length($$self);
	$count{$self}=$size;
	my $alloc=int ($size * 1.2);
	$alloc+=ALLOC - ($alloc % ALLOC);
	$$self.=NULL x ( $alloc - length($$self)/SIZE );
	my $after=length($$self);
	warn "Resize. Reallen:".$self->reallen()." Len: $before -> $after\n" if $DEBUG;
	$self;
}


sub TIEARRAY {
	my ($class,$str,@args)=@_;
	my $strref=@_>1 ? \$_[1] : \do{my $x};
	$$strref="" unless defined $$strref;
	my $self=bless $strref,$class;


	length($$strref) % SIZE and Carp::confess <<BAD_LENGTH;
Initialized with bad string length! Expecting multiples of @{[SIZE]} bytes,
got @{[length($$strref) % SIZE]} bytes extra.
BAD_LENGTH
	$count{$self}=int length($$strref)/SIZE;
	#preallocate a chunk of memory
	$self->_alloc(scalar @args);
	substr($$self,0,@args*SIZE,pack(PACK,@args));
	$self;
}

sub FETCH {
	my ($s,$o)=@_;
	return undef if $o>=$count{$s};
	return unpack(PACK,substr($$s,$o * SIZE,SIZE));
}

sub STORE {
	my ($s,$o,$v)=@_;
	$s->_alloc($o+1) if length($$s)<($o+1)*SIZE;
	$count{$s}=$o+1 if $count{$s}<=$o;
	substr($$s,$o * SIZE,SIZE)=pack(PACK,$v);
	$v
}

sub FETCHSIZE {$count{shift(@_)}}

sub STORESIZE {
	my ($s,$l)=@_;
	#print "STORESIZE $l\n";
	$s->_alloc($l+1);
	substr($$s,int($l*SIZE/ALLOC+1)*ALLOC)='';
	$s
}

sub EXTEND {
	my ($s,$l)=@_;
	$s->STORESIZE($l);
}

sub POP{
	my ($s)=@_;
	length($$s) ? unpack PACK,substr($$s,--$count{$s}*SIZE,SIZE,NULL) : undef
}

sub PUSH{
	my ($s,@args)=@_;
	return unless @args;
	my $tail=$count{$s}*SIZE;
	if (($count{$s}+@args)*SIZE>length($$s)) {
		$s->_alloc($count{$s}+@args);
	} else {
		$count{$s}+=@args;
	}
	substr($$s,$tail,@args*SIZE)=pack(PACK,@args);

}

sub CLEAR { ${$_[0]}=NULL x (ALLOC/SIZE); $count{$_[0]}=0 }

sub SHIFT {
	my ($s)=@_;
	length($$s) ? unpack PACK,substr($$s,0,SIZE,'') : undef
}
sub UNSHIFT {
	my ($s,@args)=@_;
	$$s=pack(PACK,@args).$$s;
}

sub EXISTS { $_[1] < $count{$_[0]}  }
sub DELETE {
	my ($s,$o)=@_;
	return unless $o < $count{$s};
	my $v=unpack PACK,substr($$s,$o * SIZE,SIZE);
	substr($$s,$o * SIZE,SIZE,NULL);
	return $v
}

#sub SPLICE {
#
#}

1;


__END__


=head1 NAME

Tie::Array::PackedC - Tie a Perl array to a C-style array (packed; elements of a
single, simple data type)

=head1 SYNOPSIS

  use Tie::Array::PackedC qw(packed_array packed_array_string);
  my $ref=packed_array(1,2,3,4);
  my $ref2=packed_array_string(my $s,1,2,3,4);

  use Tie::Array::PackedC Double=>'d';
  tie my @array,'Tie::Array::PackedC::Double',1..10;
  $array[0]=1.141;

=head1 DESCRIPTION

Provides a perl  array interface into  a string containing  a C style  array. In
other words the  string  is equivelent  to the  string  that would be   returned
from the equivelent  pack  command (defaulting to pack type "l!") using  a normal
array  of the same   values.
Eg:

  my @foo=(1..10);
  my $string=pack "l!*",@foo;

leaves $string in basically the same condition as

  my (@foo,$string);
  tie @foo,'Tie::Array::PackedC',$string,1..10;

Its only basically  the same and  not exactly the  same because the  tie version
may be longer due to preallocation.

=head2 USAGE

The basic usage is

  tie @array,'Tie::Array::PackedC',$string,@initialize;

This will tie @array to $string. So modifying the array will actually cause  the
string to change.  If $string is undef then it will automatically be set to  "",
otherwise the initial contents of the string will be untouched. (It will however
be extended according  to the preallocation  below.) Any values  @initialize are
treated as though an immediate

  @array[0..$#initilize]=@initialize;

occured.  This means that

  my ($s,@a)=pack "l!*",1..5;
  tie @a,'Tie::Array::PackedC',$s,reverse 1..4;

wil result in "@a" being "4 3 2 1 5".

If no $string  is provided then  an anonymous string  is used to  bind to.  This
string can be obtained by saying

  print tied(@a)->string;

B<Note> that the underlying object is  a blessed reference to the string  passed
in. The difference between saying

  ${tied(@a)}

and the string method is that the  former will return the string by copy and it
will be exactly the size of the array, the latter could be signifigantly  longer
due to preallocation.

There is also a utility method to dump the string/array in hex that is invoked
accordingly

  tied(@a)->hex_dump;

this dumps the full underlying string in hex bytes grouped according to the size
of the packed element, and is in the byte order as packed.

=head2 A NOTE ABOUT C<undef>

A  normal array  returns undef  when you  access an  element that  has not  been
explicitly stored to.  Arrays tied using  this class do  not behave in  the same
way. If an index is  within the size of the  array but has not been  assigned to
will return Tie::Array::PackedC::NULL a constant defined as the result of

  pack PACK,"";

Any index that is outside of the array will return undef as expected.

=head2 PREALLOCATION

In order to avoid having to extend the string too often a preallocation strategy
is used. This means that the underlying string is prefilled with a predetermined
number of items worth of NULL each time a STORE accesses an element not currently
mappable to the string. This allocation happens in terms of blocks which are  of
a size equal to a predetermined multiple of the size of each element. The number
elements added each time the array is  extended will be a multiple of the  block
size and will not be less than %20 of the current size.

B<NOTE> I  currently consider  the preallocation  mechanism to  be less  than it
should be and will most likely figure out a better way to do it later. Please do
not assume that the preallocation mechanism will stay the same.

=head2 CLASS FACTORY

The class uses a form of templating to provide a way to produce classes that are
just  as  fast  as the  current  version,  but use  different  pack  formats, or
allocation  block  size.  This is  done  at  compile time  by  a  special import
mechanism. This mechanism works like this:

  use Tie::Array::PackedC %Name% => %PackType%;

Where %Name% must match /[A-Z]/ and %PackType% is one of the pack formats.  (The
behaviour of the  class is only  well defined for  types that are  of fixed size
that are byte aligned.)

If the module is used as follows

  use Tie::Array::PackedC Double => 'd';

then a new class called  C<Tie::Array::PackedC::Double> is created that produces  a
tied array of packed doubles.  Thus the default implementation and usage

  use Tie::Array::PackedC;

is almost exactly equivelent to

  use Tie::Array::PackedC NativeLong => 'l!';

with the exceptions being its name and its import behaviour, the later of  which
is different in that it does not support the class factory import.

=head2 METHODs

=over 4

=item string()

Returns the string represnting the array. This is not necessarily the same as the
string passed into the array, which may be longer.

=item hex_dump()

Prints to STDOUT a hex dump of the underlying string.

=item trim()

Frees up any preallocated but unused memory. This is useful if you know
you will not be performing any more store operations on the string.

=back

=head2 PACKAGE CONSTANTS

The base package and each of the children it produces in factory mode have the following
constants defined, (adjust name accordingly)

=over 4

=item Tie::Array::PackedC::PACK

Returns the pack format used by the class. This will always have a * at the end, regardless
as to what was provided by the user.

=item Tie::Array::PackedC::SIZE

The number of bytes that a single element of PACK takes up.

=item Tie::Array::PackedC::ALLOC

Used by the preallocation system to determine chunk size of preallocation. Currently
the underlying string will always satisfy

  length($string) % Tie::Array::PackedC::ALLOC == 0

=back

These are not exportable, but they can be accessed by fully qualified name.

=head2 EXPORT

Normally Tie::Array::PackedC and  its produced classes  do not export.  However two
utility subroutines  are provided  which can  be exported  on request  using the
conventional syntax.

B<Note>  that  the class  factory  approach can  not  be mixed  with  the export
approach in the same use statement. However this means that you can do this:

  use Tie::Array::PackedC Double => 'd';
  use Tie::Array::PackedC::Double qw(packed_array);

and have the generated class export its utility subs.

=over 4

=item packed_array(LIST)

Returns a reference to an array tied to an anonymous string. The LIST is used to
initialize the array.

=item packed_array_string(STR, LIST)

Returns a reference to an array tied  to a string provided. The LIST is  used to
initialize the array.

=back

=head1 AUTHOR

demerphq, (yves at cpan dot org).

=head1 SEE ALSO

L<perl>, L<perltie>, and L<Tie::Array>

=head1 LICENCE

Released under the same terms as perl itself.

=cut





