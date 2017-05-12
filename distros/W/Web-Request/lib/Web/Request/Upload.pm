package Web::Request::Upload;
BEGIN {
  $Web::Request::Upload::AUTHORITY = 'cpan:DOY';
}
{
  $Web::Request::Upload::VERSION = '0.11';
}
use Moose;
# ABSTRACT: class representing a file upload

use HTTP::Headers;

use Web::Request::Types;


has headers => (
    is      => 'ro',
    isa     => 'Web::Request::Types::HTTP::Headers',
    coerce  => 1,
    handles => ['content_type'],
);

has tempname => (
    is  => 'ro',
    isa => 'Str',
);

has size => (
    is  => 'ro',
    isa => 'Int',
);

has filename => (
    is  => 'ro',
    isa => 'Str',
);

# XXX Path::Class, and just make this a delegation?
# would that work at all on win32?
has basename => (
    is  => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;

        require File::Spec::Unix;

        my $basename = $self->{filename};
        $basename =~ s{\\}{/}g;
        $basename = (File::Spec::Unix->splitpath($basename))[2];
        $basename =~ s{[^\w\.-]+}{_}g;

        return $basename;
    },
);

__PACKAGE__->meta->make_immutable;
no Moose;


1;

__END__

=pod

=head1 NAME

Web::Request::Upload - class representing a file upload

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  use Web::Request;

  my $app = sub {
      my ($env) = @_;
      my $req = Web::Request->new_from_env($env);
      my $upload = $req->uploads->{avatar};
  };

=head1 DESCRIPTION

This class represents a single uploaded file, generally from an C<< <input
type="file" /> >> element. You most likely don't want to create instances of
this class yourself; they will be created for you via the C<uploads> method on
L<Web::Request>.

=head1 METHODS

=head2 headers

Returns an L<HTTP::Headers> object containing the headers specific to this
upload.

=head2 content_type

Returns the MIME type of the uploaded file. Corresponds to the C<Content-Type>
header.

=head2 tempname

Returns the local on-disk filename where the uploaded file was saved.

=head2 size

Returns the size of the uploaded file.

=head2 filename

Returns the preferred filename of the uploaded file.

=head2 basename

Returns the filename portion of C<filename>, with all directory components
stripped.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
