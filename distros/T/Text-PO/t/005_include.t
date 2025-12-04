#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use Data::Pretty qw( dump ); # REMOVE ME
    use Module::Generic::File qw( cwd file tempfile );
    use POSIX ();
    use I18N::Langinfo qw( langinfo );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Text::PO' ) || BAIL_OUT( "Cannot load Text::PO" );
};

use strict;
use warnings;
use utf8;

my $include_dir = file(__FILE__)->parent->child( 'include' );

if( !$include_dir->exists )
{
    BAIL_OUT( "$include_dir does not exist." );
}

# Convenience helper
sub _msgids
{
    my( $po ) = @_;
    my $elems = $po->elements || [];
    my @ids;

    foreach my $e ( @$elems )
    {
        my $id = $e->msgid_as_text;
        next if( !defined( $id ) || !length( $id ) );
        push( @ids, $id );
    }
    return( @ids );
}

# Basic include works by default (include => 1 by default)
subtest 'Basic include works by default' => sub
{
    my $file = $include_dir->child( 'base.po' );

    my $po = Text::PO->new; # include enabled by default
    ok( $po->parse( $file ), "parse(base.po) with include enabled" );

    my @ids = _msgids( $po );

    ok( grep( $_ eq 'base-only', @ids ), "base-only msgid is present" );
    ok( grep( $_ eq 'inc-one',   @ids ), "inc-one from included file is present" );
};

# include => 0 disables include processing
subtest 'Disabling include processing' => sub
{
    my $file = $include_dir->child( 'base.po' );

    my $po = Text::PO->new( include => 0 );
    ok( $po->parse( $file ), "parse(base.po) with include disabled" );

    my @ids = _msgids( $po );

    ok( grep( $_ eq 'base-only', @ids ), "base-only present when include disabled" );
    ok( !grep( $_ eq 'inc-one', @ids ),  "inc-one NOT present when include disabled" );
};

# Non-existing include file is ignored (no extra elements), warns
subtest 'Non-existing include file is ignored' => sub
{
    my $file = $include_dir->child( 'missing-include.po' );

    my @warnings;
    local $SIG{__WARN__} = sub{ push( @warnings, @_ ) };

    my $po = Text::PO->new;
    ok( $po->parse( $file ), "parse(missing-include.po) does not die" );

    my @ids = _msgids( $po );
    is_deeply(
        [ sort @ids ],
        [ 'missing-base' ],
        "Only the base msgid is present when include target does not exist"
    );

    ok(
        scalar( @warnings ) >= 1 &&
        join( '', @warnings ) =~ /does not exist/i,
        "A warning is emitted for non-existing include file"
    );
};

# Recursive includes with a cycle: A includes B, B includes A
#     => each msgid appears once; recursion is cut
subtest 'Recursive includes' => sub
{
    my $file = $include_dir->child( 'cycle-a.po' );

    my @warnings;
    local $SIG{__WARN__} = sub{ push( @warnings, @_ ) };

    my $po = Text::PO->new;
    ok( $po->parse( $file ), "parse(cycle-a.po) does not loop forever" );

    my @ids = _msgids( $po );

    my %count;
    $count{$_}++ for( @ids );

    ok( $count{'cycle-a'}, "cycle-a msgid is present" );
    ok( $count{'cycle-b'}, "cycle-b msgid is present" );
    ok( $count{'cycle-a'} == 1, "cycle-a appears exactly once" );
    ok( $count{'cycle-b'} == 1, "cycle-b appears exactly once" );

    ok(
        join( '', @warnings ) =~ /already been included/i,
        "Cycle is detected and reported via warning"
    );
};

# Deep recursion obeys max_include_depth
subtest 'Deep recursion' => sub
{
    my $file = $include_dir->child( 'depth-root.po' );

    my @warnings;
    local $SIG{__WARN__} = sub{ push( @warnings, @_ ) };

    # Assume: max_recurse counts *levels below the top file*.
    # With max_recurse => 2, and the chain:
    #   depth-root -> depth-1 -> depth-2 -> depth-3
    # we expect: root, depth-1, depth-2, but NOT depth-3.
    my $po = Text::PO->new( max_recurse => 2 );
    ok( $po->parse( $file ), "parse(depth-root.po) with max_recurse => 2" );

    my @ids = sort( _msgids( $po ) );
    diag( "\@ids are: ", dump( \@ids ) ) if( $DEBUG ); # REMOVE ME

    ok( grep( $_ eq 'depth-root', @ids ), "depth-root present" );
    ok( grep( $_ eq 'depth-1',    @ids ), "depth-1 present" );
    ok( grep( $_ eq 'depth-2',    @ids ), "depth-2 present" );
    ok( !grep( $_ eq 'depth-3',   @ids ), "depth-3 NOT present due to depth limit" );

    ok(
        !grep( $_ eq 'depth-4', @ids ),
        "depth-4 also not present (beyond depth limit)"
    );

    ok(
        !grep( $_ eq 'depth-5', @ids ),
        "higher levels beyond depth-4 are not included either"
    );

    diag( "\@warnings contains: ", dump( \@warnings ) ) if( $DEBUG ); # REMOVE ME
    ok(
        join( '', @warnings ) =~ /Maximum include recursion depth/i,
        "A warning is emitted when maximum include depth is reached"
    );
};

# Including a non-PO file: no elements are added from that file
subtest 'Including a non-PO file' => sub
{
    my $file = $include_dir->child( 'include-nonpo.po' );

    my @warnings;
    local $SIG{__WARN__} = sub{ push( @warnings, @_ ) };

    my $po = Text::PO->new;
    ok( $po->parse( $file ), "parse(include-nonpo.po) does not die" );

    my @ids = sort( _msgids( $po ) );

    is_deeply(
        \@ids,
        [ 'nonpo-base' ],
        "Only the base msgid is present; garbage included file adds no msgid"
    );

    # It is acceptable if there are some "I do not understand the line" warnings,
    # but we do not require them explicitly here.
};

done_testing();

__END__
