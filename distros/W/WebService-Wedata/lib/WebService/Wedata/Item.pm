package WebService::Wedata::Item;
use strict;
use warnings;
use Carp;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/database name resource_url updated_at created_at created_by/);

sub new {
    my($class, %params) = @_;
    my $self = bless {
        data => $params{data} || {},
    }, $class;
    foreach my $k (qw/database name resource_url updated_at created_at created_by/) {
        $self->set($k, $params{$k}) if ($params{$k});
    }
    $self;
}

sub set_data {
    my($self, $key, $value) = @_;
    $self->{data}->{$key} = $value;
}

sub update {
    my($self, @data) = @_;

    my $item_id = _id_from_resource_url($self->resource_url);
    my $params = {
        api_key => $self->database->{api_key},
        database_name => $self->database->{name},
        id => $item_id,
        data => {@data},
    };
    my $req = _make_update_request($params);
    my $response = $self->database->{ua}->request($req);
    if ($response->is_success) {
        $self->{data} = {};
        while (my($k, $v) = each(%{ $params->{data} })) {
            $self->set_data($k, $v);
        }
    }
    else {
        croak 'Faild to update item:' . $response->status_line;
    }
}

sub _make_update_request {
    my($params) = @_;
    my $kv = [];
    while (my($k, $v) = each(%{ $params->{data} })) {
        push @$kv, "data[$k]=$v";
    }
    my $content = '';
    $content = join '&',
        "api_key=$params->{api_key}",
        @$kv
    ;
#    my $url = join '/', $WebService::Wedata::URL_BASE, 'databases', $params->{database_name}, 'items', $params->{id};
    my $url = join '/', $WebService::Wedata::URL_BASE, 'items', $params->{id};
    my $req = HTTP::Request->new(
        PUT => $url,
        HTTP::Headers->new(
            'content-type' => 'application/x-www-form-urlencoded',
            'content-length' => length($content),
        ),
        $content,
    );
    $req;
}

sub delete {
    my($self) = @_;

    my $item_id = _id_from_resource_url($self->resource_url);
    my $params = {
        api_key => $self->database->{api_key},
        id => $item_id,
    };
    my $req = _make_delete_request($params);
    my $response = $self->database->{ua}->request($req);
    if ($response->is_success) {
        $self->name('');
        $self->database({});
        $self->{data} = [];
        return;
    }
    else {
        croak 'Faild to delete item:' . $response->status_line;
    }
}

sub _make_delete_request {
    my($params) = @_;
    my $content = "api_key=$params->{api_key}";
    my $url = join '/', $WebService::Wedata::URL_BASE, 'items', $params->{id};
    my $req = HTTP::Request->new(
        DELETE => $url,
        HTTP::Headers->new(
            'content-type' => 'application/x-www-form-urlencoded',
            'content-length' => length($content),
        ),
        $content,
    );
    $req;
}

sub _id_from_resource_url {
    my $url = shift;
    $url =~ s!^http://wedata\.net/items/(\d+)$!$1!;
    $url;
}

1;
__END__

=head1 NAME

WebService::Wedata::Item - Wedata Item object

=head1 DESCRIPTION

Wedata Item object

=head1 METHODS

=head2 new

=over 4

=item Arguments: %params($database, $name, %data, $resource_url)

=item Return Value: $item

=back

Constructor. Take a parent database(L<WebService::Wedata::Database> instance) and item name.

  my $database = WebService::Wedata->get_database('AutoPagerize');
  my $item = WebService::Wedata::Item->new(
      database => $database,
      name => 'new item',
      resorce_url => ...
  );

Also take a optional data hash.

  my $item = WebService::Wedata::Item->new(
      database => $database,
      name => 'new item',
      data => {
          url => ...,
          nextLink => ...,
          pageElement => ...,
      },
      resorce_url => ...
  });


=head2 set_data

=over 4

=item Arguments: $key, $value

=item Return Value: none

=back

Set {$key => $value} to item data hash.


=head2 update

=over 4

=item Arguments: %data

=item Return Value: none

=back

Update self as %data.

  $item->update(
      url => 'aa',
      nextLink => '',
      pageElement => '',
  );


=head2 delete

=over 4

=item Arguments: none

=item Return Value: none

Delete self.

  $item->delete;

=back

=cut
