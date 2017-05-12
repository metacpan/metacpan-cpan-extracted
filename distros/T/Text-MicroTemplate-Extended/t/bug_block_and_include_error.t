use strict;
use warnings;
use Test::More;
use FindBin;
use Text::MicroTemplate::Extended;

my $mt = Text::MicroTemplate::Extended->new(
    include_path => [ "$FindBin::Bin/templates" ],
    use_cache    => 0,
);

subtest before_include_error => sub {
    like $mt->render('content'), qr/content modified/, 'templete render ok';
    done_testing;
};

subtest include_error_in_block => sub {
    my ($res, $err);
    eval {
        $res = $mt->render('include_error');
    };
    if ($@) { $err = $@ };

    like $err, qr/could not find template file: not_exist_template/, 'include error ok';
    is $res, undef;

    done_testing;
};

subtest after_include_error => sub {
    like $mt->render('content'), qr/content modified/, 'templete render ok';

    done_testing;
};

done_testing;
