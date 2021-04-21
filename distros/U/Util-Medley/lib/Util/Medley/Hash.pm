package Util::Medley::Hash;
$Util::Medley::Hash::VERSION = '0.059';
#########################################################################################

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka ('multi', 'method');
use Data::Printer alias => 'pdump';
use Hash::Merge;

=head1 NAME

Util::Medley::Hash - utility methods for working with hashes

=head1 VERSION

version 0.059

=cut

=head1 SYNOPSIS
  
  $bool = $util->isHash(\%h);
  $bool = $util->isHash(ref => \%h);
 
=cut

#########################################################################################

=head1 METHODS

=head2 isHash

Checks if the scalar value passed in is a hash.

=over

=item usage:

  $bool = $util->isHash(\%h);

  $bool = $util->isHash(ref => \%h);
   
=item args:

=over

=item ref [Any]

The scalar value you wish to check.

=back

=back
 
=cut

multi method isHash (Any :$ref!) {
    
    if (defined $ref) {
        if (ref($ref) eq 'HASH') {
            return 1;	
        }	
    }	
    
    return 0;
}

multi method isHash (Any $ref!) {
    
    return $self->isHash(ref => $ref);	
}



=head2 merge

Merge two hashrefs.  Pass-through to Hash::Merge.

=over

=item usage:

  $href = $util->merge(\%left, \%right, [$precedent]);

  $href = $util->merge(left       => \%left,
                       right      => \%right,
                       [precedent => $precedent]);
   
=item args:

=over

=item left [HashRef]

The left hashref.

=item right [HashRef]

The right hashref.

=item precedent [Str] (optional)

Inidcates which hashref should take precendence over the other.

Valid values: LEFT, RIGHT

Default: LEFT

=back

=back
 
=cut

multi method merge (HashRef :$left!,
                    HashRef :$right!,
                    Str     :$precedent = 'LEFT') {

    $precedent = uc($precedent);
    
    if ($precedent eq 'LEFT') {
        $precedent = 'LEFT_PRECEDENT';
    }
    elsif ($precedent eq 'RIGHT') {
        $precedent = 'RIGHT_PRECEDENT';
    }
    else {
        confess "invalid precedent: $precedent"; 	
    }
    
    my $hashMerge  = Hash::Merge->new($precedent);
    my $mergedHref = $hashMerge->merge( $left, $right);
    
    return $mergedHref;
}

multi method merge (HashRef $left!,
                    HashRef $right!,
                    Str     $precedent?) {

    my %args = (left => $left, right => $right);
    $args{precedent} = $precedent if $precedent;
   
    return $self->merge(%args); 
}

                    
__PACKAGE__->meta->make_immutable;

1;
