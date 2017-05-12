use strict;
use Test::More tests => 9;

###########################################################

    use WWW::Scraper::ISBN;
    
    my $scraper = WWW::Scraper::ISBN->new();
    isa_ok($scraper, 'WWW::Scraper::ISBN');
    $scraper->drivers('Siciliano');
    my $isbn = '9780994317391';
    my $result = $scraper->search($isbn);
    
    is($result->found,1 , "search isbn $isbn");
    is($result->found_in , 'Siciliano');
    
    my $book = $result->book;
    like($book->{'title'},  qr/DICIONARIO OXFORD ESCOLAR \(COM CD\)/);
    is($book->{'author'},     'EDITORA OXFORD');
    is($book->{'book_link'},  'http://www.siciliano.com.br/livro.asp?tema=2&orn=LSE&Tipo=2&ID=691958');
    is($book->{'image_link'}, 'http://www.siciliano.com.br/capas/9780994317391.jpg');
    is($book->{'pubdate'},    '2007');
    is($book->{'publisher'},  'OXFORD UNIVERSITY PRESS');
    
###########################################################
