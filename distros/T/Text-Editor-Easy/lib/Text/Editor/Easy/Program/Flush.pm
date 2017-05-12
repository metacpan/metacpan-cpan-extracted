package Text::Editor::Easy::Program::Flush;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Program::Flush - STDOUT and SDTERR redirection when launching a new application from "Editor.pl" program.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

use IO::File;
use File::Basename;
use Fcntl;
use SDBM_File;


use threads;
use threads::shared;
my $seek : shared = 0;

my $name = fileparse($0);
my $length_s_n : shared;

my $own_STDOUT = "tmp/${name}_trace.trc";
unlink($own_STDOUT);

my $info = "${own_STDOUT}.print_info";
open( INFO, ">$info", ) or die "Impossible d'ouvrir $info : $!\n";
autoflush INFO;

open( OUT, ">$own_STDOUT" ) or die "Impossible de lier $own_STDOUT\n";
print OUT "\n";
$length_s_n = tell OUT;
close OUT;
open( OUT, ">$own_STDOUT" ) or die "Impossible de lier $own_STDOUT\n";
autoflush OUT;

my %info_hash;
my $suppressed = unlink( $own_STDOUT . '.pag', $own_STDOUT . '.dir' );
tie( %info_hash, 'SDBM_File', $own_STDOUT, O_RDWR | O_CREAT, 0666 )
  or die "Couldn't tie SDBM file $own_STDOUT : $!; aborting";

open (DBG, '>tmp/debug_prog.trc') or die "Impossible d'ouvrir DBG : $!\n";
autoflush DBG;

sub TIEHANDLE {
    my ( $classe, $type ) = @_;

    my $array_ref;
    $array_ref->[0] = $type;

    bless $array_ref, $classe;
}

sub PRINT {
    my $self = shift;
    
    print DBG "Avant blocage de seek par tid", threads->tid, " : seek = $seek\n";
    lock ( $seek );
    print DBG "Après blocage de seek par tid", threads->tid, " : seek = $seek\n";
    #$seek = tell OUT;
    my $seek_start = $seek;
    
    my $value = tell INFO;
    $info_hash{$seek} = $value;
    print INFO $seek, '|';

    my @lines;
    my $first_line = "\t" . threads->tid . "||" . $self->[0] . "\n";
    push @lines, $first_line;
    my $indice = 0;
    while ( my ( $pack, $file, $line ) = caller( $indice++ ) ) {
        push @lines, "\t$file|$line|$pack\n";
    }
    my $ok     = print OUT @_;

    # Don't work even with lock... ?
    #$seek = tell OUT;

    #print INFO $seek, @_, "\n", @lines;
    
    my $data = join ( '', @_ );    
    my @data = split ( /\n/, $data, -1 );
    my $total_length = length($data) + ($length_s_n - 1 )*( scalar(@data) - 1 );
    $seek += $total_length;
    
    print INFO $seek, "\n", @lines;
    
    return if ( scalar ( @data ) < 2 );
    
    my $seek_current = $seek_start;
    for my $line ( @data ) {
        $seek_current += length ( $line ) + $length_s_n;
        $info_hash{$seek_current} = $value;
    }
    print DBG "Déblocage de seek par tid", threads->tid, " : seek = $seek\n";
    if ( $seek < $seek_start ) {
        print DBG "Problème : data = |$data|";
        print DBG "\nLongueur de data : ", length($data), "\n";
        print DBG "Vraie position : ", tell(OUT), "\n";
    }
    return $ok;
}

package main;

tie *STDOUT, "Text::Editor::Easy::Program::Flush", ( 'STDOUT' );
tie *STDERR, "Text::Editor::Easy::Program::Flush", ( 'STDERR' );

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
