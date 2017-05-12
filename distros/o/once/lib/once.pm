use 5.008;
use strict;
use warnings;

package once;
BEGIN {
  $once::VERSION = '1.101420';
}

# ABSTRACT: Execute code only once throughout the program's lifetime
use Exporter qw(import);
our @EXPORT  = qw(ONCE);

sub ONCE (&) {
    my $code = shift;
    our %seen;
    my ($package, $filename, $line) = caller;
    unless ($seen{"ONCE $package $filename $line"}++) {
        $code->();
    }
}
1;


__END__
=pod

=head1 NAME

once - Execute code only once throughout the program's lifetime

=head1 VERSION

version 1.101420

=head1 SYNOPSIS

    use once;

    sub setup {
        my $self = shift;
        ONCE {
            print "run only once however often setup() is called"
        };
        # other_things();
    }

=head1 DESCRIPTION

This module provides a way to run code only once, no matter how often the
surrounding code is called.

=head1 METHODS

=head2 ONCE

This subroutine is exported automatically. It takes a code block and executes
it only the first time that this specific call of C<ONCE> is encountered. This
might be useful, for example, in a situation where you initialize an object but
only want to do it the first time any object of that class is initialized,
perhaps to install methods or setup some other data.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=once>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/once/>.

The development version lives at
L<http://github.com/hanekomu/once/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

