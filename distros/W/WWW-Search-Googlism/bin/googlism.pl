#!/usr/local/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}' if 0;

$VERSION = '0.01';

=head1 NAME

googlism.pl - Search Googlism.com

=head1 SYNOPSIS

B<googlism.pl> query [ type ]

=head1 DESCRIPTION

A utility to search http://googlism.com/. Type C<who> is assumed if it is not specified.

=head1 SEE ALSO

L<WWW::Search>, L<WWW::Search::Googlism>

=head1 AUTHOR

xern <xern@cpan.org>

=head1 LICENSE

Released under The Artistic License

=cut

use WWW::Search::Googlism;
$query = $ARGV[0] ? $ARGV[0] : die;
$search = new WWW::Search('Googlism');
$search->http_proxy('');
$search->native_query(
		    WWW::Search::escape_query($query),
		      { type => ( $ARGV[1] ? $ARGV[1] : 'who') }
		      );
while (my $result = $search->next_result()) {
    print "$result\n";
}

