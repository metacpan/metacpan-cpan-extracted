#
# (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
#

use Win32::ShellExt::RenameMP3;

my $obj = Win32::ShellExt::RenameMP3->new;

$obj->query_context_menu("c:\\mounted\\mp3\\freedom.mp3","c:\\mounted\\mp3\\freedom2.mp3");
$obj->action("c:\\mounted\\mp3\\freedom.mp3","c:\\mounted\\mp3\\freedom2.mp3");
