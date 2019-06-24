#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Text::Parser;

my $parser = Text::Parser->new( FS => qr/\s+\=\s+|,\s+/ );

$parser->add_rule(
    if          => '$1 eq "School"',
    do          => '~school = $2;',
    dont_record => 1,
);
$parser->add_rule(
    if          => '$1 eq "Grade"',
    do          => '~grade = $2;',
    dont_record => 1,
);
$parser->add_rule(
    if          => '$1 eq "Student number"',
    do          => '~info = $2;',
    dont_record => 1
);
$parser->add_rule(
    do => 'my $p = ($this->get_records) ? $this->pop_record : {};
        $p->{~school}{~grade}{$1}{~info} = $2;
        return $p;'
);

sub read_with_text_parser {
    $parser->read('t/example-compare_native_perl-3.txt');
}

use FileHandle;
use String::Util 'trim';

sub read_with_native_perl {
    my $fh = FileHandle->new();
    $fh->open('t/example-compare_native_perl-3.txt');
    my ( $line_count, $school, $grade, $info, %data ) = (0);
    while (<$fh>) {
        $line_count++;
        chomp;
        $_ = trim($_);
        my (@field) = split /\s+\=\s+|,\s+/;
        next if not @field;
        if ( $field[0] eq 'School' ) {
            $school = $field[1];
        } elsif ( $field[0] eq 'Grade' ) {
            $grade = $field[1];
        } elsif ( $field[0] eq 'Student number' ) {
            $info = $field[1];
        } else {
            $data{$school}{$grade}{ $field[0] }{$info} = $field[2];
        }
    }
}

use Benchmark;

timethese(
    10000,
    {   'Native Perl'  => \&read_with_native_perl,
        'Text::Parser' => \&read_with_text_parser
    }
);

