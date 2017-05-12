# $Id: /mirror/perl/URI-Match/trunk/lib/URI/Match.pm 8767 2007-11-08T01:41:57.358392Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package URI::Match;
use strict;
use warnings;
use URI();
use vars ('$VERSION');
$VERSION = '0.00001';

sub URI::match_parts
{
    my $self = shift;

    if (@_ == 1) {
        return $self->_match( undef, $_[0] );
    }

    my $matched = 0;
    my $count   = 0;
    while (@_) {
        my($part, $cond) = splice(@_, 0, 2);
        $count++;

        $matched++ if $self->_match( $part, $cond );
    }
    return $matched == $count;
}

sub URI::_match
{
    my ($self, $part, $cond) = @_;

    my $target =
        ! defined $part ? $self :
        $self->can($part) ? ( $self->$part || '' ) : ''
    ;

    my $ref = ref $cond ;
    if (! $ref || $ref eq 'Regexp') {
        return $target =~ /$cond/;
    } elsif ($ref eq 'CODE') {
        return $cond->($target, $self);
    } elsif ( my $code = eval { $cond->can('match') } ) {
        return $code->( $cond, $target, $self );
    }

    return ();
}

1;

__END__

=head1 NAME

URI::Match - Match URLs By Parts

=head1 SYNOPSIS

  use URI;
  use URI::Match;

  my $uri = URI->new("http://www.example.com");

  # Match just a single part of the URL
  if ( $uri->match_parts( host => qr/^(?!www).+\.cpan\.org$/ )) {
    # matched
  }

  # Match using a subroutine
  my $code = sub {
    my ($host, $url) = @_;
    return $host eq 'www.perl.org';
  };
  if ( $uri->match_parts( host => $code ) ) {
    # matched
  }

  # Match using an object
  my $object = My::Matcher->new(); # must implement "match"
  if ( $uri->match_parts( host => $object ) ) {
    # matched
  }

  # Match several parts
  my $code = sub {
    my ($path, $url) = @_;
    return $path ne '/';
  };
  if ( $uri->match_parts(
        host => qr/^(?!www).+\.cpan\.org$/,
        path => $code
  )) {
    # matched
  }

  # Match the whole URL (just for completeness) 
  if ($uri->match_parts( qr{^http://search\.cpan\.org} )) {
    # matched
  }

=head1 DESCRIPTION

This is a simple utility that adds ability to match URL parts against
regular expressions, subroutines, or objects that implement a match() method.

Since this module uses loops and method calls, writing up a clever regular
expression and using it directly against the whole URL is probably faster.
This module aims to solve the problem where readability matters, or when you
need to assemble the match conditions at run time.

URI::Match adds the following methods to the URI namespace.

=head1 METHODS

=head2 match_parts(%cond)

Matches the URI object against the given conditions. The conditions can be
given as a single scalar or a hash. If given a single scalar, it will match
against the whole URI. Otherwise, the key value will be taken as the part
to match the condition against.

For example,

  $uri->match_parts( qr{^ftp://ftp.cpan.org$} )

Will only match if the entire URL matches the regular expression above. But
If you want to match against several different schemes (say, http and ftp)
and aother set of hosts, you could say:

  $uri->match_parts(
    scheme => qr{^(?:ftp|http)$},
    host   => qr{^.+\.example\.com$}
  )

Conditions can be either a scalar, a regular expression, a subroutine, or
an object which implements a match() method. Simple scalars are treated as 
regular expressions.

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut