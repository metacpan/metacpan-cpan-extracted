package Zucchini::Template;
$Zucchini::Template::VERSION = '0.0.21';
{
  $Zucchini::Template::DIST = 'Zucchini';
}
# ABSTRACT: process templates and output static files
# vim: ts=8 sts=4 et sw=4 sr sta
use Moo;
use strict; # for kwalitee testing
use Zucchini::Types qw(:all);

use Carp;
use Digest::MD5;
use File::Copy;
use File::stat;
use HTML::Lint;
use Path::Class;
use Template;

# object attributes
has config => (
    reader  => 'get_config',
    writer  => 'set_config',
    isa     => ZucchiniConfig,
    is      => 'ro',
);

has ttobject => (
    reader  => 'get_ttobject',
    writer  => 'set_ttobject',
    isa     => TemplateToolkit,
    is      => 'ro',
);

sub process_site {
    my $self = shift;
    my $directory = $self->get_config->get_siteconfig->{source_dir};

    # start the directory descent ...
    $self->process_directory( $directory );

    return;
}

sub process_directory {
    my $self        = shift;
    my $directory   = shift;

    # for easier access - we should probably objectify this better - TODO
    my $config  = $self->get_config->get_siteconfig();
    my $cliopt  = $self->get_config->get_options();

    # function variables
    my (@list, $relpath);

    # get the list of stuff in the directory
    @list = $self->directory_contents($directory);
    # get our relative path from 'source_dir'
    $relpath = $self->relative_path_from_full($directory);

    # loop through the items in the list and Do The Right Thing
    foreach my $item (@list) {
        # process individual files
        if (-f file($directory,$item)) {
            # skip ignored files
            if ($self->ignore_file($item)) {
                next;
            }

            # getting this far means we should (try to) process the file
            $self->process_file($directory, $item);
            next;
        }

        # process directories
        elsif (-d file($directory,$item)) {
            # skip ignored dirs
            if ($self->ignore_directory($item)) {
                next;
            }

            my $outdir = dir($config->{output_dir}, $relpath, $item);
            # make sure the directory exists in the output tree
            if (! -d $outdir) {
                warn "output directory '$outdir' does not exist\n";
                if (not mkdir($outdir)) {
                    carp "couldn't create output directory: $!";
                    exit;
                }
                warn "created: $outdir\n";

            }

            # process the subdirectory
            $self->process_directory(dir($directory,$item));
            next;
        }

        # not a file or directory?
        # we don't handle Odd Stuff (yet?)
        else {
            warn "unhandled file-type for '" . dir($directory,$item) . "\n";
            next;
        }
    }

    return;
}

sub directory_contents {
    my $self        = shift;
    my $directory   = shift;
    my (@list);

    # get a list of everything (except . and ..) in $directory
    opendir(my $dh, $directory)
        or die("can't open '$directory': $!\n");

    @list = grep { $_ !~ /^\.\.?$/ } readdir($dh);

    return @list;
}

sub file_checksum {
    my $self = shift;
    my $file = shift;
    my ($md5);

    # try to open the file
    open(my $fh,$file) or do {
        warn "Can't open $file: $!";
        return undef;
    };
    binmode($fh);

    $md5 = Digest::MD5->new->addfile($fh)->hexdigest;

    return $md5;
}

sub file_modified {
    my $self = shift;
    my ($template_file, $templated_file) = @_;
    my ($template_stat, $templated_stat);

    # if the destination file doesn't exist, it's "modified"
    if (not -e $templated_file) {
        return 1;
    }

    # get stat info for each file
    $template_stat  = stat( $template_file)   or die "no file: $!\n";
    $templated_stat = stat($templated_file)   or die "no file: $!\n";

    # return true if the templated file is OLDER than the template itself
    # i.e. the source has been altered since we last generated the final result
    return ($templated_stat->mtime < $template_stat->mtime);
}

sub ignore_directory {
    my ($self, $directory) = @_;

    foreach my $ignore_me (@{ $self->get_config->ignored_directories }) {
        my $regex = qr/ \A $ignore_me \z /x;

        if ($directory =~ $regex) {
            warn "ignoring directory '$directory'. Match on '$regex'.\n"
                if ($self->get_config->verbose);
            return 1;
        }
    }

    return;
}

sub ignore_file {
    my ($self, $filename) = @_;

    foreach my $ignore_me (@{ $self->get_config->ignored_files }) {
        my $regex = qr/ $ignore_me /x;

        if ($filename =~ $regex) {
            warn "ignoring file '$filename'. Match on '$regex'.\n"
                if ($self->get_config->verbose);
            return 1;
        }
    }

    return;
}

sub item_name {
    my $self = shift;
    my ($directory, $item) = @_;
    my ($filename);

    # TODO - objectify better
    my $cliopt  = $self->get_config->get_options();
    my $config  = $self->get_config->get_siteconfig();

    # default case - just the item name
    $filename = $item;

    # if we want to see the relative path
    if ($cliopt->{showpath}) {
        # get the full path to the file
        $filename = file($directory,$item);
        # remove path to sourcedir
        $filename =~ s{\A$config->{source_dir}/?}{}xms;
    }

    return $filename;
}

sub process_file {
    my $self        = shift;
    my $directory   = shift;
    my $item        = shift;
    my ($relpath);

    # stuff we used to pass through in the script
    # TODO objectify this
    my $config  = $self->get_config->get_siteconfig();
    my $cliopt  = $self->get_config->get_options();

    # get the relative path
    $relpath = $self->relative_path_from_full($directory);

    # push the section name into the vars to replace
    my $site_vars = {
        source_dir  => $config->{source_dir},
        %{ $config->{tags} }
    };

    # some files should be run through TT
    if ($self->template_file($item)) {

        # only create the template object once - it's stupid to create
        # a new one for each file we template
        if (not defined $self->get_ttobject) {
            $self->_prepare_template_object;
        }

        # if the template and the destination have the same timestamp, nothing's changed
        # HOWEVER, we only care if we're not forcing the template-output to be regenerated
        if (not $cliopt->{force}) {
            if ($self->always_process($item)) {
                # bypass modified check
            }
            elsif (not $self->file_modified(
                    file($directory,$item),
                    file($config->{output_dir},$relpath,$item)
                )
            ) {
                warn "unchanged: " . $self->item_name($directory,$item) .  qq{\n}
                    if ($self->get_config->verbose(2));
                return;
            }
        }

        warn (q{templating: } . $self->item_name($directory, $item) . qq{\n});
        $self->show_destination($directory, $item);

        # ->process doesn't like Path::Class thingies being thrown at it
        # so we force it to Stringify
        $self->get_ttobject->process(
            file($directory,$item) . q{},    
            $site_vars,
            file($config->{output_dir},$relpath,$item) . q{}
        )
            or Carp::croak ("\n" . $self->get_ttobject->error());

        # if we're doing lint-checking
        if ($self->get_config()->get_siteconfig()->{lint_check}) {
            # check for HTML errors in file
            if ($item =~ m{\.html?\z}) {
                my $lint;
                eval "use HTML::Lint::Pluggable";
                if ($@) {
                    # create a new HTML::Lint object
                    $lint = HTML::Lint->new();
                }
                else {
                    # create a new HTML::Lint::Pluggable object
                    $lint = HTML::Lint::Pluggable->new();
                    #  this gives us HTML5 support
                    $lint->load_plugins(qw/HTML5/);
                }

                $lint->parse_file(
                    file($config->{output_dir},$relpath,$item) . q{}
                );
                foreach my $error ( $lint->errors ) {
                    # let the user know where and what the error is
                    warn (
                            q{!! }
                        . $self->item_name($directory, $item)
                        . q{: line }
                        . $error->line
                        . q{: }
                        . $error->errtext
                        . qq{\n}
                    );
                }
            }
        }
    }
    # others should be copied (if they've changed
    else {
        # only copy files if the MD5 hasn't changed
        if (not $self->same_file(
                file($directory,$item),
                file($config->{output_dir},$relpath,$item)
            )
        ) {
            warn (q{Copying: } . $self->item_name($directory, $item) . qq{\n});
            # the ".q{}" forces stringification and resolves issues with
            # File::Copy::_eq() in perl-5.10
            copy(
                file($directory,$item) . q{},
                file($config->{output_dir},$relpath,$item) . q{}
            );
            $self->show_destination($directory, $item);
        }
    }

    return;
}

sub relative_path_from_full {
    my $self        = shift;
    my $directory   = shift;
    my $config      = $self->get_config->get_siteconfig();
    my ($relpath);

    # get the relative path from the full srcdir path
    $relpath = $directory;
    # remove source_dir from directory path
    $relpath =~ s:^$config->{source_dir}::;
    # remove leading / (if any)
    $relpath =~ s:^/::;     # fixme - assuming unix system

    return $relpath;
}

sub same_file {
    my $self = shift;
    my ($file1, $file2) = @_;

    if (! -f $file2 or ! -f $file2) {
        return 0;
    }

    if ($self->file_checksum($file1) eq $self->file_checksum($file2)) {
        return 1;
    }

    return 0;
}

sub show_destination {
    my $self = shift;
    my ($directory, $item) = @_;
    my ($relpath);

    # stuff we used to pass through in the script
    # TODO objectify this
    my $config  = $self->get_config->get_siteconfig();
    my $cliopt  = $self->get_config->get_options();

    # get the relative path for the directory
    $relpath = $self->relative_path_from_full($directory);

    if ($cliopt->{showdest}) {
        if ($relpath) {
            warn(
                    q{  --> }
                . file($config->{output_dir},$relpath,$item)
                . qq{\n}
            );
        }
        # top-level files don't have a relpath and we'd prefer not to have
        # '//' in the path
        else {
            warn(
                    q{  --> }
                . file($config->{output_dir},$item)
                . qq{\n}
            );
        }
    }

    return;
}

sub template_file {
    my ($self,$filename) = @_;
    my $config  = $self->get_config->get_siteconfig();

    foreach my $ignore_me (@{ $self->get_config->templated_files }) {
        my $regex = qr/ $ignore_me /x;

        if ($filename =~ $regex) {
            return 1;
        }
    }

    return;
}

sub always_process {
    my ($self,$filename) = @_;
    my $config  = $self->get_config->get_siteconfig();

    # if we haven't got anything listed in our siteconfig, we don't have any
    # special cases to worry about
    return
        if (not defined($self->get_config->always_process));

    # loop through our special cases ...
    foreach my $always_process (@{ $self->get_config->always_process }) {
        my $regex = qr/ $always_process /x;

        if ($filename =~ $regex) {
            return 1;
        }
    }

    return;
}



sub _prepare_template_object {
    my $self    = shift;
    my $config  = $self->get_config->get_siteconfig();
    #my $cliopt  = $self->get_config->get_options();

    my $tt_config = {
        ABSOLUTE        => 1,
        EVAL_PERL       => 0,
        INCLUDE_PATH    => "$config->{source_dir}:$config->{includes_dir}",
    };
    if (defined $config->{plugin_base}) {
        $tt_config->{PLUGIN_BASE} = $config->{plugin_base};
    }

    # if we've been given any tt_options, merge them into the config
    # now
    if (defined $config->{tt_options}) {
        my %merged_cfg = (
            %{ $tt_config },
            %{ $config->{tt_options} }
        );
        $tt_config = \%merged_cfg;
    }

    $self->set_ttobject(
        Template->new( $tt_config )
    );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Zucchini::Template - process templates and output static files

=head1 VERSION

version 0.0.21

=head1 SYNOPSIS

  # create a new templater object
  $templater = Zucchini::Template->new(
    { config => $self->get_config }
  );
  # process the site
  $templater->process_site;

=head1 DESCRIPTION

This module handles the processing of the template files into the
website source files.

The solution uses Template::Toolkit and tries to Be Smart - only process
that which has changed.

An exception to this is when a globally included file, for example header.tt,
has been modified. To apply this change to the site, one must either "touch"
all the templates, or use the 'force' option.

  # force all html files to be regenerated
  $ find . -name \*html -exec touch {} \;
  $ zucchini

  # brute force approach to regenerate all files
  $ zucchini --force

=head1 METHODS

=head2 new

Creates a new instance of the top-level Zucchini object:

  # create a new templater object
  $templater = Zucchini::Template->new(
    {
        config => $zucchini->get_config,
    }
  );

=head2 process_site

Gets appropriate site-config, and initiates the template-processing.

  # start the templating...
  $templater->process_site;

=head2 get_config / set_config

Returns/sets an object representing the current configuration.

  # get the current configuration
  $self->get_config;

  # get the source_dir from the configuration object
  $directory = $self->get_config->get_siteconfig->{source_dir};

=head2 get_ttobject / set_ttobject

Returns/sets the Template Toolkit object:

  # process the current item
  $self->get_ttobject->process(
    $template,
    \%data,
    $output_file
  );

=head2 process_directory

Perform the I<appropriate action> for each item in the given directory:
template or copy files; recurse directories. Ignore anything that should
be ignored, as per the site-config.

  # set off a cascading processing of the templates
  $templater->process_directory( $template_root_directory );

=head2 directory_contents

Get a list of everything (except . and ..) in the given directory.

  # get items in the site root
  @list = $templater->directory_contents( $template_root_directory );

=head2 file_checksum

Calculate an MD5 checksum for a given file.

  # get a checksum
  $checksum = $templater->file_checksum( $file );

=head2 file_modified

Given two files - a template file and its templated output - determine if
the template has been modified since the output was last generated.

  # do something with a changed template
  if ($self->file_modified($template, $output)) {
    # do stuff
  }

=head2 ignore_directory

Given a directory, determine if it should be ignored; useful for CVS/ and
.svn/ directories. Uses 'ignored_dirs' from site-config.

  # don't do anything with ignored directories
  if ($self->ignore_directory($dir)) {
    # next
  }

=head2 ignore_file

Given a file, determine if it should be ignored; useful for editor swap files.
Uses 'ignore_files' from site-config.

  # don't do anything with ignored files
  if ($self->ignore_file($file)) {
    # next
  }

=head2 item_name

Returns a filename, optionally formatted to include the full (destination)
path if 'showpath' option is active.

  # tell the user where we're putting something
  print   "Writing: "
        . $self->item_name($dir, $file)
        . "\n";

=head2 process_file

Given a file take one of the following actions: template it, copy it, ignore
it.

  # process the current file
  $self->process_file($dir, $file)

=head2 relative_path_from_full

This catchily named function returns the relative path to a directory,
from the template source dir; 'source_dir' in the site-config.

  # get the relative path ...
  $relpath = $self->relative_path_from_full( $dir );

=head2 same_file

Determine if two files are the same. Primarily used to avoid copying unchanged
files.

  if(not $self->same_file($file1, $file2)) {
    # do stuff
  }

=head2 show_destination

If the 'showdest' option is active, output where we are writing a file
to.

  # let user know where we're putting the item
  $self->show_destination($directory, $item);

=head2 template_file

Detemine if the file should be treated as a template. Template files are
specified by the 'template_files' variable in the site-config.

  if ($self->template_file($item)) {
    # do some templating magic
  }

=head1 SEE ALSO

L<Zucchini>,
L<Zucchini::Config>

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
