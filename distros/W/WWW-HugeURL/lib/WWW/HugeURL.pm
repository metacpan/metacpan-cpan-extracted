package WWW::HugeURL;

=head1 NAME

WWW::HugeURL - Because bigger is better, right?

=cut

use strict;
use warnings;
use WWW::Mechanize;
our $VERSION = '0.01';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(makehugelink);

sub makehugelink {
    my $short = shift;
    my $mech = WWW::Mechanize->new;
    $mech->get('http://hugeurl.com');
    $mech->submit_form(
	form_number => 1,
	fields      => {
	    encode_url => $short,
	}
       );
    my $content = $mech->content();
    $content =~ m{<A HREF='(http://hugeurl.com/\?.+)'>};
    return $1;
}

1;

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
