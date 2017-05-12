use t::TestYAMLPerl; # tests => 3;

use YAML::Perl::Parser;
use YAML::Perl::Events;

# plan skip_all => 'XXX';

filters { yaml => [qw'parse_error'] };

run_is 'yaml' => 'error';

sub parse_error {
    eval {
        my $p = YAML::Perl::Parser->new();
        $p->open($_);
        my @dummy = $p->parse();
    };
    my $error = "$@" || "Strange. No error occurred";;
    $error =~ s/\n.*/\n/s;
    return $error;
}

__DATA__
=== Bad indentation
+++ yaml
foo: 1
  bar: 2
+++ error
YAML::Perl::Error::Parser while parsing a block mapping in "<string>", line 1, column 1 expected <block end>, but found <block mapping start> in "<string>", line 2, column 3
