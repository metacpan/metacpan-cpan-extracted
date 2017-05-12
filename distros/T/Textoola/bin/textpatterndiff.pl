#!/usr/bin/perl

# PODNAME: textpatterndiff.pl
# ABSTRACT: Analyse what line based text pattern changed and how much between to text files.

use strict;
use warnings;
use v5.14;

use Getopt::Long;
use Textoola::PatternStatParser;
use Textoola::PatternStatComparator;


my %args;

GetOptions (
    "from:s"        => \$args{from},
    "to:s"          => \$args{to},
    "threshhold:s"  => \$args{threshhold},
    );

my $from_parser   = Textoola::PatternStatParser->new(path=>$args{from});
my $to_parser     = Textoola::PatternStatParser->new(path=>$args{to});
$args{threshhold} //=5; # Default 5%
my $threshhold    = $args{threshhold}/100;

$from_parser->parse();
$to_parser->parse();

my $from_stats = $from_parser->patternstats();
my $to_stats   = $to_parser->patternstats();

my $c=Textoola::PatternStatComparator->new(
    patternstats1 => $from_stats,
    patternstats2 => $to_stats,
    threshhold    => $threshhold,
    );
my $result=$c->compare_reduce();

for my $pattern (sort keys %$result) {
    if ($result->{$pattern} eq '*') {
	say "   *%".": ".$pattern;
    } else {
	say sprintf("%4d%%",(100*$result->{$pattern})).": ".$pattern;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

textpatterndiff.pl - Analyse what line based text pattern changed and how much between to text files.

=head1 VERSION

version 0.003

=head1 SYNOPSIS

textpatterndiff.pl [--from=[FILE]] [--to=[FILE]] [--threshhold=[PERCENTVALUE]]

=head1 DESCRIPTION

Two similar textfiles are split up to lines with tokens. These tokenslines are compared. For each token line the percentual change of occurence is calculated.

=over

=item --from

Path of the baseline file. If not defined then STDIN is used.

=item --to

Path of the compared file. If not defined then STDIN is used.

=item --threshhold

Show only tokenlines that have changed beyound the threshhold. 

=back

=head1 NAME

textpatterndiff.pl - Analyse what line based text pattern changed and how much between to text files.

=head1 OUTPUT

A positive og negative percent change value for each tokenline is show.
In the case of a change from nothing then "*%" is shown.

=head1 Project

L<Textoola on github.com|https://github.com/sascha-dibbern/Textoola/>

=head1 Authors 

L<Sascha Dibbern|http://sascha.dibbern.info/> (sascha@dibbern.info) 

=head1 AUTHOR

Sascha Dibbern <sacha@dibbern.info>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Sascha Dibbern.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
