package XML::DT::Sequence;
$XML::DT::Sequence::VERSION = '0.02';
use XML::DT;

use 5.006;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw($u $c %v $q &father &gfather &ggfather &root);

=encoding UTF-8

=head1 NAME

XML::DT::Sequence - Down Translator (XML::DT) for sequence XMLs

=head1 SYNOPSIS

A lot of XML files nowadays are just catalogues, simple sequences of
small chunks, that repeat, and repeat. These files can get enormous,
and DOM processing hard. SAX processing it interesting but not always
the best approach.

This module chunks the XML file in Header, a sequence of the repeating
blocks, and a footer, and each one of these chunks can be processed by
DOM, using L<XML::DT> technology.


    use XML::DT::Sequence;

    my $dt = XML::DT::Sequence->new();

    $dt->process("file.xml",
                 -tag => 'item',
                 -head => sub {
                      my ($self, $xml) = @_;
                      # do something with $xml
                 },
                 -body => {
                        item => sub {
                            # XML::DT like handler
                        }
                 },
                 -foot => sub {
                      my ($self, $xml) = @_;
                      # do something with $xml
                 },
                );

=head1 EXPLANATION

There are four options, only two mandatory: C<-tag> and
C<-body>. C<-tag> is the element name that repeats in the XML file,
and that you want to process one at a time. C<-body> is the handler to
process each one of these elements.

C<-head> is the handler to process the XML that appears before the
first instance of the repeating element, and C<-foot> the handler to
process the XML that apperas after the last instance of the repeating
element.

Each one of these handlers can be a code reference that receives the
C<XML::DT::Sequence> object and the XML string, or a hash reference,
with L<XML::DT> handlers to process each XML snippet.

Note that when processing header or footer, XML is incomplete, and the
parser can recover in weird ways.

The C<process> method returns a hash reference with three keys:
C<-head> is the return value of the C<-head> handler, and C<-foot> is
the return value of the C<-foot> handler. C<-body> is the number of
elements of the sequence that were processed.

=head1 METHODS

=head2 new

Constructor.

=head2 process

Processor. Se explanation above.

=head2 break

Forces the process to finish. Useful when you processed enough number
of elements. Note that if you break the process the C<-foot> code will
not be run.

If you are using a code reference as a handler, call it from the first
argument (reference to the object). If you are using a C<XML::DT>
handler, C<< $u >> has the object, so just call C<break> on it.

=cut

sub new {
    my ($class) = @_;
    return bless { } => $class;
}

sub break {
    my $self = shift;
    $self->{BREAK} = 1;
}

sub process {
    my ($self, $file, %ops) = @_;

    die "Option -tag is mantatory." unless exists $ops{-tag};

    local $/ = "</$ops{-tag}>";

    # XXX - fixme... utf8?
    open my $fh, "<:utf8", $file or die "Can't open file $file for reading [$!]";
    my $firstChunk = <$fh>;

    die "No $/ tag found. Bailing out." unless $firstChunk =~ $/;

    my $head = $firstChunk;
    $head =~ s/<$ops{-tag}.*//s;

    ## Process header if there is such a handler
    my $headReturn = undef;
    if (exists($ops{-head})) {
        my $headCode = $ops{-head};
        if (ref($headCode) eq "CODE") {
            $headReturn = $headCode->($self, $head);
        }
        elsif (ref($headCode) eq "HASH") {
            $headReturn = dtstring($head, -recover => 1, -userdata => $self, %$headCode);
        }
        else {
            die "No idea what to do with -head of type ".ref($ops{-head});
        }
    }

    ## process the sequence
    my $chunk = $firstChunk;
    my $totalElems = 0;
    my $bodyCode = $ops{-body} || undef;
    my $code;

    if (!$bodyCode) {
        $code = sub { };
    } elsif (ref($bodyCode) eq "CODE") {
        $code = sub { $bodyCode->($self, $_[0]) };
    } elsif (ref($bodyCode) eq "HASH") {
        $code = sub { dtstring($_[0], -userdata=> $self, %$bodyCode) }
    } else {
        die "No idea what to do with -body of type ".ref($ops{-body});
    }

    do {
        ++$totalElems;
        $chunk =~ s/^.*(?=<$ops{-tag})//s;
        $code->($chunk);
        $chunk = <$fh>;
    } while ($chunk =~ m{</$ops{-tag}>} and !$self->{BREAK});

    my $footReturn;
    if (!$self->{BREAK}) {
        if (exists($ops{-foot})) {
            my $footCode = $ops{-foot};
            if (ref($footCode) eq "CODE") {
                $footReturn = $footCode->($self, $chunk);
            }
            elsif (ref($footCode) eq "HASH") {
                $chunk =~ s{^\s*</[a-zA-Z0-9]+>}{}g;
                $footReturn = dtstring($chunk,
                                       -userdata => $self,
                                       -recover => 1, %$footCode);
            }
            else {
                die "No idea what to do with -foot of type ".ref($ops{-foot});
            }
        }
    }

    close $fh;

    return {
            -head => $headReturn,
            -body => $totalElems,
            -foot => $footReturn,
           };
}

=head1 AUTHOR

Alberto Simões, C<< <ambs at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-dt-sequence at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-DT-Sequence>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::DT::Sequence


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-DT-Sequence>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-DT-Sequence>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-DT-Sequence>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-DT-Sequence/>

=back

=head1 KNOWN BUGS AND LIMITATIONS

=over 4

=item * Spaced tags

It is not usual, but XML allows the usage of spaces inside element
tags, for instance, between the C<< < >> and the element name. This is
B<NOT> supported.

=item * Multiple usage tags

If the same tag is used in different levels of the XML hierarchy, it
is likely that the implemented algorithm will not work.

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alberto Simões.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of XML::DT::Sequence
