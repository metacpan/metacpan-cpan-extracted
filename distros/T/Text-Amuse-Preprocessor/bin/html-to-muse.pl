#!/usr/bin/env perl

use strict;
use warnings;
use Pod::Usage;
use Text::Amuse::Preprocessor::HTML qw/html_file_to_muse html_to_muse/;
use LWP::UserAgent;
use Getopt::Long;
use Encode qw/decode_utf8/;
use File::Temp;
use File::Spec;
use utf8;
binmode STDOUT, ":encoding(utf-8)";
binmode STDERR, ":encoding(utf-8)";

=head1 NAME

html-to-muse.pl - convert HTML files to muse files

=head1 SYNOPSIS

  html-to-muse.pl [ options... ] file.html

or

  html-to-muse.pl [options...] http://example.com/my-file.html

=head2 Options

=over 4

=item --lang

Set the language of the document in the muse output

=item --title

Set the title of the document (otherwise the filename is used).

=item --no-header

Do not add #title and #lang (handy if you are processing files in a
loop and merge them together.

=back

The result is printed on the standard output, thus you can use it this way:

 html-to-muse.pl my-file.html > myfile.muse

 html-to-muse.pl http://example.com/my-file.html > my-remote-file.muse

=head1 SEE ALSO

L<Text::Amuse::Preprocessor>

=cut


my ($help, $no_header);
my $lang = 'en';
my $title = '';

GetOptions (
            "lang=s" => \$lang,
            "title=s" => \$title,
            "no-header" => \$no_header,
            help => \$help) or die;

if ($help || !@ARGV) {
    pod2usage("\n");
    exit;
}

foreach my $f (@ARGV) {
    unless ($no_header) {
        if ($title) {
            $title = decode_utf8($title);
        }
        else {
            $title = $f;
        }
        print "#title $title\n";
        print "#lang $lang\n\n";
    }
    process_target($f);
}

sub process_target {
    my $f = shift;
    if (-f $f) {
        print html_file_to_muse($f, { lang => $lang });
    }
    else {
        my $fh = File::Temp->newdir;
        my $target = File::Spec->catfile($fh, 'target.hml');
        my $ua = LWP::UserAgent->new;
        my $res = $ua->mirror($f, $target);
        if ($res->is_success) {
            print html_file_to_muse($target, { lang => $lang });
        }
        else {
            warn $res->status_line . "\n";

        }
    }
    print "\n\n";
}
