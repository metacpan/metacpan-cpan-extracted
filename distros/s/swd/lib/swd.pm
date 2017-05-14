package swd;


our $VERSION = '0.01';

use strict;                                                                                                                                    
use Carp;
use Cwd qw(realpath chdir);

BEGIN {

        chdir join(q//, split(/.[^\/]+$/, realpath($0)))
                or croak "cannot chdir: $!\n";
}


1


__END__

=pod

=head1 NAME

swd - Perl pragma to change the current working directory 


=head1 SYNOPSIS

 use swd;


=head1 DESCRIPTION

The C<swd> pragma changes the current working directory($ENV{PWD}) to the directory
from which the called program is invoked; after callee returning the previous
state of $ENV{PWD} is restored.

 use swd;              # in the callee

 print "callee: $ENV{PWD}\n";
 print $_,$/ for glob'*';
 __END__


 qx/callee/;           # in the caller

 print "caller: $ENV{PWD}\n";
 print $_,$/ for glob'*';
 __END__


=head1 SEE ALSO

L<Cwd>


=head1 AUTHOR

Vidul Petrov, E<lt>vidul@cpan.orgE<gt>

=cut

