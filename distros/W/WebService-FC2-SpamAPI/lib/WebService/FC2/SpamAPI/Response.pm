package WebService::FC2::SpamAPI::Response;

use warnings;
use strict;
use base qw/ Class::Accessor::Fast /;
use Encode qw/ decode encode /;

my $Encoding = 'Shift_JIS';

__PACKAGE__->mk_accessors(
    qw/ is_spam error_message usid name url
        comment category registered_date updated_date / );

=head1 NAME

WebService::FC2::SpamAPI::Response - Reponse object of WebService::FC2::SpamAPI

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  $res = $api->check_url({ url => $url, data => 1 });
  $res->is_spam;         # 1 or 0
  $res->usid;            # fc2 user id
  $res->name;            # site name
  $res->url;             # site url
  $res->comment;         # comment
  $res->category;        # category
  $res->registered_date; # registered date
  $res->updated_date;    # updated date

=head1 FUNCTIONS

=head2 parse

Parse single response message & returns Response object.

=cut

sub parse {
    my ( $class, $content ) = @_;

    if ( $content =~ /^True/ ) { # not spam
        return $class->new({ is_spam => 0 });
    }
    if ( $content =~ /^False/ ) { # spam & no data
        return $class->new({ is_spam => 1 });
    }

    my @res = split /\r*\n/, $content;
    for my $res ( @res ) {
        $res = decode( $Encoding, $res );
    }
    unless ( $res[0] =~ /\A\d+\z/ ) { # error
        return $class->new({ is_spam => 0, error_message => $res[0] });
    }
    return $class->new({
        is_spam         => 1,
        usid            => $res[0],
        name            => $res[1],
        url             => $res[2],
        comment         => $res[3],
        category        => $res[4],
        registered_date => $res[5],
        updated_date    => $res[6],
    });
}

=head2 parse_list

Parse multiple response message & returns Response object list.

=cut

sub parse_list {
    my ( $class, $content ) = @_;
    my @r_list;
    for my $line ( split /\r*\n/, $content ) {
        if ( $line =~ /\t/ ) {
            $line = decode( $Encoding, $line );
            my @data = split /\t/, $line;
            push @r_list, $class->new({
                is_spam         => 1,
                name            => $data[0],
                url             => $data[1],
                registered_date => $data[2],
            });
        }
    }
    return @r_list;
}

=head1 AUTHOR

FUJIWARA Shunichiro, C<< <fujiwara at topicmaker.com> >>

=head1 SEE ALSO

L<WebService::FC2::SpamAPI>, http://seo.fc2.com/spam/

=head1 COPYRIGHT & LICENSE

Copyright 2007 FUJIWARA Shunichiro, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WebService::FC2::SpamAPI
