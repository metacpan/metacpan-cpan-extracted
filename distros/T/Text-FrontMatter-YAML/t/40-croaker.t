use Test::More;
use Test::Fatal;

use Text::FrontMatter::YAML;

my $DOC_STRING = <<'END_INPUT';
---
layout: frontpage
title: My New Site
---
This is just some random text. Nothing to see here. Move along.

---
Ha!
...
END_INPUT


sub tfmnew {
    return Text::FrontMatter::YAML->new(@_);
}

is(
    exception { tfmnew(document_string => $DOC_STRING) },
    undef,
    'new: no exception with only document_string',
);

is(
    exception { tfmnew(frontmatter_hashref => { foo => 'bar' }) },
    undef,
    'new: no exception with only frontmatter_hashref',
);

is(
    exception { tfmnew(data_text => 'hi mom') },
    undef,
    'new: no exception with only data text',
);

like(
    exception { tfmnew(document_string => $DOC_STRING, data_text => 'hi mom') },
    qr/cannot pass 'document_string' with either/,
    'new: croaks with document_string + data_text'
);

like(
    exception { tfmnew(document_string => $DOC_STRING, frontmatter_hashref => { foo => 'bar' }) },
    qr/cannot pass 'document_string' with either/,
    'new: croaks with document_string + frontmatter_hashref'
);

like(
    exception { tfmnew() },
    qr/must pass 'document_string', 'data_text', or 'frontmatter_hashref'/,
    'new: croaks with no parameters',
);


my $TFM = tfmnew( document_string => $DOC_STRING );

like(
    exception { $TFM->frontmatter_hashref({ foo => 'bar' }); },
    qr/you can't call frontmatter_hashref as a setter/,
    "can't call frontmatter_hashref as a setter"
);

like(
    exception { $TFM->frontmatter_text(''); },
    qr/you can't call frontmatter_text as a setter/,
    "can't call frontmatter_text as a setter"
);

like(
    exception { $TFM->data_fh(*STDERR); },
    qr/you can't call data_fh as a setter/,
    "can't call data_fh as a setter"
);

like(
    exception { $TFM->data_text(''); },
    qr/you can't call data_text as a setter/,
    "can't call data_text as a setter"
);

like(
    exception { $TFM->document_string(''); },
    qr/you can't call document_string as a setter/,
    "can't call document_string as a setter"
);

done_testing;
