# -*- perl -*-
BEGIN
{
    use Test::More qw( no_plan );
    use_ok( 'Text::PO' );
    use_ok( 'Text::PO::MO' );
};

my $po = Text::PO->new;
isa_ok( $po, 'Text::PO' );
my $mo = Text::PO::MO->new;
isa_ok( $mo, 'Text::PO::MO' );

done_testing();
