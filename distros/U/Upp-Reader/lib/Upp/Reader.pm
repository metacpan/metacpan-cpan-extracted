package Upp::Reader;

use 5.012004;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Upp::Reader ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

use vars qw($VERSION);

$VERSION           = '0.1';

sub remove_escapes {
    my $s = shift;
    $s =~ s/\\(.)/$1/g;
    return $s;
}

sub read_upp {
    my $filename = shift;
    open my $in, $filename or die "could not open upp file";

    my $content = join "", <$in>;

    my ( $file, $options, $link ) = extract($content);

}

sub extract

{
    my $content = shift;
    my @file;
    my %options;
    my %link;
    while ( $content =~ /((?:[^";]+|\"(?:\\.|.)*?\")+?)\s*;/sg ) {

        #print ">>$1<<\n";
        my $statement = $1;
        my $first     = 1;
        if ( $statement =~ /\s*([^\s(]+)(?:\((.+?)\))?/gc ) {

            #print ">>>>>>>$1 $2\n";
            my ( $section, $options ) = ( $1, $2 );
            if ( $section eq "options" or $section eq "link" ) {
                if ( $statement =~ /\G\s*\"((?:\\.|.)*?)\"|\s*(.+)/gc ) {
                    my @configuration = split /\s*\|\s*/, $options;
                    if ( $section eq "options" ) {
                        for my $c (@configuration) {
                            push @{ $options{$c} }, defined $1 ? remove_escapes($1) : $2;
                        }
                    }
                    if ( $section eq "link" ) {
                        for my $c (@configuration) {
                            push @{ $link{$c} }, defined $1 ? remove_escapes($1) : $2;
                        }
                    }
                }
            }
            elsif ( $section eq "file" ) {
                if ( $statement =~ /\G\s*(.+)/gcs ) {
                    my $filelist = $1;

                    #my @filelist;
                    while ( $filelist
                        =~ /((?:[^",]+|\"(?:\\.|.)*?\")+?)\s*,\s*|((?:[^",]+|\"(?:\\.|.)*?\")+?)\s*/gs )
                    {
                        my $file_and_options = $1 . $2;
                        if ( $file_and_options =~ /s*\"((?:\\.|.)*?)\"|\s*(.+)/g ) {
                            my $filename = defined $1 ? remove_escapes($1) : $2;
                            my %options;
                            if ( $file_and_options =~ /\s*([^\s(]+)(?:\((.+?)\))?/gc ) {

                                #print ">>>>>>>$1 $2\n";
                                my ( $section, $options ) = ( $1, $2 );
                                if ( $section eq "options" ) {
                                    if ( $file_and_options =~ /\G\s*\"((?:\\.|.)*?)\"|\s*(.+)/gc ) {
                                        my @configuration = split /\s*\|\s*/, $options;
                                        if ( $section eq "options" ) {
                                            for my $c (@configuration) {
                                                push @{ $options{$c} }, defined $1 ? remove_escapes($1) : $2;
                                            }
                                        }
                                    }
                                }
                            }
                            push @file, [ $filename, \%options ];
                        }
                    }
                }
            }
        }

        # while (/\s+|\"((?:\\.|.)+?)\")|([^\s]+)/sg)
        # {
        #     if (defined $2 && $first)
        #    {

        #      $first = 1;
        #    }
        # }

    }

    # for my $k (%options) {
    #     print "$k $options{$k}\n";
    # }
    return ( \@file, \%options, \%link );
}

sub format_filelist {
    my ($filelist) = @_;
    my $outstr;

    #print "$f->[0]\n";
    $outstr = join " ", @$filelist;

    return $outstr;
}

sub add_switch {
    my $sw = shift;
    return " " . $sw if ($sw);
    return "";
}

sub make_compilation {
    my ( $filelist, $options, $link, $target, $compiler_exe, $linker_exe, $compiler_flags, $link_flags ) = @_;

    # -Ic:\mingw\include -IC:\mingw\include\c++\3.4.5 -IC:\mingw\include\c++\3.4.5\mingw32\bits

    my $commandlist;
    my @objs;
    my $o_ext = ".o";
    my $o_sw  = "-o ";
    if ( $target =~ /^msc/i ) {
        $o_ext = ".obj";
        $o_sw  = "-Fo";
    }
    for my $f (@$filelist) {

        #print "$f->[0]\n";
        if ( $f->[0] =~ /^\.cpp|\.c$/ ) {
            my $out_filename = $f->[0];
            $out_filename =~ s/\.\w+$/$o_ext/;
            $commandlist
                .= $compiler_exe . " -c "
                . $f->[0]
                . " $o_sw"
                . $out_filename
                . add_switch( $f->[1]->{$target} )
                . add_switch( join " ", @{ $options->{$target} } )
                . add_switch($compiler_flags) . "\n";
            push @objs, $out_filename;
        }

    }
    $commandlist .= $linker_exe;
    for my $obj (@objs) {
        $commandlist .= " " . $obj;

    }
    $commandlist .= add_switch( join "", @{ $link->{$target} } ) . add_switch($link_flags);

    return $commandlist;
}

sub example1 {
    print Upp::Reader::make_compilation (
        Upp::Reader::read_upp('D:\m\upp\extractor\extractor.upp'),
        'GCC', 'gcc.exe', 'ld.exe', '-DRELEASE', ''
    );
}

1;

__END__

#-----------------------------------------------------------------------

=head1 NAME

Upp::Reader reads upp files

=head1 SYNOPSIS

my ($filelist, $options, $link) = Upp::Reader::extract($content_of_upp_file);

my ($filelist, $options, $link) = Upp::Reader::read_upp($filename);

print Upp::Reader::make_compilation (Upp::Reader::read_upp($filename), 'GCC', 'gcc.exe','ld.exe', '-DRELEASE', '') ;

=head1 DESCRIPTION

It can read Ultimate++ Ide project files and extract information contained in there. 
They have .upp extension.

These are extracted:

=over 4

=item *

list of files in the project



=item *

list of options(compiler flags) for each file


=item *

general compiler flags which are used at each compilation

=item *

linker flags 

=back 
 
There is a Limitation: used packages are not read.



=head1 Subroutines

=over 4

=item -my ($filelist, $options, $link) = Upp::Reader::extract(content_of_upp_file)


e.g. 
my ($filelist, $options, $link) = Upp::Reader::extract($content);

$filelist is a referece to a array. It is the list of files with their compiler flags
$options is a reference to a hash.
$link is  reference to a hash.

From the upp file contant it extracts project related information.

See make_compilation subroutine for data structure of $filelist, $options and $link


=item my ($filelist, $options, $link) = Upp::Reader::read_upp(filename);


e.g. 
my ($filelist, $options, $link) = Upp::Reader::read_upp('sqlproject.upp');

$filelist is a referece to a array. It is the list of files with their compiler flags
$options is a reference to a hash.
$link is  reference to a hash.

From the upp file  it extracts project related information.

=item sub make_compilation ( $filelist, $options, $link, $target, $compiler_exe, $linker_exe, $compiler_flags, $link_flags )


First three parameter must come from read_upp or extract.

$compiler_exe itself
$linker_exe  itself
$compiler_flags additional compiler flags 
$link_flags  additional linker flags

It returns a string containing a list of commands separated by new line that can compile and link the project


=head1 SEE ALSO

=over 1

=item http://www.ultimatepp.org/

Ultimate++ IDE homepage



=back

=head1 VERSION

$Revision: 0.1 $

=head1 SCRIPT CATEGORIES

CPAN

=head1 PREREQUISITES

None

=head1 AUTHOR

Marton Papp E<lt>equinox at atw dot huE<gt>

=head1 COPYRIGHT

Copyright (c) 2012 Marton Papp.



This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
