package Wiki::Toolkit::Formatter::MultiMarkdown;
use Mouse;
use Text::MultiMarkdown;

extends qw(Wiki::Toolkit::Formatter::Markdown);

has markdown => (
    isa        => 'Text::MultiMarkdown',
    is         => 'ro',
    lazy_build => 1,
    handles    => { format => 'markdown' },
);

sub _build_markdown { Text::MultiMarkdown->new( $_[0]->args ) }

1;

no Mouse;  # unimport Moose's keywords so they won't accidentally become methods
1;         # Magic true value required at end of module
__END__

=head1 NAME

Wiki::Toolkit::Formatter::Markdown - A Markdown Formatter for Wiki::Toolkit wikis.


=head1 VERSION

This document describes Wiki::Toolkit::Formatter::Markdown version 0.0.1


=head1 SYNOPSIS

    use Wiki::Toolkit::Formatter::Markdown;
    my $store     = Wiki::Toolkit::Store::SQLite->new( ... );
    my $formatter = Wiki::Toolkit::Formatter::Markdown->new( );
    my $wiki      = Wiki::Toolkit->new( store     => $store,
                                        formatter => $formatter );
    
  
  
=head1 DESCRIPTION

A formatter backend for L<Wiki::Toolkit> using  L<Text::Markdown>.

=head1 METHODS 

=over 4

=item new (Hash|HashRef)

Create a new Wiki::Toolkit::Formatter::Markdown, takes exactly two parameters

=over 4 

=item args (HashRef)

Arguments passed to the Text::Markdown object

=item markdown (Text::Markdown)

You can supply your own Text::Markdown object. This must be a subclass of Text::Markdown.

=back

=item format (Str)

Will take a string of Markdown formatted text, and return the HTML transformation.

=back 

=head1 CONFIGURATION AND ENVIRONMENT

Wiki::Toolkit::Formatter::Markdown requires no configuration files or environment variables.

=head1 DEPENDENCIES

Mouse, Text::WikiFormat

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-wiki-toolkit-formatter-markdown@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Chris Prather  C<< <perigrin@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Chris Prather C<< <perigrin@cpan.org> >>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


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
