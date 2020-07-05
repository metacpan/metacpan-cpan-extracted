package Translate::Fluent;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.6.2';

use Translate::Fluent::Parser;
use Translate::Fluent::ResourceGroup;

sub parse_file {
  my $class = shift;

  return Translate::Fluent::Parser::parse_file( @_ );
}

sub slurp_directory {
  my $class = shift;

  return Translate::Fluent::ResourceGroup->slurp_directory( @_ );
}

1; # End of Translate::Fluent


__END__

=head1 NAME

Translate::Fluent - A perl implementation of Project Fluent Translations.

=head1 VERSION

Version 0.5.3

=head1 SYNOPSIS

  use Translate::Fluent;
  
  my $translations = Translate::Fluent->slurp_directory("translations");

  my $data = {
    name    => "theMage",
    gender  => "male",

  };
  my $ctx = {
    language => 'en',
    website  => 'www.google.com',
  };
  my $text = $translations->translate('my-translation-id', $data, $ctx);


=head1 DESCRIPTION

Project Fluent (L<https://projectfluent.org/>) is a research project by
Mozilla, aiming at more natural sounding translations. I stumbled upon it
while looking for a alternative to gettext, which I think have served
software quite well for a long time, but is not enough for our time.

Multiple things attracted me to Fluent, but the ability to use different
variables to change the final sentence was the most important one. Look
at this example from their website, as an example:

  shared-photos =
    {$userName} {$photoCount ->
        [one] added a new photo
       *[other] added {$photoCount} new photos
    } to {$userGender ->
        [male] his stream
        [female] her stream
       *[other] their stream
    }.

This example, with the variables:

  { userName    => "Anne",
    useGender   => "female",
    photoCount  => 3,
  }

will result in the sentence:

  Anne added 3 new photos to her stream

It uses two different variables, one of which is not even shown in the final
text directly, to define the text.

This is impossible to do with gettext.

And that's why Translate::Fluent was started.

=head1 STATIC METHODS

=head2 parse_file

parse_file allow you to parse a single FLT file and returns a
L<Translate::Fluent::ResourceSet> object that can be used to translate
strings.

See L<Translate::Fluent::Parser#parse_file> for details.

=head2 slurp_directory

slurp_directory parses all the files in a directory, including (optionally)
sub-directories, and create a L<Translate::Fluent::ResourceGroup> object
that can be used to translate strings.

=head1 AUTHOR

theMage, C<< <neves at cpan.org> >>

=head1 TODO

There are a couple of bits of the specification that were not implemented
yet, as well as a few ideas that may be added in the future:

=over 4

=item * MISSING: the most notable omission at this point is Builtin functions

=item * MISSING: ability to define default formats for variables

=item * EXTRA: mechanism to provide application specific functions

=item * MAYBE: support for objects as variables?

=back

=head1 BUGS and SUPPORT

No known bugs at the moment, but we will be tracking them in:

L<http://magick-source.net/MagickPerl/Translate-Fluent>


=head1 PROJECT FLUENT

See L<https://projectfluent.org/> to know more about project fluent.

=head1 LICENSE AND COPYRIGHT

Copyright 2020 theMage.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

