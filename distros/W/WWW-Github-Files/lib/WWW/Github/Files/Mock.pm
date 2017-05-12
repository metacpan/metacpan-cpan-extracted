package WWW::Github::Files::Mock;
use strict;
use warnings;
use File::Spec;
use Carp;

our $VERSION = 0.12;

sub new {
    my ($class, $root) = @_;
    return bless { root => $root }, $class;
}

sub open {
    my ($self, $path) = @_;
    croak("Path should start with '/'! |$path|")
        unless $path =~ m!^/!;
    $path =~ s!/$!!;
    my $full_path = $path eq '' ? $self->{root} : File::Spec->catdir( $self->{root}, $path );
    die "File $full_path does not exists"
        unless -e $full_path;
    my $oclass = "WWW::Github::Files::Mock::" . (-d $full_path ? "Dir" : "File");
    return $oclass->new( $path, $full_path );
}

package WWW::Github::Files::Mock::Dir;

sub is_file { 0 }
sub is_dir { 1 }
sub name { return $_[0]->{name} }
sub path { return $_[0]->{path} }

sub new {
    my ($class, $path, $full_path) = @_;
    my ($name) = $path =~ m![/\\]([^/\\]+)$!;
    $name = '' unless defined $name;
    return bless { path => $path, name => $name, full_path => $full_path }, $class;
}

sub readdir {
    my $self = shift;
    opendir my $dh, $self->{full_path} or return;
    my @files = grep { not m/^\.\.?$/ } readdir $dh;
    closedir $dh;
    my @objs;
    foreach my $name (@files) {
        my $full_path = File::Spec->catdir( $self->{full_path}, $name );
        my $oclass = "WWW::Github::Files::Mock::" . (-d $full_path ? "Dir" : "File");
        my $path = $self->{path} . '/' . $name;
        push @objs, $oclass->new( $path, $full_path );
    }
    return @objs;
}

package WWW::Github::Files::Mock::File;

sub is_file { 1 }
sub is_dir { 0 }
sub name { return $_[0]->{name} }
sub path { return $_[0]->{path} }

sub new {
    my ($class, $path, $full_path) = @_;
    my ($name) = $path =~ m![/\\]([^/\\]+)$!;
    $name = '' unless defined $name;
    return bless { path => $path, name => $name, full_path => $full_path }, $class;
}

sub read {
    my $self = shift;
    open my $fh, "<", $self->{full_path}
        or die "could not find file " . $self->full_path;
    my $content = do { local $/ = <$fh> };
    close $fh;
    return $content;
}

1;

=head1 NAME

WWW::Github::Files::Mock - Read files and directories from local directory, as if they came from Gibhub

=head1 SYNOPSIS

    my $gitfiles = WWW::Github::Files::Mock->new($respodir);
    my @files = $gitfiles->open('/')->readdir();

=head1 DESCRIPTION

Suppose that you wrote some code that is based on WWW::Github::Files 
accessing some github repository and reading files.

Now suppose you want to use the same code on a local repository. 
Say for testing, or whatever. 
Fear not, this module will abstract the disk access as if the files
where hosted on Github.

What is doesn't do - Can't select branch or commit to read from. 
This module assumes that the current state is the desired commit.
(If you think that the ability to select commit/branh is important,
please file a feature request)

This module mocks L<WWW::Github::Files>, so go look there for interface documentation.

=head1 AUTHOR
 
Fomberg Shmuel, E<lt>shmuelfomberg@gmail.comE<gt>
 
=head1 COPYRIGHT AND LICENSE
 
Copyright 2013 by Shmuel Fomberg.
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
