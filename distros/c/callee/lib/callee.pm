use 5.008;
use strict;
use warnings;

package callee;
our $VERSION = '1.100820';
# ABSTRACT: support recursive anonymous functions
use Devel::Caller qw(caller_cv);
use Exporter qw(import);
our @EXPORT  = qw(callee);
sub callee { caller_cv(1) }
1;


__END__
=pod

=head1 NAME

callee - support recursive anonymous functions

=head1 VERSION

version 1.100820

=head1 SYNOPSIS

    use callee;

    my $f = sub {
        my $x = shift;
        return 1 if $x <= 1;
        $x * callee->($x-1);
    }->(5);

    # $f is 120

=head1 DESCRIPTION

This module exports one function, C<callee()>, which allows anonymous
functions to refer to themselves. This is necessary for recursive anonymous
functions. 

A recursive function must be able to refer to itself. Typically, a function
refers to itself by its name. However, an anonymous function does not have a
name, and if there is no accessible variable referring to it, i.e. the
function is not assigned to any variable, the function cannot refer to itself.
This is where C<callee> comes in.

This module is just very thin syntactic sugar for L<Devel::Caller>.

=head1 FUNCTIONS

=head2 callee

Returns a coderef to the function within which it is called.

=head1 SEE ALSO

Takesako-san wrote C<arguments.pm> - see
L<http://svn.coderepos.org/share/lang/perl/arguments/trunk/> - which does
practically the same thing; see also his blog entry (in Japanese):
L<http://d.hatena.ne.jp/TAKESAKO/20080501/1209637452>.

I released this module because C<arguments.pm> is not on CPAN, and because
Devel::Caller already existed on CPAN, but not with the syntax I wanted.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=callee>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/callee/>.

The development version lives at
L<http://github.com/hanekomu/callee/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

