use strict;
use warnings;
package WebService::NextEpisode;
use LWP::Simple;
use HTML::TreeBuilder::XPath;

# ABSTRACT: Fetches air date from next-episode.net
our $VERSION = '0.003'; # VERSION

use Carp;

=pod

=encoding utf8

=head1 NAME

WebService::NextEpisode -  Fetch air date from next-episode.net


=head1 SYNOPSIS

    $ perl -MWebService::NextEpisode -e 'print WebService::NextEpisode::of "Better Call Saul"'
    Mon Jun 05, 2017


=head1 METHODS AND ARGUMENTS


=over 4

=item of($show)

Retrieves air date of next epsiode of $show

=cut

sub of {
    my ($show_minus, $show) = (shift) x 2;

    $show =~ s/ /+/g;
    $show_minus =~ s/ /-/g;

    my $page = get("http://next-episode.net/$show_minus")
            // get("http://next-episode.net/site-search-$show.html");
    defined $page or die "Couldn't get it!";

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($page);

    my $next = $tree->findvalue( '/html/body//div[@id="next_episode"]');

    $next =~ s/.*Date:(.*)Season.*/$1/;

    return $next;
}



1;
__END__

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/WebService-NextEpisode>

=head1 SEE ALSO

L<The Perl Home Page|http://www.perl.org/>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
