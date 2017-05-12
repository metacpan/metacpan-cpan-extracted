package WebService::Simplenote::Note::Meta::Types;
{
  $WebService::Simplenote::Note::Meta::Types::VERSION = '0.2.1';
}

# ABSTRACT Custom type library for Notes

use Moose::Util::TypeConstraints;

enum 'SystemTags', [qw/pinned unread markdown list/];

no Moose::Util::TypeConstraints;

__END__
=pod

=for :stopwords Ioan Rogers Fletcher T. Penney github

=head1 NAME

WebService::Simplenote::Note::Meta::Types

=head1 VERSION

version 0.2.1

=head1 AUTHORS

=over 4

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Fletcher T. Penney <owner@fletcherpenney.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Ioan Rogers.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/ioanrogers/WebService-Simplenote/issues>.

=head1 SOURCE

The development version is on github at L<http://github.com/ioanrogers/WebService-Simplenote>
and may be cloned from L<git://github.com/ioanrogers/WebService-Simplenote.git>

=cut

