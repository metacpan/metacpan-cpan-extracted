
use strict;
use Text::CSV::Encoded;

my $csv  = Text::CSV::Encoded->new(  );

is( $csv->coder_class, 'Text::CSV::Encoded::Coder::Encode' );

$csv  = Text::CSV::Encoded->new( { coder_class => 'Text::CSV::Encoded::Coder::Base' } );

is( $csv->coder_class, 'Text::CSV::Encoded::Coder::Base' );

1;

__END__
