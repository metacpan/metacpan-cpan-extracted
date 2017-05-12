package Zeal::Document;

use 5.014000;
use strict;
use warnings;

our $VERSION = '0.001001';

use parent qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/id name type path anchor docset/);

sub fetch {
	my ($self) = @_;
	$self->docset->fetch($self->path)
}

1;
__END__

=encoding utf-8

=head1 NAME

Zeal::Document - Class representing a Dash/Zeal document

=head1 SYNOPSIS

  use Zeal::Document;
  my $doc = $ds->query('perlsec'); # $ds is a Zeal::Docset instance
  say $doc->name; # perlsec
  say $doc->type; # Module
  say $doc->path; # perldoc-html/perlsec.html
  my $html = $doc->fetch; # $html is now the HTML documentation for perlsec

=head1 DESCRIPTION

Dash is an offline API documentation browser. Zeal::Document is a class
representing a Dash/Zeal document.

Available methods:

=over

=item $doc->B<id>

The ID of this document. Not typically interesting.

=item $doc->B<name>

The name of this document.

=item $doc->B<type>

The type of this document. The list of types is available on
the Dash website: L<http://kapeli.com/docsets#supportedentrytypes>

=item $doc->B<path>

The path of this document, relative to
F<docset_root/Contents/Resources/Documents/>. This can also be a HTTP
URL.

=item $doc->B<anchor>

The URL anchor/fragment identifier of this document.

=item $doc->B<fetch>

The HTML content of this document, retrieved from the file system or
via HTTP::Tiny.

=back

=head1 SEE ALSO

L<Zeal>, L<http://kapeli.com/dash>, L<http://zealdocs.org>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
