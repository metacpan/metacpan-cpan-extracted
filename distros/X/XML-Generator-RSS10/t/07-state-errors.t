use strict;
use warnings;

use XML::Generator::RSS10;

use Test::More;

BEGIN {
    eval { require XML::SAX::Writer };

    if ($@) {
        plan skip_all => 'Cannot run tests without XML::SAX::Writer.';
    }
    else {
    }
}

{
    my $out;

    my $writer = XML::SAX::Writer->new( Output => \$out );

    my $gen = XML::Generator::RSS10->new(
        Handler => $writer,
        pretty  => 1,
    );

    eval {
        $gen->image(
            title => 'Image title',
            url   => 'http://example.com/image.jpg',
            link  => 'http://example.com/bar',
        ) for 1 .. 2;
    };

    like(
        $@, qr/call image\(\) more than once/,
        'call image twice'
    );
}

{
    my $out;

    my $writer = XML::SAX::Writer->new( Output => \$out );

    my $gen = XML::Generator::RSS10->new(
        Handler => $writer,
        pretty  => 1,
    );

    $gen->item(
        title => 'Item title',
        link  => 'http://example.com/foo',
    );

    $gen->channel(
        title       => 'Channel title',
        link        => 'http://example.com/',
        description => 'a description',
    );

    eval {
        $gen->image(
            title => 'Image title',
            url   => 'http://example.com/image.jpg',
            link  => 'http://example.com/bar',
        ) for 1 .. 2;
    };

    like(
        $@, qr/call image\(\) after calling channel\(\)/,
        'call image after channel'
    );
}

{
    my $out;

    my $writer = XML::SAX::Writer->new( Output => \$out );

    my $gen = XML::Generator::RSS10->new(
        Handler => $writer,
        pretty  => 1,
    );

    eval {
        $gen->textinput(
            title       => 'Textinput title',
            name        => 'ti',
            description => 'Textinput description',
            url         => 'http://example.com/search',
        ) for 1 .. 2;
    };

    like(
        $@, qr/call textinput\(\) more than once/,
        'call image twice'
    );
}

{
    my $out;

    my $writer = XML::SAX::Writer->new( Output => \$out );

    my $gen = XML::Generator::RSS10->new(
        Handler => $writer,
        pretty  => 1,
    );

    $gen->item(
        title => 'Item title',
        link  => 'http://example.com/foo',
    );

    $gen->channel(
        title       => 'Channel title',
        link        => 'http://example.com/',
        description => 'a description',
    );

    eval {
        $gen->textinput(
            title       => 'Textinput title',
            name        => 'ti',
            description => 'Textinput description',
            url         => 'http://example.com/search',
        );
    };

    like(
        $@, qr/call textinput\(\) after calling channel\(\)/,
        'call image after channel'
    );
}

{
    my $out;

    my $writer = XML::SAX::Writer->new( Output => \$out );

    my $gen = XML::Generator::RSS10->new(
        Handler => $writer,
        pretty  => 1,
    );

    eval {
        $gen->channel(
            title       => 'Channel title',
            link        => 'http://example.com/',
            description => 'a description',
        );
    };

    like(
        $@, qr/without any items/,
        'call channel without items'
    );
}

{
    my $out;

    my $writer = XML::SAX::Writer->new( Output => \$out );

    my $gen = XML::Generator::RSS10->new(
        Handler => $writer,
        pretty  => 1,
    );

    $gen->item(
        title => 'Item title',
        link  => 'http://example.com/foo',
    );

    $gen->channel(
        title       => 'Channel title',
        link        => 'http://example.com/',
        description => 'a description',
    );

    eval {
        $gen->channel(
            title       => 'Channel title',
            link        => 'http://example.com/',
            description => 'a description',
        );
    };

    like(
        $@, qr/call channel\(\) more than once/,
        'call channel twice'
    );
}

done_testing();
