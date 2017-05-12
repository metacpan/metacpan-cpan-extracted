package WWW::Mechanize::AutoPager;

use strict;
use 5.8.1;
our $VERSION = '0.02';

use HTML::AutoPagerize;
use Scalar::Util qw( weaken );
use WWW::Mechanize::DecodedContent;
use JSON;

sub WWW::Mechanize::autopager {
    my $mech = shift;
    $mech->{autopager} ||= WWW::Mechanize::AutoPager->new($mech);
}

sub WWW::Mechanize::next_link {
    my $mech = shift;
    $mech->{autopager}->next_link;
}

sub WWW::Mechanize::page_element {
    my $mech = shift;
    $mech->{autopager}->page_element;
}

sub new {
    my($class, $mech) = @_;
    my $self = bless {
        mech => $mech,
        autopager => HTML::AutoPagerize->new,
    }, $class;

    weaken($self->{mech}); # don't make it a circular reference
    $self;
}

sub load_siteinfo {
    my $self = shift;
    my $url  = shift || "http://wedata.net/databases/AutoPagerize/items.json";

    my $res = $self->{mech}->get($url);

    if (my $content = $self->{mech}->content) {
        if ($res->content_type =~ m{text/html}) { # backward compatibility
            while ($content =~ m!<textarea class="autopagerize_data".*?>\s*(.*?)\s*</textarea>!gs) {
                my $site = $self->parse_siteinfo($1);
                $self->{autopager}->add_site(%$site);
            }
        } else {
            for my $row ( @{ from_json( $content ) } ) {
                $self->{autopager}->add_site(%{ $row->{data} });
            }
        }
    }
}

sub add_site {
    my $self = shift;
    $self->{autopager}->add_site(@_);
}

sub parse_siteinfo {
    my($self, $config) = @_;
    my $site;
    while ($config =~ /^(\w+):\s+(.*?)\s*$/mg) {
        $site->{$1} = $2;
    }
    return $site;
}

sub next_link {
    my $self = shift;

    my $res = $self->{autopager}->handle($self->{mech}->uri, $self->{mech}->decoded_content)
        or return;

    return $res->{next_link};
}

sub page_element {
    my $self = shift;

    my $res = $self->{autopager}->handle($self->{mech}->uri, $self->{mech}->decoded_content)
        or return;

    return $res->{page_element};
}


1;
__END__

=for stopwords AutoPagerize siteinfo

=head1 NAME

WWW::Mechanize::AutoPager - Automatic Pagination using AutoPagerize

=head1 SYNOPSIS

  use WWW::Mechanize::AutoPager;

  my $mech = WWW::Mechanize->new;

  # Load siteinfo from http://swdyh.infogami.com/autopagerize
  $mech->autopager->load_siteinfo();

  # Or, load manually
  $mech->autopager->add_site(
      url => 'http://.+\.tumblr\.com/',
      nextLink => ...,
  );

  $mech->get('http://otsune.tumblr.com/');

  if (my $link = $mech->next_link) {
      $mech->get($link);
      $mech->page_element; # HTML snippet
  }

=head1 DESCRIPTION

WWW::Mechanize::AutoPager is a plugin for WWW::Mechanize to do
automatic pagination using AutoPagerize user script.

B<THIS MODULE IS CONSIDERED EXPERIMENTAL AND ITS API WILL BE LIKELY TO CHANGE>

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTML::AutoPagerize>, L<http://swdyh.infogami.com/autopagerize>

=cut
