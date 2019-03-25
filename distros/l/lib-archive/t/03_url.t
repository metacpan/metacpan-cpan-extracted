use strict;
use warnings;

use Test::More;
use version;

our $cpan_ok = 0;
eval {
    require HTTP::Tiny;
    my $rp = HTTP::Tiny->new->get('https://www.cpan.org/modules/by-authors/id/');
    $cpan_ok = 1 if $rp->{success};
};

SKIP: {
    skip "cannot accesss CPAN" unless $cpan_ok;

    use_ok('lib::archive', qw(
        CPAN://Callback-1.07.tar.gz
        https://www.cpan.org/authors/id/T/TO/TOMK/Array-DeepUtils-0.2.tar.gz
    ));

    use_ok('Callback') ;
    is(
        version->parse($Callback::VERSION),
        version->parse(1.07),
        'Callback version'
    );

    use_ok('Array::DeepUtils');
    is(
        version->parse($Array::DeepUtils::VERSION),
        version->parse(0.2),
        'Array::DeepUtils version'
    );
}

done_testing();
