use strict;
use warnings;
use Test::More;
use Capture::Tiny qw(capture);

use Unix::Sudo qw(sudo);

use lib 't/lib';
use sudosanity;

sudosanity::checks && do {
    my($stdout, $stderr, $rv) = capture { sudo {
        eval "use Data::Dumper; \$Data::Dumper::Deparse=1";
        print Dumper({ code => sub { { foo => 'bar' } } });
    } };

    is_deeply(
        eval("my $stdout")->{code}->(),
        { foo => 'bar' },
        "Can return complex data on STDOUT"
    );
};

done_testing();
