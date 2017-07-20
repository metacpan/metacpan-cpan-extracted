use               Test::More;
eval         'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required for testing POD Coverage' if $@;
eval         'use Tk';
plan skip_all => 'Tk                  required for testing POD Coverage' if $@; # hoping this will fix this test from failing
plan tests    =>  1  ;
pod_coverage_ok( 'Tk::AbstractCanvas',
  { 'also_private' => [ qr/^(ClassInit|InitObject|coords|create(Arc|Bitmap|Image|Line|Oval|Polygon|Rectangle|Text|Window)?|delete|find|move|[xy]view)$/ ], },
                                                          'POD Covered');
