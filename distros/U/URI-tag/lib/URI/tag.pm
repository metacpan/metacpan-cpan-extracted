package URI::tag;

use strict;
our $VERSION = '0.02';

use base qw(URI);

sub authority {
    my $self = shift;
    $self->_accessor('authority', @_);
}

sub date {
    my $self = shift;
    $self->_accessor('date', @_);
}

sub specific {
    my $self = shift;
    $self->_accessor('specific', @_);
}

sub _accessor {
    my $self = shift;
    my $attr = shift;

    my $stuff = $self->_from_opaque($self->opaque);
    my $old   = $stuff->{$attr};
    if (@_) {
        $stuff->{$attr} = shift;
        $self->opaque( $self->_to_opaque($stuff) );
    }
    return $old;
}

sub _from_opaque {
    my($self, $opaque) = @_;

    # relaxed regexp rather than from the ABNF in RFC 4151
    my $stuff;
    $opaque =~ /^([\w\-\.\@]*)(?:,(\d{4}(?:-\d\d(?:-\d\d)?)?)?(?::([$URI::uric]*))?)?$/;
    $stuff->{authority} = $1;
    $stuff->{date}      = $2;
    $stuff->{specific}  = $3;

    $stuff;
}

sub _to_opaque {
    my($self, $stuff) = @_;

    sprintf "%s,%s:%s", map { $stuff->{$_} || '' } qw( authority date specific );
}

1;
__END__

=head1 NAME

URI::tag - Tag URI Scheme (RFC 4151)

=head1 SYNOPSIS

  use URI;
  use URI::tag;

  my $uri = URI->new("tag:my-ids.com,2001-09-15:blog-555");

  $uri->authority; # my-ids.com
  $uri->date;      # 2001-09-15
  $uri->specific;  # blog-555

  $uri = URI->new("tag:");
  $uri->authority("example.com");
  $uri->date("2006-09-22");
  $uri->specific("blahblah");

  print $uri->as_string; # tag:example.com,2006-09-22:blahblah

=head1 DESCRIPTION

URI::tag is an URI class that represents Tag URI Scheme, defined in RFC 4151.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://www.ietf.org/rfc/rfc4151.txt>

=cut
