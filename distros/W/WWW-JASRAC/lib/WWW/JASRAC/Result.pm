# $Id: Result.pm 1 2006-03-14 18:30:19Z daisuke $
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package WWW::JASRAC::Result;
use strict;

sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = bless {
        title   => $args{title},
        link    => $args{link},
        rights  => $args{rights},
        artists => $args{artists},
    }, $class;

    return $self;
}

sub title   { shift->{title} }
sub rights  { my $r = shift->{rights}; wantarray ? @$r : $r }
sub artists { my $r = shift->{artists}; wantarray ? @$r : $r }

1;

__END__

=head1 NAME

WWW::JASRAC::Result - Search Result From JASRAC

=head1 SYNOPSIS

  use WWW::JASRAC::Result;
  my $r = WWW::JASRAC::Result->new(
    title   => $title,
    link    => $link,
    rights  => [ ... ],
    artists => [ ... ]
  );

=head1 METHODS

=head2 new

Create a new result object.

=head2 title

Return the title of the result

=head2 rights

Return the rights holder list.

=head2 artists

Return the artist(s).

=head2 link

Return the link to the description page.

=cut
