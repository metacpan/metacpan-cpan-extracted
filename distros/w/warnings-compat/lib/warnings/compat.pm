package warnings::compat;
use strict;
use warnings;

{   no strict "vars";
    $VERSION = '0.07';
}

"experience Satoshi Kon's Paprika (great movie)"

__END__

=head1 NAME

warnings::compat - warnings.pm emulation for pre-5.6 Perls

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    use warnings::compat;


=head1 DESCRIPTION

This is a module to help writing portable programs and modules across recent
and old versions of Perl by providing a unique API to enable and disable
warnings. Under the hood, it will use the real C<warnings.pm> module when
available, or install and use an emulation compatible with Perl 5.000.
Therefore, C<use warnings::compat> should do the right thing on every Perl
version.

If you want this module to be automatically installed by the CPAN shell on
old Perls, simply add it to the prerequisites list in your F<Makefile.PL>:

    PREREQ_PM => {
        "warnings::compat"  => 0,
    }

Note that only the files needed for your version of Perl will be installed
(i.e., it won't install or overwrite the emulation modules on Perl 5.6
and later).

If you prefer to install it only on modern Perls, you can use this variant:

    # on pre-5.6 Perls, add warnings::compat to the prereq modules
    push @extra_prereqs, "warnings::compat"  if $] < 5.006;

    WriteMakefile(
        ...
        PREREQ_PM => {
            ...
            @extra_prereqs,
        },
    );


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< <sebastien at aperghis.net> >>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-warnings-compat at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=warnings-compat>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc warnings::compat

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/warnings-compat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/warnings-compat>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=warnings-compat>

=item * Search CPAN

L<http://search.cpan.org/dist/warnings-compat>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2006, 2007, 2008 SE<eacute>bastien Aperghis-Tramoni, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

