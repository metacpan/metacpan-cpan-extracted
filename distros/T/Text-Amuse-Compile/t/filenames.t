#!perl
use strict;
use warnings;
use utf8;

use File::Basename;

use Text::Amuse::Compile::FileName;
use Test::More tests => 50;

for my $fstype (qw/unix mswin32/) {
    fileparse_set_fstype($fstype);
    my %filenames =  ('my-filename:0,2,3,post' => {
                                              partial => [0,2,3, 'post'],
                                              file => 'my-filename.muse',
                                              spec => 'my-filename:0,2,3,post',
                                             },
                      'my-filename' => {
                                        file => 'my-filename.muse',
                                        spec => 'my-filename',
                                       },
                      '/path/to/filename.muse' => {
                                                   file => 'filename.muse',
                                                   spec => 'filename',
                                                  },
                      '../path/to/file.muse' => {
                                                 file => 'file.muse',
                                                 spec => 'file',
                                                },
                      '../path/to/file.muse:pre,1,4,5,1001' => {
                                                       file => 'file.muse',
                                                       partial => ['pre', 1,4,5,1001],
                                                       spec => 'file:pre,1,4,5,1001',
                                                      });
    foreach my $file (sort keys %filenames) {
        my $obj = Text::Amuse::Compile::FileName->new($file);
        my $spec = delete $filenames{$file}{spec};
        is $obj->suffix, '.muse', "suffix is ok";
        is_deeply({ $obj->text_amuse_constructor }, $filenames{$file},
                  "constructor ok for $file");
        ok ($obj->path, "Path is " . $obj->path);
        is $obj->name_with_fragments, $spec;
        if ($spec =~ m/:/) {
            $spec =~ s/:/\.muse:/;
        }
        else {
            $spec =~ s/$/\.muse/;
        }
        is $obj->name_with_ext_and_fragments, $spec, "$spec ok";
    }
}


