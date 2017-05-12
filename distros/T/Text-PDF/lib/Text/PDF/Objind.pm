package Text::PDF::Objind;

=head1 NAME

Text::PDF::Objind - PDF indirect object reference. Also acts as an abstract
superclass for all elements in a PDF file.

=head1 INSTANCE VARIABLES

Instance variables differ from content variables in that they all start with
a space.

=over

=item parent

For an object which is a reference to an object in some source, this holds the
reference to the source object, so that should the reference have to be
de-referenced, then we know where to go and get the info.

=item objnum (R)

The object number in the source (only for object references)

=item objgen (R)

The object generation in the source

There are other instance variables which are used by the parent for file control.

=item isfree

This marks whether the object is in the free list and available for re-use as
another object elsewhere in the file.

=item nextfree

Holds a direct reference to the next free object in the free list.

=back

=head1 METHODS

=cut

use strict;
use vars qw(@inst %inst $uidc);
# no warnings qw(uninitialized);

# protected keys during emptying and copying, etc.

@inst = qw(parent objnum objgen isfree nextfree uid);
map {$inst{" $_"} = 1} @inst;
$uidc = "pdfuid000";


=head2 Text::PDF::Objind->new()

Creates a new indirect object

=cut

sub new
{
    my ($class) = @_;
    my ($self) = {};

    bless $self, ref $class || $class;
}

=head2 uid

Returns a Unique id for this object, creating one if it didn't have one before

=cut

sub uid
{ $_[0]->{' uid'} || ($_[0]->{' uid'} = $uidc++); }

=head2 $r->release

Releases ALL of the memory used by this indirect object, and all of its
component/child objects.  This method is called automatically by
'C<Text::PDF::File-E<gt>release>' (so you don't have to call it yourself).

B<NOTE>, that it is important that this method get called at some point prior
to the actual destruction of the object.  Internally, PDF files have an
enormous amount of cross-references and this causes circular references within
our own internal data structures.  Calling 'C<release()>' forces these circular
references to be cleaned up and the entire internal data structure purged.

B<Developer note:> As part of the brute-force cleanup done here, this method
will throw a warning message whenever unexpected key values are found within
the C<Text::PDF::Objind> object.  This is done to help ensure that unexpected
and unfreed values are brought to your attention, so you can bug us to keep the
module updated properly; otherwise the potential for memory leaks due to
dangling circular references will exist.

=cut

sub release
{
    my ($self, $force) = @_;
    my (@tofree);

# delete stuff that we know we can, here

    if ($force)
    {
        foreach my $key (keys %{$self})
        {
            push(@tofree,$self->{$key});
            $self->{$key}=undef;
            delete($self->{$key});
        }
    }
    else
    {  @tofree = map { delete $self->{$_} } keys %{$self}; }

    while (my $item = shift @tofree)
    {
        my $ref = ref($item);
        if (UNIVERSAL::can($ref, 'release'))        # $ref was $item
        { $item->release($force); }
        elsif ($ref eq 'ARRAY')
        { push( @tofree, @{$item} ); }
        elsif (UNIVERSAL::isa($ref, 'HASH'))
        { release($item, $force); }
    }

# check that everything has gone - it better had!
    foreach my $key (keys %{$self})
    { warn ref($self) . " still has '$key' key left after release.\n"; }
}


=head2 $r->val

Returns the val of this object or reads the object and then returns its value.

Note that all direct subclasses *must* make their own versions of this subroutine
otherwise we could be in for a very deep loop!

=cut

sub val
{
    my ($self) = @_;
    
    $self->{' parent'}->read_obj(@_)->val unless ($self->{' realised'});
}

=head2 $r->realise

Makes sure that the object is fully read in, etc.

=cut

sub realise
{ $_[0]->{' realised'} ? $_[0] : $_[0]->{' parent'}->read_obj(@_); }

=head2 $r->outobjdeep($fh, $pdf)

If you really want to output this object, then you must need to read it first.
This also means that all direct subclasses must subclass this method or loop forever!

=cut

sub outobjdeep
{
    my ($self, $fh, $pdf, %opts) = @_;

    $self->{' parent'}->read_obj($self)->outobjdeep($fh, $pdf) unless ($self->{' realised'});
}


=head2 $r->outobj($fh)

If this is a full object then outputs a reference to the object, otherwise calls
outobjdeep to output the contents of the object at this point.

=cut

sub outobj
{
    my ($self, $fh, $pdf, %opts) = @_;

    if (defined $pdf->{' objects'}{$self->uid})
    { $fh->printf("%d %d R", @{$pdf->{' objects'}{$self->uid}}[0..1]); }
    else
    { $self->outobjdeep($fh, $pdf, %opts); }
}


=head2 $r->elementsof

Abstract superclass function filler. Returns self here but should return
something more useful if an array.

=cut

sub elementsof
{
    my ($self) = @_;

    if ($self->{' realised'})
    { return ($self); }
    else
    { return $self->{' parent'}->read_obj($self)->elementsof; }
}


=head2 $r->empty

Empties all content from this object to free up memory or to be read to pass
the object into the free list. Simplistically undefs all instance variables
other than object number and generation.

=cut

sub empty
{
    my ($self) = @_;
    my ($k);

    for $k (keys %$self)
    { undef $self->{$k} unless $self->dont_copy($k); }
    $self;
}


=head2 $r->merge($objind)

This merges content information into an object reference place-holder.
This occurs when an object reference is read before the object definition
and the information in the read data needs to be merged into the object
place-holder

=cut

sub merge
{
    my ($self, $other) = @_;
    my ($k);

    for $k (keys %$other)
    { $self->{$k} = $other->{$k} unless $self->dont_copy($k); }
    $self->{' realised'} = 1;
    bless $self, ref($other);
}


=head2 $r->is_obj($pdf)

Returns whether this object is a full object with its own object number or
whether it is purely a sub-object. $pdf indicates which output file we are
concerned that the object is an object in.

=cut

sub is_obj
{ defined $_[1]->{' objects'}{$_[0]->uid}; }


=head2 $r->copy($inpdf, $res, $unique, $outpdf, %opts)

Returns a new copy of this object.

$inpdf gives the source pdf object for the object to be copied. $outpdf gives the
target pdf for the object to be copied into. $outpdf may be undefined. $res may be
defined in which case the object is copied into that object. $unique controls
recursion. if $unique is non zero then new objects are always created and recursion
always occurs. But each time recursion occurs, $unique is incremented. Thus is $unique
starts with a negative value it is possible to stop the recursion at a certain depth. Of
course for a positive value of $unique, recursion always occurs.

If $unique is 0 then recursion only occurs if $outpdf is not the same as $inpdf. In this
case, a cache is held in $outpdf to see whether a previous copy of the same object has
been made. If so, then that previous copy is returned otherwise a new object is made and
added to the cache and recursed into.  

Objects that are full objects with their own id numbers are correspondingly full objects
in the output pdf.

=cut

sub copy
{
    my ($self, $inpdf, $res, $unique, $outpdf, %opts) = @_;
    my ($k, $o);

    $outpdf = $inpdf unless $outpdf;
    $self->realise;
    unless (defined $res)
    {
        if ($outpdf eq $inpdf && !$unique)
        { return $self; }
        elsif (!$unique && defined $outpdf->{' copies'}{$self->uid})
        { return $outpdf->{' copies'}{$self->uid}; }

        $res = {};
        bless $res, ref($self);
    }

    if ($self->is_obj($inpdf) && ($unique || ($outpdf ne $inpdf && !defined $outpdf->{' copies'}{$self->uid})))
    {
        $outpdf->new_obj($res);
#        $outpdf->{' copies'}{$self->uid} = $res unless ($unique);
    }
        
    $res;
}



sub dont_copy
{ return $inst{$_[1]}; }

1;

