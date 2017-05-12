use Test::More;
use Encode;

BEGIN { use_ok( 'Wight::Chart::ChartJS' ); }

my $chart = Wight::Chart::ChartJS->new(
  type => "spark",
  width => 100,
  height => 50,
  colour => "#000000",
  output => "spark.png",
);

$chart->columns([a..g]);
$chart->rows([0.2, 0.2, 0.6, 0.4, 0.2, 0.9, 2.1]);
$chart->render();

$chart = Wight::Chart::ChartJS->new(
  type => "line",
  output => "line.png",
);

$chart->columns([a..g]);
$chart->rows([0.2, 0.2, 0.6, 0.4, 0.2, 0.9, 2.1]);
$chart->render({
  scaleOverride => JSON::XS::true,
  scaleLabel => decode_utf8("£<%=value%>"),
  scaleStepWidth => 1,
  scaleSteps => 10,
});

done_testing;
