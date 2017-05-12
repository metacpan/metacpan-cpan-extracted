package URI::jar;

use strict;
use warnings;

use base qw(URI::_generic);
use URI;

=head1 NAME

URI::jar - Java ARchive URI

=head1 VERSION

version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use URI;
  use URI::jar;

  my $jar_uri = URI->jar("jar:http://www.art-code.org/foo/bar.jar!/content/baz/zigorou.js");
  local $\ = "\n";
  print $jar_uri->jar_entry_name; # will print "/content/baz/zigorou.js"
  print $jar_uri->jar_file_uri; # will print "http://www.art-code.org/foo/bar.jar"

=head1 METHOD

=head2 jar_entry_name()

Return entry name in jar file.

=cut

sub jar_entry_name {
    my ($self, $jar_entry_name) = @_;
    my @leaf = split(/!/, $$self);

    if (@leaf == 2) {
        if ($jar_entry_name) {
            $self->path(join("!", $leaf[0], $jar_entry_name));
        }
        else {
            return $leaf[1];
        }
    }
    else {
        return;
    }
}

=head2 jar_file_uri()

Return jar file's uri as L<URI> object.

=cut

sub jar_file_uri {
    my ($self, $jar_file_uri) = @_;

    my @leaf = split(/!/, $self->path);

    if (@leaf == 2) {
        if ($jar_file_uri) {
            if (UNIVERSAL::isa($jar_file_uri, "URI")) {
                $jar_file_uri = $jar_file_uri->as_string;
            }

            $self->path(join("!", $jar_file_uri, $leaf[1]));
        }
        else {
            if ($leaf[0] =~ /^([^:]+)\:/) {
                return URI->new($leaf[0]);
            }
            else {
                return URI->new($leaf[0], "file");
            }
        }
    }
    else {
        return;
    }
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-uri-jar@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of URI::jar
