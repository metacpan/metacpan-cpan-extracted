#########
# Author:        rmp@psyphi.net
# Maintainer:    rmp@psyphi.net
# Created:       2006-06-08
# Last Modified: $Date: 2009/01/09 14:38:54 $
# Id:            $Id: File.pm,v 1.3 2009/01/09 14:38:54 zerojinx Exp $
# Source:        $Source: /cvsroot/xml-feedlite/xml-feedlite/lib/XML/FeedLite/File.pm,v $
# $HeadURL$
#
package XML::FeedLite::File;
use strict;
use warnings;
use base qw(XML::FeedLite);
use English qw(-no_match_vars);
use Carp;

our $VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/smxg); sprintf '%d.'.'%03d' x $#r, @r };

sub fetch {
  my ($self, $url_ref) = @_;

  for my $fn (keys %{$url_ref}) {
    if(!ref $url_ref->{$fn} eq 'CODE') {
      next;
    }

    open my $fh, q(<), $fn or croak $ERRNO;
    local $RS = undef;
    my $xml   = <$fh>;
    close $fh or carp $ERRNO;

    my $cb = $url_ref->{$fn};
    &{$cb}(\$xml); ## no critic
  }
  return;
}

1;

__END__

=head1 NAME

XML::FeedLite::File

=head1 VERSION

$Revision: 1.3 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 fetch - Fetch feed data from file

  $xflf->fetch({
                '/path/to/file1' => sub { ... },
                '/path/to/file2# => sub { ... },
               });

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rmp@psyphi.netE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2005 by Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
