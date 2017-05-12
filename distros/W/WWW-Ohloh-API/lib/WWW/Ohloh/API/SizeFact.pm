package WWW::Ohloh::API::SizeFact;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;
use WWW::Ohloh::API::KudoScore;

our $VERSION = '0.3.2';

my @ohloh_of : Field : Arg(ohloh) : Get(_ohloh);
my @request_url_of : Field : Arg(request_url) : Get( request_url );
my @xml_of : Field : Arg(xml);

my @api_fields = qw/
  month
  code
  comments
  blanks
  comment_ratio
  commits
  man_months
  /;

my @month_of : Field : Set(_set_month) : Get(month);
my @code_of : Field : Set(_set_code) : Get(code);
my @comments_of : Field : Set(_set_comments) : Get(comments);
my @blanks_of : Field : Set(_set_blanks) : Get(blanks);
my @comment_ratio_of : Field : Set(_set_comment_ratio) : Get(comment_ratio);
my @commits_of : Field : Set(_set_commits) : Get(commits);
my @man_months_of : Field : Set(_set_man_months) : Get(man_months);

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _init : Init {
    my $self = shift;

    my $dom = $xml_of[$$self] or return;

    for my $f (@api_fields) {
        my $m = "_set_$f";

        $self->$m( $dom->findvalue("$f/text()") );
    }

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _overload_array_ref : Arrayify {
    my $self = shift;

    return [ $self->stats ];
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub stats {
    my $self = shift;

    return map { $self->$_ } qw/
      month
      commits
      code
      blanks
      comments
      comment_ratio
      man_months
      /;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('size_fact');

    for my $attr (@api_fields) {
        $w->dataElement( $attr => $self->$attr );
    }

    $w->endTag;

    return $xml;
}

'end of WWW::Ohloh::API::SizeFact';
__END__

=head1 NAME

WWW::Ohloh::API::SizeFact - statistics about a Project source code

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my @size_facts = $ohloh->get_size_facts( $project_id );

    my $size_fact = shift @size_facts;

    print $size_fact->month;

=head1 DESCRIPTION

W::O::A::SizeFact contains the statistics associated with an Ohloh 
project.
To be properly populated, it must be created via
the C<get_size_facts> method of a L<WWW::Ohloh::API> object.

=head1 METHODS 

=head2 API Data Accessors

=head3 month

Indicate the month covered by this SizeFact.

=head3 code

The total net lines of code, excluding comments and blanks, as of the end of this month.

=head3 comments

The total net lines of comments as of the end of this month.

=head3 blanks

The total net blank lines as of the end of this month.

=head3 comment_ratio

The fraction of net lines which are comments as of the end of this month.

=head3 man_months

The cumulative total months of effort expended by all contributors on this project, including this month.

=head3 stats

 ( $month, $commits, $code, $blanks, $comments, $comment_ratio, $man_month )
    = $size_fact->stats;

Return the facts as an array.

=head2 Other Methods

=head3 as_xml

Return the size fact
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server.

=head2 Overloading

=head3 Array reference

    @stats = @$size_fact;   # equivalent to 
                            # @stats = $size_fact->stats
    
Using the object as an array reference can be used as a 
shortcut for the method I<stats>.

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>.

=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh size_fact API reference: 
http://www.ohloh.net/api/reference/size_fact

=back

=head1 VERSION

This document describes WWW::Ohloh::API version 0.3.2

=head1 BUGS AND LIMITATIONS

WWW::Ohloh::API is very extremely alpha quality. It'll improve,
but till then: I<Caveat emptor>.

The C<as_xml()> method returns a re-encoding of the account data, which
can differ of the original xml document sent by the Ohloh server.

Please report any bugs or feature requests to
C<bug-www-ohloh-api@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Yanick Champoux  C<< <yanick@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Yanick Champoux C<< <yanick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

