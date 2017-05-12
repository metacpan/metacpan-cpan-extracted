package WWW::Scraper::ISBN::LOC_Driver;

use strict;
use warnings;

our $VERSION = '0.26';

#--------------------------------------------------------------------------

###########################################################################
# Inheritence

our @ISA = qw(WWW::Scraper::ISBN::Driver);

###########################################################################
# Modules

use HTTP::Request::Common;
use LWP::UserAgent;
use WWW::Scraper::ISBN::Driver;

###########################################################################
# Public Interface

sub search {
    my $self = shift;
    my $isbn = shift;
    my %data;

    $self->found(0);
    $self->book(undef);

    # first, initialize the session:
    my $post_url = "http://www.loc.gov/cgi-bin/zgate?ACTION=INIT&FORM_HOST_PORT=/prod/www/data/z3950/locils.html,z3950.loc.gov,7090";
    my $ua = new LWP::UserAgent;
    my $res = $ua->request(GET $post_url);
    my $doc = '';

    # get page
    # removes blank lines, DOS line feeds, and leading spaces.
    $doc = join "\n", grep { /\S/ } split /\n/, $res->as_string();
    $doc =~ s/\r//g;
    $doc =~ s/^\s+//g;

    my $sessionID = '';

    unless ( ($sessionID) = ($doc =~ /<INPUT NAME="SESSION_ID" VALUE="([^"]*)" TYPE="HIDDEN">/i) ) {
        print "Error starting LOC Query session.\n" if $self->verbosity;
        $self->error("Cannot start LOC query session.\n");
        $self->found(0);
        return 0;
    }

    $post_url = "http://www.loc.gov/cgi-bin/zgate";
    $res = $ua->request(
        POST $post_url,
        Referer => $post_url,
        Content => [
            TERM_1      => $isbn,
            USE_1       => '7',
            ESNAME      => 'F',
            ACTION      => 'SEARCH',
            DBNAME      => 'VOYAGER',
            MAXRECORDS  => '20',
            RECSYNTAX   => '1.2.840.10003.5.10',
            STRUCT_1    => '1',
            STRUCT_2    => '1',
            STRUCT_3    => '1',
            SESSION_ID  => $sessionID
        ]
    );

    $doc = '';

    # get page
    # removes blank lines, DOS line feeds, and leading spaces.
    $doc = join "\n", grep { /\S/ } split /\n/, $res->as_string();
    $doc =~ s/\r//g;
    $doc =~ s/^\s+//g;

    if ( (my $book_data) = ($doc =~ /.*<PRE>(.*)<\/PRE>.*/is) ) {
        print $book_data if ($self->verbosity > 1);

        my @author_lines;
        my $other_authors;

        # get author field
        while ($book_data =~ s/uthor(s)?:\s+(\D+?)(?:, [0-9-.]*|\.)$/if (($1) && ($1 eq "s")) { "uthors:"; } else { "" }/me) {
            my $temp = $2;
            $temp =~ s/ ([A-Z])$/ $1./; # trailing middle initial
            push @author_lines, $temp;
        }

        @author_lines = sort @author_lines;
        foreach my $line(@author_lines) {
            $line =~ s/(\w+), (.*)/$2 $1/;
        }
        $data{author} = join ", ", @author_lines;

        # get other fields
        ($data{title})                      = $book_data =~ /Title:\s+((.*)\n(\s+(.*)\n)*)/;
        ($data{edition})                    = $book_data =~ /Edition:\s+(.*)\n/;
        ($data{volume})                     = $book_data =~ /Volume:\s+(.*)\n/;
        ($data{dewey})                      = $book_data =~ /Dewey No.:\s+(.*)\n/;
        ($data{publisher},$data{pubdate})   = $book_data =~ /Published:\s+[^:]+:\s+(.*), c(\d+)\.\n/;
        ($data{pages},$data{height})        = $book_data =~ /Description:\s+\w+,\s+(\d+)\s+:[^;]+;\s+(\d+)\s*cm.\n/;
        ($data{isbn10},$data{binding})      = $book_data =~ /ISBN:\s+(\d+)\s+\(([^\)]+)\)\n/;

        # trim and clean data
        for my $key (keys %data) {
            next    unless($data{$key});
            $data{$key} =~ s/\n//g;
            $data{$key} =~ s/ +/ /g;
        }

        # reformat and default fields
        $data{title} =~ s/(.*) \/(.*)/$1/;
        $data{height} *= 10;    # cm => mm
        $data{author}  ||= '';
        $data{edition} ||= 'n/a';
        $data{volume}  ||= 'n/a';

        # print data if in verbose mode
        if($self->verbosity > 1) {
            for my $key (keys %data) {
                printf "%-8s %s\n", "$key:", $data{$key};
            }
        }

        # store book data
        my $bk = {
            'isbn'      => $isbn,
            'isbn13'    => $isbn,
            'ean13'     => $isbn
        };

        $bk->{isbn10} = $data{isbn10} if(length($data{isbn10}) == 10);
        $bk->{$_} = $data{$_} for(qw(author title edition volume dewey publisher pubdate pages height binding));

        $self->book($bk);
        $self->found(1);
        return $self->book;

    } else {
        print "Error extracting data from LOC result page.\n" if $self->verbosity;
        $self->error("Could not extract data from LOC result page.\n");
        $self->found(0);
        return 0;
    }
}

1;

__END__

=head1 NAME

WWW::Scraper::ISBN::LOC_Driver - Search driver for the Library of Congress' online catalog for book information

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 REQUIRES

Requires the following modules be installed:

=over 4

=item L<WWW::Scraper::ISBN::Driver>

=item L<HTTP::Request::Common>

=item L<LWP::UserAgent>

=back

=head1 DESCRIPTION

Searches for book information from the Library of Congress's online catalog.
May be slower than most drivers, because it must first create a session and
grab a session ID before perforiming a search. This payoff may be worth it, if
the catalog is more comprehensive than others, but it may not. Use your best
judgment.

=head1 METHODS

=over 4

=item C<search()>

Starts a session, and then passes the appropriate form fields to the LOC's
page.  If a valid result is returned, the following fields are available
via the book hash:

  isbn          (now returns isbn13)
  isbn10
  isbn13
  ean13         (industry name)
  title
  author
  edition
  volume
  dewey
  publisher
  pubdate
  binding       (if known)
  pages         (if known)
  height        (if known) (in millimetres)

=back

=head1 SEE ALSO

=over 4

=item L<WWW::Scraper::ISBN>

=item L<WWW::Scraper::ISBN::Record>

=item L<WWW::Scraper::ISBN::Driver>

=back

=head1 AUTHOR

  2004-2013 Andy Schamp, E<lt>andy@schamp.netE<gt>
  2013-2014 Barbie, E<lt>barbie@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright 2004-2013 by Andy Schamp
  Copyright 2013-2014 by Barbie

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
