package WebService::Qiita::V2;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use WebService::Qiita::V2::Client;

sub new {
    my ($class, $args) = @_;

    WebService::Qiita::V2::Client->new($args);
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Qiita::V2 - Qiita API(v2) Client

=head1 SYNOPSIS

    use WebService::Qiita::V2;

    my $client = WebService::Qiita::V2->new;

    $client->get_user_items('qiita'); # qiita's item list
    $client->{token} = 'your access token';
    $client->get_authenticated_user_items({ page => 1, per_page => 10 }); # your recently 10 items

=head1 DESCRIPTION

WebService::Qiita::V2 is a client of Qiita API V2 for Perl.
This module wrapped all Qiita API(not include deprecated).

API document: https://qiita.com/api/v2/docs

=head1 AUTHOR

risou E<lt>risou.f@gmail.comE<gt>

=head1 LICENSE

Copyright (C) risou

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

