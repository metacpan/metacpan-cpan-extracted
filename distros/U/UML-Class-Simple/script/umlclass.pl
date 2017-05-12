#!/usr/bin/env perl

# vim:set ft=perl ts=4 sw=4 et fdm=marker:

use strict;
use warnings;

use File::Slurp;
use YAML::Syck;
use Getopt::Long;
use File::Spec;
use UML::Class::Simple;

my $ext_regex = qr/(?:\.pl|\.pm)$/i;

my $outfile = 'a.png';
my $dot_prog = $ENV{'UMLCLASS_DOT'} || 'dot';

GetOptions(
    "color|c=s"     => \my $node_color,
    "help|h"        => \my $help,
    "without-inherited-methods" => \my $without_inherited_methods,
    "M=s"           => \my @preload_modules,
    "out|o=s"       => \$outfile,
    "P|public-only" => \my $public_only,
    "pattern|p=s"   => \my $pattern,
    "recursive|r"   => \my $recursive,
    "size|s=s"      => \my $size,
    "dot=s"         => \$dot_prog,
    "include|I=s"   => \my @include_paths,
    "exclude|E=s"   => \my @exclude_paths,
    "no-methods"  => \my $no_methods,
    "moose-roles"   => \my $moose_roles,
    "no-inheritance" => \my $no_inheritance,
) or help(1);

#warn "include_paths: @include_paths\n";
#warn "exclude_paths: @exclude_paths\n";

help(0) if $help;

# We need to add the include paths to @INC so that modules will be found
unshift @INC, @include_paths;

# We need preloaded modules to be loaded, really.  Not pretended.
foreach my $mod (@preload_modules) {
    my $loc = $mod . ".pm";
    $loc =~ s{::}{/}gsmx;
    eval { require $loc; };
    if ($@) { warn "can't pre-load $mod: $@\n"; }
}

my ($width, $height);
if ($size) {
    if ($size !~ /(?x) ([\d\.]+) x ([\d\.]+) /) {
        die "error: -s or --size option only takes argument like 3.2x5 and 7x3\n";
    }
    ($width, $height) = ($1, $2);
}

my @infiles = sort map { -d $_ ? all_in($_) : $_ } map glob, @ARGV;

my @plfiles = grep { !/(?:\.dot|\.yml)$/i } @infiles;
for my $plfile (@plfiles) {
    if (!-e $plfile) {
        die "error: input file $plfile not found.\n";
    }
}

my $painter;

if (!@plfiles) {
    if (@infiles) {
        my $file = pop @infiles;
        if ($file =~ /\.dot$/i) {
            $painter = UML::Class::Simple->new;
            $painter->set_dot(read_file($file));
        }
        elsif ($file =~ /\.yml$/i) {
            $painter = UML::Class::Simple->new;
            my $dom = LoadFile($file);
            $painter->set_dom($dom);
        }
    }
} else {
    if (@plfiles != @infiles) {
        die "error: perl source files are not allowed when ",
            ".yml or .dot files are also given.\n";
    }
}

if (!$painter) {
    my @classes;
    @classes = classes_from_runtime(\@preload_modules, $pattern) if !@plfiles;
    push @classes, classes_from_files(\@plfiles, $pattern) if @plfiles;
    if (@classes) {
        if (@include_paths) {
            @classes = grep_by_paths(\@classes, @include_paths);
        }
        if (@exclude_paths) {
            @classes = exclude_by_paths(\@classes, @exclude_paths);
        }
        if (!@classes) {
            die "error: no class found.\n";
        }
        print join("\n", sort @classes), "\n\n";
        $painter = UML::Class::Simple->new(\@classes);
    } else {
        die "error: no class found.\n";
    }
}

$painter->dot_prog($dot_prog);
$painter->public_only($public_only) if $public_only;
$painter->inherited_methods(0) if $without_inherited_methods;
#die "inherited_methods: ", $painter->inherited_methods;
$painter->size($width, $height) if $width and $height;
$painter->node_color($node_color) if $node_color;
#$painter->root_at($root_class) if $root_class;
$painter->display_methods(0) if $no_methods;
$painter->moose_roles($moose_roles) if $moose_roles;
$painter->display_inheritance(0) if $no_inheritance;

my $ext = 'png';
if ($outfile =~ /\.(\w+)$/) { $ext = lc($1); }

if ($ext eq 'png') {
    $painter->as_png($outfile);
}
elsif ($ext eq 'gif') {
    $painter->as_gif($outfile);
}
elsif ($ext eq 'dot') {
    $painter->as_dot($outfile);
}
elsif ($ext eq 'yml') {
    my $dom = $painter->as_dom;
    DumpFile($outfile, $dom);
}
elsif ($ext eq 'xmi') {
    $painter->as_xmi($outfile);
}
elsif ($ext eq 'svg') {
    $painter->as_svg($outfile);
}
else {
    die "error: unknown output file format: $ext\n";
}

print "$outfile generated.\n" if $outfile;

sub help {
    my $code = shift;
    warn <<"_EOC_";
Usage: $0 [-M module] [-o outfile] [-p regex] [infile... indir...]
    infile...    Perl source files, .pm, .pl, .yml, or .dot file, or
                 .yml files containing the class info DOM. They're
                 optional.
    indir...     Directory containing perl source files. They're
                 optional too.
Options:
    --color color
    -c color     Set the node color. Defaults to "#f1e1f4".

    --dot path   Tell it where to find the graphviz program "dot"

    --exclude path
    -E path
                 exclude modules that were installed to <path> from
                 the drawing. multiple -E options are supported.

    --help
    -h           Print this help.

    --include path
    -I path
                 Include *only* the classes that were installed to
                 <path> in the drawing. multiple -I options are supported.

    -M module    Preload the specified module to runtime.
                 (multiple -M are supported.)

    --moose-roles
                 Show relationships between Moose::Role packages
                 and their consumers in the output.

    --no-methods
                 Do not show any method names at all in the output.

    --no-inheritance
                 Do not draw class inheritance relationships in the output.

    --out outfile
    -o outfile   Specify the output file name. it can be one of the
                 following types: .png, .dot, .xmi and .yml. Defaults
                 to a.png.

    --public-only
                 Show public methods only.

    --pattern regex
    -p regex     Specify the perl regex as the pattern used to
                 filter out classes to be drawn.

    --recursive
    -r           Process subdirectories of indir recursively.

    --size <w>x<h>
    -s <w>x<h>   Specify the width and height (in inches) for the
                 output images. For instance, 3.2x6.3 and 4x8.

    --without-inherited-methods
                 Do not show methods from parent classes.

Report bugs or wishlist to Yichun Zhang <agentzh\@gmail.com>.
_EOC_
    exit($code);
}

# Stolen directly from 'prove'
sub all_in {
    my $start = shift;
    my @hits = ();

    local *DH;
    if ( opendir( DH, $start ) ) {
        my @files = sort readdir DH;
        closedir DH;
        for my $file ( @files ) {
            next if $file eq File::Spec->updir || $file eq File::Spec->curdir;
            next if $file eq ".svn";
            next if $file eq "CVS";

            my $currfile = File::Spec->catfile( $start, $file );
            if ( -d $currfile ) {
                push( @hits, all_in( $currfile ) ) if $recursive;
            } else {
                push( @hits, $currfile ) if $currfile =~ $ext_regex;
            }
        }
    } else {
        warn "$start: $!\n";
    }

    return @hits;
}

__END__

=head1 NAME

umlclass.pl - Utility to generate UML class diagrams from Perl source or runtime

=head1 SYNOPSIS

    # generate a PNG file for the Foo module:
    $ umlclass.pl -M Foo -o foo.png -p "^Foo::"

    # generate an SVG image file which is vectorized and super clear:
    $ umlclass.pl --without-inherited-methods -o foo.svg -r lib/

    # generate the dot source file:
    $ umlclass.pl -M Foo -o foo.dot

    $ umlclass.pl -o bar.gif -p "Bar::|Baz::" lib/Bar.pm lib/*/*.pm

    $ umlclass.pl -o blah.png -p Blah -r ./blib

    $ umlclass.pl --without-inherited-methods -o blah.png -r lib

=head1 DESCRIPTION

This is a simple command-line frontend for the L<UML::Class::Simple> module.

I'll illustrate the usage of this tool via some real-world examples.

=head2 Draw Stevan's Moose

  $ umlclass.pl -M Moose -o samples/moose_small.png -p "^(Class::MOP|Moose::)" -s 4x8

This command will generate a simple class diagram in PNG format for the Moose module
with classes having names matching the regex C<"^(Class::MOP|Moose::)">. The image's
width is 4 inches while its height is 8 inches.

We need the -M option here since C<umlclass.pl> needs to preload L<Moose> into the
memory so as to inspect it at runtime.

The graphical output is given below:

=begin html

<img src="http://perlcabal.org/agent/images/moose_small.png">

=end html

(See also L<http://perlcabal.org/agent/images/moose_small.png>.)

Yes, the image above looks very fuzzy since the whole stuff is huge. If you strip
the -s option, then the resulting image will enlarge automatically:

  $ umlclass.pl -M Moose -o samples/moose_big.png -p "^(Class::MOP|Moose::)"

The image obtained is really really large, I won't show it here, but you
can browse it in your favorite picture browser from
L<http://perlcabal.org/agent/images/moose_big.png>.

Before trying out these commands yourself, please make sure that you have
L<Moose> already installed. (It's also on CPAN, btw.)

=head2 Perl libraries that use Moose

Perl classes that inherit from Moose will have tons of "meta methods" like
C<before>, C<after>, C<has>, and C<meta>, which are not very interesting
while plotting the class diagram. So it's common practice to specify
the C<--without-inherited-methods> option like this:

  $ umlclass.pl --without-inherited-methods -o uml.png -r lib

If you also add C<--moose-roles>, extra edges will appear in the
graph, in an alternate color, representing the relationships between roles
and their consumers.

=head2 Draw Alias's PPI

  $ umlclass.pl -M PPI -o samples/ppi_small.png -p "^PPI::" -s 10x10

=begin html

<img src="http://perlcabal.org/agent/images/ppi_small.png">

=end html

(See also L<http://perlcabal.org/agent/images/ppi_small.png>.)

Or the full-size version:

  $ umlclass.pl -M PPI -o samples/ppi_big.png -p "^PPI::"

(See L<http://perlcabal.org/agent/images/ppi_big.png>.)

BTW, L<PPI> is a prerequisite of this module.

=head2 Draw FAST.pm from UML::Class::Simple's Test Suite

  $ umlclass.pl -M FAST -o samples/fast.png -s 5x10 -r t/FAST/lib

This is an example of drawing classes contained in Perl source files.

=head2 Draw Modules of Your Own

Suppose that you're a CPAN author too and want to produce a class diagram for I<all>
the classes contained in your lib/ directory. The following command can do all the
hard work for you:

    $ umlclass.pl -o mylib.png -r lib

or just plot the packages in the specified .pm files:

    $ umlclass.pl -o a.png lib/foo.pm lib/bar/baz.pm

or even specify a pattern (in perl regex) to filter out the packages you want to draw:

    $ umlclass.pl -o a.png -p "^Foo::" lib/foo.pm

Quite handy, isn't it? ;-)

=head1 IMPORTANT ISSUES

Never feed plain module names to F<umlclass.pl>, for intance,

  $ umlclass.pl Scalar::Defer  # DO NOT DO THIS!

will lead you to the following error message:

  error: input file Scalar::Defer not found.

Use C<-M> and C<-p> options to achieve your goals:

  $ umlclass.pl -M Scalar::Defer -p "Scalar::Defer"

In this example, I must warn you that you may miss the
packages which belong to Scalar::Defer but don't have "Scalar::Defer"
in their names. I'm sorry for that. F<umlclass.pl> is not I<that>
smart.

The safest ways to do this are

=over

=item 1.

Don't specify the C<-p regex> option and generate a large image which shows
every classes including CORE modules, figure out the appropriate class
name pattern yourself, and rerun C<umlclass.pl> with the right regex pattern.

=item 2.

Grab the Scalar::Defer's tarball, and do something like this:

   $ umlclass.pl -r Scalar-Defer-0.07/lib

=back

It's worth mentioning that when .pl or .pm files are passing as the command line
arguments, I<only> the classes I<defined> in these files will be drawn. This is
a feature. :)

For F<.pm> files on your disk, simply pass them as the command line
arguments. For instance:

   $ umlclass.pl -o bar.gif lib/Bar.pm lib/*/*.pm

or tell F<umlclass.pl> to iterate through the directories for you:

   $ umlclass.pl -o blah.png -r ./lib

=head1 OPTIONS

=over

=item --color color

=item -c color

Sets the node color. Defaults to C<#f1e1f4>.

You can either specify RGB values like C<#rrggbb> in hex form, or
color names like "C<grey>" and "C<red>".

=item --dot path

Tell it where the graphviz "dot" program is

=item --exclude path

=item -E path

excludes modules that were installed to C<path> from
the drawing. multiple C<-E> options are supported.

=item --help

=item -h

Shows the help message.

=item --include path

=item -I path

Draws I<only> the classes that were installed to
C<path> in the drawing. multiple C<-I> options are supported.

=item -M module

Preloads the module which contains the classes you want to depict. For example,

    $ umlclass.pl -M PPI -o ppi.png -p "^PPI::"

Multiple C<-M> options are accepted. For instance:

    $ umlclass.pl -M Foo -M Bar::Baz -p "Class::"

=item --no-methods

Don't display method names in the output.

=item --no-inheritance

Don't show the inheritance relationships in the output.  Not terribly useful
unless you are using C<Moose> and asking for C<--moose-roles>.

=item --out outfile

=item -o outfile

Specifies the output file name. Note that the file extension will be honored.
If you specify "C<-o foo.png>", a PNG image named F<foo.png> will be generated,
and if you specify "C<-o foo.dot>", the dot source file named F<foo.dot> will
be obtained.
If you specify "C<-o foo.xmi>", the XMI model file will be generated.
Likewise, "C<-o foo.yml>" will lead to a YAML file holding the whole
internal DOM data.

A typical usage is as follows:

    $ umlclass.pl -o foo.yml lib/Foo.pm

    # ...edit the foo.yml so as to adjust the class info
    # feed the updated foo.dot back
    $ umlclass.pl -o foo.dot foo.yml

    # ...edit the foo.dot so as to adjust the graphviz dot source
    # now feed the updated foo.dot back
    $ umlclass.pl -o foo.png foo.dot

You see, F<umlclass.pl> allows you to control the behaviors at several different
levels. I really like this freedom, since tools can't always do exactly what I want.

If no C<-o> option was specified, F<a.png> will be assumed.

=item --pattern regex

=item -p regex

Specifies the pattern (perl regex) used to filter out the class names to be drawn.

=item --public-only

=item -P

Shows public methods only.

=item --recursive

=item -r

Processes subdirectories of input directories recursively.

=item --moose-roles

If a package appears to be a L<Moose::Role>, determine which other
packages consume that role, and add that information to the graph
in a different color from the inheritance hierarchy.  Depending on
the particular input classes and your personal artistic tastes,
this may substantially alter the usefulness and/or cleanliness of
the resulting diagram.  For large package hierarchies, it is
recommended to combine this with B<--no-inheritance>.

=item --size

=item -s <w>x<h>

Specifies the width and height of the resulting image. For example:

    -s 3.6x7

    --size 5x6

where the unit is inches instead of pixels.

=item --without-inherited-methods

Do not show methods from parent classes.

All inherited and imported methods will be excluded. Note that if a method
is overridden in the current subclass, it will still be included even if
it appears in one of its ancestors.

=back

=head1 TODO

=over

=item *

If the user passes plain module names like "Foo::Bar", then its (and only its)
ancestors and subclasses will be drawn. (This is suggested by Christopher Malon.)

=back

=head1 AUTHORS

Yichun Zhang E<lt>agentzh@gmail.comE<gt>,
Maxim Zenin E<lt>max@foggy.ruE<gt>

=head1 COPYRIGHT

Copyright 2006-2017 by Yichun Zhang. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=head1 SEE ALSO

L<UML::Class::Simple>.
