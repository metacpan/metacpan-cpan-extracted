#!/usr/bin/perl

use strict;
use warnings;

use WWW::OpenSVN;
use Getopt::Long;

my $password_file;
my $project;

GetOptions(
    "project=s" => \$project,
    "passwordfile=s" => \$password_file
);

open my $p_fh, "<", $password_file
    or die "Cannot open password file";
my $password = <$p_fh>;
chomp($password);
close($p_fh);

eval {
    my $opensvn = WWW::OpenSVN->new(
        project => $project,
        password => $password
    );

    $opensvn->fetch_dump('filename' => "$project.dump.gz");
};

if ($@)
{
    my $err = $@;
    print "Project = ", $err->project(), "\n";
    print "Phase = ", $err->phase(), "\n";
    die $err;
}
