package WiX3;

use 5.008003;
use warnings;
use strict;

our $VERSION = '0.011';

1;                                     # Magic true value required at end of module

__END__

=begin readme text

WiX3 Version 0.011

=end readme

=for readme stop

=head1 NAME

WiX3 - Objects useful for generating Windows Installer XML files.

=head1 VERSION

This document describes WiX3 version 0.011

=for readme continue

=head1 DESCRIPTION

This distribution is designed to assist in writing XML files for Windows Installer XML
version 3.0, otherwise known as WiX.

Since Windows Installer, and therefore WiX, keeps track of each individual 
file, installers using it are more complicated than other installers.

This distribution, therefore contains Moose classes that represent different 
WiX tags to keep track of files, directories, etc.

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

This method of installation will install a current version of Module::Build 
if it is not already installed.
    
Alternatively, to install with Module::Build, you can use the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

	
=end readme

=for readme stop

=head1 SYNOPSIS

    # use WiX3;

This is a documentation-only module. Instead of this module, you'll be using 
specific classes in this distribution.

See those classes for documentation.

Things that apply to all classes are here.

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT
  
WiX3 requires no configuration files or environment variables.

=for readme continue

=head1 DEPENDENCIES

L<Moose|Moose>, L<Exception::Class|Exception::Class>, 
L<List::MoreUtils|List::MoreUtils>, L<Data::UUID|Data::UUID>, 
L<Params::Util|Params::Util>, L<MooseX::Singleton|MooseX::Singleton>,
L<MooseX::Types|MooseX::Types>, L<Regexp::Common|Regexp::Common>, and 
L<Readonly|Readonly>.

=head1 WARNING

This distribution is not nearly complete yet - it is still in an alpha state.

=for readme stop

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-wix3@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, L<Alien::WiX|Alien::WiX>

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=for readme continue

=head1 LICENCE AND COPYRIGHT

Copyright 2009, 2010, 2011 Curtis Jewell C<< <csjewell@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.1 itself. See L<perlartistic|perlartistic>.

=for readme stop

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
