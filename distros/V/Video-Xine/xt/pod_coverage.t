use Test::Pod::Coverage tests => 3;
pod_coverage_ok(
    "Video::Xine",
    { 'also_private' => [qr/^xine_/] },
    "Video::Xine is covered"
);
pod_coverage_ok(
    "Video::Xine::Driver::Audio",
    { 'also_private' => [qr/^xine_/] },
    "Video::Xine::Driver::Audio is covered"
);
pod_coverage_ok(
    "Video::Xine::Driver::Video",
    { 'also_private' => [ qr/^xine_/, 'send_gui_data' ] },
    "Video::Xine::Driver::Video is covered"
);
