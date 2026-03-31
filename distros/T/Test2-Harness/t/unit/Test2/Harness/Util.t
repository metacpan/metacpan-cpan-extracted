use Test2::V0 -target => 'Test2::Harness::Util';

# Backward-compat: looks_like_uuid was moved to Test2::Util::UUID in v2.x
# but old code (e.g., v1.x YathUI.pm installed in perldocker containers)
# still imports it from Test2::Harness::Util.
subtest 'looks_like_uuid backward-compat export' => sub {
    can_ok($CLASS, 'looks_like_uuid');

    # Verify it can be imported
    $CLASS->import('looks_like_uuid');
    ok(defined &looks_like_uuid, 'looks_like_uuid is importable from Test2::Harness::Util');

    # Verify it works correctly
    my $valid = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
    is(looks_like_uuid($valid), $valid, 'recognizes a valid UUID');
    ok(!looks_like_uuid(undef),      'rejects undef');
    ok(!looks_like_uuid('too-short'), 'rejects short strings');
    ok(!looks_like_uuid('not-a-uuid-at-all-but-has-36-chars!'), 'rejects non-hex 36-char strings');
};

done_testing;
