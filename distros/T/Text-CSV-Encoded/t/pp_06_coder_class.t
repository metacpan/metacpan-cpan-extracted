#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use Text::CSV::Encoded;

my $csv  = Text::CSV::Encoded->new(  );

is( $csv->coder_class,
    $] >= 5.008 ? 'Text::CSV::Encoded::Coder::Encode' : 'Text::CSV::Encoded::Coder::Base' );

$csv  = Text::CSV::Encoded->new( { coder_class => 'Text::CSV::Encoded::Coder::Base' } );

is( $csv->coder_class, 'Text::CSV::Encoded::Coder::Base' );


__END__
