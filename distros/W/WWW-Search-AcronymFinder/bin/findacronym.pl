#!/usr/local/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0;

$VERSION = '0.01';

=head1 NAME

findacronym.pl - Search AcronymFinder.com

=head1 SYNOPSIS

B<findacronym.pl> query [ function ]

=head1 DESCRIPTION

A utility to search acronyms. It iterates through all the search functions if it is not specified.

=head1 SEE ALSO

L<WWW::Search>, L<WWW::Search::AcronymFinder>

=head1 AUTHORS

xern <xern@cpan.org>

=head1 LICENSE

Released under The Artistic License

=cut


$query = $ARGV[0] || die "$0 query function\n";
$function = $ARGV[1];

@funcarr = ('exact', 'prefix', 'reverse', 'wildcard');

use WWW::Search::AcronymFinder;

$search = new WWW::Search('AcronymFinder');

for ( $function ? $function : @funcarr ){
    $search->native_query(WWW::Search::escape_query($query), { function => $_ });
    print "-"x14, $_, "-"x14, $/;
    while (my $result = $search->next_result()) {
        print "$result\n";
    }
}
