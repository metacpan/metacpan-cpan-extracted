use Test::Lib;
use Test::Most;

{
    package Local::Test;

    use Moo;
    use Valiant::Filters;

    has 'info' => (is=>'ro', required=>1);

    filters 'info',
      template => 'Hello {{name}}, you are {{age}} years old!';
}


ok my $object = Local::Test->new(
  info => +{
    name => 'John',
    age => '52',
  }
);

is $object->info, 'Hello John, you are 52 years old!';

done_testing;
