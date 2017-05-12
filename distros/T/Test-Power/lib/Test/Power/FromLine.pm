package Test::Power::FromLine;
use strict;
use warnings;
use utf8;
use 5.010_001;

use Cwd ();
use File::Spec;

our $BASE_DIR = Cwd::getcwd();
our %FILECACHE;

sub inspect_line {
    my $level = shift;

    my ($package, $filename, $line_no) = caller($level+1);
    my $line = sub {
        undef $filename if $filename eq '-e';
        if (defined $filename) {
            $filename = File::Spec->rel2abs($filename, $BASE_DIR);
            my $file = $FILECACHE{$filename} ||= [
                do {
                    # Do not die if we can't open the file
                    open my $fh, '<', $filename
                        or return '';
                    <$fh>
                }
            ];
            my $line = $file->[ $line_no - 1 ];
            $line =~ s{^\s+|\s+$}{}g;
            $line;
        } else {
            "";
        }
    }->();
    return ($package, $filename, $line_no, $line);
}

1;

