package WWW::Domain::Registry::VeriSign;

use strict;
use base qw/Class::Accessor/;
use warnings;
use Carp;
use WWW::Mechanize;

__PACKAGE__->mk_accessors(qw(mech));

our $VERSION = '0.02';

sub new {
    my ($class, $id, $password) = @_;
    my $self = bless {}, $class;
    $self->{reg} = {
                    base => 'https://nsmanager.verisign-grs.com',
                    id => $id,
                    password => $password,
                };
    $self->mech(WWW::Mechanize->new);
    $self;
}

sub login {
    my $self = shift;
    $self->mech->get($self->{reg}->{base} .'/ncc/login_page.do');
    $self->mech->submit_form(
                               form_number => 1,
                               fields => {
                                          logonname     => $self->{reg}->{id},
                                          logonpassword => $self->{reg}->{password},
                                      }
                           );
    $self->parse_login($self->mech->content);
}

sub parse_login {
    my ($self, $content) = @_;
    $content =~ m/currently logged in/;
}

sub account_view_page {
    my $self = shift;
    $self->mech->get($self->{reg}->{base} .'/ncc/account_view_page.do?MENU=Accounts');
    $self->parse_account_view_page($self->mech->content);
}

sub parse_account_view_page {
    my ($self, $content) = @_;
    my $content_from = qq(<div class="content">);
    my $content_till = qq(</div>);
    return unless $content =~ /$content_from(.*?)$content_till/s;;
    $content = $1;
    my $data;
    while ($content =~ m{<td class="alt3"[^>]*>([^:]+):</td>\n\s+<td class="alt4"[^>]*>([^<]+)</td>\n}ig) {
        my($key, $val) = ($1, $2);
        $val =~ s/&nbsp;?/ /g;
        $val =~ s/^\s+//;
        $val =~ s/\s+$//;
        $val =~ s/\n+/\n/g;
        $data->{lc($key)} = $val =~ m/\n/ ? [ split m/\n/ , $val ] : $val;
    }

    return $data;
}

sub credit_balance_view_page {
    my $self = shift;
    $self->mech->get($self->{reg}->{base} .'/ncc/credit_balance_view_page.do?MENU=Finance');
    $self->parse_credit_balance_view_page($self->mech->content);
}

*parse_credit_balance_view_page = \&parse_account_view_page;

# Preloaded methods go here.

1;
__END__

=head1 NAME

WWW::Domain::Registry::VeriSign - VeriSign NDS (https://www.verisign-grs.com/) Registrar Tool

=head1 SYNOPSIS

  use WWW::Domain::Registry::VeriSign;
  use Data::Dumper;

  my $reg = WWW::Domain::Registry::VeriSign->new('id', 'password');
  $reg->login;
  my $res = $reg->account_view_page;
  print Dumper $res;

=head1 DESCRIPTION

WWW::Domain::Registry::VeriSign uses WWW::Mechanize to scrape VeriSign NDS (https://www.verisign-grs.com/).

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
