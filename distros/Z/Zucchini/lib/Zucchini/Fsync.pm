package Zucchini::Fsync;
$Zucchini::Fsync::VERSION = '0.0.21';
{
  $Zucchini::Fsync::DIST = 'Zucchini';
}
# ABSTRACT: move files using FTP
# vim: ts=8 sts=4 et sw=4 sr sta
use Moo;
use strict; # for kwalitee testing
use MooX::Types::MooseLike::Base qw(:all);
use Zucchini::Types qw(:all);

use Carp;
use Config::Any;
use Digest::MD5 qw(md5_hex);
use File::Basename;
use File::Find;
use File::Slurp qw(read_file write_file);
use File::Temp qw( tempfile );
use Net::FTP;
use Path::Class;

# class data
has config => (
    reader  => 'get_config',
    writer  => 'set_config',
    isa     => ZucchiniConfig,
    is      => 'ro',
);
has ftp_client => (
    reader  => 'get_ftp_client',
    writer  => 'set_ftp_client',
    isa     => NetFTP,
    is      => 'ro',
);
has ftp_root => (
    reader  => 'get_ftp_root',
    writer  => 'set_ftp_root',
    isa     => Str,
    is      => 'ro',
);
has remote_digest => (
    reader  => 'get_remote_digest',
    writer  => 'set_remote_digest',
    isa     => Str,
    is      => 'ro',
);

sub BUILD {
    my $self = shift;

    # set up an ftp client/connection to work with
    if (defined $self->get_config) {
        $self->prepare_ftp_client;
    }
}

sub build_transfer_actions {
    my $self = shift;
    my $config  = $self->get_config->get_siteconfig();
    my ($local_digest_file, $remote_digest_file);
    my ($local_md5_of, $remote_md5_of, %transfer_action_of);

    # the two files we are going to compare
    $local_digest_file = file(
        $config->{output_dir},
        q{digest.md5}
    );
    $remote_digest_file = file(
        $self->get_remote_digest
    );

    $local_md5_of   = $self->parse_md5file($local_digest_file);
    $remote_md5_of  = $self->parse_md5file($remote_digest_file) || {};

    # run through the list of files we have locally
    foreach my $relpath (
        sort { length($a) <=> length($b) } keys %{$local_md5_of}
    ) {
        my $dirname     = dirname($relpath);
        my $parentdir   = dir($dirname)->parent();

        # make sure our parent directory exists
        # (prevents problems with nested dirs that contain no files)
        while (
            q{..} ne $parentdir
                and 
            not exists $transfer_action_of{$parentdir}
        ) {
            # this is effectively a NO-OP that gets the directory name
            # into the list of (required) remote directories
            push @{$transfer_action_of{$parentdir}},
            {
                action  => 'dir-dir',
            };

            # recurse upwards
            $parentdir = $parentdir->parent();
        }

        # does the file live in the server?
        if (exists $remote_md5_of->{$relpath}) {
            # if the MD5s match - nothing to do
            if ($local_md5_of->{$relpath} eq $remote_md5_of->{$relpath}) {
                delete $local_md5_of->{$relpath};
                delete $remote_md5_of->{$relpath};
                next;
            }

            push @{$transfer_action_of{$dirname}},
            {
                action  => 'update',
                relname => $relpath,
            };
            delete $local_md5_of->{$relpath};
            delete $remote_md5_of->{$relpath};
        }
        # ... it's a new file to put on the server
        else {
            push @{$transfer_action_of{$dirname}},
            {
                action  => 'new',
                relname => $relpath,
            };
            delete $local_md5_of->{$relpath};
        }
    }

    # anything left in remote is a file we don't have locally
    # we'll store actions (remove) for these, but won't act on the
    # action until specifically asked
    foreach my $relpath (sort keys %{$remote_md5_of}) {
        my $dirname = dirname($relpath);
        push @{$transfer_action_of{$dirname}},
        {
            action  => 'remove',
            relname => $relpath,
        };
        delete $remote_md5_of->{$relpath};
    }

    # make sure we didn't miss anything
    if (keys %{$local_md5_of}) {
        warn qq{Some local files were not processed};
        warn qq{Local:   } . pp($local_md5_of);
    }
    if (keys %{$remote_md5_of}) {
        warn qq{Some remote files were not processed};
        warn qq{Remote:   } . pp($remote_md5_of);
    }

    return \%transfer_action_of;
}

sub do_remote_update {
    my $self                = shift;
    my $transfer_actions    = shift;
    my $config              = $self->get_config->get_siteconfig();
    my $ftp                 = $self->get_ftp_client;
    my $ftp_root            = $self->get_ftp_root;
    my $errors              = 0;

    if (not defined $ftp) {
        warn(qq{No FTP server defined. Aborting upload.\n});
        return;
    }

    # do transfer actions shortest dirname first
    my @remote_dirs = sort {
        length($a) <=> length($b)
    } keys %{$transfer_actions};

    my $ftp_root_status = $ftp->cwd($ftp_root);
    if (not $ftp_root_status) {
        die "$ftp_root: couldn't CWD to remote directory\n";
    }
    my $default_dir = $ftp->pwd();
    if ($default_dir !~ m{/\z}xms) {
        $default_dir .= q{/};
    }

    # make missing (remote) directories
    warn "checking remote directories...\n"
        if ($self->get_config->verbose(1));
    foreach my $dir (@remote_dirs) {
        my $status = $ftp->cwd($default_dir . $dir);
        if (not $status) {
            # verbose ouput
            warn (q{MKDIR } . dir($default_dir, $dir) . qq{\n})
                if ($self->get_config->verbose(1));
            # make the missing directory
            if (not $ftp->mkdir($default_dir . $dir)) {
                warn (
                        q{FAILED MKDIR }
                    . dir($default_dir, $dir) 
                    . q{ - }
                    . $ftp->message
                    . qq{\n});
            }
        }
    }
    # return to the default location
    $ftp->cwd($default_dir);

    # now run through everything and take the appropriate action for files
    warn "transferring files...\n"
        if ($self->get_config->verbose(1));
    foreach my $dir (@remote_dirs) {
        # run through the actions for the directory
        foreach my $action ( @{$transfer_actions->{$dir}} ) {
            if ($action->{action} =~ m{\A(?:new|update)\z}) {
                # verbose ouput
                warn (
                        q{PUT }
                    . $action->{relname}
                    . q{ }
                    . $action->{relname}
                    . qq{\n}
                )
                    if ($self->get_config->verbose(1));
                # send the file
                if (not $ftp->put( $action->{relname}, $action->{relname} )) {
                    $errors++;
                    warn "failed to upload $action->{relname}\n";
                    warn (
                        q{FAILED PUT }
                        . $action->{relname}
                        . q{ }
                        . $action->{relname}
                        . q{ - }
                        . $ftp->message
                        . qq{\n}
                    );
                }
            }
        }
    }

    # if we didn't have any errors, upload the digest
    if (not $errors) {
        # verbose ouput
        warn (
                q{PUT }
            . q{digest.md5}
            . qq{\n}
        )
            if ($self->get_config->verbose(1));
        # upload the digest file
        $ftp->put('digest.md5');
    }
    else {
        warn qq{$errors error(s), digest file not transferred\n};
    }
}

sub fetch_remote_digest {
    my $self = shift;
    my $config  = $self->get_config->get_siteconfig();
    my ($fh, $filename, $get_ok);

    # a temporary file to use
    ($fh, $filename) = tempfile();
    $config->{tmp_remote_digest} = $filename;

    # get the (remote) digest file
    $get_ok = $self->get_ftp_client->get(
        file(
            $self->get_ftp_root(),
            q{digest.md5}
        ),
        $filename
    );
    if (not $get_ok) {
        warn "No remote digest\n";
        return;
    }

    $self->set_remote_digest($filename);

    return;
}

sub ftp_sync {
    my $self    = shift;
    my $config  = $self->get_config->get_siteconfig();
    my (@md5strings, $transfer_actions);

    # make sure we have an ftp client to use
    if (not defined $self->get_ftp_client) {
        warn(qq{Failed to obtain remote FTP connection. Aborting upload.\n});
        return;
    }

    # regenerate (local) md5s
    find(
        sub{
            $self->local_ftp_wanted(\@md5strings);
        },
        $config->{output_dir}
    );
    write_file(
        qq{$config->{output_dir}/digest.md5},
        @md5strings
    );

    # get the remote digest
    $self->fetch_remote_digest;

    # work out what needs to happen
    $transfer_actions = $self->build_transfer_actions;

    # do the remote update
    $self->do_remote_update($transfer_actions);

    return;
}

sub local_ftp_wanted {
    my ($self, $md5string_list) = @_;
    my $config  = $self->get_config->get_siteconfig();

    if (
        -f $_
            and
        $_ ne q{digest.md5}
            and
        $_ !~ m{\.sw?}
    ) {
        push @{$md5string_list},
                $self->md5file($File::Find::name)
            . qq{\n};
    }
}

sub md5file {
    my ($self, $file) = @_;
    my $config  = $self->get_config->get_siteconfig();
    my $dir_prefix = $config->{output_dir};
    my ($filedata, $md5sum, $rel_filename, $md5data);

    # slurp the file
    $filedata = read_file($file)
        or die "$file: $!";
    # get the md5sum of the file
    $md5sum = md5_hex($filedata);
    # trim off any leading directories - making filename relative)
    if (defined $dir_prefix) {
        $rel_filename = $file;
        $rel_filename =~ s{\A${dir_prefix}/}{};
    }

    # return an md5 string
    return "$md5sum    $rel_filename";
}

sub parse_md5file {
    my ($self, $file) = @_;
    my (%md5_of, @lines);

    if (not defined $file or $file =~ m{\A\s*\z}) {
        # empty digest file
        carp "undefined filename passed to parse_md5file()"
            if ($self->get_config->verbose(2));
        return {};
    }

    if (! -f $file) {
        carp "$file: file not found"
            if ($self->get_config->verbose(2));
        return {};
    }

    # read in the file - ".q{}" forces any Path::Class objects to be
    # stringified
    @lines = read_file($file.q{})
        or die "$file: $!";

    # parse/split each line
    foreach my $line (@lines) {
        chomp($line);
        if ($line =~ m{\A([a-z0-9]{32})\s+(.+)\z}xms) {
            $md5_of{$2} = $1;
        }
    }

    return \%md5_of;
}

sub prepare_ftp_client {
    my $self = shift;
    my $config      = $self->get_config->get_siteconfig();
    my $cliopt      = $self->get_config->get_options();

    # make sure we have some defaults
    $config->{ftp}{hostname}    ||= 'localhost';
    $config->{ftp}{passive}     ||= 0;
    $config->{ftp}{username}    ||= 'anonymous';
    $config->{ftp}{password}    ||= 'coward';

    # if we already have an FTP object, use it
    if (defined $self->get_ftp_client) {
        warn qq{using existing FTP object\n}
            if ($self->get_config->verbose(3));
        # nothing to actually do
    }
    else {
        # make sure we can chdir() to the local root
        if (not chdir($config->{output_dir})) {
            warn qq{could not chdir to: $config->{output_dir}\n};
            exit;
        }

        warn qq{creating new FTP object\n}
            if ($self->get_config->verbose(3));
        my $ftp = Net::FTP->new(
            $config->{ftp}{hostname},
            Debug   => ($cliopt->{'ftp-debug'} || 0),
            Passive => $config->{ftp}{passive},
        );
        # make sure we've got a usable FTP object
        if (not defined $ftp) {
            warn(qq{Failed to connect to server [$config->{ftp}{hostname}]: $!\n});
            return;
        };
        # try to login
        if (not $ftp->login(
                $config->{ftp}{username},
                $config->{ftp}{password}
            )
        ) {
            warn(qq{Failed to login as $config->{ftp}{username}\n});
            return;
        }
        # try to cwd, if required
        if (defined $config->{ftp}{path}) {
            if (not $ftp->cwd( $config->{ftp}{path} ) ) {
                warn(qq{Cannot change directory to $config->{ftp}{path}\n});
                return;
            }
        }
        # use binary transfer mode
        if (not $ftp->binary()) {
            warn(qq{Failed to set binary mode\n});
            return;
        }

        # set our FTP_ROOT based on where we are now
        $self->set_ftp_root(
            $ftp->pwd()
        );

        $self->set_ftp_client($ftp);
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Zucchini::Fsync - move files using FTP

=head1 VERSION

version 0.0.21

=head1 SYNOPSIS

  # create a new fsync object
  $fsyncer = Zucchini::Fsync->new(
    {
      config => $self->get_config,
    }
  );

  # transfer the site
  $fsyncer->ftp_sync;

=head1 DESCRIPTION

This module implements the functionality to transfer files to the remote site
using FTP.

Because it's slow, painful, annoying and just plain wasteful (of bandwidth)
the module uses digest files to mimic a form of rsync-over-ftp.

The first ftp-sync for any site will require a full upload, as there is no
digest file to compare against. Subsequent transfers should only transfer
modified files.

=head1 METHODS

=head2 new

Creates a new instance of the Zucchini Fsync object:

  # create a new fsync object
  $fsyncer = Zucchini::Fsync->new(
    {
      config => $zucchini->get_config,
    }
  );

=head2 ftp_sync

This is the top-level function that prepares data, and performs the remote
upload.

  # create a new fsync object
  $fsyncer = Zucchini::Fsync->new(
    {
      config => $self->get_config,
    }
  );

  # transfer the site
  $fsyncer->ftp_sync;

=head2 get_config

Returns an object representing the current configuration.

  # get the current configuration
  $self->get_config;

  # get the source_dir from the configuration object
  $directory = $self->get_config->get_siteconfig->{source_dir};

=head2 get_ftp_client

Returns a Net::FTP object, logged-in to the remote server.

  # make a remote directory
  $fsyncer->get_ftp_client->mkdir( $dir );

=head2 get_ftp_root

Returns the remote directory to treat as the base directory on the remote
server.

  # change to the remote base directory
  $fsyncer->get_ftp_client->cd(
    $fsyncer->get_ftp_root
  );

=head2 get_remote_digest

After the remote digest has been copied locally for comparison, this method
will return the full path to the file.

  # read the remote digest file into a scalar
  use File::Slurp qw(read_file);
  @digest_lines = read_file(
    $fsyncer->get_remote_digest
  );

=head2 build_transfer_actions

This method compares two digest files and determines the actions that are
required to mirror the local digest remotely.

Files not listed in either digest are ignored.

  # get a list of actions to perform on the remote FTP server
  $transfer_actions = $fsyncer->build_transfer_actions;

The function returns a list of actions of the form:

  [
    'dirname' => {
        action  => 'update|new|remove|dir-dir',
        relname => $filename_relative_to_site_root,
    },

    ...
  ]

=head2 do_remote_update

This function processes the results of build_transfer_actions() to perform the
required actions on the remote FTP server.

  # update files on the remote server
  $fsyncer->do_remote_update($transfer_actions);

=head2 fetch_remote_digest

This function retrieves the digest file from the remote server, saves it
locally, and sets the remote_digest attribute on the object, for later
retrieval with get_remote_digest()

  # get the remote digest
  $self->fetch_remote_digest;

=head2 local_ftp_wanted

Used as the \&wanted in the call to File::Find::find() in conjunction with
md5file() to build the list of digest records ("md5   filename") for the local
output directory. 

  # regenerate (local) md5s
  find(
    sub{
      $fsyncer->local_ftp_wanted(\@md5strings);
    },
    $config->{output_dir}
  );

=head2 md5file

Generates a single digest entry for a given file

  # generate a digest entry
  $entry = $fsyncer->md5file($file);

=head2 parse_md5file

Given an md5file returns a hash-ref of the form:

  {
    'file_with_path' => 'md5sum',
    ...
  }

The method is primarily used in build_transfer_actions() to determine what
actions need to be taken

  # get md5 details from the digest file
  $local_md5_of = $fsyncer->parse_md5file($local_digest_file);

=head2 prepare_ftp_client

This method creates an Net::FTP object, log in to the remote server and store
the object for later retrieval using get_ftp_client().

  # set up an ftp client/connection to work with
  if (defined $self->get_config) {
    $self->prepare_ftp_client;
  }

=head1 SEE ALSO

L<Zucchini>,

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
