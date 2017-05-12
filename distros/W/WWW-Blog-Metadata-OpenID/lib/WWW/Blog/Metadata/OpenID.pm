package WWW::Blog::Metadata::OpenID;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use WWW::Blog::Metadata;
use URI;

WWW::Blog::Metadata->mk_accessors(qw( openid_server openid_delegate ));

sub on_got_tag {
    my $class = shift;
    my($meta, $tag, $attr, $base_uri) = @_;
    if ($tag eq 'link' && $attr->{rel}) {
        my %rel = map { $_ => 1 } split /\s+/, lc $attr->{rel};
        for my $role (qw( server delegate )) {
            if ($rel{"openid.$role"}) {
                my $meth = "openid_$role";
                $meta->$meth(URI->new_abs($attr->{href}, $base_uri)->as_string);
            }
        }
    }
}

sub on_got_tag_order { 99 }

1;
__END__

=head1 NAME

WWW::Blog::Metadata::OpenID - Extract OpenID server from weblog

=head1 SYNOPSIS

  use WWW::Blog::Metadata;
  my $meta = WWW::Blog::Metadata->extract_from_uri($uri)
      or die WWW::Blog::Metadata->errstr;
  print $meta->openid_server;
  print $meta->openid_delegate;

=head1 DESCRIPTION

WWW::Blog::Metadata::OpenID is a WWW::Blog::Metadata plugin to extract
OpenID server URL from weblog HTML.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW::Blog::Metadata> L<Net::OpenID::Consumer> http://www.openid.net/

=cut
