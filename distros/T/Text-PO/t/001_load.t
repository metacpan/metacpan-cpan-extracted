# -*- perl -*-
BEGIN
{
    use strict;
    use lib './lib';
    use Test::More qw( no_plan );
};

# To build the list of modules:
# for m in `find ./lib -type f -name "*.pm"`; do echo $m | perl -pe 's,./lib/,,' | perl -pe 's,\.pm$,,' | perl -pe 's/\//::/g' | perl -pe 's,^(.*?)$,use_ok\( ''$1'' \)\;,'; done
BEGIN
{
    use_ok( 'Text::PO' );
    use_ok( 'Text::PO::Element' );
    use_ok( 'Text::PO::Gettext' );
    use_ok( 'Text::PO::MO' );
};

my $po = Text::PO->new;
isa_ok( $po, 'Text::PO' );
my $mo = Text::PO::MO->new;
isa_ok( $mo, 'Text::PO::MO' );

done_testing();
