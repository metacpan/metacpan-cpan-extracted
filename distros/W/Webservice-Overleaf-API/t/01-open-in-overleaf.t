use strict;
use warnings;
use Test::More;

use Webservice::Overleaf::API;

{
    local $ENV{http_proxy}  = 'definitely-not-a-proxy-url';
    local $ENV{https_proxy} = 'definitely-not-a-proxy-url';
    local $ENV{all_proxy}   = 'definitely-not-a-proxy-url';
    my $lazy_ok = eval { Webservice::Overleaf::API->new; 1 };
    ok $lazy_ok, 'constructor is HTTP-lazy and does not inspect proxy environment';
}

my $ol = Webservice::Overleaf::API->new;

my $url = $ol->open_uri(
    uri           => 'https://example.org/a paper.zip',
    engine        => 'lualatex',
    main_document => 'main.tex',
    visual_editor => 1,
);

like $url, qr{\Ahttps://www\.overleaf\.com/docs\?}, 'uses official /docs endpoint';
like $url, qr{snip_uri=https%3A%2F%2Fexample\.org%2Fa%20paper\.zip}, 'URI escaped';
like $url, qr{engine=lualatex}, 'engine included';
like $url, qr{main_document=main\.tex}, 'main document included';
like $url, qr{visual_editor=true}, 'visual editor included';

my $multi = $ol->open_uri(
    uris  => [ 'https://e/a.tex', 'https://e/b.tex' ],
    names => [ 'first.tex', 'second.tex' ],
);
like $multi, qr{snip_uri%5B%5D=https%3A%2F%2Fe%2Fa\.tex}, 'first URI array parameter';
like $multi, qr{snip_name%5B%5D=first\.tex}, 'first name array parameter';
like $multi, qr{snip_name%5B%5D=second\.tex}, 'second name array parameter';

my $data = $ol->open_data("\\documentclass{article}\n", mime => 'application/x-tex');
like $data, qr{snip_uri=data%3Aapplication%2Fx-tex%3Bbase64%2C}, 'data URI encoded into import URL';

my $form = $ol->open_snippet_form(
    '\\documentclass{article}',
    engine => 'pdflatex',
);
is $form->action, 'https://www.overleaf.com/docs', 'form action';
is $form->method, 'POST', 'form method';
is $form->fields->snip, '\\documentclass{article}', 'raw snippet retained';
is $form->fields->engine, 'pdflatex', 'form feature retained';

my $bad_engine = eval { $ol->open_uri(uri => 'https://e/a.tex', engine => 'context'); 1 };
ok !$bad_engine, 'bad engine rejected';
like $@, qr/unsupported TeX engine/, 'bad engine diagnostic';

my $bad_names = eval {
    $ol->open_uri(
        uris  => [ 'https://e/a.tex', 'https://e/b.tex' ],
        names => ['a.tex'],
    );
    1;
};
ok !$bad_names, 'mismatched names rejected';
like $@, qr/one entry for each URI/, 'mismatched names diagnostic';

done_testing;
