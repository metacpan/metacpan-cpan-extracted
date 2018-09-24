##- Nanar <nanardon@mandriva.org>
##-
##- This program is free software; you can redistribute it and/or modify
##- it under the terms of the GNU General Public License as published by
##- the Free Software Foundation; either version 2, or (at your option)
##- any later version.
##-
##- This program is distributed in the hope that it will be useful,
##- but WITHOUT ANY WARRANTY; without even the implied warranty of
##- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##- GNU General Public License for more details.
##-
##- You should have received a copy of the GNU General Public License
##- along with this program; if not, write to the Free Software
##- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

##- $Id: packdrake.pm 12160 2005-11-15 12:42:54Z rgarciasuarez $

package packdrake;

use strict;
use warnings;
use MDV::Packdrakeng;
our @ISA = qw(MDV::Packdrakeng);
our $VERSION = $MDV::Packdrakeng::VERSION;

sub new {
    my ($class, $file, %options) = @_;
    my $pack = MDV::Packdrakeng->open(
        %options,
        archive => $file
    ) or do { print STDERR "Can't open $file: $!\n"; return undef };
    #- rebless
    bless($pack, $class);
}

sub extract_archive {
    my ($pack, $dir, @files) = @_;
    @files or return;
    $pack->extract($dir, @files);
}

sub extract_all_archive {
    my ($pack, $dir) = @_;
    my ($d, $f, $l) = $pack->getcontent();
    $pack->extract($dir, @$d, @$f, @$l);
}

sub list_archive {
    foreach my $archive (@_) {
        my $pack = MDV::Packdrakeng->open(archive => $archive) or do {
	    print STDERR "Can't open $archive: $!\n";
	    next;
	};
        $pack->list();
    }
}

sub build_archive {
    my ($listh, $dir, $archive, $size, $compress, $uncompress) = @_;
    my ($comp_level) = $compress =~ m/ -(\d)(?:\s|$)/;
    $compress =~ s/ -\d(\s|$)/$1/;
    my $pack = MDV::Packdrakeng->new(
        archive => $archive,
        compress => $compress,
        uncompress => $uncompress,
        block_size => $size,
        comp_level => $comp_level,
    ) or return;
    while (my $line = <$listh>) {
        chomp($line);
        $pack->add($dir, $line) or return;
    }
    1;
}

sub cat_archive {
    foreach my $archive (@_) {
        my $pack = MDV::Packdrakeng->open(archive => $archive) or do {
	    print STDERR "Can't open $archive: $!\n";
	    next;
	};
        (undef, my $files, undef) = $pack->getcontent();
        foreach (@$files) {
            $pack->extract_virtual(\*STDOUT, $_);
        }
    }
}

1;

__END__

=head1 NAME

packdrake - Simple Archive Extractor/Builder

This module is a compatibility wrapper around the new MDV::Packdrakeng module.

=head1 SYNOPSIS

    require packdrake;

    packdrake::cat_archive("/export/media/media_info/hdlist.cz",
                           "/export/media/media_info/hdlist2.cz");
    packdrake::list_archive("/tmp/modules.cz2");

    my $packer = new packdrake("/tmp/modules.cz2");
    $packer->extract_archive("/tmp", "file1.o", "file2.o");

    my $packer = packdrake::build_archive
        (\*STDIN, "/lib/modules", "/tmp/modules.cz2",
         400000, "bzip2", "bzip2 -d");
    my $packer = packdrake::build_archive
        (\*STDIN, "/export/media/media_info/hdlist.cz",
         400000, "gzip -9", "gzip -d");

=head1 DESCRIPTION

C<packdrake> is a very simple archive extractor and builder used by Mandrakesoft.

=head1 FUNCTIONS

=over

=item B<new($file, %options)>

Open the packdrake archive $file and return a packdrake object.
Return undef on failure.

=item B<< packdrake->extract_archive($dir, @files) >>

Extract files list into the specified directory.

=item B<< packdrake->extract_all_archive($dir) >>

Extract all files into the specified directory.

=item B<packdrake::list_archive(@list)>

List files packed into achives given.

=item B<packdrake::build_archive($input,$dir,$archive,$blocksize,$compress,$uncompress)>

Build a new archive:
- $input is a file handle to find file list to pack
- $dir is the directory based where file are located
- $archive is the archive filename to create
- $blocksize is the size of compressed block
- $compress is the program to use to compress data
- $uncompress is the program to use to uncompress data

=item B<packdrake::cat_archive(@files)>

Dump data to STDOUT of files given as parameters, or all files if no files are
specified

=back

=head1 SEE ALSO

L<MDV::Packdrakeng>.

=head1 COPYRIGHT

Copyright (C) 2000-2004 Mandrakesoft <nanardon@mandriva.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
