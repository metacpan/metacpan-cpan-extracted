use Test::More;
eval         'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required for testing POD Coverage' if $@;
plan tests    => 1;
pod_coverage_ok('Tk::AbstractCanvas',
  { 'also_private' => [ qr/^(ClassInit|InitObject|coords|create(Arc|Bitmap|Image|Line|Oval|Polygon|Rectangle|Text|Window)?|delete|find|move|[xy]view)$/ ], },
                                                          'POD Covered');
