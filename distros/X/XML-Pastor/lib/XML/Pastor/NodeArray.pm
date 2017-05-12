use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);


#========================================================
package XML::Pastor::NodeArray;
use Data::HashArray;
our @ISA = qw(Data::HashArray);

use vars qw($VERSION);
$VERSION	= '1.0.1';

1;


__END__


=head1 NAME

B<XML::Pastor::NodeArray> - An array class of hashes that has magical properties via overloading and AUTOLOAD. 

=head1 ISA

This class is a simple wrapper around L<Data::HashArray> 

=head1 SYNOPSIS

  # please see the documentation of Data::HashArray  

=head1 DESCRIPTION

B<XML::Pastor::NodeArray> is an array class that is used for element multiplicity in L<XML::Pastor>. 

Normally, B<XML::Pastor::NodeArray> is an array of hashes or hash-based objects. This class has some magical properties
that make it easier to deal with multiplicity. 

B<XML::Pastor::NodeArray> is a simple wrapper around the generic class L<Data::HashArray>. Please see the documentation of
L<Data::HashArray> for more details.


=head1 BUGS & CAVEATS

There no known bugs at this time, but this doesn't mean there are aren't any. 
Note that, although some testing was done prior to releasing the module, this should still be considered alpha code. 
So use it at your own risk.

Note that there may be other bugs or limitations that the author is not aware of.

=head1 AUTHOR

Ayhan Ulusoy <dev(at)ulusoy(dot)name>


=head1 COPYRIGHT

  Copyright (C) 2006-2008 Ayhan Ulusoy. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

See also L<Data::HashArray>, L<XML::Pastor>, L<XML::Pastor::ComplexType>


=cut
