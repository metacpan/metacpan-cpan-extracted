# XML::Toolkit #

XML::Toolkit is a suite of tools that work to make handling XML easier. It is designed to marshall XML documents into Moose classes and back again with minimal changes.

For example given a xml document like the following

    <?xml version="1.0"?>
    <note>
        <to>Tove</to>
        <from>Jani</from>
        <heading>Reminder</heading>
        <body>Don't forget me this weekend!</body>
    </note>

XML::Toolkit will generate classes for each of the elements. The <note > element's class would be something like

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
        handles    => { add_to => ['push'] },
        description => {
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
        handles    => { add_from => ['push'] },
        description => {
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
        handles    => { add_body => ['push'] },
        description => {
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
        handles    => { add_heading => ['push'] },
        description => {
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

You can then use the set of classes to load the original document, or create new documents that match this structure.

    my $document = MyApp::Note->new(
        to_collection => [MyApp::To->new(text => 'Bob')],
        from_collection => [MyApp::From->new(text => 'Alice')],
        headings => [MyApp::Heading->new(text => 'Secret' )],
        body_collection => [MyApp::Body->new(text=>'Shh!')],
    )

    my $generator = Generator->new( );
    $generator->render_object($document);
    print $document->output;

    # output
    #
    # <note>
    #     <to>Bob</to>
    #     <from>Alice</from>
    #     <heading>Secret</heading>
    #     <body>Shhh!</body>
    # </note>

The original intention of XML::Toolkit was to round-trip XML documents with an unkonwn schema through an editor and back out to disk with very few semantic or structural changes.

