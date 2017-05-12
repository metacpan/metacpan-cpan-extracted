package Zucchini;
$Zucchini::VERSION = '0.0.21';
{
  $Zucchini::DIST = 'Zucchini';
}
# ABSTRACT: turn templates into static websites
# vim: ts=8 sts=4 et sw=4 sr sta
use Moo;
use strict; # for kwalitee testing
use Zucchini::Types qw(:all);

use Zucchini::Config;
use Zucchini::Fsync;
use Zucchini::Rsync;
use Zucchini::Template;

has config => (
    reader  => 'get_config',
    writer  => 'set_config',
    isa     => ZucchiniConfig,
    is      => 'ro',
);

sub BUILD {
    my ($self, $arg_ref) = @_;

    # set our config to be a new Zucchini::Config object
    # instantiated with the arguments passed to ourself
    $self->set_config(
        Zucchini::Config->new(
            $arg_ref
        )
    );

    return;
}

sub gogogo {
    my $self = shift;

    # if we're not rsync-only or fsync-only, we should perform the
    # template processing
    if (
        not (
            $self->get_config->is_rsync_only()
                or 
            $self->get_config->is_fsync_only()
        )
    ) {
        $self->process_templates;
    }
    # let verbose people know we're *NOT* processing any templates
    else {
        if ($self->get_config->verbose) {
            warn "Skipping template processing phase\n";
        }
    }


    # was a remote-sync requested?
    if (
        $self->get_config->is_rsync()
            or 
        $self->get_config->is_rsync_only()
    ) {
        $self->remote_sync;
    }

    # was an ftp-sync requested?
    if (
        $self->get_config->is_fsync()
            or 
        $self->get_config->is_fsync_only()
    ) {
        $self->ftp_sync;
    }
}

sub process_templates {
    my $self = shift;
    my ($templater);

    # create a new templater object
    $templater = Zucchini::Template->new(
        {
            config => $self->get_config,
        }
    );
    # process the site
    $templater->process_site;

    return;
}

sub ftp_sync {
    my $self = shift;
    my ($fsyncer);

    # create a new fsync object
    $fsyncer = Zucchini::Fsync->new(
        {
            config => $self->get_config,
        }
    );
    # transfer the site
    $fsyncer->ftp_sync;

    return;
}

sub remote_sync {
    my $self = shift;
    my ($rsyncer);

    # create a new rsync object
    $rsyncer = Zucchini::Rsync->new(
        {
            config => $self->get_config,
        }
    );
    # transfer the site
    $rsyncer->remote_sync;

    return;
}

# true value at tail end of module'
q{This truth was inspired by YAPC::Europe::2008};

__END__

=pod

=encoding UTF-8

=head1 NAME

Zucchini - turn templates into static websites

=head1 VERSION

version 0.0.21

=head1 SYNOPSIS

  $ zucchini --create-config    # create a default config

  $ perldoc Zucchini::Config    # information for configuring Zucchini

  $ perldoc zucchini            # the worker script

=head1 DESCRIPTION

You have a hosted website. It's static. Your website has the
same headers, footers, menu, etc.

Copying the same change from the header section in one file into
the other fifty-eight files in your site is boring.
It's also prone to error.

Ideally the site would be written using some kind of templating
system, so header files et al only needed to be updated once.

This is where Zucchini comes in. Zucchini processes a directory
of templates (written using L<Template::Toolkit> markup) and outputs
a static copy of each processed template.

You now have the source for a staic website, waiting to be uploaded
to your remote server - which, conveniently, Zucchini can do for you;
using rsync or ftp.

Zucchini is usually invoked through the C<zucchini> script, which is installed
as part of the package.

=head1 METHODS

=head2 new

Creates a new instance of the top-level Zucchini object:

  # create a new zucchini object
  $zucchini = Zucchini->new(
    \%cliopt
  );

=head2 gogogo

This function is called from the C<zucchini> script and decides what
actions to perform based on the command-line options passed to new()

  # work out what to do, and Just Do It
  $zucchini->gogogo;

=head2 process_templates

This function processes the template directories and outputs the static
website source files.

  # generate the static site
  $zucchini->process_templates;

=head2 ftp_sync

This function transfers the static website source files to the remote server
using an FTP solution.

  # transfer files to remote FTP site
  $zucchini->ftp_sync;

=head2 remote_sync

This function transfers the static website source files to the remote server
using an rsync solution.

  # transfer files to remote server, using rsync
  $zucchini->remote_sync;

=head1 SEE ALSO

L<Zucchini::Config>,
L<Zucchini::Fsync>,
L<Zucchini::Rsync>,
L<Zucchini::Template>,
L<Template>

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
