package WebService::Qiita;
use strict;
use warnings;
use utf8;
our $VERSION = '0.04';

use Carp qw(croak);

use WebService::Qiita::Client;


sub new {
    my ($class, %options) = @_;

    WebService::Qiita::Client->new(\%options);
}

# Delegade method to WebService::Qiita::Client object
sub AUTOLOAD {
    my $func = our $AUTOLOAD;
       $func =~ s/.*://g;
    my (@args) = @_;

    {
        no strict 'refs';

        *{$AUTOLOAD} = sub {
            my $class  = shift;
            my $client = $class->new;
            defined $client->can($func) || croak "no such func $func";
            shift @args;
            $client->$func(@args);
        };
    }
    goto &$AUTOLOAD;
}

sub DESTROY {}

1;
__END__

=head1 NAME

WebService::Qiita - Perl wrapper for the Qiita API

=head1 SYNOPSIS

  use WebService::Qiita;

  # Class method style
  my $user_items = WebService::Qiita->user_items('y_uuki_');

  my $tag_items = WebService::Qiita->tag_items('perl');

  my $item_uuid = '1234567890abcdefg';
  my $markdown_content = WebService::Qiita->item($item_uuid);

  # Instance method style
  my $client = WebService::Qiita->new(
    url_name => 'y_uuki_',
    password => 'mysecret',
  );
  # or
  $client = WebService::Qiita->new(
    token => 'myauthtoken',
  );

  my $myinfo = $client->user_items;
  $myinfo->{uuid}; #=> "1a43e55e7209c8f3c565"
  $myinfo->{user}->{url_name}; #=> "y_uuki_"

=head1 DESCRIPTION

WebService::Qiita is a wrapper for Qiita API.

=head1 METHODS

=over 4

=item my $client = WebService::Qiita->new(%args)

Creates a new instance of WebService::Qiita.

=item my $user_items = $client->user_items([$url_name], [\%params])

Retrieves an ARRAY reference of user items

=item my $user_tags = $client->user_following_tags($url_name, [\%params])

Retrieves an ARRAY reference of user following tags

=item my $following_users = $client->user_following_users($url_name, [\%params])

Retrieves an ARRAY reference of user following users

=item my $user_stocks = $client->user_stocks([$url_name], [\%params])

Retrieves an ARRAY reference of user stock items

=item my $user = $client->user([$url_name])

Retrieves an HASH reference of user info

=item my $tag_items = $client->tag_items($url_name, [\%params])

Retrieves an ARRAY reference of tag items

=item my $tags = $client->tags([\%params])

Retrieves an ARRAY reference of tags

=item $client->post_item(\%params)

Creates an item

=item $client->update_item($uuid, \%params)

Edits item by uuid

=item $client->delete_item($uuid)

Deletes an item by uuid

=item my $item = $client->item($uuid)

Retrieves an item by uuid

=item my $items = $client->search_items($query, \%params)

Searchs an item by query

=item $client->stock_item($uuid)

Creates stock of an item by uuid

=item $client->unstock_item($uuid)

Deletes stock of an item by uuid

=back

=head1 AUTHOR

Yuuki Tsubouchi E<lt>yuuki@cpan.orgE<gt>

=head1 SEE ALSO

L<<a href="http://qiita.com/docs">Qiita API Documet</a>>
L<<a href="https://github.com/yaotti/qiita-rb">Qiita Ruby wrapper</a>>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
