package WebService::Akeneo::Resource::Categories;
$WebService::Akeneo::Resource::Categories::VERSION = '0.001';
use v5.38;
use Object::Pad;
use Mojo::JSON 'encode_json';
use Mojo::URL;

class WebService::Akeneo::Resource::Categories 0.001;
field $t :param;
field $paginator;

BUILD { $paginator = WebService::Akeneo::Paginator->new( transport => $t ) }

method get ($code)                  { $t->request('GET',   "/categories/$code") }
method upsert ($code, $payload)     { $t->request('PATCH', "/categories/$code", json   => $payload) }
method upsert_ndjson ($records)     { $t->request('PATCH', "/categories",       ndjson => $records) }
method list (%params)               { $paginator->collect('/categories', %params) }

method list_under_root ($root_code, %opt) {
  my $limit = delete($opt{limit}) // 100;
  my $query = {
    with_position => 'true',
    limit => $limit,
    search => encode_json({ parent => [ { operator => '=', value => $root_code } ] }),
  };
  my $acc = [];
  my $path = '/categories';
  while (1) {
    my $page_res = $t->request('GET', $path, query => $query);
    my $items = ($page_res->{items}//($page_res->{_embedded} && $page_res->{_embedded}{items})) // [];
    push @$acc, @$items if @$items;
    my $next = ($page_res->{_links}//{})->{next} && $page_res->{_links}{next}{href};
    last unless $next;
    my $url = Mojo::URL->new($next); $path = $url->path->to_string; $query = $url->query->to_hash;
  }
  my $root = $self->get($root_code);
  die sprintf('Category %s is not root.', $root_code) if defined $root->{parent};
  push @$acc, $root;
  return $acc;
}

1;
