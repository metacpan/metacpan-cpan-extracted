package WebService::Wedata::Database;
use strict;
use warnings;
use Carp;
use JSON::XS;
use WebService::Wedata::Item;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/ua api_key name description resource_url permit_other_keys updated_at created_at created_by/);

sub new {
    my($class, %params) = @_;

    my $self = bless {
        required_keys => [],
        optional_keys => [],
        items => [],
    }, $class;
    foreach my $k (qw/ua api_key name description resource_url updated_at created_at created_by/) {
        $self->set($k, $params{$k}) if ($params{$k});
    }
    foreach my $k (@{ $params{required_keys} }) {
        $self->add_required_key($k);
    }
    foreach my $k (@{ $params{optional_keys} }) {
        $self->add_optional_key($k);
    }
    if ($params{permit_other_keys} == 1 || $params{permit_other_keys} eq 'true') {
        $self->permit_other_keys(1);
    }
    else {
        $self->permit_other_keys(0);
    }
    $self;
}

sub add_required_key {
    my($self, $key) = @_;
    push @{ $self->{required_keys} }, $key;
}

sub add_optional_key {
    my($self, $key) = @_;
    push @{ $self->{optional_keys} }, $key;
}

sub update {
    my $self = shift;

    my $params = {
        api_key => $self->api_key,
        name => $self->name,
        description => $self->description,
        required_keys => $self->required_keys,
        optional_keys => $self->optional_keys,
        resource_url => $self->resource_url,
    };
    my $req = _make_update_request($params);
    my $response = $self->ua->request($req);
    if ($response->is_success) {
        return;
    }
    else {
        croak 'Faild to update database:' . $response->status_line;
    }
}

sub _make_update_request {
    my($params) = @_;
    my $param_required_keys = join '%20', @{$params->{required_keys}};
    my $param_optional_keys = join '%20', @{$params->{optional_keys}};
    my $param_permit_other_keys = ($params->{permit_other_keys}) ? 'true' : 'false';
    my $content = '';
    $content = join '&',
        "api_key=$params->{api_key}",
        "database[name]=$params->{name}",
        "database[description]=$params->{description}",
        "database[required_keys]=$param_required_keys",
        "database[optional_keys=$param_optional_keys",
        "database[permit_other_keys]=$param_permit_other_keys"
    ;
    my $req = HTTP::Request->new(
        PUT => $params->{resource_url},
        HTTP::Headers->new(
            'content-type' => 'application/x-www-form-urlencoded',
            'content-length' => length($content),
        ),
        $content,
    );
    $req;
}

sub delete {
    my($self, @params) = @_;
    my $params = {@params};

    $params->{api_key} = $self->api_key;
    $params->{name} = $self->name;
    my $req = _make_delete_request($params);
    my $response = $self->ua->request($req);
    if ($response->is_success) {
        # clean up
        $self->name('');
        $self->description('');
        $self->{required_keys} = [];
        $self->{optional_keys} = [];
        $self->resource_url('');
        $self->updated_at('');
        $self->created_at('');
        $self->created_by('');
        $self->{items} = [];
        return;
    }
    else {
        croak 'Faild to delete database:' . $response->status_line;
    }
}

sub _make_delete_request {
    my($params) = @_;

    my $content = "api_key=$params->{api_key}";
    my $url = $WebService::Wedata::URL_BASE . '/databases/' . $params->{name};
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

sub get_items {
    my($self) = @_;
    $self->get_item(database_name => $self->name);
}

sub get_item {
    my($self, @params) = @_;
    my $params = {@params};

    my $page = ($params->{page}) ? $params->{page} : '';

    my $parse_response = sub {
        my($data) = @_;
        my $item = WebService::Wedata::Item->new(
            database => $self,
            name => $data->{name},
            data => $data->{data},
            resource_url => $data->{resource_url},
            updated_at => $data->{updated_at},
            created_at => $data->{created_at},
            created_by => $data->{created_by},
        );
        $item;
    };

    my $url = $WebService::Wedata::URL_BASE;
    if ($params->{database_name}) {
        $url .= '/databases/' . $params->{database_name} . '/items.json';
    }
    elsif ($params->{id}){
        $url .= '/items/' . $params->{id} . '.json';
    }
    else {
        croak "specify item_id or database_name";
    }

    my $response = $self->ua->get($url, page => $page);
    if ($response->is_success) {
        my $data = decode_json($response->content);
        if ($params->{database_name}) {
            my $result = [];
            foreach my $item (@$data) {
                push @$result, $parse_response->($item);
            }
            $result;
        }
        else {
            $parse_response->($data);
        }
    }
    else {
        croak 'Faild to get_item:' . $response->status_line;
        return;
    }
}

sub create_item {
    my($self, @params) = @_;
    my $params = {@params};
    croak "require name on create_item\n" unless $params->{name};

    my $url = $WebService::Wedata::URL_BASE . '/databases/' . $self->name . '/items';
    my $kv = [];
    while (my($k, $v) = each(%{ $params->{data} })) {
        push @$kv, "data[$k]=$v";
    }
    
    my $content = '';
    $content = join '&',
        "api_key=" . $self->api_key,
        "name=$params->{name}",
        @$kv
    ;
    my $req = HTTP::Request->new(
        POST => $url,
        HTTP::Headers->new(
            'content-type' => 'application/x-www-form-urlencoded',
            'content-length' => length($content),
        ),
        $content,
    );
    my $response = $self->ua->request($req);
    if ($response->is_success) {
        my $new_item = WebService::Wedata::Item->new(
            database => $self,
            name => $params->{name},
            data => $params->{data},
            resource_url => $response->header('location'),
        );
        $new_item;
    }
    else {
        croak 'Faild to create_item:' . $response->status_line;
    }
}

sub update_item {
    my($self, @params) = @_;
    my $params = {@params};

    %$params = (%$params, %{ {
        api_key => $self->api_key,
        database_name => $self->name,
    } });
    my $req = WebService::Wedata::Item::_make_update_request($params);
    my $response = $self->ua->request($req);
    if ($response->is_success) {
        $self->get_item(id => $params->{id});
    }
    else {
        croak 'Faild to update_item:' . $response->status_line;
    }
}

sub delete_item {
    my($self, @params) = @_;
    my $params = {@params};
    croak "require item_id on delete_item\n" unless $params->{id};

    %$params = (%$params, %{ {
        api_key => $self->api_key,
    } });
    my $req = WebService::Wedata::Item::_make_delete_request($params);
    my $response = $self->ua->request($req);
    if ($response->is_success) {
        return;
    }
    else {
        croak 'Faild to delete_item:' . $response->status_line;
    }
}

1;
__END__

=head1 NAME

WebService::Wedata::Database - Wedata Database object

=head1 DESCRIPTION

Wedata Database object

=head1 METHODS

=head2 new

=over 4

=item Arguments: %params($ua, $api_key, $name, $description, $resource_url, @required_keys, @optional_keys, $permit_other_keys)

=item Return Value: $database

=back

  my $database = WebService::Databse->new(
      ua => LWP::UserAgent->new,
      api_key => 'YOUR_API_KEY',
      name => 'YOUR_DATABASE_NAME',
      description => 'DESCRIPTUON',
      required_keys => [qw/foo bar baz/],
      optional_keys => [qw/hoge fuga/],
      permit_other_keys => 1,
  );

Constructor.


=head2 add_required_key

=over 4

=item Arguments: $key

=item Return Value: none

=back

Add $key to required_keys.


=head2 add_optional_key

=over 4

=item Arguments: $key

=item Return Value: none

=back

Add $key to optional_keys.


=head2 update

=over 4

=item Arguments: none

=item Return Value: none

=back

  $database->description('updated description');
  $database->update;

Update database.


=head2 delete

=over 4

=item Arguments: none

=item Return Value: none

=back

Delete database.


=head2 get_items

=over 4

=item Arguments: none

=item Return Value: @items

=back

  my @items = $database->get_items;

Get all items in $database.


=head2 get_item

=over 4

=item Arguments: %params($id)

=item Return Value: $item

=back

Get specified $id item. Return value is instance of WebService::Wedata::Item.


=head2 create_item

=over 4

=item Arguments: %params($name, %data(key => value))

=item Return Value: $item

=back

Crete $item.


=head2 update_item

=over 4

=item Arguments: %params($name, %data(key => value))

=item Return Value: $item

=back

Update $item.


=head2 delete_item

=over 4

=item Arguments: %params($id)

=item Return Value: none

=back

Delete specified $id item.


=cut
