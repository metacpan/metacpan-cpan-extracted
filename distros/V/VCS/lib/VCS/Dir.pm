package VCS::Dir;

use VCS::File;

my $PREFIX = 'VCS';

sub new {
    my $container_classtype = shift;
    $container_classtype =~ s#^$PREFIX##;
    my ($hostname, $impl_class, $path, $query) = VCS->parse_url(@_);
    VCS->class_load($impl_class);
    my $this_class = "$impl_class$container_classtype";
    return $this_class->new(@_);
}

# assumes no query string
sub init {
    my($class, $url) = @_;
    my ($hostname, $impl_class, $path, $query) = VCS->parse_url($url);
    if (substr($path, -1, 1) ne '/') {
        $path .= '/';
        $url .= '/';
    }
    my $self = {};
    $self->{HOSTNAME} = $hostname;
    $self->{IMPL_CLASS} = $impl_class;
    $self->{PATH} = $path;
    $self->{URL} = $url;
    bless $self, $class;
    return $self;
}

sub url {
    my $self = shift;
    $self->{URL};
}

sub content {
}

sub path {
    my $self = shift;
    $self->{PATH};
}

sub tags {
  my $self = shift;
  my $rh = {}; # result hash
  my @files = $self->recursive_read_dir();

  my $url;

  foreach my $file (@files) {
    my $vcsfile = eval { VCS::File->new('vcs://'.$self->{HOSTNAME}.'/'.$self->{IMPL_CLASS}.'/'.$file) } or next;
    my $file_tag_information = $vcsfile->tags();
    foreach my $filetag (keys(%$file_tag_information)) {
      $rh->{$filetag}->{$file} = $file_tag_information->{$filetag};
    }
  }

  return $rh;

}


sub recursive_read_dir {
  my $self = shift;
  my ($dir) = @_;
  $dir ||= $self->path(); # let it take path if its not been
                          # defined, i'm not really sure about this,
                          # to be honest the whole things need an
                          # an overhaul in the way it works,
                          # but for now i'm just happy to get
                          # my work done. - Greg
  $dir.='/' unless (substr($dir,-1,1) eq '/');
  my @files;
  opendir(DIR,$dir);
  my @contents = grep { (!/^\.\.?$/) } readdir(DIR);
  @contents = grep { (!/,v$/) } @contents; # RCS files, shouldn't matter if they are RCS/*,v or just *,v
  @contents = grep { (!/^CVS$/) } @contents;

  closedir(DIR);
  foreach my $content (@contents) {
    if (-d $dir.$content) {
      push(@files,($self->recursive_read_dir($dir.$content)));
    } else {
      push(@files,$dir.$content);
    }
  }
  return @files;
}

sub read_dir {
    my ($self, $dir) = @_;
    local *DIR;
    opendir DIR, $dir;
    my @d = grep { (!/^\.\.?$/) } readdir DIR;
    closedir DIR;
#warn "d: @d\n";
    @d;
}

1;

__END__

=head1 NAME

VCS::Dir - module for access to a VCS directory

=head1 SYNOPSIS

    use VCS;
    my $d = VCS::Dir->new($url);
    print $d->url . "\n";
    foreach my $x ($d->content) {
        print "\t" . $x->url . "\t" . ref($x) . "\n";
    }

=head1 DESCRIPTION

C<VCS::Dir> abstracts access to a directory under version control.

=head1 METHODS

Methods marked with a "*" are not yet finalised/implemented.

=head2 VCS::Dir-E<gt>create_new($url) *

C<$url> is a file-container URL.  Creates data as
appropriate to convince the VCS that there is a file-container, and
returns an object of class C<VCS::Dir>, or throws an exception if it
fails. This is a pure virtual method, which must be over-ridden, and
cannot be called directly in this class (a C<die> will result).

=head2 VCS::Dir-E<gt>introduce($name, $create_class) *

C<$name> is a file or directory name, absolute or relative.
C<$create_class> is either C<File> or C<Dir>, and implementation
classes are expected to use something similar to this code, to call the
appropriate create_new:

    sub introduce {
        my ($class, $name, $create_class) = @_;
        my $call_class = $class;
        $call_class =~ s/[^:]+$/$create_class/;
        return $call_class->create_new($name);
    }

This is a pure virtual method, which must be over-ridden, and cannot be
called directly in this class (a C<die> will result).

=head2 VCS::Dir-E<gt>new($url)

C<$url> is a file-container URL.  Returns an object of class
C<VCS::Dir>, or throws an exception if it fails. Normally, an override of
this method will call C<VCS::Dir-E<gt>init($url)> to make an object,
and then add to it as appropriate.

=head2 VCS::Dir-E<gt>init($url)

C<$url> is a file-container URL.  Returns an object of class
C<VCS::Dir>. This method calls C<VCS-E<gt>parse_url> to make sense of
the URL.

=head2 $dir-E<gt>tags

* THIS METHOD WORKS RECURSIVELY ON THE DIRECTORY AT HAND *

Returns all the tags inside a directory and a little bit more
information. The actual datstructure is a hash of hashes. The first
level hash is a hash keyed on tag names, in other words it lists as
its keys every single tag name in or below a directory. Each of
these tag names point to another hash with has filenames as keys
and version numbers as values.

=head2 $dir-E<gt>url

Returns the C<$url> argument to C<new>.

=head2 $dir-E<gt>content

Returns a list of objects, either of class C<VCS::Dir> or
C<VCS::File>, corresponding to files and directories within this
directory.

=head2 $dir-E<gt>path

Returns the absolute path of the directory.

=head2 $dir-E<gt>read_dir($dir)

Returns the contents of the given filesystem directory. This is intended
as a utility method for subclasses.

=head1 SEE ALSO

L<VCS>.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
