package NewsAPITestUserAgent;

use warnings;
use strict;
use base qw(Test::LWP::UserAgent);

sub new {
    my $class = shift;
    my $ua = $class->SUPER::new(@_);

    # /top-headlines, but no parameters specified.
    $ua->map_response(
        qr{top-headlines$}, HTTP::Response->new(
            400,
            'parametersMissing',
            [
                'Content-Type' => 'text/plain',
            ],
            'Required parameters are missing. Please set any of the following parameters and try again: sources, q, language, country, category.'
         )
    );


    # /top-headlines, good request.
    $ua->map_response(
        qr{top-headlines\?}, HTTP::Response->new(
            200,
            'OK',
            [
                'Content-Type' => 'application/json',
            ],
            q{{"status":"ok","totalResults":38,"articles":[{"source":{"id":"cnbc","name":"CNBC"},"author":"Christine Wang","title":"NY Fed clarifies Williams speech that market took as signal of a rate cut - CNBC","description":"Earlier, Williams delivered a speech at the annual meeting of the Central Bank Research Association in which he said, \"It's better to take preventative measures than to wait for disaster to unfold.\"","url":"https://www.cnbc.com/2019/07/18/fed-clarifies-williams-speech-that-market-took-as-signal-of-a-rate-cut.html","urlToImage":"https://image.cnbcfm.com/api/v1/image/105778438-1551897714571rtx6pxq6.jpg?v=1551897816","publishedAt":"2019-07-18T23:09:11Z","content":"When New York Federal Reserve President John Williams said central bankers need to \"act quickly\" as economic growth slows, a spokesperson said he was drawing from research, not hinting at what may happen at this month's Federal Open Market Committee meeting.\r… [+1341 chars]"},{"source":{"id":null,"name":"Cosmopolitan.com"},"author":"Hannah Chambers","title":"Questions About the 'Cats' Trailer - What is Happening in Cats? - Cosmopolitan.com","description":"Are there...litter boxes?","url":"https://www.cosmopolitan.com/entertainment/movies/a28439536/cats-trailer-questions/","urlToImage":"https://hips.hearstapps.com/hmg-prod.s3.amazonaws.com/images/cats-taylor-swift-1563488138.jpg?crop=0.808xw:0.808xh;0.173xw,0.160xh&resize=1200:*","publishedAt":"2019-07-18T22:34:00Z","content":"So...even though not a single one of the 7 billion human beings on Earth asked for it, the Cats trailer has officially dropped. It is one of the most horrifying things I have ever witnessed in my entire life, and I am speaking as a person who once innocently … [+3878 chars]"}]}},
         )
    );

    # /everything, good request, with properly formatted 'from' param
    $ua->map_response(
        qr{everything\?from=2010.*T.*Z$}, HTTP::Response->new(
            200,
            'OK',
            [
                'Content-Type' => 'application/json',
            ],
            q{{"status":"ok","totalResults":426,"articles":[{"source":{"id":"the-new-york-times","name":"The New York Times"},"author":"Jolie Kerr","title":"Thank Heaven for Charo","description":"The entertainer wants you to live.","url":"https://www.nytimes.com/2019/06/22/style/charo-cuchi-cuchi.html","urlToImage":"https://static01.nyt.com/images/2019/06/23/fashion/22Charo-3/22Charo-3-facebookJumbo-v2.jpg","publishedAt":"2019-06-23T00:30:16Z","content":"Her first television appearancewas on Johnny Carsons show in 1965; the host asked Charo, What are you? I am cuchi cuchi! came her reply.\r\nAfter that, she got a call from Norman Brokaw, the renowned agent at William Morris who made Marilyn Monroe into a star. … [+1276 chars]"},{"source":{"id":"mashable","name":"Mashable"},"author":"Alexis Nedd","title":"The truly wild first 'Cats' trailer is here. You're definitely not ready.","description":"It's here, it's real, and it's kitty-riffic! Cat-tacular! Meow-gnificent! It's the first trailer for the live-action movie adaptation of Cats ! Starring Taylor Swift, James Corden, Judi Dench, Rebel Wilson, Idris Elba, Jason Derulo, Jennifer Hudson, and many …","url":"https://mashable.com/video/cats-movie-trailer/","urlToImage":"https://mondrian.mashable.com/2019%252F07%252F18%252F98%252F9c1891a0890f47d3a3bafe057e7fefd1.ed023.jpg%252F1200x630.jpg?signature=msvnRq0QxUE4waDd20HWlsMtF4Q=","publishedAt":"2019-07-18T21:11:27Z","content":"It's here, it's real, and it's kitty-riffic! Cat-tacular! Meow-gnificent! It's the first trailer for the live-action movie adaptation of Cats!\r\nStarring Taylor Swift, James Corden, Judi Dench, Rebel Wilson, Idris Elba, Jason Derulo, Jennifer Hudson, and many … [+197 chars]"}]}},
         )
    );

    # /everything, good request, with properly formatted 'domains' param
    $ua->map_response(
        qr{everything\?domains=example\.com%2Canother}, HTTP::Response->new(
            200,
            'OK',
            [
                'Content-Type' => 'application/json',
            ],
            q{{"status":"ok","totalResults":426,"articles":[{"source":{"id":"the-new-york-times","name":"The New York Times"},"author":"Jolie Kerr","title":"Thank Heaven for Charo","description":"The entertainer wants you to live.","url":"https://www.nytimes.com/2019/06/22/style/charo-cuchi-cuchi.html","urlToImage":"https://static01.nyt.com/images/2019/06/23/fashion/22Charo-3/22Charo-3-facebookJumbo-v2.jpg","publishedAt":"2019-06-23T00:30:16Z","content":"Her first television appearancewas on Johnny Carsons show in 1965; the host asked Charo, What are you? I am cuchi cuchi! came her reply.\r\nAfter that, she got a call from Norman Brokaw, the renowned agent at William Morris who made Marilyn Monroe into a star. … [+1276 chars]"},{"source":{"id":"mashable","name":"Mashable"},"author":"Alexis Nedd","title":"The truly wild first 'Cats' trailer is here. You're definitely not ready.","description":"It's here, it's real, and it's kitty-riffic! Cat-tacular! Meow-gnificent! It's the first trailer for the live-action movie adaptation of Cats ! Starring Taylor Swift, James Corden, Judi Dench, Rebel Wilson, Idris Elba, Jason Derulo, Jennifer Hudson, and many …","url":"https://mashable.com/video/cats-movie-trailer/","urlToImage":"https://mondrian.mashable.com/2019%252F07%252F18%252F98%252F9c1891a0890f47d3a3bafe057e7fefd1.ed023.jpg%252F1200x630.jpg?signature=msvnRq0QxUE4waDd20HWlsMtF4Q=","publishedAt":"2019-07-18T21:11:27Z","content":"It's here, it's real, and it's kitty-riffic! Cat-tacular! Meow-gnificent! It's the first trailer for the live-action movie adaptation of Cats!\r\nStarring Taylor Swift, James Corden, Judi Dench, Rebel Wilson, Idris Elba, Jason Derulo, Jennifer Hudson, and many … [+197 chars]"}]}},
         )
    );

    # /sources, good request.
    $ua->map_response(
        qr{sources}, HTTP::Response->new(
            200,
            'OK',
            [
                'Content-Type' => 'application/json',
            ],
            q{{"status":"ok","sources":[{"id":"google-news-fr","name":"Google News (France)","description":"Informations complètes et à jour, compilées par Google Actualités à partir de sources d&#39;actualités du monde entier.","url":"https://news.google.com","category":"general","language":"fr","country":"fr"},{"id":"le-monde","name":"Le Monde","description":"Les articles du journal et toute l'actualit&eacute; en continu : International, France, Soci&eacute;t&eacute;, Economie, Culture, Environnement, Blogs ...","url":"http://www.lemonde.fr","category":"general","language":"fr","country":"fr"},{"id":"lequipe","name":"L'equipe","description":"Le sport en direct sur L'EQUIPE.fr. Les informations, résultats et classements de tous les sports. Directs commentés, images et vidéos à regarder et à partager !","url":"https://www.lequipe.fr","category":"sports","language":"fr","country":"fr"},{"id":"les-echos","name":"Les Echos","description":"Toute l'actualité économique, financière et boursière française et internationale sur Les Echos.fr","url":"https://www.lesechos.fr","category":"business","language":"fr","country":"fr"},{"id":"liberation","name":"Libération","description":"Toute l'actualité en direct - photos et vidéos avec Libération","url":"http://www.liberation.fr","category":"general","language":"fr","country":"fr"}]}},
         )
    );

    return $ua;
}

1;
