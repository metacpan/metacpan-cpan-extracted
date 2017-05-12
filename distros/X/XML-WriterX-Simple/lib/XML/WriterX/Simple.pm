package XML::WriterX::Simple;
$XML::WriterX::Simple::VERSION = '0.151401';
#ABSTRACT:Make XML production simpler.
use 5.010;
use strict;
use warnings FATAL => 'all';



sub XML::Writer::produce{
    my $writer  = shift;
    
    TAG:
    while( my $tagName = shift ){
        my ($attr, $children, $text) = XML::WriterX::Simple::arrange_args( $writer, shift );
        if(($text//'') eq '' and !@$children){
            $writer->emptyTag( $tagName, @$attr );
        }
        else{
            if(ref($text) eq 'CODE'){
                XML::WriterX::Simple::produce_content( $writer, $tagName => $text );
            }
            else{
                $writer->startTag( $tagName, @$attr );
                $writer->characters( $text ) if defined $text;
                while( @$children ){
                    my ($tag, $content) = (shift(@$children), shift(@$children));
                    $tag = ".$tagName" if $tag =~ /^[&"]$/ and ref $content eq 'CODE';
                    XML::WriterX::Simple::produce_content( $writer, $tag => $content );
                }
                $writer->endTag( $tagName );
            }
        }
    }
    #return writer to allow chaining
    $writer;
}       


sub stringify{
    local $_ = shift;
    return $_ unless ref;
    if(ref eq 'ARRAY'){
    }
    elsif(ref eq 'HASH'){
    }
    elsif(ref eq 'SCALAR'){
        return $$_;
    }
    elsif(ref eq 'REF'){
        return stringify( $$_ );
    }
    return "$_";#? REGEXP or GLOB or blessed object... : let's use perl stringifier
}

sub arrange_args{
    my ($writer, $tagContent) = @_;
    my (@attr, @children, $text);
    if(ref $tagContent eq 'CODE'){
        $text = $tagContent;
    }
    elsif(defined $tagContent){
        @_ = @$tagContent if ref $tagContent eq 'ARRAY';
        @_ = %$tagContent if ref $tagContent eq 'HASH';
        @_ = ('"', $$tagContent) if ref($tagContent) =~ /^(SCALAR|REF)$/;
        @_ = ('"', $tagContent) if !ref $tagContent;
        while( @_ ){
            my ($tag,$content) = (shift, shift);
            if($tag =~ /^#/){
                #comment is added as a children
                push @children, $tag => $content;
            }
            elsif($tag =~ /^:attr/ and ref($content) =~ /^(ARRAY|HASH)$/){
                #multiple attributes in $content
                my @attrs = $1 eq 'ARRAY' ? @$content : %$content;
                #!warning if %attr != @$content : attribute name must be unique!
                push @attr, shift(@attrs), shift(@attrs) while @attrs;
            }
            elsif($tag =~ /^:(.*)/){
                #single attribute named $1 value is stringify($content)
                push @attr, $1 => $content;
            }
            else{
                #(processing instruction are added as a children like all other cases)
                push @children, $tag => $content;
            }
        }
    }
    return (\@attr, \@children, $text);
}


#CANNOT:
#   - produce a comment from a sub{}
#   - produce a tag attributes from a sub{}
#   - prodice attributes from a sub{} ?
sub produce_content{
    my ($writer, $tag, $content) = @_;

    unless($tag){
        warn "try to produce content without any tag name!";
        $DB::single=1;
        return;
    }

    if(ref($content) eq 'CODE'){
        $writer->startTag( $tag ) unless $tag =~ /^\./;
        $content->( $writer, $tag );
        $writer->endTag( $tag ) unless $tag =~ /^\./;
        return;
    }

    return $writer->characters( stringify( $content ) )
        if $tag eq '"';

    return $writer->comment( stringify $content )
        if $tag =~ /^#/;

    return $writer->pi( $1 => stringify $content )
        if $tag =~ /^\?(.*)/;
    
    return $writer->produce( $tag, $$content )
        if ref $content eq 'SCALAR';
        
    return $writer->produce( $tag, $content );
}


1; # End of XML::WriterX::Simple

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::WriterX::Simple - Make XML production simpler.

=head1 VERSION

version 0.151401

=head1 SYNOPSIS

Make XML production simpler, just like XML::Simple with attributes, comments and processing instructions.

    use XML::Writer;
    use XML::WriterX::Simple;
    
    my $writer = new XML::Writer(OUTPUT => \*STDOUT, DATA_INDENT => 1, DATA_MODE => 1);
    $writer->xmlDecl('UTF-8');
    
    $writer->produce( docTag => [   #an ARRAY ref will produce ordered children
            ':attr' => [ id => 42, time => localtime() ], 
            '"' => \&simple_producer,
            '#foobar' => "comment after content tag",
            footer => { 
                ':name' => 'bar',   #unordered arguments
                ':id'   => 6*7,
                '"' => 'Text content',
                child1 => 'val1',
                child2 => 'val2',
            }, #An hash ref may produce unordered children.
            '#foobar' => "comment after footer tag",
        ]
    );

    sub simple_producer{
        my ($writer, $tag) = @_;
        $writer->characters( 'foobar' );
        $writer->produce( dumy => [ ':attr1' => 'valattr1', child1 => 'valchild1', '"' => 'text1' ] );
    }

=head1 NAME

XML::WriterX::Simple - Make XML production simpler.

=head1 EXPORT

The only exposed methods is the produce method, injected in XML::Writer namespace.

=head1 SUBROUTINES/METHODS

=head2 XML::Writer::produce( $writer, $tagName => $tagContent )

Produce XML tag of name $tagName with content generated by ... arguments depending on there name and forms.

The $tagName can begin with :

    - a '#' to produce a comment
    - a '?' to produce a processing instruction
    - a ':' to produce a attribute (when $tagContent is not an ARRAY/HASH)
    - a '.' when it is associated with a CODEREF, so it won't produce the tag itself.

or to produce orderd attributes, use the following:

    ':attr' => [ name => value, ... ]

To produce a text content, use $tagName = '"' (one double quote).

To produce an empty tag, provide an undef $content value.

The $tagContent can be any value such as SCALAR, ARRAY, HASH or CODE.

    #TODO: improve documentation here.

When a tag content is :

    - a SCALAR reference (not blessed) or a SCALAR, 
    - a ARRAY reference (not blessed), 
    - a HASH reference (not blessed), 
    - a CODE reference, then the start-tag will be generated before to call the CODE and the end-tag tag will be produce after that call, but only f the tag does NOT begin with a DOT (.).
    - anything else, producer will use the perl built in stringification.

=head2 stringify

Internal use, return argument(s) in a flattened format.

=head2 arrange_args ( $writer, %arguments )

Internal use, split arguments into @attr[ibutes], @children and $text.

=head2 produce_content ( $writer, $tag, $content )

Internal use, will produce the tag content.

=head1 AUTHOR

Nicolas GEORGES, C<< <xlat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-writerx-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-WriterX-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::WriterX::Simple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-WriterX-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-WriterX-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-WriterX-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-WriterX-Simple/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2014, 2015 Nicolas GEORGES.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 AUTHOR

Nicolas Georges <xlat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Nicolas Georges.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
