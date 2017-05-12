use Test::More;

plan 'no_plan';



use Text::PO::Parser;



my $pofile = new Text::PO::Parser("t/gnome-mag.HEAD.fr.po");
ok ($pofile, 'open a po file');

ok(not ($pofile->end_file),'not eof');

$pofile->next;
$pofile->next;

is($pofile->get_comment,"#: ../magnifier/GNOME_Magnifier.server.in.in.h:1\n",'test a comment');
is($pofile->get_msgid,"Magnifier\n","test a msgid");
is($pofile->get_msgstr,"Loupe\n","test a msgstr");

$pofile->next;
ok($pofile->end_file,'eof');
