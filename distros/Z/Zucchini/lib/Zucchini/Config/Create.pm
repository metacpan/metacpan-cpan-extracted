package Zucchini::Config::Create;
$Zucchini::Config::Create::VERSION = '0.0.21';
{
  $Zucchini::Config::Create::DIST = 'Zucchini';
}
# ABSTRACT: write a sample configuration file
# vim: ts=8 sts=4 et sw=4 sr sta
use Moo;
use strict; # for kwalitee testing

use IO::File;

sub write_default_config {
    my $self        = shift;
    my $filename    = shift;

    if (-e $filename) {
        # TODO - copy file to file.TIMESTAMP and create new
        warn "$filename already exists\n";
        return;
    }

    # create a filehandle to write to
    my $fh = IO::File->new($filename, 'w');

    # loop through the __DATA__ for this module
    # and print it to the filehandle
    while (my $line = <DATA>) {
        print $fh <DATA>;
    }
    $fh->close;
    close DATA;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Zucchini::Config::Create - write a sample configuration file

=head1 VERSION

version 0.0.21

=head1 SYNOPSIS

  # create a new object
  $zucchini_cfg_create = Zucchini::Config::Create->new();

  # write out a default config file
  $zucchini_cfg_create->write_default_config(
    file($ENV{HOME}, q{.zucchini})
  );

=head1 DESCRIPTION

It's mean to expect people to pluck a configuration file out if thin air.

This module's sole purpose is to write out a default .zucchini file to give
users a fighting chance.

=head1 NAME

Zucchini::Config::Create - write a sample configuration file

=head1 METHODS

=head2 new

Creates a new instance of the top-level Zucchini object:

  # create a new object
  $zucchini_cfg_create = Zucchini::Config::Create->new();

=head2 write_default_config

Given a filename, write out the default/sample configuration file. If the file
already exists it I<will not> be overwritten.

  # write out a default config file
  $zucchini_cfg_create->write_default_config(
    file($ENV{HOME}, q{.zucchini})
  );

=head1 SAMPLE CONFIGURATION FILE

The sample configuration file is supposed to be a reasonable example of how a
functioning configuration file should look.

You should be able to get up and running with Zucchini by creating the default
file, and modifying the following variables:
I<source_dir>, I<includes_dir>, I<output_dir>.

You might also like to edit some of the values in the C<< <tags> >> section.

=head1 SEE ALSO

L<Zucchini>,
L<Zucchini::Config>

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

Copyright 2008-2009 by Chisel Wright

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

default_site   default

<site>
    # a default site
    <default>
        source_dir          /path/to/tt_templates
        includes_dir        /path/to/tt_includes
        output_dir          /var/www/default_site/html

        template_files      \.html\z

        ignore_dirs         CVS
        ignore_dirs         .svn

        ignore_files        \.swp\z

        lint_check          1

        <tags>
            author          Joe Bloggs
            email           joe@localhost
            copyright       &copy; 2006-2008 Joe Bloggs. All rights reserved.
        </tags>

        <ftp>
            hostname        remote.ftp.site
            username        joe.bloggs
            password        sekrit
            passive         1
            path            /
        </ftp>
    </default>


    # a second site definition - to demonstrate how to define multiple sites
    <mysite>
        source_dir          /path/to/tt_templates
        includes_dir        /path/to/tt_includes
        output_dir          /var/www/default_site/html

        plugin_base         MyPrefix::Template::Plugin

        template_files      \.html\z

        ignore_dirs         CVS
        ignore_dirs         .svn

        ignore_files        \.swp\z

        lint_check          1

        <tags>
            author          Joe Bloggs
            email           joe@localhost
            copyright       &copy; 2000-2006 Joe Bloggs. All rights reserved.
        </tags>

        <rsync>
            hostname        remote.site
            path            /home/joe.bloggs
         </rsync>
    </mysite>
</site>
