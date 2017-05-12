package HTML::KhatGallery;
use strict;
use warnings;

=head1 NAME

HTML::KhatGallery - HTML photo album generator.

=head1 VERSION

This describes version B<0.03> of HTML::KhatGallery.

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    # use the khatgallery script
    khatgallery --plugins HTML::KhatGallery::Plugin::MyPlugin I<directory>
    
    # from within a script
    require HTML::KhatGallery;

    my @plugins = qw(HTML::KhatGallery:;Core HTML::KhatGallery::Plugin::MyPlugin);
    HTML::KhatGallery->import(@plugins);
    HTML::KhatGallery->run(%args);

=head1 DESCRIPTION

HTML::KhatGallery generates a HTML photo gallery.  It takes a directory
of images, and generates the HTML pages and thumbnails needed.

This includes the khatgallery script (to generate the gallery)
and the kg_image_info script (to get information about an image).

I decided to write this because, while there are gazillion gallery scripts
out there, none of them do quite what I want, and I wanted to take nice
features from different scripts and bring them together.

=over

=item *

Pre-generated (baked, not fried)

=item *

Can recurse down into sub-directories of the top gallery directory.

=item *

Generates only new files by default.

=item *

Can clean out unused files.

=item *

Can force regeneration of HTML or thumbnails.

=item *

Does not require Javascript.

=item *

Ability to add plugins.

=item *

Meta-data from more than just jpeg files.

=item *

Multi-page albums.  That is, directories with lots of images can show
only so many images per index page, instead of having to load every
single thumbnail.

=item *

Very simple page template, not complicated themes.

=item *

Pixel-area thumbnails (rather than conforming to particular width or
height, you get higher-quality thumbnails by making them have a given
area).

=item *

XHTML compliant.

=item *

Dynamic columns with CSS and HTML, rather than fixed tables.

=back

=head2 The Name

KhatGallery comes from a slight mangling of "Kat's HTML Gallery"; it's
so hard to come up with names that haven't already been used.

=cut

=head1 CLASS METHODS

=head2 import

require HTML::KhatGallery;

HTML::KhatGallery->import(@plugins);

This needs to be run before L</run>.
See L<HTML::KhatGallery::Core> for more information.

This loads plugins, modules which subclass HTML::KhatGallery and override its
methods and/or make additional methods.  The arguments of this method are the
module names, in the order in which they should be loaded.  The given modules
are required and arranged in an "is-a" chain.  That is, HTML::KhatGallery
subclasses the last plugin given, which subclasses the second-to-last, up to
the first plugin given, which is the base class.

This can be called in two different ways.  It can be called implicitly
with the "use" directive, or it can be called explicitly if one 'requires'
HTML::KhatGallery rather then 'use'-ing it.

The advantage of calling this explicitly is that one can set the
plugins dynamically, rather than hard-coding them in the calling
script.

(idea taken from Module::Starter by Andy Lester and Ricardo Signes)

=cut
sub import {
    my $class = shift;

    my @plugins = @_ ? @_ : 'HTML::KhatGallery::Core';
    my $parent;

    no strict 'refs';
    for (@plugins, $class) {
        if ($parent) {
            eval "require $parent;"; 
            die "couldn't load plugin $parent: $@" if $@;
            push @{"${_}::ISA"}, $parent;
        }
        $parent = $_;
    }
} # import

=head1 REQUIRES

    Test::More
    POSIX
    File::Basename
    File::Spec
    Cwd
    File::stat
    YAML
    Image::Info
    Image::Magick

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the script.

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}


=head1 SEE ALSO

perl(1).

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot org
    http://www.katspace.org/tools

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2006 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::KhatGallery
__END__
