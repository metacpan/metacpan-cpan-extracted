use strict;
use warnings;

use Test::More;
if ($ENV{RUN_MAINTAINER_TESTS}) {
    plan 'tests' => 3;
} else {
    plan 'skip_all' => 'Module maintainer tests';
}

SKIP: {
    if (! eval 'use Test::Pod 1.26; 1') {
        skip('Test::Pod 1.26 required for testing POD', 1);
    }

    pod_file_ok('lib/Thread/Cancel.pm');
}

SKIP: {
    if (! eval 'use Test::Pod::Coverage 1.08; 1') {
        skip('Test::Pod::Coverage 1.08 required for testing POD coverage', 1);
    }

    pod_coverage_ok('Thread::Cancel',
                    {
                        'trustme' => [
                        ],
                        'private' => [
                            qr/^import$/,
                        ]
                    }
    );
}

SKIP: {
    if (! eval 'use Test::Spelling; 1') {
        skip('Test::Spelling required for testing POD spelling', 1);
    }
    if (system('aspell help >/dev/null 2>&1')) {
        skip("'aspell' required for testing POD spelling", 1);
    }
    set_spell_cmd('aspell list --lang=en');
    add_stopwords(<DATA>);
    pod_file_spelling_ok('lib/Thread/Cancel.pm', 'POD spelling');
    unlink("/home/$ENV{'USER'}/en.prepl", "/home/$ENV{'USER'}/en.pws");
}

exit(0);

__DATA__

Hedden
SIGUSR1
TIDs
cpan

__END__
