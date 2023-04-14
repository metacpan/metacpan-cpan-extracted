use Test::Most;
use Valiant::HTML::Tag;

ok 1;

done_testing

__END__

{
  ok my $tag = Valiant::HTML::Tag->new(
    model_name => 'person',
    method_name => 'name',
    view => 1,
  );

}

{
  ok my $tag = Valiant::HTML::Tag->new(
    model_name => 'person[]',
    method_name => 'name',
    view => 1,
    options => +{ model=>111 },
  );

  use Devel::Dwarn;
  Dwarn $tag->options;
  Dwarn $tag;
  warn $tag->model;
    Dwarn $tag;

}


done_testing;
