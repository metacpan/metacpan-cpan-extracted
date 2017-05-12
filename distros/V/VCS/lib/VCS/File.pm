package VCS::File;

my $PREFIX = 'VCS';

use Carp;
use File::Basename;

sub new {
    my $container_classtype = shift;
    $container_classtype =~ s#^$PREFIX##;
    my ($hostname, $impl_class, $path, $query) = VCS->parse_url(@_);
    VCS->class_load($impl_class);
    my $this_class = "$impl_class$container_classtype";
    return $this_class->new(@_);
}

sub init {
    my ($class, $url) = @_;
    my ($hostname, $impl_class, $path, $query) = VCS->parse_url($url);
    my $self = {};
    $self->{URL} = $url;
    $self->{PATH} = $path;
    bless $self, $class;
}

sub url {
    my $self = shift;
    $self->{URL};
}

sub tags {
}

sub versions {
}

sub path {
    my $self = shift;
    $self->{PATH};
}

1;

__END__

=head1 NAME

VCS::File - module for access to a file under version control

=head1 SYNOPSIS

    use VCS;
    my $f = VCS::File->new($url);
    print $f->url . "\n";
    foreach my $v ($f->versions) {
        print "\tversion: " . $v->version . "\t" . ref($v) . "\n";
    }

=head1 DESCRIPTION

C<VCS::File> abstracts access to a file under version control.

=head1 METHODS

Methods marked with a "*" are not yet finalised/implemented.

=head2 VCS::File-E<gt>create_new($name) *

C<$name> is a file name, absolute or relative.  Creates data as
appropriate to convince the VCS that there is a file, and returns an
object of class C<VCS::File>, or throws an exception if it fails. This
is a pure virtual method, which must be over-ridden, and cannot be called
directly in this class (an exception ("C<die>") will result).

=head2 VCS::File-E<gt>introduce($version_args) *

C<$version_args> is a hash-ref, see L<VCS::Version> for details.
Implementation classes are expected to use something similar to this
code, to call create_new in the right C<VCS::Version> subclass:

    sub introduce {
        my ($class, $version_args) = @_;
        my $call_class = $class;
        $call_class =~ s/[^:]+$/Version/;
        return $call_class->create_new($version_args);
    }

This is a pure virtual method, which must be over-ridden, and cannot be
called directly in this class (a C<die> will result).

=head2 VCS::File-E<gt>new($url)

C<$url> is a file URL.  Returns an object of class C<VCS::File>, or
throws an exception if it fails. Normally, an override of this method
will call C<VCS::File-E<gt>init($url)> to make an object, and then add
to it as appropriate.

=head2 VCS::File-E<gt>tags()

Returns a reference to a hash that has keys that are any tags attached
to the file and the values are the corresponding versions which the
tags refer to.

=head2 VCS::File-E<gt>tags_hash()

Cvs ONLY

Same as for -E<gt>.

=head2 VCS::File-E<gt>tags_array()

Cvs ONLY

Returns an array of tags that are connected with the file, this is useful
alongside tags_hash() as it allows you to inspect the order in which
tags were applied.

=head2 VCS::File-E<gt>init($url)

C<$url> is a file URL. Returns an object of class C<VCS::File>. This
method calls C<VCS-E<gt>parse_url> to make sense of the URL.

=head2 $file-E<gt>url

Returns the C<$url> argument to C<new>.

=head2 $file-E<gt>versions

Returns a list of objects of class C<VCS::Version>, in order of ascending
revision number. If it is passed an extra (defined) argument, it only
returns the last version as a C<VCS::Version>.

=head2 $file-E<gt>path

Returns the absolute path of the file.

=head1 SEE ALSO

L<VCS>.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
