package Win32::Packer;
$load_pl_code = do { local $/; <DATA> };

1;

__DATA__

warn "hello!";

my ($dir) = $0 =~ m|(.*)[/\\]| or die "unable to find loader path";
@INC = ("$dir\\lib");

$ENV{PATH} = "$dir;$dir\\bin;$ENV{PATH}";

my $name = $^X;
$name =~ s|^.*[\\/]||;
$name =~ s|\.exe$|.pl| or die "Unable to infer script name";

my $script = "$dir\\lib\\$name";

my $rc = do $script;

unless (defined $rc) {
    die if $@;
    die "Error loading $script: $^E";
}

warn "bye!!!";
