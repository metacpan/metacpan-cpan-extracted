package Text::PDF::Null;

=head1 NAME

Text::PDF::Null - PDF Null type object.  This is a subclass of
Text::PDF::Objind and cannot be subclassed.

=head1 METHODS

=cut
  
use strict;

use vars qw(@ISA);
@ISA = qw(Text::PDF::Objind);

# There is only one null object  (section 3.2.8).
my ($null_obj) = {};
bless $null_obj, "Text::PDF::Null";


=head2 Text::PDF::Null->new

Returns the null object.  There is only one null object.

=cut
  
sub new {
    return $null_obj;
}

=head2 $s->realise

Pretends to finish reading the object.

=cut

sub realise {
    return $null_obj;
}

=head2 $s->outobjdeep

Output the object in PDF format.

=cut

sub outobjdeep
{
    my ($self, $fh, $pdf) = @_;
    $fh->print ("null");
}

=head2 $s->is_obj

Returns false because null is not a full object.

=cut

sub is_obj {
    return 0;
}

=head2 $s->copy

Another no-op.

=cut
  
sub copy {
    return $null_obj;
}

=head2 $s->val

Return undef.

=cut
  
sub val
{
    return undef;
}

1;
