package XML::Toolkit;
{
  $XML::Toolkit::VERSION = '0.15';
}
use strict;
use XML::Toolkit::MetaDescription::Trait;

1;    # Magic true value required at end of module
__END__

=head1 NAME

XML::Toolkit - A suit of XML tools with Antlers.

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use XML::Toolkit::App;
    my $loader = XML::Toolkit::App->new( xmlns => { '' => 'MyApp' } )->loader;
    $loader->parse_file( $file );
    print join '', @{ $loader->render };

or

    use XML::Toolkit::App;
    my $builder = XML::Toolkit::App->new( xmlns => { '' => 'MyApp' } )->builder
    $builder->parse_string($xml)
    say $builder->render()

Typically you would use the C<xmltk> command line script.

    xmltk generate --input mydocument.xml --xmlns ''=MyApp
    
=head1 DESCRIPTION

XML::Toolkit is a suite of tools that work to make handling XML easier.
It is designed to marshall XML documents into Moose classes and back
again with minimal changes.

For example given a xml document like the following

    <?xml version="1.0"?>
    <note>
        <to>Tove</to>
        <from>Jani</from>
        <heading>Reminder</heading>
        <body>Don't forget me this weekend!</body>
    </note>

C<XML::Toolkit> will generate classes for each of the elements. The 
C< <note> > element's class would be something like

   package MyApp::Note;
   use Moose;
   use namespace::autoclean;
   use XML::Toolkit;
   
   has 'to_collection' => (
        isa         => 'ArrayRef[MyApp::To]',
        is          => 'ro',     
        init_arg    => 'tos',
        traits      => [qw(XML Array)],
        lazy        => 1,
        auto_deref  => 1,
        default     => sub { [] },
        handles    => { add_to => ['push'] },     description => {
           Prefix => "",
           LocalName => "to",
           node_type => "child",
           Name => "to",
           NamespaceURI => "",
           sort_order => 0,
        },
   );
  
   has 'from_collection' => (
        isa         => 'ArrayRef[MyApp::From]',
        is          => 'ro',     
        init_arg    => 'froms',
        traits      => [qw(XML Array)],
        lazy        => 1,
        auto_deref  => 1,
        default     => sub { [] },
        handles    => { add_from => ['push'] },     description => {
           Prefix => "",
           LocalName => "from",
           node_type => "child",
           Name => "from",
           NamespaceURI => "",
           sort_order => 1,
        },
   );
   
   has 'body_collection' => (
        isa         => 'ArrayRef[MyApp::Body]',
        is          => 'ro',     
        init_arg    => 'bodys',
        traits      => [qw(XML Array)],
        lazy        => 1,
        auto_deref  => 1,
        default     => sub { [] },
        handles    => { add_body => ['push'] },     description => {
           Prefix => "",
           LocalName => "body",
           node_type => "child",
           Name => "body",
           NamespaceURI => "",
           sort_order => 2,
        },
   );
   
   has 'heading_collection' => (
        isa         => 'ArrayRef[MyApp::Heading]',
        is          => 'ro',     
        init_arg    => 'headings',
        traits      => [qw(XML Array)],
        lazy        => 1,
        auto_deref  => 1,
        default     => sub { [] },
        handles    => { add_heading => ['push'] },     description => {
           Prefix => "",
           LocalName => "heading",
           node_type => "child",
           Name => "heading",
           NamespaceURI => "",
           sort_order => 3,
        },
   );
   
   1;
   __END__

You can then use the set of classes to load the original document, or
create new documents that match this structure.

    my $document = MyApp::Note->new(
        to_collection => [MyApp::To->new(text => 'Bob')],
        from_collection => [MyApp::From->new(text => 'Alice')],
        headings => [MyApp::Heading->new(text => 'Secret' )],
        body_collection => [MyApp::Body->new(text=>'Shh!')],
    )
    
    my $generator = XMLTK::App->new( xmlns => { '' => '' } )->generator;
    $generator->render_object($root);
    my $output = join( '', $generator->output );
    
    # output
    #    
    # <note>
    #     <to>Bob</to>
    #     <from>Alice</from>
    #     <heading>Secret</heading>
    #     <body>Shhh!</body>
    # </note>

The original intention of XML::Toolkit was to round-trip XML documents
with an unkonwn schema through an editor and back out to disk with very
few semantic or structural changes. 

=head1 SEE ALSO

L<PRANG|PRANG>, L<XML::Compile|XML::Compile> and L<XML::Pastor|XML::Pastor>
have similarities to C<XML::Toolkit> in scope if not design.

=head1 DEPENDENCIES

L<Devel::PackagePath|Devel::PackagePath>, L< Moose | Moose >,
L<MooseX::MetaDescription|MooseX::MetaDescription>,
L<MooseX::Types::Path::Class|MooseX::Types::Path::Class>,
L<MooseX::App::Cmd|MooseX::App::Cmd>, L<Template::Toolkit|Template::Toolkit>,
L<XML::SAX|XML::SAX>, L<XML::SAX::Writer|XML::SAX::Writer>,
L<Bread::Board|Bread::Board> and L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Currently XML::Toolkit only supports Auto-Discovery of class hierarchy from
XML instances, and does not know anything about DTDs, RelaxNG, XML-Schema or
anything else. Future work is being considered in this, and patches may be
accepted if they come with documentation and tests.

Please report any bugs or feature requests to C<bug-xml-toolkit@rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>. Additional support may
be available via C<#xml-toolkit> on C<irc.perl.org>.

=head1 AUTHORS

Chris Prather  C<< <chris@prather.org> >>
Robin Smidsrød C<< <robin@smidsrod.no> >>
Jesse Luehrs C<< <doy@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008-2010, Chris Prather C<< <chris@prather.org> >>. Some
rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

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
