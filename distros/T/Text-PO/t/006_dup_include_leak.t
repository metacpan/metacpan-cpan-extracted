#!perl
# Regression test for the state leak of $e between blocks when a msgid is skipped as a
# duplicate of an included file.
#
# The bug had two faces, both stemming from the duplicate-skip branch using 'next',
# which jumped over the $e reset at the end of the block boundary:
#
#   1. msgstr leak: the following block's 'msgstr ""' (which, before the fix, did not
#      reset the field when the quoted content was empty) inherited the previous
#      block's msgstr.
#
#   2. msgid fusion: if the skipped block had a multi-line msgid (an array reference
#      internally), the following block's 'msgid ""' continuation lines were appended to
#      that leaked arrayref by _add(), producing a single fused msgid spanning two PO
#      entries.
#
# Both faces are exercised below. Each sub-case is built so that the relevant msgid is a
# duplicate of an entry in the included file (parsed first), so the main-file entry hits
# the duplicate-skip branch.
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use Test::More qw( no_plan );
    use Module::Generic::File qw( file tempfile );
};

BEGIN
{
    use_ok( 'Text::PO' ) || BAIL_OUT( "Cannot load Text::PO" );
};

use strict;
use warnings;
use utf8;

# Helper: locate the first element whose msgid (as text) matches a pattern.
sub _find
{
    my( $po, $re ) = @_;
    my $elems = $po->elements || [];
    foreach my $e ( @$elems )
    {
        my $id = $e->msgid_as_text;
        return( $e ) if( defined( $id ) && $id =~ $re );
    }
    return;
}

# ---------------------------------------------------------------------------
# Face 1: msgstr leak across a duplicate-skipped block.
#
# Include declares A and B (single-line msgids). Main re-declares A and B
# (so both are skipped as duplicates), then declares C with a multi-line
# msgid and an empty msgstr. Before the fix, C inherited B's leaked msgstr.
# ---------------------------------------------------------------------------
subtest 'msgstr does not leak across a duplicate-skipped block' => sub
{
    my $inc = tempfile( extension => 'po', cleanup => 1 );
    $inc->open( '>', { binmode => ':utf8' });
    $inc->print( <<'EOT' );
msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\n"

msgid "A"
msgstr "include-translation-of-A"

msgid "B"
msgstr "include-translation-of-B"
EOT
    $inc->close;

    my $main = tempfile( extension => 'po', cleanup => 1 );
    $main->open( '>', { binmode => ':utf8' });
    $main->print( '#. $include "' . $inc->basename . '"' . "\n" );
    $main->print( <<'EOT' );

msgid "A"
msgstr "main-translation-of-A"

msgid "B"
msgstr "main-translation-of-B"

msgid ""
"C line one "
"C line two"
msgstr ""
EOT
    $main->close;

    my $po = Text::PO->new( include => 1, debug => 0 );
    $po->parse( $main ) || BAIL_OUT( "parse failed: " . $po->error );

    my $c = _find( $po, qr/^C line one/ );
    ok( defined( $c ), 'entry C is present' );

    is( $c->msgid_as_text, 'C line one C line two',
        'entry C keeps its own msgid' );

    my $msgstr = $c->msgstr_as_text;
    ok( !defined( $msgstr ) || !length( $msgstr ),
        'entry C has an empty msgstr (no leak from the previous block)' );
};

# ---------------------------------------------------------------------------
# Face 2: msgid fusion across a duplicate-skipped multi-line block.
#
# Include declares a multi-line msgid "DupML". Main re-declares the same
# multi-line msgid (skipped as duplicate), then declares "Fresh" with a
# multi-line msgid. Before the fix, the leaked DupML arrayref had the Fresh
# continuation lines appended to it, fusing both msgids into one.
# ---------------------------------------------------------------------------
subtest 'msgid does not fuse across a duplicate-skipped multi-line block' => sub
{
    my $inc = tempfile( extension => 'po', cleanup => 1 );
    $inc->open( '>', { binmode => ':utf8' });
    $inc->print( <<'EOT' );
msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\n"

msgid ""
"DupML part one "
"DupML part two"
msgstr "include-translation-of-DupML"
EOT
    $inc->close;

    my $main = tempfile( extension => 'po', cleanup => 1 );
    $main->open( '>', { binmode => ':utf8' });
    $main->print( '#. $include "' . $inc->basename . '"' . "\n" );
    $main->print( <<'EOT' );

msgid ""
"DupML part one "
"DupML part two"
msgstr "main-translation-of-DupML"

msgid ""
"Fresh line one "
"Fresh line two"
msgstr "translation-of-Fresh"
EOT
    $main->close;

    my $po = Text::PO->new( include => 1, debug => 0 );
    $po->parse( $main ) || BAIL_OUT( "parse failed: " . $po->error );

    my $fresh = _find( $po, qr/Fresh line one/ );
    ok( defined( $fresh ), 'entry Fresh is present' );

    is( $fresh->msgid_as_text, 'Fresh line one Fresh line two',
        'entry Fresh has its own msgid, not fused with the skipped DupML block' );

    is( $fresh->msgstr_as_text, 'translation-of-Fresh',
        'entry Fresh keeps its own msgstr' );

    # No element should contain both DupML and Fresh fragments.
    my $elems = $po->elements || [];
    my @fused = grep( ( $_->msgid_as_text // '' ) =~ /DupML.*Fresh|Fresh.*DupML/s, @$elems );
    is( scalar( @fused ), 0, 'no fused msgid spanning DupML and Fresh exists' );
};

done_testing();

__END__
