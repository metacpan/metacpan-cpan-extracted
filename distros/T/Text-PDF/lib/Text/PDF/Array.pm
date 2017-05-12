package Text::PDF::Array;

use strict;
use vars qw(@ISA);
# no warnings qw(uninitialized);

use Text::PDF::Objind;
@ISA = qw(Text::PDF::Objind);

=head1 NAME

Text::PDF::Array - Corresponds to a PDF array. Inherits from L<PDF::Objind>

=head1 INSTANCE VARIABLES

This object is not an array but an associative array containing the array of
elements. Thus, there are special instance variables for an array object, beginning
with a space

=over

=item var

Contains the actual array of elements

=back

=head1 METHODS

=head2 PDF::Array->new($parent, @vals)

Creates an array with the given storage parent and an optional list of values to
initialise the array with.

=cut

sub new
{
    my ($class, @vals) = @_;
    my ($self);

    $self->{' val'} = [@vals];
    $self->{' realised'} = 1;
    bless $self, $class;
}


=head2 $a->outobjdeep($fh, $pdf)

Outputs an array as a PDF array to the given filehandle.

=cut

sub outobjdeep
{
    my ($self, $fh, $pdf, %opts) = @_;
    my ($obj);

    $fh->print("[ ");
    foreach $obj (@{$self->{' val'}})
    {
        $obj->outobj($fh, $pdf, %opts);
        $fh->print(" ");
    }
    $fh->print("]");
}


=head2 $a->removeobj($elem)

Removes all occurrences of an element from an array.

=cut

sub removeobj
{
    my ($self, $elem) = @_;

    $self->{' val'} = [grep($_ ne $elem, @{$self->{' val'}})];
}   


=head2 $a->elementsof

Returns a list of all the elements in the array. Notice that this is
not the array itself but the elements in the array.

=cut

sub elementsof
{ wantarray ? @{$_[0]->{' val'}} : scalar @{$_[0]->{' val'}}; }


=head2 $a->add_elements

Appends the given elements to the array. An element is only added if it
is defined.

=cut

sub add_elements
{
    my ($self) = shift;
    my ($e);

    foreach $e (@_)
    { push (@{$self->{' val'}}, $e) if defined $e; }
    $self;
}


=head2 $a->val

Returns the value of the array, this is a reference to the actual array
containing the elements.

=cut

sub val
{ $_[0]->{' val'}; }


=head2 $d->copy($inpdf, $res, $unique, $outpdf, %opts)

Copies an object. See Text::PDF::Objind::Copy() for details

=cut

sub copy
{
    my ($self, $inpdf, $res, $unique, $outpdf, %opts) = @_;
    my ($i, $path);

    $res = $self->SUPER::copy($inpdf, $res, $unique, $outpdf, %opts);
    $res->{' val'} = [];
    $path = delete $opts{'path'};
    for ($i = 0; $i < scalar @{$self->{' val'}}; $i++)
    {
        if (UNIVERSAL::can($self->{'val'}[$i], "is_obj") && !grep {"$path\[$i\]" =~ m|$_|} @{$opts{'clip'}})
        { push (@{$res->{' val'}}, $self->{' val'}[$i]->realise->copy($inpdf, undef, $unique ? $unique + 1 : 0,
                        $outpdf, %opts, 'path' => "$path\[$i\]")); }
        else
        { push (@{$res->{' val'}}, $self->{' val'}[$i]); }
    }
    $res->{' realised'} = 1;
    $res;
}

1;


