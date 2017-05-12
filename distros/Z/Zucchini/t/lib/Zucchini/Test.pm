package Zucchini::Test;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Path::Class;
use Test::More;
use File::Find;

sub add_to_tree_list {
    my $cfg     = shift;
    my $file    = shift;
    my $dir     = shift;
    my $root    = shift;
    my $listref = shift;

    # don't add ignored files to the list
    foreach my $ignore_me (@{ $cfg->get_siteconfig->{ignore_files} }) {
        my $regex = qr/ $ignore_me /x;
        return
            if ($file =~ $regex);
    }

    # push the information onto the list
    $dir =~ s{\A${root}}{};
    push @{$listref}, file($dir, $file);
}

sub compare_input_output {
    my $zucchini_cfg = shift;
    my (@input_tree, @output_tree);

    # get a list of files in the input dir
    find(
        {
            wanted => sub {
                -r && do {
                    add_to_tree_list(
                        $zucchini_cfg,
                        $_,
                        $File::Find::dir,
                        #$zucchini_tpl->get_config->get_siteconfig->{source_dir},
                        $zucchini_cfg->get_siteconfig->{source_dir},
                        \@input_tree
                    );
                };
            },
        },
        #$zucchini_tpl->get_config->get_siteconfig->{source_dir},
        $zucchini_cfg->get_siteconfig->{source_dir},
    );
    # get a list of files in the output dir
    find(
        {
            wanted => sub {
                -r && do {
                    add_to_tree_list(
                        $zucchini_cfg,
                        $_,
                        $File::Find::dir,
                        #$zucchini_tpl->get_config->get_siteconfig->{output_dir},
                        $zucchini_cfg->get_siteconfig->{output_dir},
                        \@output_tree
                    );
                };
            },
        },
        #$zucchini_tpl->get_config->get_siteconfig->{output_dir},
        $zucchini_cfg->get_siteconfig->{output_dir},
    );

    # make sure we have sorted what we're comparing
    @input_tree = sort @input_tree;
    @output_tree = sort @output_tree;

    # we should have the same files in the template directory
    # and the output directory
    is_deeply(\@input_tree, \@output_tree, q{correct files in output directory});
}

1; # just be true
