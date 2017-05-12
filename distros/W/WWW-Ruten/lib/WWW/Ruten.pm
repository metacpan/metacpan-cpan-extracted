package WWW::Ruten;
{
  $WWW::Ruten::VERSION = '0.03';
}
# ABSTRACT: Scripting www.ruten.com.tw

use 5.008;
use strict;
use warnings;
use WWW::Mechanize 1.66;
use Encode;
use HTML::TreeBuilder::XPath;
use HTML::Selector::XPath;

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub search {
    my ($self, $term, @params) = @_;
    $self->{search_params} = {
        term => $term
    };

    return $self;
}

sub each {
    my ($self, $cb) = @_;
    $self->_do_search();

    foreach my $result (@{ $self->{search_results} }) {
        $cb->($result);
    }
    return $self;
}

sub _do_search {
    my ($self) = @_;
    die unless defined $self->{search_params}{term};

    $self->{mech} ||= WWW::Mechanize->new;

    my $mech = $self->{mech};
    $mech->get("http://www.ruten.com.tw");
    $mech->submit_form(
        form_name => "srch",
        fields => {
            k => $self->{search_params}{term}
        }
    );

    my $content = $mech->content;

    my @results = ();
    my $html = HTML::TreeBuilder::XPath->new;
    $html->parse($content);

    my $selector = HTML::Selector::XPath->new("ul.items h3.title a");

    for my $node ($html->findnodes($selector->to_xpath)) {
        push @results, {
            url => $node->attr("href"),
            title => join("", $node->content_list)
        }
    }

    $self->{search_results} ||=[];
    push @{  $self->{search_results} }, @results;

    return $self;
}

1;


__END__
=pod

=head1 NAME

WWW::Ruten - Scripting www.ruten.com.tw

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use WWW::Ruten;

    my $ruten = WWW::Ruten->new;
    $ruten->search("iPod");
    $ruten->each(sub {
        my $result = shift;

        print $result->{title};
        print $result->{url};
    })

=head1 DESCRIPTION

=head1 INTERFACE 

=over

=item new()

Creates a new ruten object and returns it.

=item search( $term )

Search something. $term is a string, required.

=item each( $coderef )

After calling C<search>, you then call this method, give it a
callback. The callback will be called for each item in the search
result. The first argument passed to the callback is a hashref
containing the information. At this point, it has "url" and "title"
keys. This might be changed in the future.

Notices that, the content inside L<www.ruten.com.tw> response is
encoded as big5 text. This module internally decoded it into Perl
strings and returns it to you.

=back

=head1 DEPENDENCIES

L<Encode>, L<HTML::TreeBuilder>, L<HTML::Selector::XPath>, L<WWW::Mechanize>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-www-ruten@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>

=head1 LICENCE AND COPYRIGHT

The MIT License

Copyright (c) 2008, Kang-min Liu.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Kang-min Liu.

This is free software, licensed under:

  The MIT (X11) License

=cut

