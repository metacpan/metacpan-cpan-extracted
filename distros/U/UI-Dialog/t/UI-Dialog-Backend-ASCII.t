use Test::More;
BEGIN { use_ok( 'UI::Dialog::Backend::ASCII' ); }
require_ok( 'UI::Dialog::Backend::ASCII' );

#########################

my $obj = UI::Dialog::Backend::ASCII->new();
isa_ok( $obj, 'UI::Dialog::Backend::ASCII' );

my @methods = qw( new state ra rs rv beep clear
                  yesno msgbox inputbox password textbox menu
                  checklist radiolist fselect dselect
                  spinner draw_gauge end_gauge );
can_ok( 'UI::Dialog::Backend::ASCII', @methods );

done_testing();
