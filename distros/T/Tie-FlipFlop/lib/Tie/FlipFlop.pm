package Tie::FlipFlop;

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';


our $VERSION = '2009110701';


sub TIESCALAR {
    my $class = shift;
    do {require Carp;
        Carp::croak ("Incorrect number of arguments");
    } unless 2 == @_;
    bless [reverse @_] => $class;
}

sub FETCH     {
    my $state = shift;
     (@$state = reverse @$state) [0]
}

sub STORE     {
    require Carp;
    Carp::croak ("Cannot modify read only variable");
}


1;


__END__

=pod

=head1 NAME

Tie::FlipFlop - Alternate between two values.

=head1 SYNOPSIS

    use Tie::FlipFlop;

    tie my $flipflop => Tie::FlipFlop => qw /Red Green/;

    print  $flipflop;      # Prints 'Red'.
    print  $flipflop;      # Prints 'Green'.
    print  $flipflop;      # Prints 'Red'.

=head1 DESCRIPTION

C<Tie::FlipFlop> allows you to tie a scalar in such a way that refering to
the scalar alternates between two values. When tying the scalar, exactly
two extra arguments have to be given, the values to be alternated between.

Assigning to the scalar leads to a fatal, but trappable, error.

=head1 DEVELOPMENT
 
The current sources of this module are found on github,
L<< git://github.com/Abigail/tie--flipflop.git >>.

=head1 AUTHOR
    
Abigail L<< <cpan@abigail.be> >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 1999, 2009 by Abigail

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
