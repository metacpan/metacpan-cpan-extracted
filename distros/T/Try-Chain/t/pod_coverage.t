#!perl -T

use strict;
use warnings;

use Test::More;

eval 'use Test::Pod::Coverage 1.04; 1'
    or plan( skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' );

all_pod_coverage_ok();

__END__

#!perl -T

use strict;
use warnings;

use Test::More;

eval 'use Test::Pod::Coverage 1.04; 1'
    or plan( skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' );
eval 'use Pod::Coverage::Moose; 1'
    or plan( skip_all => 'Pod::Coverage::Moose required for testing POD coverage' );

all_pod_coverage_ok({coverage_class => 'Pod::Coverage::Moose'});

__END__

#!perl -T

use strict;
use warnings;

use Test::More;

eval 'use Test::Pod::Coverage 1.04; 1'
    or plan( skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' );
eval 'use Pod::Coverage::Moose; 1'
    or plan( skip_all => 'Pod::Coverage::Moose required for testing POD coverage' );

#all_pod_coverage_ok({coverage_class => 'Pod::Coverage::Moose'});

my @module = grep {
    $_ !~ m{
        (?:
            Locale::File::PO::Header::Base
            | Locale::File::PO::Header::ContentTypeItem
            | Locale::File::PO::Header::ExtendedItem
            | Locale::File::PO::Header::Item
            | Locale::File::PO::Header::MailItem
        )
        \z
    }xms;
} all_modules();
plan tests => scalar @module;
for my $module (@module) {
    pod_coverage_ok( $module, {coverage_class => 'Pod::Coverage::Moose'} );
}
