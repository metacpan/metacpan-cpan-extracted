package Util::Medley::List;
$Util::Medley::List::VERSION = '0.008';
#########################################################################################

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use List::Util;

=head1 NAME

Util::Medley::List - utility methods for working with lists

=head1 VERSION

version 0.008

=cut

=head1 SYNOPSIS

 %map = $util->listToMap(@list);
 %map = $util->listToMap(list => \@list);
 
 $min = $util->min(@list);
 $min = $util->min(list => \@list);
 
 $max = $util->max(@list);
 $max = $util->max(list => \@list);

 @list = $util->undefsToStrings(@list);
 @list = $util->undefsToStrings(list => \@list);

 @uniq = $util->uniq@list);
 @uniq = $util->uniq(list => \@list); 
 
=head1 DESCRIPTION

...

=cut

#########################################################################################

=head1 METHODS

=head2 listToMap

=over

=item usage:

  %map = $util->listToMap(@list);

  %map = $util->listToMap(list => \@list);
   
=item args:

=over

=item list [Array|ArrayRef]

The array you wish to convert to a hashmap.

=back

=back
 
=cut

multi method listToMap (@list) {

    my %map = map { $_ => 1 } @list;
    return %map;
}

multi method listToMap (ArrayRef :$list!) {

	return $self->listToMap(@$list);
}

=head1 min

Just a passthrough to List::Util::min()

=over

=item usage:

 $min = $util->min(@list);
 
 $min = $util->min(list => \@list);

=back
 
=cut

multi method min (@list) {

    return List::Util::min(@list);    
}

multi method min (ArrayRef :$list!) {

	return $self->min(@$list);	
}

=head1 max

Just a passthrough to List::Util::max()

=over

=item usage:

 $max = $util->max(@list);
 
 $max = $util->max(list => \@list);

=back
 
=cut

multi method max (@list) {

    return List::Util::max(@list);    
}

multi method max (ArrayRef :$list!) {

	return $self->max(@$list);	
}

=head2 undefsToStrings

=over

=item usage:

 %map = $util->undefsToStrings($list, [$string]);

 %map = $util->undefsToStrings(list => \@list, [string => $str]);
   
=item args:

=over

=item list [ArrayRef]

The list to act on.

=item string [Str]

What to convert undef items to.  Default is empty string ''.

=back

=back
 
=cut

multi method undefsToStrings (ArrayRef $list,
                              Str 	   $string = '') {

    my @return;
    foreach my $val (@$list) {
        $val = $string if !defined $val;
        push @return, $val;
    }

    return \@return;
}

multi method undefsToStrings (ArrayRef :$list!,
                              Str 	   :$string = '') {
                              	
	return $self->undefsToStrings($list, $string);                              	
}	


=head1 uniq

Just a proxy to List::Util::uniq().

=over

=item usage:

 @uniq = $util->uniq(@list);

 @uniq = $util->uniq(list => \@list);
   
=cut

multi method uniq (@list) {

    return List::Util::uniq(@list);    
}

multi method uniq (ArrayRef :$list!) {

	return $self->uniq(@$list);
}

1;
