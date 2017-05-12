use Test::More tests => 1;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);
use List::Util qw(max);
use Module::CPANfile;
use Module::Metadata;

my $cpanfile = Module::CPANfile->load(catfile( $Bin, qw(.. .. cpanfile) ));
my @features = map $_->identifier, $cpanfile->features;
my @modules  = $cpanfile->effective_prereqs(\@features)->merged_requirements->required_modules;

my @report;
for my $module (sort @modules) {
    my $meta    = Module::Metadata->new_from_module($module) or next;
    my $version = $meta->version($module) || 0;
    push @report, [$module, $version];
}

my $indent = ' ' x 4;

my %widths;
$width{module}  = max(map length($_->[0]), @report);
$width{version} = max(map length($_->[1]), @report);
$width{total}   = $width{module} + 1 + $width{version};

diag "\nVersions for all modules (including optional ones):\n\n";
diag $indent, sprintf("%-*s %s", $width{module}, 'Module', 'Version');
diag $indent, '=' x $width{module}, ' ', '=' x $width{version};

for my $line (@report) {
    diag $indent, sprintf("%-*s %s", $width{module}, @$line);
}

diag $indent, '=' x $width{module}, ' ', '=' x $width{version};
diag "\n";

pass;
