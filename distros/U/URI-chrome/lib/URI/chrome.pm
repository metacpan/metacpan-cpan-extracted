package URI::chrome;

use strict;
use warnings;

use base qw(URI::_generic);

use Carp::Clan qw(croak);

=head1 NAME

URI::chrome - Mozilla chrome uri

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

our $CHROME_PACKAGE_REGEX = qr{([a-zA-Z0-9]+)};
our $CHROME_PART_REGEX = qr{((content|skin|locale)(/[a-zA-Z0-9-._]+)*)};
our $CHROME_FILE_REGEX = qr{([a-zA-Z0-9-._]+)};
our $CHROME_REGEX = qr{^chrome://$CHROME_PACKAGE_REGEX/$CHROME_PART_REGEX/$CHROME_FILE_REGEX$};

=head1 SYNOPSIS

  use URI;
  use URI::chrome;

  my $uri = URI->new("chrome://communicator/content/bookmarks/bookmarksManager.xul");
  local $\ = "\n";

  print $uri->package_name; # communicator
  print $uri->part; # content/bookmarks
  print $uri->file_name; # bookmarksManager.xul

=head1 DESCRIPTION

=head2 The Chrome URL Specification

The basic syntax of a chrome URI is as follows, 

  chrome://<package_name>/<part>/<file_name>

The elements of chrome URI detail is as follows, 

=over 4

=item package_name

The "package_name" is the package name.
For example, "browser", "messenger" or "communicator".

=item part

The "part" is simillar to path of http URI.
It's string is beggining of "content", "skin" or "locale".
For example, "content", "content/bookmarks". 

=item file_name

The "file_name" is the file name.

=back 

More detail, please see http://developer.mozilla.org/en/docs/XUL_Tutorial:The_Chrome_URL

=head1 METHODS

=head2 package_name([$package_name])

Getter/Setter of package_name

=cut

sub package_name {
    my ($self, $package_name) = @_;

    if ($package_name && $package_name =~ m|$CHROME_PACKAGE_REGEX|ox) { # setter
        $self->_chrome_setter("package_name", $package_name);
    }
    else {
        return $self->_chrome_struct->{package_name};
    }
}

=head2 part([$part])

Getter/Setter of part

=cut

sub part {
    my ($self, $part) = @_;

    if ($part && $part =~ m|$CHROME_PART_REGEX|ox) { # setter
        $self->_chrome_setter("part", $part);
    }
    else {
        return $self->_chrome_struct->{part};
    }
}

=head2 file_name([$file_name])

Getter/Setter of file_name

=cut

sub file_name {
    my ($self, $file_name) = @_;

    if ($file_name && $file_name =~ m|$CHROME_FILE_REGEX|ox) { # setter
        $self->_chrome_setter("file_name", $file_name);
    }
    else {
        return $self->_chrome_struct->{file_name};
    }
}

#### protected method

sub _init {
    my ($class, $uri_str, $scheme) = @_;

    if ($uri_str =~ m|$CHROME_REGEX|ox) {
        return $class->SUPER::_init($uri_str, $scheme);
    }
    else {
        croak(q|Invalid part prefix, must be "content" or "skin" or "locale".|);
    }
}

sub _chrome_setter {
    my ($self, $name, $value) = @_;

    my $struct = $self->_chrome_struct;
    $struct->{$name} = $value;
    $$self = $self->_chrome_uri_string($struct);
}

sub _chrome_uri_string {
    my ($self, $struct) = @_;

    return sprintf("chrome://%s/%s/%s", map { $struct->{$_} } qw(package_name part file_name));
}

sub _chrome_struct {
    my $self = shift;

    my ($package_name, $part, undef, undef, $file_name) 
        = ($$self =~ m|$CHROME_REGEX|ox);

    return {
        package_name => $package_name,
        part => $part,
        file_name => $file_name
    };
}

=head1 SEE ALSO

=over 4

=item L<URI>

=item http://developer.mozilla.org/en/docs/XUL_Tutorial:The_Chrome_URL

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-uri-chrome@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of URI::chrome
