package WWW::Domain::Registry::Afilias;

use strict;
use base qw/Class::Accessor/;
use warnings;
use Carp;
use WWW::Mechanize;

__PACKAGE__->mk_accessors(qw(mech));

our $VERSION = '0.01';

sub new {
    my ($class, $id, $password) = @_;
    my $self = bless {}, $class;
    $self->{reg} = {
                    base => 'https://admin.afilias.net',
                    id => $id,
                    password => $password,
                };
    $self->mech(WWW::Mechanize->new);
    $self;
}

sub login {
    my $self = shift;
    $self->mech->get($self->{reg}->{base} .'/');
    $self->mech->post($self->{reg}->{base} .'/login.do',
                      {
                       user => $self->{reg}->{id},
                       pass => $self->{reg}->{password},
                       "login_submit" => 'Login',
                   }
                  );
    $self->parse_login($self->mech->content);
}

sub parse_login {
    my ($self, $content) = @_;
    $content =~ m/Account Information/;
}

sub home {
    my $self = shift;
    $self->mech->get($self->{reg}->{base} .'/home.do');
    $self->parse_home($self->mech->content);
}

sub parse_home {
    my ($self, $content) = @_;
    my $content_from = qq(<div class="bodyCopy">);
    my $content_till = qq(<div id="clearfooter"></div>);
    return unless $content =~ /$content_from(.*?)$content_till/s;
    $content = $1;
    $content =~ s,<(br|/?p|/div|/tr)>\n,,g;
    $content =~ s,<tbody><tr>\n,,g;
    $content =~ s,</tbody></table>\n,,g;
    $content =~ s,&nbsp;,,g;

    my $data;
    return unless $content =~ m,>Account balance:</span> (.*?)<,s;
    $data->{balance} = $1;
    return unless $content =~ m,>Domain names created in your account yesterday:</span>(.*?)<p>,s;
    $data->{yesterday} = $1;

    while ($content =~ m{<td width="20"></td><td width="40">(.+)</td><td width="50">(.+)</td>\n}ig) {
        my($key, $val) = ($1, $2);
        $val =~ s/^\s+//;
        $val =~ s/\s+$//;
        $val =~ s/\n+/\n/g;
        $data->{lc($key)} = $val;
    }

    return $data;
}

sub account {
    my $self = shift;
    $self->mech->get($self->{reg}->{base} .'/account.do');
    $self->parse_account($self->mech->content);
}

sub parse_account {
    my ($self, $content) = @_;

    my $content_from = qq(<p class="contentSubSections">Account Information</p>);
    my $content_till = qq(<div id="clearfooter"></div>);
    return unless $content =~ /$content_from(.*?)$content_till/s;
    $content = $1;
    $content =~ s,&nbsp;,,g;

    my $data;
    while ($content =~ m{<td align="right" valign="top" width="150">(.+)</td><td align="left" valign="top">(.*)</td>\n}ig) {
        my($key, $val) = ($1, $2);
        $val =~ s/^\s+//;
        $val =~ s/\s+$//;
        $val =~ s/\n+/\n/g;
        $data->{lc($key)} = $val;
    }

    return $data;
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

WWW::Domain::Registry::Afilias - Afilias (https://admin.afilias.net/) Registry  Tool

=head1 SYNOPSIS

  use WWW::Domain::Registry::Afilias;
  use Data::Dumper;

  my $reg = WWW::Domain::Registry::Afilias->new('id', 'password');
  $reg->login;
  my $res = $reg->home;
  print Dumper $res;

=head1 DESCRIPTION

WWW::Domain::Registry::Afilias uses WWW::Mechanize to scrape Afilias (https://admin.afilias.net/).

=head1 SEE ALSO

L<WWW::Mechanize>

=head1 AUTHOR

Masahito Yoshida E<lt>masahito@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Masahito Yoshida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
