package Test::JsonAPI::Autodoc::Path;
use strict;
use warnings;
use utf8;
use Carp;
use FindBin;
use Path::Tiny;

use constant end_condition_file => 'cpanfile';

sub find_project_root_path {
    my $class = shift;

    my $path = path($FindBin::Bin);

    my %paths;
    my $project_root_path;
    while (1) {
        if (-f $path->child(end_condition_file)) {
            $project_root_path = $path;
            last;
        }

        my $abs_path = $path->absolute;
        if ($paths{$abs_path}) {
            croak '! cpanfile is not found. Please put cpanfile on a project root.';
        }

        $paths{$abs_path}++;
        $path = $path->parent;
    }

    return $project_root_path;
}

sub document_path {
    my ($class, $output_path) = @_;

    (my $document_name = $FindBin::Script) =~ s/\.t$//;
    my $markdown_file = "$document_name.md";

    my $document_path;
    if ($output_path) {
        if ($output_path =~ m!^~?/!) {
            # Absolute path
            $document_path = path($output_path)->child($markdown_file);
        }
        else {
            # Relative path
            $document_path = path($FindBin::Bin)->child("$output_path/$markdown_file");
        }
    }
    else {
        # Default
        my $project_root_path = __PACKAGE__->find_project_root_path;
        $document_path = $project_root_path->child("docs/$markdown_file");
    }

    $document_path->touchpath;

    return $document_path;
}

1;
