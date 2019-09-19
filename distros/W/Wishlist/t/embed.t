use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new(
  'Wishlist',
  {database => ':temp:'}
);

{
  package Local::MockLink;
  use Mojo::Base -base;
  has [qw/title url html/];
}

# "mock" the link helper
my ($url, $data);
$t->app->helper('link' => sub {
  $url = $_[1];
  my $cb = $_[2];
  $cb->(undef, Local::MockLink->new($data));
});

$data = {
  title => 'Cool Beans',
  url => 'coolbeans.notasite',
  html => '<p>Some really Cool Beans</p>',
};

$t->get_ok('/add?url=coolbeans.notasite')
  ->status_is(200)
  ->text_is('#item-detail p', 'Some really Cool Beans')
  ->element_exists(
    'form input[type="hidden"][name="title"][value="Cool Beans"]'
  )
  ->element_exists(
    'form input[type="hidden"][name="url"][value="coolbeans.notasite"]'
  );

is $url, 'coolbeans.notasite', 'correct site was requested';

done_testing;

