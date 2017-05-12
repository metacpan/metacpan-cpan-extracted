#!perl

use Test::More;

if (! -e '.git') {
    plan skip_all => "not a git repo - not testing git status";
} else {
    plan tests => 1;
    my $modified=`git-ls-files --exclude-standard -o -m -d`;
    is($modified,'','modified or changed files in working directory?')
        and do {system('git-rev-parse HEAD > .version')};
    diag "Current revision: ",`cat .version`;
}

