# 
# This file is part of Tk-Sugar
# 
# This software is copyright (c) 2009 by Jerome Quelin.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 
use 5.008;
use strict;
use warnings;

package Tk::Sugar;
our $VERSION = '1.093190';


# ABSTRACT: Sugar syntax for Tk

use Sub::Exporter -setup => {
    exports => [ qw{
        top bottom left right
        fillx filly fill2 xfillx xfilly xfill2 expand
        pad pad1 pad2 pad5 pad10 pad20 padx pady
        ipad ipad1 ipad2 ipad5 ipad10 ipad20 ipadx ipady
        enabled disabled
        N S E W C NE NW SE SW
        horizontal vertical
    } ],
    groups  => {
        fill    => [ qw{ fillx filly fill2 xfillx xfilly xfill2 expand } ],
        side    => [ qw{ top bottom left right } ],
        pad     => [ qw{ pad pad1 pad2 pad5 pad10 pad20 padx pady } ],
        ipad    => [ qw{ ipad ipad1 ipad2 ipad5 ipad10 ipad20 ipadx ipady } ],
        pack    => [ qw{ -fill -side -pad -ipad } ],
        state   => [ qw{ enabled disabled } ],
        anchor  => [ qw{ N S E W C NE NW SE SW } ],
        orient  => [ qw{ horizontal vertical } ],
        options => [ qw{ -state -anchor -orient } ],
        default => [ qw{ -pack -options } ],
    }
};

## no critic (ProhibitSubroutinePrototypes)

# -- pack options
# cf perldoc Tk::pack for more information

# pack sides
sub top    () { return ( -side => 'top'    ); }
sub bottom () { return ( -side => 'bottom' ); }
sub left   () { return ( -side => 'left'   ); }
sub right  () { return ( -side => 'right'  ); }

# pack fill / expand
sub fillx  () { return ( -fill => 'x'    ); }
sub filly  () { return ( -fill => 'y'    ); }
sub fill2  () { return ( -fill => 'both' ); }
sub xfillx () { return ( -expand => 1, -fill => 'x'    ); }
sub xfilly () { return ( -expand => 1, -fill => 'y'    ); }
sub xfill2 () { return ( -expand => 1, -fill => 'both' ); }
sub expand () { return ( -expand => 1 ); }

# padding
sub pad1  () { return ( -padx => 1,  -pady => 1  ); }
sub pad2  () { return ( -padx => 2,  -pady => 2  ); }
sub pad5  () { return ( -padx => 5,  -pady => 5  ); }
sub pad10 () { return ( -padx => 10, -pady => 10 ); }
sub pad20 () { return ( -padx => 20, -pady => 20 ); }
sub pad  { my $n=shift; return ( -padx => $n, -pady => $n ); }
sub padx { my $n=shift; return ( -padx => $n ); }
sub pady { my $n=shift; return ( -pady => $n ); }

# internal padding
sub ipad1  () { return ( -ipadx => 1,  -ipady => 1  ); }
sub ipad2  () { return ( -ipadx => 2,  -ipady => 2  ); }
sub ipad5  () { return ( -ipadx => 5,  -ipady => 5  ); }
sub ipad10 () { return ( -ipadx => 10, -ipady => 10 ); }
sub ipad20 () { return ( -ipadx => 20, -ipady => 20 ); }
sub ipad  { my $n=shift; return ( -ipadx => $n, -ipady => $n ); }
sub ipadx { my $n=shift; return ( -ipadx => $n ); }
sub ipady { my $n=shift; return ( -ipady => $n ); }


# -- common widget options
# cf perldoc Tk::options for more information

# widget state
sub enabled  () { return ( -state => 'normal'   ); }
sub disabled () { return ( -state => 'disabled' ); }

# anchor
sub N  () { return ( -anchor => 'n'      ); }
sub S  () { return ( -anchor => 's'      ); }
sub E  () { return ( -anchor => 'e'      ); }
sub W  () { return ( -anchor => 'w'      ); }
sub C  () { return ( -anchor => 'center' ); }
sub NE () { return ( -anchor => 'ne'     ); }
sub NW () { return ( -anchor => 'nw'     ); }
sub SE () { return ( -anchor => 'se'     ); }
sub SW () { return ( -anchor => 'sw'     ); }

# orientation
sub horizontal () { return ( -orient => 'horizontal' ); }
sub vertical   () { return ( -orient => 'vertical' ); }



1;


=pod

=head1 NAME

Tk::Sugar - Sugar syntax for Tk

=head1 VERSION

version 1.093190

=head1 SYNOPSIS

    use Tk::Sugar qw{ :pack :state };

    $widget->pack( top, xfill2, pad10 );
    # equivalent to those pack options:
    #     -side   => 'top'
    #     -expand => 1
    #     -fill   => 'both'
    #     -padx   => 10
    #     -pady   => 10

    $widget->configure( enabled );
    # equivalent to: -state => 'enabled'

=head1 DESCRIPTION

L<Tk> is a great graphical toolkit to write desktop applications.
However, one can get bothered with the constant typing of quotes and
options. L<Tk::Sugar> provides handy subs for common options used when
programming Tk.

Benefits are obvious:

=over 4

=item * Reduced typing.

The constant need to type C<< => >> and C<''> is fine for one-off cases,
but the instant you start using Tk it starts to get annoying.

=item * More compact statements.

Reduces much of the redundant typing in most cases, which makes your
life easier, and makes it take up less visual space, which makes it
faster to read.

=item * No string worries.

Strings are often problematic, since they aren't checked at compile-
time. Sometimes it makes spotting an error a difficult task. Using this
alleviates that worry.

=back

=head1 EXPORTS

This module is using L<Sub::Exporter> underneath, so you can use all its
shenanigans to change the export names.

=head2 Exported subs

Look below for the list of available subs.

=head3 Pack options

Traditional packer sides (available as C<:side> export group):

=over 4

=item * top - equivalent to C<< ( -side => 'top' ) >>

=item * bottom - ditto for C<bottom>

=item * left - ditto for C<left>

=item * right - ditto for C<right>

=back

Packer expand and filling (available as C<:fill> export group):

=over 4

=item * fillx - equivalent to C<< ( -fill => 'x' ) >>

=item * filly - equivalent to C<< ( -fill => 'y' ) >>

=item * fill2 - equivalent to C<< ( -fill => 'both' ) >>

=item * xfillx - same as C<fillx> with C<< ( -expand => 1 ) >>

=item * xfilly - ditto for C<filly>

=item * xfill2 - ditto for C<fill2>

=item * expand - equivalent to C<< ( -expand => 1 ) >> if you don't like
the C<xfill*> notation

=back

Packer padding (available as C<:pad> export group):

=over 4

=item * pad1 - equivalent to C<< ( -padx => 1, -pady => 1 ) >>

=item * pad2 - ditto with 2 pixels

=item * pad5 - ditto with 5 pixels

=item * pad10 - ditto with 10 pixels

=item * pad20 - ditto with 20 pixels

=item * pad($n) - ditto with $n pixels (function call with one argument)

=item * padx($n) - x padding with $n pixels (function call with one argument)

=item * pady($n) - y padding with $n pixels (function call with one argument)

=back

Packer padding (available as C<:ipad> export group):

=over 4

=item * ipad1 - equivalent to C<< ( -ipadx => 1, -ipady => 1 ) >>

=item * ipad2 - ditto with 2 pixels

=item * ipad5 - ditto with 5 pixels

=item * ipad10 - ditto with 10 pixels

=item * ipad20 - ditto with 20 pixels

=item * ipad($n) - ditto with $n pixels (function call with one argument)

=item * ipadx($n) - internal x padding with $n pixels (function call
with one argument)

=item * ipady($n) - internal y padding with $n pixels (function call
with one argument)

=back

=head3 Common options

Widget state (available as C<:state> export group):

=over 4

=item * enabled - equivalent to C<< ( -state => 'normal' ) >>

=item * disabled - ditto for C<disabled>

=back

Widget anchor (available as C<:anchor> export group). Note that those
subs are upper case, otherwise the sub C<s> would clash with the regex
substitution:

=over 4

=item * N - equivalent to C<< ( -anchor => 'n' ) >>

=item * S - ditto with C<s>

=item * E - ditto with C<e>

=item * W - ditto with C<w>

=item * C - ditto with C<center>

=item * NE - ditto with C<ne>

=item * NW - ditto with C<nw>

=item * SE - ditto with C<se>

=item * SW - ditto with C<sw>

=back

Widget orientation (available as C<:orient> export group).:

=over 4

=item * horizontal - equivalent to C<< ( -orient => 'horizontal' ) >>

=item * vertical - ditto with C<vertical>

=back

=head2 Export groups

Beside the individual groups outlined above, the following export groups
exist for your convenience:

=over 4

=item :default

This exports all existing subs.

=item :pack

This exports subs related to L<Tk::pack> options. Same as C<:side>,
C<:fill>, C<:pad> and C<:ipad>.

=item :options

This exports subs related to widget configure options. Same as
C<:state>, C<:anchor> and C<:orient>.

=back

=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-Sugar/>

=item * Open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-Sugar>

=item * Git repository

L<http://github.com/jquelin/tk-sugar.git>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-Sugar>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-Sugar>

=back

=head1 AUTHOR

  Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__