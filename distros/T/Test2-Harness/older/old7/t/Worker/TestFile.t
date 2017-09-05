use Test2::Bundle::Extended -target => 'Test2::Harness::Worker::TestFile';
use Test2::Harness::Util::JSON qw/encode_json decode_json/;

use File::Temp qw/tempfile/;

use ok $CLASS;

my ($fh1, $simple_name) = tempfile();
print $fh1 <<EOT;
#!/usr/bin/env perl
use strict;
use warnings;

ok(1);
done_testing;
EOT
close($fh1);

my ($fh2, $shbang_name) = tempfile();
print $fh2 <<EOT;
#!/usr/bin/env perl -T -w
use strict;
use warnings;

ok(1);
done_testing;
EOT
close($fh2);

my ($fh3, $directive_name) = tempfile();
print $fh3 <<EOT;
#!/usr/bin/env perl
use strict;
use warnings;
# HARNESS-NO-PRELOAD
# HARNESS-YES-FOO

ok(1);
done_testing;
EOT
close($fh3);

subtest TO_JSON => sub {
    my $one = $CLASS->new(filename => $simple_name);

    is(
        $one->TO_JSON,
        {
            filename => $simple_name,
            headers  => {},
            shbang => {line => '#!/usr/bin/env perl', switches => []},
            no_preload => 0,
            content => <<'            EOT',
#!/usr/bin/env perl
use strict;
use warnings;

ok(1);
done_testing;
            EOT
        },
        "serialized simple"
    );

    my $two = $CLASS->new(filename => $shbang_name);
    is(
        $two->TO_JSON,
        {
            filename => $shbang_name,
            headers  => {},
            shbang => {line => '#!/usr/bin/env perl -T -w', switches => ['-T', '-w']},
            no_preload => 1,
            content => <<'            EOT',
#!/usr/bin/env perl -T -w
use strict;
use warnings;

ok(1);
done_testing;
            EOT
        },
        "serialized shbang"
    );

    my $three = $CLASS->new(filename => $directive_name);
    is(
        $three->TO_JSON,
        {
            filename => $directive_name,
            headers  => {features => {preload => 0, foo => 1}},
            shbang => {line => '#!/usr/bin/env perl', switches => []},
            no_preload => 1,
            content => <<'            EOT',
#!/usr/bin/env perl
use strict;
use warnings;
# HARNESS-NO-PRELOAD
# HARNESS-YES-FOO

ok(1);
done_testing;
            EOT
        },
        "serialized directives"
    );

};

subtest construction => sub {
    like(
        dies { $CLASS->new },
        qr/^'filename' is required/,
        "Need filename"
    );
};

subtest simple => sub {
    my $one = $CLASS->new(filename => $simple_name);

    is($one->headers, {}, "no headers");
    is($one->shbang, {line => '#!/usr/bin/env perl', switches => []}, "Got shbang info, no switches");
    is($one->no_preload, 0, "preload is ok");
};

subtest shbang => sub {
    my $one = $CLASS->new(filename => $shbang_name);

    is($one->headers, {}, "no headers");
    is($one->shbang, {line => '#!/usr/bin/env perl -T -w', switches => ['-T', '-w']}, "parsed shbang");
    is($one->no_preload, 1, "cannot preload with switches in the shbang");
};

subtest directives => sub {
    my $one = $CLASS->new(filename => $directive_name);

    is($one->headers, {features => {preload => 0, foo => 1}}, "Parsed headers");
    is($one->shbang, {line => '#!/usr/bin/env perl', switches => []}, "No switches");
    is($one->no_preload, 1, "preload intentionally disabled");
};

done_testing;

unlink($simple_name);
unlink($shbang_name);
unlink($directive_name);
