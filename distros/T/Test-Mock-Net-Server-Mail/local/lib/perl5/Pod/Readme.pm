package Pod::Readme;

=head1 NAME

Pod::Readme - Intelligently generate a README file from POD

=for readme plugin version

=head1 SYNOPSIS

In a module's POD:

  =head1 NAME

  MyApp - my nifty app

  =for readme plugin version

  =head1 DESCRIPTION

  This is a nifty app.

  =begin :readme

  =for readme plugin requires

  =head1 INSTALLATION

  ...

  =end :readme

  =for readme stop

  =head1 METHODS

  ...

Then from the command-line:

  pod2readme lib/MyModule.pm README

=for readme stop

From within Perl:

  use Pod::Readme;

  my $prf = Pod::Readme->new(
    input_file		=> 'lib/MyModule.pm',
    translate_to_file	=> $dest,
    translation_class	=> 'Pod::Simple::Text',
  );

  $prf->run();

=for readme start

=head1 DESCRIPTION

This module filters POD to generate a F<README> file, by using POD
commands to specify which parts are included or excluded from the
F<README> file.

=begin :readme

See the L<Pod::Readme> documentation for more details on the POD
syntax that this module recognizes.

See L<pod2readme> for command-line usage.

=head1 INSTALLATION

See
L<How to install CPAN modules|http://www.cpan.org/modules/INSTALL.html>.

=for readme plugin requires heading-level=2 title="Required Modules"

=for readme plugin changes

=end :readme

=for readme stop

=head1 POD COMMANDS

=head2 C<=for readme stop>

Stop including the POD that follows in the F<README>.

=head2 C<=for readme start>

=head2 C<=for readme continue>

Start (or continue to) include the POD that follows in the F<README>.

Note that the C<start> command was added as a synonym in version
1.0.0.

=head2 C<=for readme include>

  =for readme include file="INSTALL" type="text"

Include a text or POD file in the F<README>.  It accepts the following
options:

=over

=item C<file>

Required. This is the file name to include.

=item C<type>

Can be "text" or "pod" (default).

=item C<start>

An optional regex of where to start including the file.

=item C<stop>

An optional regex of where to stop including the file.

=back

=head2 C<=for readme plugin>

Loads a plugin, e.g.

  =for readme plugin version

Note that specific plugins may add options, e.g.

  =for readme plugin changes title='CHANGES'

See L<Pod::Readme::Plugin> for more information.

Note that the C<plugin> command was added in version 1.0.0.

=head2 C<=begin :readme>

=head2 C<=end :readme>

Specify a block of POD to include only in the F<README>.

You can also specify a block in another format:

  =begin readme text

  ...

  =end readme text

This will be translated into

  =begin text

  ...

  =end text

and will only be included in F<README> files of that format.

Note: earlier versions of this module suggested using

  =begin readme

  ...

  =end readme

While this version supports that syntax for backwards compatibility,
it is not standard POD.

=cut

use v5.10.1;

use Moo;
extends 'Pod::Readme::Filter';

our $VERSION = 'v1.2.3';

use Carp;
use IO qw/ File Handle /;
use List::Util 1.33 qw/ any /;
use Module::Load qw/ load /;
use Path::Tiny qw/ path tempfile /;
use Pod::Simple;
use Types::Standard qw/ Bool Maybe Str /;

use Pod::Readme::Types qw/ File WriteIO /;

# RECOMMEND PREREQ: Pod::Man
# RECOMMEND PREREQ: Pod::Markdown
# RECOMMEND PREREQ: Pod::Markdown::Github
# RECOMMEND PREREQ: Pod::Simple::HTML
# RECOMMEND PREREQ: Pod::Simple::LaTeX
# RECOMMEND PREREQ: Pod::Simple::RTF
# RECOMMEND PREREQ: Pod::Simple::Text
# RECOMMEND PREREQ: Pod::Simple::XHTML

=head1 ATTRIBUTES

This module extends L<Pod::Readme::Filter> with the following
attributes:

=head2 C<translation_class>

The class used to translate the filtered POD into another format,
e.g. L<Pod::Simple::Text>.

If it is C<undef>, then there is no translation.

Only subclasses of L<Pod::Simple> are supported.

=cut

has translation_class => (
    is      => 'ro',
    isa     => Maybe [Str],
    default => undef,
);

=head2 C<translate_to_fh>

The L<IO::Handle> to save the translated file to.

=cut

has translate_to_fh => (
    is      => 'ro',
    isa     => WriteIO,
    lazy    => 1,
    builder => '_build_translate_to_fh',
    coerce  => sub { WriteIO->coerce(@_) },
);

sub _build_translate_to_fh {
    my ($self) = @_;
    if ( $self->translate_to_file ) {
        $self->translate_to_file->openw;
    }
    else {
        my $fh = IO::Handle->new;
        if ( $fh->fdopen( fileno(STDOUT), 'w' ) ) {
            return $fh;
        }
        else {
            croak "Cannot get a filehandle for STDOUT";
        }
    }
}

=head2 C<translate_to_file>

The L<Path::Tiny> filename to save the translated file to. If omitted,
then it will be saved to C<STDOUT>.

=cut

has translate_to_file => (
    is      => 'ro',
    isa     => File,
    coerce  => sub { File->coerce(@_) },
    lazy    => 1,
    builder => 'default_readme_file',
);

=head2 C<output_file>

The L<Pod::Readme::Filter> C<output_file> will default to a temporary
file.

=cut

has '+output_file' => (
    lazy    => 1,
    default => sub { tempfile( SUFFIX => '.pod', UNLINK => 1 ); },
);

around '_build_output_fh' => sub {
    my ( $orig, $self ) = @_;
    if ( defined $self->translation_class ) {
        $self->$orig();
    }
    else {
        $self->translate_to_fh;
    }
};

=head2 C<force>

For a new F<README> to be generated, even if the dependencies have not
been updated.

See L</dependencies_updated>.

=cut

has 'force' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

=head2 C<zilla>

For use with L<Dist::Zilla> plugins.

This allows plugins which normally depend on files in the distribution
to use metadata from here instead.

=cut

=head1 METHODS

This module extends L<Pod::Readme::Filter> with the following methods:

=head2 C<default_readme_file>

The default name of the F<README> file, which depends on the
L</translation_class>.

=cut

sub default_readme_file {
    my ($self) = @_;

    my $name = uc( $self->target );

    state $extensions = {
        'Pod::Man'           => '.1',
        'Pod::Markdown'      => '.md',
        'Pod::Simple::HTML'  => '.html',
        'Pod::Simple::LaTeX' => '.tex',
        'Pod::Simple::RTF'   => '.rtf',
        'Pod::Simple::Text'  => '',
        'Pod::Simple::XHTML' => '.xhtml',
    };

    my $class = $self->translation_class;
    if ( defined $class ) {
        if ( my $ext = $extensions->{$class} ) {
            $name .= $ext;
        }
    }
    else {
        $name .= '.pod';
    }

    path( $self->base_dir, $name );
}

=head2 C<translate_file>

This method runs translates the resulting POD from C<filter_file>.

=cut

sub translate_file {
    my ($self) = @_;

    if ( my $class = $self->translation_class ) {

        load $class;
        my $converter = $class->new()
          or croak "Cannot instantiate a ${class} object";

        if ( $converter->isa('Pod::Simple') ) {

            my $tmp_file = $self->output_file->stringify;

            close $self->output_fh
              or croak "Unable to close file ${tmp_file}";

            $converter->output_fh( $self->translate_to_fh );
            $converter->parse_file($tmp_file);

        }
        else {

            croak "Don't know how to translate POD using ${class}";

        }

    }
}

=head2 C<dependencies_updated>

Used to determine when the dependencies have been updated, and a
translation can be run.

Note that this only returns a meaningful value after the POD has been
processed, since plugins may add to the dependencies.  A side-effect
of this is that when generating a POD formatted F<README> is that it
will always be updated, even when L</force> is false.

=cut

sub dependencies_updated {
    my ($self) = @_;

    my $dest = $self->translate_to_file;

    if ( $dest and $self->input_file) {

        return 1 unless -e $dest;

        my $stat = $dest->stat;
        return 1 unless $stat;

        my $time = $stat->mtime;
        return any { $_->mtime > $time } ( map { $_->stat } $self->depends_on );

    }
    else {
        return 1;
    }
}

=head2 C<run>

This method runs C<filter_file> and then L</translate_file>.

=cut

around 'run' => sub {
    my ( $orig, $self ) = @_;
    $self->$orig();
    if ( $self->force or $self->dependencies_updated ) {
        $self->translate_file();
    }
};

=head2 C<parse_from_file>

  my $parser = Pod::Readme->new();
  $parser->parse_from_file( 'README.pod', 'README' );

  Pod::Readme->parse_from_file( 'README.pod', 'README' );

This is a class method that acts as a L<Pod::Select> compatibility
shim for software that is designed for versions of L<Pod::Readme>
prior to v1.0.

Its use is deprecated, and will be deleted in later versions.

=cut

sub parse_from_file {
    my ( $self, $source, $dest ) = @_;

    my $class = ref($self) || __PACKAGE__;
    my $prf = $class->new(
        input_file        => $source,
        translate_to_file => $dest,
        translation_class => 'Pod::Simple::Text',
        force             => 1,
    );
    $prf->run();
}

=head2 C<parse_from_filehandle>

Like L</parse_from_file>, this exists as a compatibility shim.

Its use is deprecated, and will be deleted in later versions.

=cut

sub parse_from_filehandle {
    my ( $self, $source_fh, $dest_fh ) = @_;

    my $class = ref($self) || __PACKAGE__;

    my $src_io =
      IO::Handle->new_from_fd( ( defined $source_fh ) ? fileno($source_fh) : 0,
        'r' );

    my $dest_io =
      IO::Handle->new_from_fd( ( defined $dest_fh ) ? fileno($dest_fh) : 1,
        'w' );

    my $prf = $class->new(
        input_fh          => $src_io,
        translate_to_fh   => $dest_io,
        translation_class => 'Pod::Simple::Text',
        force             => 1,
    );
    $prf->run();
}

use namespace::autoclean;

1;

=for readme start

=head1 CAVEATS

This module is intended to be used by module authors for their own
modules.  It is not recommended for generating F<README> files from
arbitrary Perl modules from untrusted sources.

=head1 SEE ALSO

See L<perlpod>, L<perlpodspec> and L<podlators>.

=head1 AUTHORS

The original version was by Robert Rothenberg <rrwo@cpan.org> until
2010, when maintenance was taken over by David Precious
<davidp@preshweb.co.uk>.

In 2014, Robert Rothenberg rewrote the module to use filtering instead
of subclassing a POD parser.

=head2 Acknowledgements

Thanks to people who gave feedback and suggestions to posts about the
rewrite of this module on L<http://blogs.perl.org>.

=head2 Suggestions, Bug Reporting and Contributing

This module is developed on GitHub at
L<http://github.com/bigpresh/Pod-Readme>

=head1 LICENSE

Copyright (c) 2005-2014 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
