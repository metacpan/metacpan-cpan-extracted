use Test;
use Cwd;
my $ASPELL = "C:\\usr\\Aspell\\bin\\aspell.exe";

#$ENV{RELEASE_TESTING}++;

my $chdir = 0;

if ( cwd() =~ m/t$/ ) {
    chdir "..";
    $chdir++;
}

eval { require Test::Spelling; Test::Spelling->import; };

if ($@) {
    plan tests => 1;
    skip("Test::Spelling not installed; skipping");
}
else {
    if ( $ENV{RELEASE_TESTING} ) {
        set_spell_cmd("$ASPELL -l");
        add_stopwords(<DATA>);
        all_pod_files_spelling_ok('lib');
    }
    else {
        plan tests => 1;
        skip( "Author only private tests" );
    }
}

chdir "t" if $chdir;  # back to t/

__DATA__
CGI
CPAN
GPL
STDIN
STDOUT
DWIM
OO
RTFM
RTFS
James
Freeman
gmail
behaviour
