package VCS::Version;

my $PREFIX = 'VCS';

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
    my @path = split '/', $path;
    my $version = pop @path;
    my $filename = join '/', @path;
    my $self = {
        URL => $url,
        VERSION => $version,
        PATH => $filename,
    };
    bless $self, $class;
}

sub url {
    my $self = shift;
    $self->{URL};
}

sub version {
    my $self = shift;
    $self->{VERSION};
}

sub tags {
}

sub text {
}

sub diff {
}

sub author {
}

sub date {
}

sub reason {
}

sub path {
    my $self = shift;
    $self->{PATH};
}

1;

__END__

=head1 NAME

VCS::Version - module for access to a VCS version

=head1 SYNOPSIS

    use VCS;
    die "Usage: $0 file-url\ne.g.: vcs://localhost/VCS::Rcs/file/name/1.2\n"
        unless @ARGV == 1;
    my $version = VCS::Version->new(@ARGV);
    print "Methods of \$version:\n",
        "url: ", $version->url, "\n",
        "author: ", $version->author, "\n",
        "version: ", $version->version, "\n",
        ;

=head1 DESCRIPTION

VCS::Version abstracts a single revision of a file under version
control.

=head1 METHODS

Methods marked with a "*" are not yet finalised/implemented.

=head2 VCS::Version-E<gt>create_new(@version_args) *

C<@version_args> is a list which will be treated as a hash, with
contents as follow:

    @version_args = (
        name    => 'a file name',
        version => 'an appropriate version identifier',
        tags    => [ 'A_TAG_NAME', 'SECOND_TAG' ],
        author  => 'the author name',
        reason  => 'the reason for the checkin',
        text    => 'either literal text, or a ref to the filename',
    );

This is a pure virtual method, which must be over-ridden, and cannot be
called directly in this class (a C<die> will result).

=head2 VCS::Version-E<gt>new($url)

C<$url> is a VCS URL, of the format:

    vcs://localhost/VCS::Rcs/file/name/1.2

The version is a version number, or tag. Returns an object of class
C<VCS::Version>, or throws an exception if it fails. Normally, an
override of this method will call C<VCS::Version-E<gt>init($url)> to
make an object, and then add to it as appropriate.

=head2 VCS::Version-E<gt>init($url)

C<$url> is a version URL. Returns an object of class C<VCS::Version>. This
method calls C<VCS-E<gt>parse_url> to make sense of the URL.

=head2 $version-E<gt>url

Returns the C<$url> argument to C<new>.

=head2 $version-E<gt>version

Returns the C<$version> argument to C<new>.

=head2 $version-E<gt>tags

Returns a list of tags applied to this version.

=head2 $version-E<gt>text

Returns the text of this version of the file.

=head2 $version-E<gt>diff($other_version)

Returns the differences (in C<diff -u> format) between this version and
the other version. Currently, the other version must also be a
C<VCS::Version> object.

=head2 $version-E<gt>author

Returns the name of the user who checked in this version.

=head2 $version-E<gt>date

Returns the date this version was checked in.

=head2 $version-E<gt>reason

Returns the reason given on checking in this version.

=head2 $version-E<gt>path

Returns the absolute path of the file to which this version relates.

=head1 SEE ALSO

L<VCS>.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
