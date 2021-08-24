package Example;
use oCLI qw/ oCLI::Plugin::Settings /;
extends qw( oCLI );

__PACKAGE__->model( 
    'ua' => (
        class => 'LWP::UserAgent',
        args  => {
            timeout => 60,
        },
    )
);

1;
