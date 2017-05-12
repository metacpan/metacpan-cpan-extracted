package VIM::Packager::Uploader;
use warnings;
use strict;

use Exporter::Lite;

our @EXPORT_OK=qw(upload);


sub edit_release_note {
    my $bin = $ENV{SVN_EDITOR} || $ENV{EDITOR} || 'vim';
    use File::Temp qw'tempfile';
    my ($fh, $filename) = tempfile();
    print $fh "\n\n\n\n(This package is released by VIM::Packager http://github.com/c9s/vim-packager)";
    close $fh;

    print "Launching Editor: $bin\n";
    system("$bin $filename");
    print "Done\n";
    return $filename;
}

# XXX: currently is for vim.org
sub upload {
    $|++;
    my $file           = shift @ARGV;
    my $vim_version    = shift @ARGV;
    my $script_version = shift @ARGV;
    my $script_id      = shift @ARGV; # vim online script id

    die "you need to specify script_id in your meta file" unless $script_id;

    print "File: $file\n";
    print "VIM Version: $vim_version\n";
    print "Script Version: $script_version\n";
    print "Script ID: $script_id\n";

    require VIM::Uploader;
    my $uploader = VIM::Uploader->new();
    $uploader->login();

    my $filename = edit_release_note();
    local $/;
    open FH , '<' , $filename;
    my $comment = <FH>;
    close FH;

    my $ok = $uploader->upload( 
        script_id => $script_id ,
        script_file => $file ,
        vim_version => $vim_version,  
        script_version => $script_version,
        version_comment => $comment,
    );

    print "DONE" if $ok;
}





1;
