use Ubigraph;

my $u = new Ubigraph();

my $v1 = $u->Vertex();
my $v2 = $u->Vertex(shape=>"sphere");

my $e1 = $u->Edge($v1, $v2);

$v1->shape("torus");
$v1->size(3.5);

sleep(2);

$u->clear();

my @v;
for (0..100){
    $v[$_] = $u->Vertex();
}

for (0..100){
    $u->Edge($v[int(rand(100))], $v[int(rand(100))]);
    select(undef, undef, undef, 0.05);
}
