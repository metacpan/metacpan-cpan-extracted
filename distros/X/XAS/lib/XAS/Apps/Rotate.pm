package XAS::Apps::Rotate;

our $VERSION = '0.04';

use Try::Tiny;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::App',
  utils      => 'compress glob2regex',
  constants  => 'TRUE FALSE WILDCARD',
  filesystem => 'Dir File',
  constant => {
    X2SECS => {
        's' => 1,
        'm' => 60, 
        'h' => 60 * 60,
        'd' => 60 * 60 * 24,
        'w' => 60 * 60 * 24 * 7
    },
    X2BYTES => {
        b => 1,
        k => 1024, 
        m => 1024 * 1024, 
        g => 1024 * 1024 * 1024,
        t => 1024 * 1024 * 1204 * 1024
    }
  },
;

# ----------------------------------------------------------------------
# Global Variables
# ----------------------------------------------------------------------

my $compressor;
my $modify_age;
my $create_age;
my $compress;
my $ifempty;
my $method;
my $missingok;
my $file_size;
my $create_new;
my $prolog;
my $epilog;
my $lines_or_files;
my $line_count;
my $file_count;
my $pause;

my $zipcmd;
my $gzipcmd;
my $bzipcmd;
my $compcmd;
my $tailcmd;
my $logfile;

my @wanted_files;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub run_cmd {
    my $self = shift;
    my $cmd  = shift;

    #
    # Runs a command and places the output into the logfile. 
    #

    $self->log->info("running '$cmd'");

    my @output = `$cmd 2>&1`;
    foreach my $line (@output) {

        $self->log->info(compress($line));

    }

}

sub get_extension {
    my $self = shift;

    #
    # Return the compressor's extension.
    #

    my $ext;

    # Try to guess what the right extension would be 

    $ext = '.gz'  if ($compressor =~ /gzip/i);
    $ext = '.zip' if ($compressor =~ /zip/i);
    $ext = '.bz2' if ($compressor =~ /bzip2/i);
    $ext = '.Z'   if ($compressor =~ /compress/i);

    return($ext);

}

sub is_true {
    my $self = shift;
    my $parm = shift;

    #
    # Checks to see if the parameter is the string 't', 'true' or the number 1.
    #

    my @truth = qw(yes true t 1 0e0);

    return scalar(grep {lc($parm) eq $_} @truth);

}


sub is_false {
    my $self = shift;
    my $parm = shift;

    #
    # Checks to see if the parameter is the string 'f' or 'false' or the number 0.
    #

    my @truth = qw(no false f 0);

    return scalar(grep {lc($parm) eq $_} @truth);

}

sub is_oldder {
    my $self = shift;
    my $age_diff = shift;
    my $age = shift;

    #
    # Parses $age_diff and checks to see if the $age is newer than
    # the current time minus $age_diff. That is we return 
    # TRUE if a file is too new based on the criteria $age_diff and $age
    # and the implicit parameter: the current time.
    #

    return FALSE unless $age_diff;
    $self->log->debug("age_diff = $age_diff, age = $age");

    # Parse age string, e.g. 20 hours, 3 days, 4 weeks, etc.

    if ( $age_diff !~ /(\d+)\s+([smhdw])/i ) {

        $self->log->warn_msg('age_params', $age_diff);

        return FALSE;

    } else {

        my $sec_diff = $1 * X2SECS->{lc $2};
        my $diff = time() - $sec_diff;
        $self->log->debug("age = $age; diff = $diff");
        my $ret = $age <= $diff;
        $self->log->debug("is_oldder: $ret");

        return $ret;

    }

}

sub is_bigger {
    my $self = shift;
    my $size_spec = shift;
    my $size = shift;

    #
    # Parses $size_spec and checks to see if the $size is bigger than
    # that. We return TRUE if a file is too big.
    #

    return FALSE unless $size_spec;
    $self->log->debug("size_spec = $size_spec, size = $size");

    # Parse size string, e.g. 20 MB, 3 bytes, 4 GB, etc.

    if ($size_spec !~ /(\d+)\s+([bkmgt])/i ) {

        $self->log->warn_msg('size_params', $size_spec);

        return FALSE;

    } else {

        my $max_size = $1 * X2BYTES->{lc $2};
        my $ret = $size >= $max_size;

        $self->log->debug("is_bigger: $ret");

        return $ret;

    }

}

sub compress_file {
    my $self = shift;
    my $filename = shift;

    #
    # Compress the .0th version of this file.
    #

    my $cmd;
    my $ext;

    $self->log->debug("entering compress_file()");

    if ($self->is_true($compress)) {

        my $file = $filename->path . ".0";
        $ext = get_extension();
        $self->log->info_msg('compressing', $file);

        if ($compressor =~ /zip/i) {

            $cmd = $zipcmd . " -m " . $file . $ext . " " . $file;
            $self->log->debug("ZIP command = $cmd");

        } elsif ($compressor =~ /gzip/i) {

            $cmd = $gzipcmd . " " . $file;
            $self->log->debug("GZIP command = $cmd");

        } elsif ($compressor =~ /bzip2/i) {

            $cmd = $bzipcmd . " " . $file;
            $self->log->debug("BZIP2 command = $cmd");

        } elsif ($compressor =~ /compress/i) {

            $cmd = $compcmd . " " . $file;
            $self->log->debug("COMPRESS command = $cmd");

        }

        $self->run_cmd($cmd);
        $self->log->error_msg('nocompress', $file) if $?;

    }

    $self->log->debug("leaving compress_file()");

}

sub recreate_file {
    my $self = shift;
    my $filename = shift;

    #
    # Recreate the file if needed.
    #

    my $cmd;
    my $tmpname;

    $self->log->debug("entering recreate_file()");
    $self->log->debug("filename = " . $filename->path);

    if ($self->is_true($create_new)) {

        if ($lines_or_files =~ /files/i) {

            try {

                # thanks MS, Windows doesn't delete files in a timely
                # manner, so the below code is needed to ensure file
                # deletion...

                for (1..20) {

                    last unless ($filename->exists);
                    $filename->delete();
                    sleep($pause);

                }

                $filename->open('w');

            } catch {

                my $ex = $_;
                my $ref = ref($ex);

                $self->log->warn_msg('norecreate', $filename->path);

            };

        } else {

            $tmpname = $filename->path . '.0';

            if ($^O eq 'MSWin32') {

                #
                # The Tail command from the Windows 2003 Resource Kit
                # is broken. The -n switch does not work, so the default
                # number of lines is used.
                #

                $cmd = $tailcmd . " " . $tmpname . ' > ' . $filename->path;

            } else {

                $cmd = $tailcmd . ' -n ' . $line_count . ' ' . $tmpname . ' > ' . $filename->path;

            }

            $self->run_cmd($cmd);
            $self->log->error_msg('notail', $line_count, $filename) if $?;

        }

    }

    $self->log->debug("leaving recreate_file()");

}

sub rotate_file {
    my $self = shift;
    my $filename = shift;

    #
    # Rotate the files.
    #

    my $x;
    my $count;
    my $tmpname;
    my $prvname;
    my $first = TRUE;
    my $ext = $self->get_extension();   

    $self->log->debug("entering rotate_file(); filename = $filename");

    for ($count = $file_count - 1; $count > 0; $count--) {

        $tmpname = File($filename->path . '.' . $count);
        $tmpname = File($tmpname->path . $ext) if ($self->is_true($compress));
        $self->log->debug("tmpname = $tmpname");

        if ($first) {

            unlink($tmpname->path);
            $self->log->debug("removed $tmpname");
            $first = FALSE;

        }

        $x = $count - 1;
        $prvname = File($filename->path . '.' . $x);
        $prvname = File($prvname->path . $ext) if ($self->is_true($compress));
        $self->log->debug("prvname = $prvname");

        if ($prvname->exists) {

            if ($method =~ /copy/i) {

                $prvname->copy($tmpname->path);
                $self->log->info_msg('copied', $prvname, $tmpname);

            } else { 

                $prvname->move($tmpname->path); 
                $self->log->info_msg('moved', $prvname, $tmpname);

            }

        } else {

            $self->log->warn_msg('noexist', $prvname);

        }

    }

    if ($method =~ /copy/i) {

        $filename->copy($filename->path . '.0');
        $self->log->info_msg('copied', $filename, $filename. '.0');

    } else { 

        $filename->move($filename->path . '.0');
        $self->log->info_msg('moved', $filename, $filename . '.0');

    }

    $self->log->debug("leaving rotate_file()");

}

sub process_files {
    my $self = shift;

    #
    # Process the files.
    #

    my $ran_prolog = FALSE;
    
    $self->log->debug("entering process_files()");

    if (($prolog) && (scalar(@wanted_files) > 0)) {

        
        $ran_prolog = TRUE;
        $self->run_cmd($prolog);
        sleep $pause;

    }

    while (my $filename = pop(@wanted_files)) {

        $self->log->debug("processing $filename->path");

        $self->rotate_file($filename);
        $self->recreate_file($filename);
        $self->compress_file($filename);

    }

    if (($epilog) && ($ran_prolog)) {

        $self->run_cmd($epilog);
        sleep $pause;

    }

    $self->log->debug("leaving process_files()");

}

sub find_files {
    my $self = shift;
    my $from = shift;

    #
    # Scan the local directory looking for files to rotate.
    #

    $self->log->debug("entering find_files()");

    my @files;
    my $fdir = Dir($from->volume, $from->dir);

    $self->log->info_msg('processing', $from->name, $fdir->path);

    if ($from->name =~ WILDCARD) {

        my $regex = glob2regex($from->name);
        my $pattern = qr/$regex/;

        @files = grep ( $_->path =~ /$pattern/, $fdir->files() );

    } else {

        push(@files, $from);

    }

    foreach my $file (@files) {

        next unless($file->exists);

        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,
            $size,$atime,$mtime,$ctime,$blksize,$blocks) = $file->stat;

        $self->log->debug("file = $file, size = $size, ctime = $ctime, mtime = $mtime");

        if ($self->is_oldder($modify_age, $mtime)) {

            if (($size != 0) && ($self->is_false($ifempty))) {

                push(@wanted_files, $file);
                $self->log->debug("added $file; modify-age");

            }

        } elsif ($self->is_oldder($create_age, $ctime)) {

            if (($size != 0) && ($self->is_false($ifempty))) {

                push(@wanted_files, $file);
                $self->log->debug("added $file; create-age");

            }

        } elsif ($self->is_bigger($file_size, $size)) {

            if (($size != 0) && ($self->is_false($ifempty))) {

                push(@wanted_files, $file);
                $self->log->debug("added $file; file-size");

            }

        }

    }

    $self->log->debug("the wanted_files array has $#wanted_files elements");

    if ($#wanted_files < 0) {

        $self->log->warn_msg('nomatch', $fdir->path, $from->name) if ($self->is_true($missingok));

    }

    $self->log->debug("leaving find_files()");

}

sub setup {
    my $self = shift;

    $compressor = $self->cfg->val('settings', 'compressor', 'zip');
    $zipcmd     = $self->cfg->val('settings', 'zip-command', 'c:\bin\zip.exe');
    $gzipcmd    = $self->cfg->val('settings', 'gzip-command', 'c:\bin\gzip.exe');
    $bzipcmd    = $self->cfg->val('settings', 'bzip2-command', 'c:\bin\bzip2.exe');
    $compcmd    = $self->cfg->val('settings', 'compress-command', 'c:\bin\compress.exe');
    $tailcmd    = $self->cfg->val('settings', 'tail-command', 'c:\bin\tail.exe');

}

sub main {
    my $self = shift;

    $self->setup();

    my $directory;
    my @sections = $self->cfg->Sections();

    $self->log->info('start run');
    $self->log->debug("found $#sections Sections");

    foreach my $section (@sections) {

        $self->log->debug("section = $section");
    
        next if ($section =~ /settings/i);

        $directory  = File($section);

        $modify_age = $self->cfg->val($section, 'modify-age');
        $create_age = $self->cfg->val($section, 'create-age');
        $file_size  = $self->cfg->val($section, 'file-size');
        $compress =   $self->cfg->val($section, 'compress', 'false');
        $create_new = $self->cfg->val($section, 'create-new', 'false');
        $ifempty =    $self->cfg->val($section, 'ifempty', 'false');
        $file_count = $self->cfg->val($section, 'file-count', '5');
        $method =     $self->cfg->val($section, 'method', 'copy');
        $missingok =  $self->cfg->val($section, 'missingok', 'true');
        $line_count = $self->cfg->val($section, 'line-count', '10');
        $prolog =     $self->cfg->val($section, 'prolog');
        $epilog =     $self->cfg->val($section, 'epilog');
        $pause =      $self->cfg->val($section, 'pause', '10');
        $lines_or_files = $self->cfg->val($section, 'lines-or-files', 'files');

        $self->find_files($directory);
        $self->process_files();

    }

    $self->log->info('stop run');

}

sub options {
    my $self = shift;

    return {
        'cfgfile=s' => sub { 
            my $cfgfile = File($_[1]); 
            $self->env->cfgfile($cfgfile);
        },
    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{cfg} = Config::IniFiles->new(
        -file    => $self->cfgfile->path,
        -default => 'settings',
    ) or $self->throw_msg(
        'xas.apps.rotate.init.badini',
        'badini',
        $self->cfgfile->path
    );

    return $self;

}

1;

__END__

=head1 NAME

XAS::Apps::Rotate - Rotate files based on a config file

=head1 SYNOPSIS

 use XAS::Apps::Rotate;

 my $app = XAS::Apps::Rotate->new(
    -throws   => 'rotate',
    -facility => 'systems',
    -priority => 'warn',
 );

 exit $app->run;

=head1 DESCRIPTION

This module is used to rotate files.

=head1 CONFIGURATION

The configuration file uses the standard windows .ini file. It has the
following format.

 [settings]
 compressor = zip         - default file compressor
 zip-command              - zip command defaults to 'c:\bin\zip.exe'
 gzip-command             - gzip command defaults to 'c:\bin\gzip.exe'
 bzip2-command            - bzip2 command defaults to 'c:\bin\bzip2.exe'
 compress-command         - compress command defaults to 'c:\bin\compress.exe'
 tail-command             - tail command defaults to 'c:\bin\tail.exe'

 [log\test.log]           - file to process, may have DOS wildcards
 compress = true          - wither to compress the file
 method = move            - how to handle the file
 missingok = false        - whither a missing file is OK
 lines-or-files = files   - 
 create-new = false       - create a new file after rotation
 modify-age               - process based on last modification
 create-age               - process based in creation time
 file-size                - process based on file size
 ifempty                  - process if file is empty
 file-count               - number of rotated files kept
 line-count               - how many line to transfer to new file
 prolog                   - command to process before rotation
 epilog                   - command to process after rotation
 pause                    - number of seconds to pause after prolog and epilog

=head1 METHODS

=head2 main

Process the configuration file.

=head2 run_cmd($cmd)

Run a command and capture the output to the log file.

=over 4

=item B<$cmd>

The command to run.

=back

=head2 get_extension

Return the file extension base on compressor type.

=head2 is_true($param)

Return TRUE or FALSE based on $param. If $param is 'true', or 1 then TRUE.

=head2 is_false($param)

Return TRUE or FALSE based on $param. If $param is 'false' or 0 then TRUE.

=head2 is_older($age_diff, $age)

Parses $age_diff and checks to see if the $age is newer than
the current time minus $age_diff. That is we return 
TRUE if a file is too new based on the criteria $age_diff and $age
and the implicit parameter: the current time.

=head2 is_bigger($size_spec, $size)

Parses $size_spec and checks to see if the $size is bigger than
that. We return TRUE if a file is too big.

=head2 compress_file($filename)

Compress the file based on chosen compression type.

=over 4

=item B<$filename>

The file to compress

=back

=head2 recreate_file($filename)

Recreate the file if needed. This checks the file-or-line config item.
If it is 'file' then a new file is created, if it is 'lines' then 
the config item 'line-count' is used to copy that number of lines from
the end of the file into the beginning of the new file.

=over 4

=item B<$filename>

The file to recreate.

=back

=head2 rotate_file($filename)

Perform the basic file rotation.

=over 4

=item B<$filename>

The file to rotate.

=back

=head2 process_files

Process the selected files. It preforms the following actions:

=over 4

=item 1 Process the prolog command.

=item 2 Rotate the file.

=item 3 Recreate the new file.

=item 4 Compress the rotated file

=item 5 Process the epilog command.

=back

=head2 find_files

Scan the local directory looking for files to rotate.

=head1 SEE ALSO

L<Rotate|Rotate>

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

TThis is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
