package VCS::SaVeS::SVS;
$VERSION = '0.10';
use 5.005;
use strict;
#use VCS::SaVeS::Config;
#my $config = VCS::SaVeS::Config->new();

###############################################################################
# debugging support
###############################################################################
sub DUMP {
    require YAML;
    print STDERR YAML::Dump(@_);
}
sub PRINT {
    print STDERR @_, "\n";
}
sub DIE {
    die @_, "\n";
}

###############################################################################
# command support routines
###############################################################################
sub add {
    my ($self, $switches, $files) = @_;
    assert_repository();
    validate_files($files);
    my $file_list = files_not_in_manifest($files);
    write_manifest([read_manifest(), $file_list]);
    initialize_repository();
    my $count = update_repository($file_list, 
                                  get_message($switches));
    printf STDOUT "%d files added to MANIFEST\n", $count;
}

sub break {
    my ($self, $switches, $files) = @_;
    validate_no_files($files);
    assert_no_repository();
    make_repository();
    write_manifest([]);
    print STDOUT ".saves breakpoint created\n";
}

sub delete {
    my ($self, $switches, $files) = @_;
    assert_repository();
    validate_files($files);
    my %manifest = map {($_, 1)} @{read_manifest()};
    my $file_list = files_in_manifest($files);
    DIE "None of these files are in the manifest"
      unless @$file_list;
    if (not defined $switches->{f}) {
        printf "Are you sure you want to delete %d files from the repository? ",
               0+@$file_list;
        my $answer = <STDIN>;
        unless ($answer =~ /^(y|yes)$/i) {
            print STDOUT "svs delete aborted\n";
            return;
        }
    }
    for (@$file_list) {
        delete $manifest{$_};
        system("rm -f .saves/SAVES/$_,v") == 0
          or DIE "Can't delete .saves/SAVES/$_,v";
    }
    write_manifest([keys %manifest]);
    printf STDOUT "%d files deleted from .saves repository\n", 0+@$file_list;
}

sub diff {
    my ($self, $switches, $files) = @_;
    assert_repository();
    push @$files, '.' unless @$files;
    validate_files($files);
    show_diff($files, $switches);
}

sub find {
    my ($self, $switches, $files) = @_;
    assert_repository();
    my $pattern = $files->[0] || '';
    my $regexp = qr{$pattern};
    print "$_\n" for grep {$_ =~ $regexp}
      @{read_manifest()};
}

sub help {
    my ($self, $switches, $sections) = @_;
    my $section;
    DIE "'svs help' only takes one argument at a time"
      if @$sections > 1;
    require VCS::SaVeS::Help;
    $section = @$sections
               ? $sections->[0]
               : 'general';
    print STDOUT VCS::SaVeS::Help->$section;
}
    
sub history {
    my ($self, $switches, $files) = @_;
    assert_repository();
    assert_file_in_repository($files);
    my $file = $files->[0];
    dump_history($file);
}

sub import_ {
    my ($self, $switches, $files) = @_;
    assert_no_repository();
    push @$files, '.' unless @$files;
    validate_files($files);
    make_repository();
    write_manifest($files);
    initialize_repository();
    my $count = update_repository(read_manifest(), 
                                  get_message($switches));
    printf STDOUT "%d files imported\n", $count;
}

sub manifest {
    my ($self, $switches, $files) = @_;
    assert_repository();
    if (@$files) {
        write_manifest($files);
        print("MANIFEST updated\n");
    }
    else {
        display_manifest();
    }
}

sub remove {
    my ($self, $switches, $files) = @_;
    assert_repository();
    validate_files($files);
    my %manifest = map {($_, 1)} @{read_manifest()};
    my $file_list = files_in_manifest($files);
    delete $manifest{$_} for @$file_list;
    write_manifest([keys %manifest]);
    printf STDOUT "%d files removed from MANIFEST\n", 0+@$file_list;
}

sub restore {
    my ($self, $switches, $files) = @_;
    assert_repository();
    assert_file_in_repository($files);
    my $file = $files->[0];
    my $revision = $switches->{r} || @{parse_rlog($file)};
    if ($revision =~ /^\d+$/ and $revision > 0) {
        restore_by_number($file, $revision);
    }
    else{
        DIE "-n must be positive integer";
    }
}

sub save {
    my ($self, $switches, $files) = @_;
    assert_repository();
    push @$files, '.' unless @$files;
    validate_files($files);
    my $count = update_repository(files_in_manifest($files),
                                  get_message($switches));
    printf STDOUT "%d files saved\n", $count;
}

sub status {
    my ($self, $switches, $files) = @_;
    assert_repository();
    push @$files, '.' unless @$files;
    validate_files($files);
    show_status(files_in_manifest($files));
}

sub version {
    print STDOUT <<VERSION;

You are using version $VCS::SaVeS::SVS::VERSION of SaVeS (Standalone Versioning System)

VERSION
}

###############################################################################
# support routines
###############################################################################
sub get_message {
    my ($switches) = @_;
    my $default = '...';
    return $default if defined $switches->{M};

    if (defined $switches->{m}) {
        return $switches->{m} || $default;
    }
    $| = 1;
    my $msg = '';
    print "Enter a message, terminated with single '.' or end of file:\n";
    print ">> ";
    my $line = <STDIN>;
    while (defined $line and $line !~ /^\.$/) {
        $msg .= $line;
        print ">> ";
        $line = <STDIN>;
    }
    unless ($msg =~ /\n./s) {
        chomp $msg;
    }
    return $msg || $default;
}

sub make_repository {
    use File::Path;
    mkpath('.saves/SAVES');
}

sub write_manifest {
    my ($file_list) = @_;
    my $files = find_all_files_in_list($file_list);

    chmod 0644, '.saves/MANIFEST';
    open MANIFEST, "> .saves/MANIFEST" 
        or DIE $!;
    print MANIFEST <<END;
#==============================================================================
#
# This file was generated by the SaVeS system. It contains a manifest of
# all the files that are currently active. Note that this file contains
# no directory names. SaVeS only affects files, not directories.
#
# Please don't edit this file by hand. The following commands should be
# used to change the manifest:
#   
#   svs import - create a new manifest and set its initial contents
#   svs manifest - list or set the manifest contents
#   svs add - add a list of files to the manifest 
#   svs remove - remove a list of files from the manifest
#
#==============================================================================
END

    if (@$files) {
        print MANIFEST "$_\n" for @$files;
    }
    else {
        print MANIFEST <<END;
# NOTE: This manifest is EMPTY! If there were files in the manifest,
#       they would be listed right here.
END
    }
    
    close MANIFEST;
    chmod 0444, '.saves/MANIFEST';
}

sub initialize_repository {
    my $files = read_manifest();
    make_SAVES_paths($files);
    my $shell_commands = '';
    for my $file (@$files) {
        unless (-f ".saves/SAVES/$file,v") {
            $shell_commands .= 
              qq{rcs -q -i .saves/SAVES/$file,v < /dev/null\n};
        }
    }
    open SH, "| sh" or DIE $!;
    print SH $shell_commands;
    close SH;
}

sub update_repository {
    my ($files, $msg) = @_;
    my $shell_commands = '';
    my %stamp;
    for my $file (@$files) {
        $shell_commands .= qq{ci -q -l -m"$msg" $file .saves/SAVES/$file,v\n};
        $stamp{$file} = -M ".saves/SAVES/$file,v";
    }
    open SH, "| sh" or DIE $!;
    print SH $shell_commands;
    close SH;
    my $count = 0;
    for my $file (@$files) {
        $count++, next if $stamp{$file} < .000001;
        next unless -e ".saves/SAVES/$file,v";
        if ((-M $file) < (-M ".saves/SAVES/$file,v")) {
            system "touch .saves/SAVES/$file,v";
        }
        $count++ if (-M ".saves/SAVES/$file,v") < $stamp{$file};
    }
    return $count;
}

sub read_manifest {
    my $files = [];
    open MANIFEST, '< .saves/MANIFEST'
      or DIE "Can't open .saves/MANIFEST for input";
    @$files = map {chomp; $_} grep {not /^\s*\#/} <MANIFEST>;
    close MANIFEST;
    return $files;
}

sub display_manifest {
    my $files = read_manifest();
    print STDOUT "$_\n" for @$files;
}

sub make_SAVES_paths {
    my ($files) = @_;
    my %paths;
    use File::Path();
    for my $file (@$files) {
        (my $path = $file) =~ s/(.*)\/.*/$1/ or next;
        $paths{$path} = 1;
    }
    for (keys %paths) {
        my $path = ".saves/SAVES/$_";
        File::Path::mkpath($path) unless -e $path;
    }
}

sub find_all_files_in_list {
    my ($file_list) = @_;
    my %files = ();
    for (map {ref($_) ? @$_ : $_} @$file_list) {
        s/^\.\///, $files{$_} = 1 for find_files($_, '');
    }
    my $files = [(map {$_} sort keys %files)];
    return $files;
}

sub find_files {
    my ($file, $path) = @_;
    $file = "$path/$file" if length($path);
    return () if $file =~ /(?:^|\/)\.saves(?:\/|$)/;
    if (not -e $file) {
        warn "$file is not a valid file. Ignoring\n";
        return ();
    }
    if (-f $file) {
        return () if -B $file; # Don't allow binary files for now.
        return ($file);
    }
    if (-d $file) {
        return () if -e "$file/.saves" and $file !~ /^\.\/?$/;
        my @files = ();
        local *DIR;
        opendir(DIR, $file) or DIE "Can't opendir $file";
        while (my $new_file = readdir(DIR)) {
            next if $new_file =~ /^(\.|\.\.|(\.\/)\.saves)$/;
            push @files, find_files($new_file, $file);
        }
        return @files;
    }
    DIE "Don't know how to handle $file";
}

sub files_in_manifest {
    my ($files) = @_;
    my %manifest = map {($_, 1)} @{read_manifest()};
    return [ grep {$manifest{$_}} 
             @{find_all_files_in_list($files)}
           ];
}

sub files_not_in_manifest {
    my ($files) = @_;
    my %manifest = map {($_, 1)} @{read_manifest()};
    return [ grep {not $manifest{$_}} 
             @{find_all_files_in_list($files)} 
           ];
}

sub show_status {
    my ($file_list) = @_;
    mkdir(".saves/tmp", 0777) unless -d ".saves/tmp";
    open STATUSLIST, "> .saves/tmp/statuslist"
      or DIE $!;
    print STATUSLIST ".saves/SAVES/$_,v\n" for @$file_list;
    close STATUSLIST;
    open STATUSTEXT, "cat .saves/tmp/statuslist | xargs rlog -zLT |"
      or DIE $!;
    local $/;
    my $statustext = <STATUSTEXT>;
    close STATUSTEXT;
    my @sections = split /^=+$/m, $statustext;
    pop @sections;
    for my $section (@sections) {
        $section =~ 
          /^RCS file: (.*?)\n.*?^locks:.*?:\s+(.*?)\n/sm
            or DIE "Can't grok rlog output:\n$section";
        my ($version, $file) = ($2, $1);
        $section =~ 
          /^revision\s+\Q$version\E.*?\n.*?date:\s+(.*?);/sm
            or DIE "Can't grok rlog output:\n$section";
        my $date = $1;
        $file =~ s{^\.saves/SAVES/(.*),v$}{$1};
        my $modified = ((-M $file) < (-M ".saves/SAVES/$file,v"))
                       ? '*'
                       : ' ';
        $version =~ s/^\d+\.//;
        print STDOUT "$date ($version)$modified$file\n";
    }
}

sub dump_history {
    my ($file) = @_;
    my $rlog = parse_rlog($file);
    my $i = 1;
    for (@{$rlog}) {
        my $message = $_->{message};
        $message =~ s/(.*?)\n\s*\n.*/$1/;
        $message =~ s/\n/ /g;
        $message = substr($message, 0, 40);
        
        chomp $_->{message};
        printf STDOUT 
          "%d) %s (%6s) %s\n",
          $i++, 
          $_->{date},
          $_->{delta},
          $message;
    }
    if ((-M $file) < (-M ".saves/SAVES/$file,v")) {
        print STDOUT "*) Working file has been modified since last save\n";
    }
}

sub parse_rlog {
    my ($file) = @_;
    open RLOG, "rlog -zLT .saves/SAVES/$file |"
      or DIE $!;
    local $/;
    my $input = <RLOG>;
    close RLOG;
    (my $rlog = $input) =~ s/\n=+$.*\Z//ms;
    my @rlog = split /^-+\n/m, $rlog;
    shift(@rlog);
    my $parse;
    for (reverse @rlog) {
        /^revision\s+(\S+).*?
         ^date:\s+(.+?);.*?
         (?:lines:\s+(.+?))?\n
         (?:branches:.*?\n)?
         (.*)
        /xms or DIE "Couldn't parse rlog for '$file':\n$rlog";
        push @$parse,
          {
            revision => $1,
            date => $2,
            delta => $3 || 'Origin',
            message => $4,
          };
    }
    return $parse;
}

sub restore_by_revision {
    my ($file, $revision) = @_;
    my @revisions = @{parse_rlog($file)};
    my %revisions = map {($_->{revision}, 1)} @revisions;
    my $latest = $revisions[-1]{revision};
    DIE "Revision number is invalid"
      unless defined $revisions{$revision};
    my $command = join ' && ',
      qq{rcs -q -u $file .saves/SAVES/$file,v},
      qq{co -q -f$revision $file .saves/SAVES/$file,v},
      qq{rcs -q -l$latest $file .saves/SAVES/$file,v},
      qq{chmod +w $file},
      qq{sleep 1},
      qq{touch $file};
    system($command) == 0
      or DIE "Couldn't restore file '$file', revision '$revision'";
}

sub restore_by_number {
    my ($file, $number) = @_;
    my $rlog = parse_rlog($file);
    DIE "Revision number is invalid"
      if $number-- > @$rlog;
    my $revision = $rlog->[$number]{revision};
    restore_by_revision($file, $revision);
}

sub show_diff {
    my ($files, $switches) = @_;
    my @files = @{files_in_manifest($files)};
    my $options = '';
    if (defined $switches->{r}) {
        DIE "'diff -r' can only be used on a single file"
          unless (@files == 1);
        DIE "Invalid value for -r"
          unless $switches->{r} =~ /^(\d+)(?:-(\d+))?$/;
        my ($r1, $r2) = ($1, $2);
        my $rlog;
        for ($r1, $r2) {
            next unless defined;
            unless (/\./) {
                $_ = $_ - 1;
                $rlog ||= parse_rlog($files[0]);
                DIE "Revision number is invalid"
                  if $_ >= @$rlog;
                $_ = $rlog->[$_]{revision};
            }
        }
        $options = "-r$r1";
        $options .= " -r$r2" if defined($r2);
    }
    mkdir(".saves/tmp", 0777) unless -d ".saves/tmp";
    if (-e '.saves/tmp/diff') {
        unlink('.saves/tmp/diff')
          or DIE "Can't unlink .saves/tmp/diff";
    }
    my $shell_commands;
    for my $file (@files) {
        $shell_commands .= 
          qq{rcsdiff -q -zLT -u $options $file .saves/SAVES/$file,v} .
          qq{ >> .saves/tmp/diff\n};
    }
    open SH, "| sh" or DIE $!;
    print SH $shell_commands;
    close SH;
    open DIFF, '.saves/tmp/diff' or DIE $!;
    local $/;
    print STDOUT <DIFF>;
    close DIFF;
} 

###############################################################################
# assertions and validations
###############################################################################
sub assert_repository {
    (my $command = (caller(1))[3]) =~ s/.*::(\w+?)_?$/$1/;
    DIE "Can't do 'svs $command'; no repository in this directory.\n",
        "You can use 'svs import' to create a repository.\n"
          unless -d ".saves";
}

sub assert_no_repository {
    if (-d '.saves') {
        (my $command = (caller(1))[3]) =~ s/.*::(\w+?)_?$/$1/;
        DIE <<END;
Can't do 'svs $command'; a '.saves' repository already exists.
If you really want to $command, you must first remove the repository.
END
    }
}

sub validate_no_files {
    my ($files) = @_;
    DIE "You can't specify files for this command\n"
      if @$files;
}

sub validate_files {
    my ($files) = @_;
    my %paths;
    (my $command = (caller(1))[3]) =~ s/.*::(\w+?)_?$/$1/;
    DIE "No files specified for 'svs $command'\n"
      unless @$files;
    for (@$files) {
        my $file = $_;
        DIE "Absolute pathnames may not be used\n"
          if $file =~ /^[\/\\]/;
        DIE "Paths containing '../' not allowed\n"
          if $file =~ /\.\.\//;
        DIE "$file does not exist\n"
          unless -e $file;
        if ($file =~ m|/| or -d $file) {
            my @dirs = split '/', $file;
            pop @dirs if -f $file;
            my $path = shift(@dirs);
            $paths{$path} = 1;
            for my $dir (@dirs) {
                $path .= "/$dir";
                $paths{$path} = 1;
            }
        }
    }
    delete $paths{'.'};
    for my $path (sort keys %paths) {
        DIE <<END if -d "$path/.saves";
Can't use files in '$path'. 
It contains its own '.saves' directory.
Use 'svs merge $path',
if you want these files under the current repository.
END
    }
}

sub assert_file_in_repository {
    my ($files) = @_;
    (my $command = (caller(1))[3]) =~ s/.*::(\w+?)_?$/$1/;
    DIE "'svs $command' requires one filename\n"
      unless @$files == 1;
    $files->[0] =~ s|^\./||;
    my $file = $files->[0];
    DIE "'$file' is not a regular file\n"
      unless -f $file;
    my %manifest = map {($_, 1)} @{read_manifest()};
    DIE "'$file' is not in the manifest\n"
      unless $manifest{$file};
}

###############################################################################
# miscellaney
###############################################################################
sub AUTOLOAD {
    (my $cmd = $VCS::SaVeS::SVS::AUTOLOAD) =~ s/.*:://;
    print "The svs '$cmd' command is not yet implemented\n\n";
}

1;

__END__

=head1 NAME

VCS::SaVeS::SVS - Support module for Standalone Versioning System(tm)

=head1 SYNOPSIS

This is just the support Perl Module for the SaVeS command line tools:
C<svs> and C<saves>.

See the following manpages for more information:

    perldoc svs
    perldoc saves
    svs help

=head1 DESCRIPTION

SaVeS(tm) (the Standalone Versioning System) is a very easy to use file
versioning system. It gives you many of the powers of CVS, with few of
the headaches.

The interface consists of two commands:

=over 4

=item * svs

This is the main SaVeS command. It is used to control all SaVeS operations. For more information use the following command:

    svs help

=item * saves

This is the SaVeS shortcut that simply backs up everything under the current directory. It is identical to:

    svs import -m'saves' .

or:

    svs save -m'saves' .

=back

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002 Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
