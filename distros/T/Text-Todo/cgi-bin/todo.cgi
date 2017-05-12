#!/usr/bin/perl
# $AFresh1: todo.cgi,v 1.1 2010/01/16 04:06:37 andrew Exp $
########################################################################
# todo.cgi *** A RESTful interface to a todo.txt file.
########################################################################
# Copyright (c) 2010 Andrew Fresh <andrew@cpan.org>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
########################################################################
use strict;
use warnings;

use 5.010;

use Text::Todo;
use CGI;
use Digest::MD5 qw/ md5_hex /;
use File::Spec;

my $BASE_DIR = '/users'; # the path to the users dirs
my $TODO_DIR = 'todo';   # subdirectory of the users dir where todo lists are.
my $TODO_SUFFIX    = '.txt';    # suffix of todo lists
my $DEFAULT_FORMAT = 'text';    # The default format if none specified

my %TRANSFORMS = (
    text => {
        start => sub { $_[0]->header('text/plain') },
        end   => sub { q{} },
        files => sub { join "\n", @_ },
        list  => sub { map $_->text . "\n", @_; },
        entry => sub { $_[0]->text, "\n" },
    }
);
$TRANSFORMS{txt} = $TRANSFORMS{text};

#BEGIN { if (require xxx) }

my $q = CGI->new();
my %res = path_to_resource($ENV{PATH_INFO});

print transform( $res{format}, 'start', $q );

given ( $ENV{REQUEST_METHOD} ) {
    when ( '' || 'GET' ) { print handle_get( \%res ) }
    when ('POST')   { handle_post() }
    when ('PUT')    { handle_put() }
    when ('DELETE') { handle_delete() }
    default         { die "Unhandled method $ENV{REQUEST_METHOD}\n" };
}

print transform( $res{format}, 'end', $q );


sub handle_get {
    my ($res) = @_;

    if ( $res{entry} ) {
        return get_entry( $res );
    }
    elsif ( $res{list} ) {
        return get_list( $res );
    }
    elsif ( $res{user} ) {
        return get_user( $res );
    }
    else {
        return get_error( $res );
    }
}

sub get_entry {
    my ($res) = @_;

    my $file = local_path( 'list', $res );
    my $todo = Text::Todo->new($file);

    my $entry;
    if ( $res->{entry} =~ /^[[:xdigit:]]{32}$/xms ) {
        my $search = lc $res->{entry};

    ENTRY: foreach my $e ( $todo->list ) {
            if ( $search eq md5_hex( $e->text ) ) {
                $entry = $e;
                last ENTRY;
            }
        }
    }
    elsif ( $res->{entry} =~ /^\d+$/xms ) {
        $entry = $todo->list->[ $res->{entry} - 1 ];
    }

    if ( !$entry ) {
        die "Unable to find entry!\n";
    }

    return transform( $res->{format}, 'entry', $entry );
}

sub get_list {
    my ($res) = @_;

    my $file = local_path( 'list', $res );
    my $todo = Text::Todo->new($file);

    return transform( $res->{format}, 'list', $todo->list );
}

sub get_user {
    my ($res) = @_;

    my $dir = local_path( 'user', $res );

    opendir my $dh, $dir or die "Couldn't opendir: $!\n";
    my @files = grep {m/$TODO_SUFFIX$/xms} readdir $dh;
    closedir $dh;

    return transform( $res->{format}, 'files', @files );
}

sub get_error {
    my ($res) = @_;
    return "ERROR";
}

sub handle_post   { die "Unsupported [POST]\n" }
sub handle_put    { die "Unsupported [PUT]\n" }
sub handle_delete { die "Unsupported [DELETE]\n" }

sub path_to_resource {
    my ($path) = @_;

    my $ext = $DEFAULT_FORMAT;
    if ( $path =~ s/\.(\w+)$//xms ) {
        $ext = $1;
    }
    my ( undef, $user, $list, $entry ) = split '/', $path;

    return (
        user   => $user,
        list   => $list,
        entry  => $entry,
        format => $ext,
    );
}

sub transform {
    my ( $format, $type, @args ) = @_;

    if ( !( defined $format && defined $type ) ) {
        die "Usage: transform('format', 'type', 'arg'[, 'arg...'])\n";
    }

    if ( exists $TRANSFORMS{$format} ) {
        if ( exists $TRANSFORMS{$format}{$type} ) {
            return $TRANSFORMS{$format}{$type}->(@args);
        }
        else { die "Transform [$format] cannot output [$type]\n" }
    }
    else { die "Unsupported format [$format]\n" }

    return;
}

sub local_path {
    my ( $type, $res ) = @_;

    given ($type) {
        when ('user') {
            return File::Spec->catdir( $BASE_DIR, $res->{'user'}, $TODO_DIR );
        }
        when ('list') {
            return File::Spec->catfile( $BASE_DIR, $res->{'user'}, $TODO_DIR,
                $res->{'list'} . $TODO_SUFFIX );
        }
    }
    return;
}
