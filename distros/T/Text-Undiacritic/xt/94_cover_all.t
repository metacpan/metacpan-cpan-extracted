#!/usr/bin/perl

use strict;
use warnings;

use File::Find;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg =
        'Author test. Set (export) $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

my $cover_html = '../cover_db/coverage.html'; # Devel::Cover report

my $cover_goals = {
#    'pod'   => 100,
#    'cond'  => 20,
 #   'stmt'  => 80,
#    'sub'   => 100,
#    'time' => 0,
#    'bran'  => 0,
    'file'  => 100,
#    'total' => 60,
};

my %coverage;
my @col_names;

# read the results of Devel::Cover
if ( -e $cover_html ) {
    open( my $file, '<', $cover_html ) or die 'cannnot open file $cover_html';

    my $is_table = 0;
    LINE:
    while ( my $line = <$file> ) {
        if ( $line =~ m{ \A <tr><th> file </th> }xms ) {
            $is_table = 1;
            @col_names = parse_html_tr( $line );
            next LINE;
        }
        if ( $is_table && $line =~ m{ \A <tr> }xms ) {
            my @values = parse_html_tr( $line );

            my $i = 0;
            for my $value ( @values ) {
                $coverage{$values[0]}->{$col_names[$i]}
                    = $value =~ m{ \A [0-9.\s]+ \z }xms
                        ? $value
                        : $col_names[$i] =~ m{ file | bran | cond }xmsi
                            ? 100 : 0;
                $i++;
            }
            next LINE;
        }
    }
    close $file;
}
else {
    my $msg =
        "$cover_html not found. Run cover first.";
    plan( skip_all => $msg );
}

my %LIST;
find(
    sub {
        if ( $File::Find::name =~
            m{ (lib [/] Hyper [/] [A-Za-z0-9_/-]+ [.]pm) $ }xms
        ) {
                $LIST{$1} = 1;
            }
    },
    ('../lib'),
);

plan ( tests => (scalar keys %LIST) * (scalar keys %$cover_goals) );

#XXX delete $coverage{'Total'};

for my $module (sort keys %LIST) {
    for my $goal (sort keys %$cover_goals) {
        ok( (
            exists $coverage{$module}
            && $coverage{$module}->{$goal} >= $cover_goals->{$goal}
            ),
            "$module covers $goal >= $cover_goals->{$goal}"
        );
    }
}


sub parse_html_tr {
    my $line = shift;

    $line =~ s{ [\n\r] }{}xmsg;         # paranoia chomp

    $line =~ s{                         # substitute
        < \s* [/] \s* t [dh] [^>]* >    # a closing </td> or </th>
        < \s*         t [dh] [^>]* >    # followed by an opening one
    }{|}xmsgi;                          # by '|'

    $line =~ s{ < [^>]* > }{}xmsg;      # remove remaining HTML-tags

    return split( /\|/, $line);
}

