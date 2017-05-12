use strict;
use warnings;
use Test::Requires {
    'Template::Declare' => 0.44
};
use Test::More;
use Tiffany;
use Tiffany::Template::Declare;

diag "Template::Declare: $Template::Declare::VERSION";

{
    package MyPage;
    use Template::Declare::Tags; # defaults to 'HTML'
    use base 'Template::Declare';

    template simple => sub {
        my ($class, $name) = @_;
        html {
            head {} body {
                p { "Hello, $name." };
            }
        }
    };
}

{
    eval {
        my $tmpl = Tiffany::Template::Declare->new();
        $tmpl->render('unknown');
    };
    ok $@;
}

{
    my $tmpl = Tiffany::Template::Declare->new({dispatch_to => ['MyPage']});
    like $tmpl->render('simple', 'john'), qr/Hello, john./;
}

done_testing;


