use T2::B 'Extended';

t2->like(
    eval '$abc = "oops"' || $@,
    qr/"\$abc" requires explicit package name/,
    "'strict' imported into scope by bundle",
);

t2->ok(1, 'got ok');

t2->done_testing;
