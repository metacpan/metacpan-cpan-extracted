package WWW::Github::Files;
use strict;
use warnings;
use LWP::UserAgent;
use JSON qw{decode_json};
use Carp;

our $VERSION = 0.13;

sub new {
    my ($class, %options) = @_;

    die "Please pass a author name"
        unless exists $options{author};
    die "Please pass a resp name"
        unless exists $options{resp};
    die "Please pass either a branch name or a commit"
        unless exists $options{branch} or exists $options{commit};

    my $self = {};
    foreach my $key (qw( author resp token branch commit self_token )) {
        next unless exists $options{$key};
        $self->{$key} = $options{$key};
    }
    if (not exists $self->{token}) {
        $self->{ua} = LWP::UserAgent->new();
        $self->{ua}->default_header( Authorization => "token ".$self->{self_token} )
            if exists $self->{self_token};
    }
    $self->{apiurl} = 'https://api.github.com/repos/'.$options{author}.'/'.$options{resp};
    bless $self, $class;
}

sub open {
    my ($self, $path) = @_;
    croak("Path should start with '/'! |$path|")
        unless $path =~ m!^/!;
    my $commit = $self->__fetch_root();
    $path =~ s!/$!!;
    $path = '/' if $path eq '';
    my $f_data = $self->geturl("/contents$path?ref=$commit");
    if (ref($f_data) eq 'ARRAY') {
        # a directory
        my ($name) = $path =~ m!/([^/]*)$!;
        my $dir = {
            FS => $self,
            content => $f_data,
            name => $name,
            path => ( $path eq '/' ? '' : substr($path, 1) ),
        };
        return bless $dir, 'WWW::Github::Files::Dir';
    }
    elsif ($f_data->{type} eq 'file') {
        return bless $f_data, 'WWW::Github::Files::File';
    }
    else {
        croak('unrecognised file type for $path');
    }
}

sub get_file {
    my ($self, $path) = @_;
    return $self->open($path)->read();
}

sub get_dir {
    my ($self, $path) = @_;
    return $self->open($path)->readdir();
}

sub __fetch_root {
    my $self = shift;
    my $root = $self->{root_commit};
    return $root if $root;

    if ($self->{branch}) {
        my $b_data = $self->geturl('/branches/'.$self->{branch});
        $root = $b_data->{commit}->{sha};
    }
    else {
        my $c_data = $self->geturl('/git/commits/'.$self->{commit});
        $root = $self->{commit};
    }
    $self->{root_commit} = $root;
    return $root;
}

sub geturl {
    my ($self, $url, $method) = @_;
    my $token = $self->{token} || $self->{ua};
    $method ||= 'get';
    my $res = $token->$method($self->{apiurl} . $url);
    if (!$res->is_success()) {
        if ($res->message() =~ m/Internal Server Error/) {
            # retry
            my $res2 = $token->$method($self->{apiurl} . $url);
            if ($res2->is_success()) {
                $res = $res2;
            }
            print STDERR $res2->message(), ", ", $res2->content, "\n";
        }
        if (!$res->is_success()) {
            die "Failed to read $self->{apiurl}$url from github: ".$res->message(). ", ".$res->content;
        }
    }
    my $content = $res->content;
    return decode_json($content);
}

package WWW::Github::Files::File;
use MIME::Base64 qw{decode_base64};

sub is_file { 1 }
sub is_dir { 0 }

sub name { return $_[0]->{name} }
sub path { return '/'.$_[0]->{path} }

sub read {
    my $self = shift;
    if (not $self->{content}) {
        # this is a file object created from directory listing. 
        # need to fetch the content
        my $f_data = $self->{FS}->open('/'.$self->{path});
        $self->{$_} = $f_data->{$_} for (qw{ encoding content });
    }
    if ($self->{encoding} eq 'base64') {
        return decode_base64($self->{content});
    }
    else {
        die "can not handle encoding " . $self->{encoding} . " for file ". $self->{path};
    }
}

package WWW::Github::Files::Dir;

sub is_file { 0 }
sub is_dir { 1 }

sub name { return $_[0]->{name} }
sub path { return '/'.$_[0]->{path} }

sub readdir {
    my $self = shift;
    if (not $self->{content}) {
        # this is a file object created from directory listing. 
        # need to fetch the content
        my $f_data = $self->{FS}->open('/'.$self->{path});
        $self->{content} = $f_data->{content};
    }
    my @files;
    foreach my $rec (@{ $self->{content} }) {
        $rec->{FS} = $self->{FS};
        if ($rec->{type} eq 'file') {
            push @files, bless($rec, 'WWW::Github::Files::File');
        }
        elsif ($rec->{type} eq 'dir') {
            push @files, bless($rec, 'WWW::Github::Files::Dir');
        }
        else {
            croak('unrecognised file type: '.$rec->{type});
        }
    }
    return @files;
}

1;

=head1 NAME

WWW::Github::Files - Read files and directories from Github

=head1 SYNOPSIS

    my $gitfiles = WWW::Github::Files->new(
        author => 'semuel',
        resp => 'site-lang-collab',
        branch => 'master',
    );

    my @files = $gitfiles->open('/')->readdir();

=head1 DESCRIPTION

Using Github API to browse a git resp easily and download files

This modules is a thin warper around the API, just to make life easier

=head1 ALTERNATIVES

The easiest way to get a file off Github is to use the raw url:

https://raw.github.com/semuel/perlmodule-WWW-Github-Files/master/MANIFEST

This will return the content of this module's MANIFEST file. Easy, but 
the file have to be public and you need to know beforehand where exactly 
it is. (this method does not fetch directory content)

Also, if you download two files under 'master', there is a chance that a
commit happened in the middle and you get two files from two different
versions of the respo. Of course you can fetch the current commit and
use it instead of master, but then it is less easy

This module let you use Access Token for permission, and scan directories

=HEAD1 MOCKING

Need to write code that read files from Github and local repositories?
Check out L<WWW::Github::Files::Mock> that uses the same interface
for local directory.

=head1 CONSTRUCTOR OPTIONS

=over 4

=item author - resp author

=item resp - resp name

=item branch - The branch to read from

Mutual exlusive with 'commit'. 

On first access the object will "lock" on the latest commit in this branch,
and from this point will serve files only from this commit

=item commit - a specific commit to read from

The object will retrive files and directories as they were after this commit

=item token

Optional Net::Oauth2 Access Token, for using in API calls.
If not specified, will make anonymous calls using LWP

=item self_token

Optional Github "Personal Access Token" to use for API authentication. 

=back

=head1 METHODS

=head2 open(path)

receive path (which have to start with '/') and return file or dir object
for that location

=head2 get_file(path)

shortcut to $gitfiles->open(path)->read()

=head2 get_dir(path)

shortcut to $gitfiles->open(path)->readdir()

=head1 FILE OBJECT METHODS

=head2 name

The name of the file

=head2 path

full path (+name) of the file

=head2 is_file

=head2 is_dir

=head2 read

returns the content of the file

=head1 DIRECTORY OBJECT METHODS

=head2 name

The name of the directory

=head2 path

full path (+name) of the directory

=head2 is_file

=head2 is_dir

=head2 readdir

returns a list of file/dir objects that this directory contains

=head1 AUTHOR
 
Fomberg Shmuel, E<lt>shmuelfomberg@gmail.comE<gt>
 
=head1 COPYRIGHT AND LICENSE
 
Copyright 2013 by Shmuel Fomberg.
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=cut
