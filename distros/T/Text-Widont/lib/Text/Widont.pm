package Text::Widont;

use strict;
use warnings;

use Carp qw( croak );

our $VERSION = '0.01';


# By default export the 'widont' function and 'nbsp' constant.
use base qw/ Exporter /;
our @EXPORT = qw( widont nbsp );


=head1 NAME

Text::Widont - Suppress typographic widows

=head1 SYNOPSIS

    use Text::Widont;

    # For a single string...
    my $string = 'Look behind you, a Three-Headed Monkey!';
    print widont($string, nbsp->{html});  # "...a Three-Headed&nbsp;Monkey!"

    # For a number of strings...
    my $strings = [
        'You fight like a dairy farmer.',
        'How appropriate. You fight like a cow.',
    ];
    print join "\n", @{ widont( $strings, nbsp->{html} ) };

Or the L<object oriented|/METHODS> way:

    use Text::Widont qw( nbsp );

    my $tw = Text::Widont->new( nbsp => nbsp->{html} );

    my $string = "I'm selling these fine leather jackets.";
    print $tw->widont($string);  # "...fine leather&nbsp;jackets."


=head1 DESCRIPTION

Collins English Dictionary defines a "widow" in typesetting as:

    A short line at the end of a paragraph, especially one that occurs as the
    top line of a page or column.

For example, in the text...

    How much wood could a woodchuck
    chuck if a woodchuck could chuck
    wood?

...the word "wood" at the end is considered a widow. Using C<Text::Widont>,
that sentence would instead appear as...

    How much wood could a woodchuck
    chuck if a woodchuck could
    chuck wood?


=head1 NON-BREAKING SPACE TYPES

C<Text::Widont> exports a hash ref, C<nbsp>, that contains the following
representations of a non-breaking space to be used with the widont function:

=over

=item html

The C<&nbsp;> HTML character entity.

=item html_hex

The C<&#xA0;> HTML character entity.

=item html_dec

The C<&#160;> HTML character entity.

=item unicode

Unicode's "No-Break Space" character.

=back


=cut


use constant nbsp => {
    html     => '&nbsp;',
    html_dec => '&#160;',
    html_hex => '&#xA0;',
    unicode  => pack( 'U', 0x00A0 ),
};


=head1 FUNCTIONS

=head2 widont( $string, $nbsp )

The C<widont> function takes a string and returns a copy with the space
between the final two words replaced with the given C<$nbsp>. C<$string> can
optionally be a reference to an array of strings to transform. In this case
strings will be modified in place as well as a copy returned.

In the absence of an explicit C<$nbsp>, Unicode's No-Break Space character
will be used.


=cut


# This function also acts as an object method as described in the next POD
# section.
sub widont {
    my ( $self, $string, $nbsp );
    $string = shift;
    
    # Check to see if the subroutine has been called as an object method...
    if ( ref $string eq 'Text::Widont' ) {
        $self   = $string;
        $string = shift;
        
        $nbsp = $self->{nbsp} eq 'html'     ? nbsp->{html}
              : $self->{nbsp} eq 'html_dec' ? nbsp->{html_dec}
              : $self->{nbsp} eq 'html_hex' ? nbsp->{html_hex}
              : $self->{nbsp} eq 'unicode'  ? nbsp->{unicode}
              : $self->{nbsp};
    }
    
    # Make sure a $string was passed...
    croak 'widont requires a string' if !defined $string;
    
    # $nbsp defaults to unicode...
    $nbsp ||= shift || nbsp->{unicode};
    
    
    # Iterate over the string(s) to perform the transformation...
    foreach ( ref $string eq 'ARRAY' ? @$string : $string ) {
        s/([^\s])\s+([^\s]+\s*)$/$1$nbsp$2/;
    }
    
    return $string;
}


=head1 METHODS

C<Text::Widont> also provides an object oriented interface.

=head2 -E<gt>new( nbsp => $nbsp )

Instantiates a new C<Text::Widont> object. C<nbsp> is an optional argument
that will be used when performing the substitution. It defaults to Unicode's
No-Break Space character.


=cut


sub new {
    my $class = shift;
    my $self  = bless { @_ }, $class;
    
    # Default to No-Break Space.
    $self->{nbsp} ||= nbsp->{unicode};
    
    return $self;
}


=head2 -E<gt>widont( $string )

Performs the substitution described L<above|/FUNCTIONS>, using the object's
C<nbsp> property and the given string.


=cut


# sub widont {} already defined above.



1;  # End of the module code; everything from here is documentation...
__END__

=head1 DEPENDENCIES

C<Text::Widont> requires the following modules:

=over

=item *

L<Carp>

=back


=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-widont at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Widont>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Widont

You may also look for information at:

=over 4

=item * Text::Widont

L<http://perlprogrammer.co.uk/modules/Text::Widont/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Widont/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Widont>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Widont/>

=back


=head1 AUTHOR

Dave Cardwell <dcardwell@cpan.org>


=head1 ACKNOWLEDGEMENTS

I was first introduced to the concept of typesetting widows and how they might
be solved programatically by Shaun Inman.

L<http://www.shauninman.com/archive/2006/08/22/widont_wordpress_plugin>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Dave Cardwell. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.


=cut
