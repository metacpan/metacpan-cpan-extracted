=head1 NAME

WebService::Yahoo::TermExtractor - Perl wrapper for the Yahoo! Term Extraction WebService

=head1 SYNOPSIS

  use WebService::Yahoo::TermExtractor;

  my $yte = WebService::Yahoo::TermExtractor->new( appid => 'your_app_id', context => $source_text);

  my $terms = $yte->get_terms; # returns an array ref

=head1 DESCRIPTION

WebService::Yahoo::TermExtractor provides a simple object-oriented
wrapper around the Yahoo! Term Extraction WebService.

The Yahoo! Term Extraction WebService attempts to extract a list of
significant words or phrases from the content submitted.

=head1 EXAMPLES

    use WebService::Yahoo::TermExtractor;

    my $source_text = 'A chunk of text, that mentions perl, to extract terms from...';

    my $yte = WebService::Yahoo::TermExtractor->new( appid => 'your_app_id', context => $source_text);

    my $terms = $yte->get_terms;

    die "An error occured while trying to extract terms..." unless $terms;

    print "This article is about:\n";

    foreach my $term (@$terms) {
        print "\t$term\n";
    }

If you are making multiple calls, each with different source text, and have already initialised a
WebService::Yahoo::TermExtractor object you can reuse the object and
call C<get_terms> with the text to extract from.

    my $yte = WebService::Yahoo::TermExtractor->new( appid => 'textextract', context => $source_text);

    my $terms = $yte->get_terms;

    ... do stuff and then later ...

    $terms = $yte->get_terms($new_source_text);

The following example shows input text from the London PM home page:

"We are a group of people dedicated to the encouragement of all things
Perl-like in London. This involves helping each other, discussing  topics,
sharing information and the occasional drink and mention of Buffy the
Vampire Slayer."

Which returns the following terms:

        buffy the vampire slayer
        occasional drink
        encouragement
        perl
        london

=cut

#######################################################################

package WebService::Yahoo::TermExtractor;
use strict;
use warnings;
use LWP::UserAgent;
use vars qw($VERSION);

$VERSION = "0.01";

=head1 FUNCTIONS

As an object-oriented module WebService::Yahoo::TermExtractor exports no
functions.

=head1 CONSTRUCTOR

=over 4

=item new ( appid => 'your_app_id', context => 'your_source_text' )

This is the constructor for a new WebService::Yahoo::TermExtractor
object. The C<appid> is required for you to use the Yahoo webservice and
must be requested from them. See L<SEE ALSO> for more details.

C<context> is the source text that terms should be extracted from. Both
arguments are required.

=back

=cut

sub new {
  my ($class, %args) = @_;
  bless \%args, $class;
}

=head1 METHODS

=over 4

=item get_terms ( [ $context ] )

This method sends the request and returns an array reference of any
extracted terms. If invoked without an argument the C<context> provided
in C<new> is used. If an argument is passed it is assumed to be source
text that terms should be extracted from. This was added as a convience
for working with multiple pieces of text.

C<get_terms> returns an array reference pointing to the list of terms on
success and undef on failure.

=back

=cut

sub get_terms {
  my $self = shift;
  my $url  = 'http://search.yahooapis.com/ContentAnalysisService/V1/termExtraction';
  my $context = shift || $self->{context};
  my @terms; # this holds the extracted terms;

  my $ua = LWP::UserAgent->new;
  $ua->timeout(20);

  my $response = $ua->post( $url, { appid   => $self->{appid},
                                    context => $context,
                                   }
                           );

  return undef unless $response->is_success;

  my $content = $response->content;

  while($content =~ m!<Result>(.*?)</Result>!g) {
    push(@terms, $1);
  }

  return \@terms;
}

1;

#######################################################################

=head1 DEPENDENCIES

WebService::Yahoo::TermExtractor requires the following module:

L<LWP::UserAgent>

=head1 SEE ALSO

For information about the Yahoo! Term Extractor service -
L<http://developer.yahoo.com/search/content/V1/termExtraction.html>

To sign up for an application key -
L<http://api.search.yahoo.com/webservices/register_application>

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2006 Dean Wilson.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dean Wilson <dean.wilson@gmail.com>

=cut
