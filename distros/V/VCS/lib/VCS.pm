package VCS;

use VCS::Dir;
use VCS::File;
use VCS::Version;
use URI;

our $VERSION = '0.25';

sub parse_url {
    # vcs://hostname/classname/...
    my ($class, $url) = @_;
    my $uri = URI->new($url);
    die "Non-vcs URL '$url' passed!\n" unless $uri->scheme eq 'vcs';
    my $path = $uri->path;
    $path =~ s#^/([^/]+)##;
    my $classname = $1;
    ($uri->authority, $classname, $path, $uri->query)
}

sub _class2file {
    my $class = shift;
    $class =~ s#::#/#g;
    $class .= '.pm';
    $class;
}

sub class_load {
    my ($class, $to_load) = @_;
    require(_class2file($to_load));
}

1;

__END__

=head1 NAME

VCS - Version Control System access in Perl

=head1 SYNOPSIS

    use VCS;
    $file = VCS::File->new($ARGV[0]);
    print $file->url, ":\n";
    for $version ($file->versions) {
        print $version->version,
              ' was checked in by ',
              $version->author,
              "\n";
    }

=head1 DESCRIPTION

C<VCS> is an API for abstracting access to all version control systems
from Perl code. This is achieved in a similar fashion to the C<DBI>
suite of modules. There are "container" classes, C<VCS::Dir>,
C<VCS::File>, and C<VCS::Version>, and "implementation" classes, such
as C<VCS::Cvs::Dir>, C<VCS::Cvs::File>, and C<VCS::Cvs::Version>, which
are subclasses of their respective "container" classes.

The container classes are instantiated with URLs. There is a URL scheme
for entities under version control. The format is as follows:

    vcs://localhost/VCS::Cvs/fs/path/?query=1

The "query" part is ignored for now. The path must be an absolute path,
meaningful to the given class. The class is an implementation class,
such as C<VCS::Cvs>.

The "container" classes work as follows: when the C<new> method of a
container class is called, it will parse the given URL, using the
C<VCS-E<gt>parse_url> method. It will then call the C<new> of the
implementation's appropriate container subclass, and return the
result. For example,

    VCS::Version->new('vcs://localhost/VCS::Cvs/fs/path/file/1.2');

will return a C<VCS::Cvs::Version>.

An implementation class is recognised as follows: its name starts with
C<VCS::>, and C<require "VCS/Classname.pm"> will load the appropriate
implementation classes corresponding to the container classes.

=head1 VCS METHODS

=head2 VCS-E<gt>parse_url

This returns a four-element list:

    ($hostname, $classname, $path, $query)

For example,

    VCS->parse_url('vcs://localhost/VCS::Cvs/fs/path/file/1.2');

will return

    (
        'localhost',
        'VCS::Cvs',
        '/fs/path/file/1.2',
        ''
    )

This is mostly intended for use by the container classes, and its
interface is subject to change.

=head2 VCS-E<gt>class_load

This loads its given implementation class.

This is mostly intended for use by the container classes, and its
interface is subject to change.

=head1 VCS::* METHODS

Please refer to the documentation for L<VCS::Dir>, L<VCS::File>,
and L<VCS::Version>; as well as the implementation specific documentation
as in L<VCS::Cvs>, L<VCS::Rcs>.

=head1 AUTHORS

  Greg McCarroll <greg@mccarroll.org.uk>
  Leon Brocard
  Ed J

=head1 KUDOS

Thanks to the following for patches,

    Richard Clamp
    Pierre Denis
    Slaven Rezic

=head1 COPYRIGHT

Copyright (c) 1998-2003 Leon Brocard & Greg McCarroll. All rights
reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<VCS::Cvs>, L<VCS::Dir>, L<VCS::File>, L<VCS::Rcs>, L<VCS::Version>.
