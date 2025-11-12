package WebService::Akeneo::Paginator;
$WebService::Akeneo::Paginator::VERSION = '0.001';
use v5.38;

use Object::Pad;
use Mojo::URL;

class WebService::Akeneo::Paginator 0.001;

field $transport :param;   # WebService::Akeneo::Transport

method collect ($path, %params) {
  my $limit = delete($params{limit}) // 100;
  my $page  = delete($params{page})  // 1;
  my $query = { %params, limit=>$limit, page=>$page };

  my $acc = [];
  while (1) {
    my $page_res = $transport->request('GET', $path, query => $query);
    my $items = ($page_res->{items}//($page_res->{_embedded} && $page_res->{_embedded}{items})) // [];
    push @$acc, @$items if @$items;

    my $next = ($page_res->{_links}//{})->{next} && $page_res->{_links}{next}{href};
    last unless $next;
    my $url = Mojo::URL->new($next); $query = $url->query->to_hash;
  }
  return $acc;
}

1;
