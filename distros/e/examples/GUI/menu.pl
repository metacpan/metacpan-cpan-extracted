use Tk;
$top = MainWindow->new();
# Create Menu Bar
$menu_bar = $top->Frame()->pack('-side' => 'top');
 
#Search menu button
$search_mb = $menu_bar->Menubutton('-text'         => 'Search',
                                   '-relief'       => 'raised',
                                   '-borderwidth'  => 2,
                                   )->pack('-side' => 'left',
                                           '-padx' => 2
                                           );
# Find
$search_mb->command('-label'       => 'Find',
                    '-accelerator' => 'Meta+F',
                    '-underline'   => 0,
                    '-command'     => sub {print "find\n"}
                    );
# Find Again
$search_mb->command('-label'       => 'Find Again',
                    '-accelerator' => 'Meta+A',
                    '-underline'   => 5,
                    '-command'     => sub {print "find again\n"}
                    );

$match_type = "regexp"; $case_type = 1;
$search_mb->separator();
# Regexp match
$search_mb->radiobutton('-label'    => 'Regexp match',
                        '-value'    => 'regexp',
                        '-variable' => \$match_type);
# Exact match
$search_mb->radiobutton('-label'    => 'Exact match',
                        '-value'    => 'exact',
                        '-variable' => \$match_type);
$search_mb->separator();
# Ignore case
$search_mb->checkbutton('-label'    => 'Ignore case?',
                        '-variable' => \$case_type);

MainLoop();
