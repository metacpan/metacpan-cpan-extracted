#!/usr/bin/perl

my ($dir) = $0 =~ m|(.*)[/\\]| or die "unable to find loader path";
@INC = ("$dir\\lib");

$ENV{PATH} = "$dir\\bin;$ENV{PATH}";

my $name = $^X;
$name =~ s|^.*[\\/]||;
$name =~ s|\.exe$|.pl| or die "Unable to infer script name";

my $script = "$dir\\scripts\\$name";

my $rc = do $script;

unless (defined $rc) {
    die if $@;
    die "Error loading $script: $^E";
}

warn "bye!!!";
