#!/opt/bin/perl
use strict;
#--------------------------------------------------------------
# perlman: man page viewer in Perl
#--------------------------------------------------------------
use Tk;

print STDERR "Scouting man directories\n";
scout_man_dirs();
print STDERR "Starting UI ...";
create_ui();
print STDERR "Done \n";
MainLoop();
exit(0);

#-------------------------------------------------------------------
my $menu_headings;        # "Headings" MenuButton
my $ignore_case;          # 1 if check-button on in Search menu
my $match_type;           # '-regexp' or '-exact'. 
my $text;                 # Main text widget
my $show;                 # "Show" entry widget
my $search;               # "Search" entry widget
my %sections;             # Maps section ('1', '3' ,'3n' etc.)
                          #  to list of topics in that section

sub show_man {
    my $entry = $show->get();   # get entry from $show
    my ($man, $section) = ($entry =~ /^(\w+)(\(.*\))?/);
    if ($section && (!is_valid_section($section))) {
        undef $section ;
    }
    my $cmd_line = get_command_line($man, $section); # used by open

    # Erase everything to do with current page (contents, menus, marks)
    $text->delete('1.0', 'end');  # erase current page
    $text->insert('end', "Formatting \"$man\" .. please wait", 'section');
    $text->update();                  # Flush changes to text widget
    $menu_headings->menu()->delete(0,'end'); # Delete current headings
    my $mark;
    foreach $mark ($text->markNames) {  # remove all marks 
        $text->markUnset($mark);
    }

    # UI is clean now. Open the file
    if (!open (F, $cmd_line)) {
        # Use the text widget for error messages 
        $text->insert('end', "\nError in running man or rman");
        $text->update();
        return;
    }
    # Erase the "Formatting $man ..." message
    $text->delete('1.0', 'end');
    my $lines_added = 0; my $line;
    
    while ($line = <F>) {
        $lines_added = 1;
        # If first character is a capital letter, it's likely a section
        if ($line =~ /^[A-Z]/) {  
            # Likely a section heading
            ($mark = $line) =~ s/\s.*$//g;  # $mark has section title
            my $index = $text->index('end');# note current end location
            # Give 'section' tag to the section title
            $text->insert('end', "$mark\n\n", 'section');
            # Create a menu entry. Have callback invoke text widget's
            # 'see' method to go to the index noted above
            $menu_headings->command(
                    '-label' => $mark,
                    '-command' => [sub {$text->see($_[0])},$index])
        } else {
            $text->insert('end', $line); # Ordinary text. Just insert.
        }
    }
    if ( ! $lines_added ) {
        $text->insert('end', "Sorry. No information found on $man");
    }
    close(F);
}

sub get_command_line {
    my ($man, $section) = @_; # Given topic and section, construct 
                              # Unix command-line
    if ($section) {
        $section =~ s/[()]//g; # remove parens
        return "man -s $section $man 2> /dev/null | rman |";
    } else {
        return "man $man 2> /dev/null | rman |";
    }
}

sub create_ui {
    my $top = MainWindow->new();

    # MENU STUFF

    # Menu bar
    my $menu_bar = $top->Frame()->pack('-side' => 'top', '-fill' => 'x');

    # File menu
    my $menu_file = $menu_bar->Menubutton('-text' => 'File',
                                          '-relief' => 'raised',
                                          '-borderwidth' => 2,
                                          )->pack('-side' => 'left',
                                                  '-padx' => 2,
                                                  );
    $menu_file->separator();
    $menu_file->command('-label' => 'Quit', '-command' => sub {exit(0)});

    #Sections Menu
    $menu_headings = $menu_bar->Menubutton('-text' => 'Headings',
                                           '-relief' => 'raised',
                                           '-borderwidth' => 2,
                                           )->pack('-side' => 'left',
                                                   '-padx' => 2,
                                                   );
    $menu_headings->separator();

    
    #Search menu 
    my $search_mb = $menu_bar->Menubutton('-text'         => 'Search',
                                          '-relief'       => 'raised',
                                          '-borderwidth'  => 2,
                                          )->pack('-side' => 'left',
                                                  '-padx' => 2
                                               );
    $match_type = "-regexp"; $ignore_case = 1;
    $search_mb->separator();

    # Regexp match
    $search_mb->radiobutton('-label'    => 'Regexp match',
                            '-value'    => '-regexp',
                            '-variable' => \$match_type);
    # Exact match
    $search_mb->radiobutton('-label'    => 'Exact match',
                            '-value'    => '-exact',
                            '-variable' => \$match_type);
    $search_mb->separator();
    # Ignore case
    $search_mb->checkbutton('-label'    => 'Ignore case?',
                            '-variable' => \$ignore_case);


    #Sections Menu
    my $menu_sections = $menu_bar->Menubutton('-text' => 'Sections',
                                              '-relief' => 'raised',
                                              '-borderwidth' => 2,
                                              )->pack('-side' => 'left',
                                                      '-padx' => 2,
                                                      );
    # Populate sections menu with keys of % sections
    my $section_name;
    foreach $section_name (sort keys %sections) {
        $menu_sections->command (
                 '-label' => "($section_name)",
                 '-command' => [\&show_section_contents, $section_name]);
    }
    
    # TEXT STUFF

    $text = $top->Text ('-width' =>  80, 
                        '-height' => 40)->pack();
    $text->tagConfigure('section', 
                        '-font' => '-adobe-helvetica-bold-r-normal--14-140-75-75-p-82-iso8859-1');
    $text->bind('<Double-1>', \&pick_word);
    $top->Label('-text' => 'Show:')->pack('-side' => 'left');

    $show = $top->Entry ('-width'   =>  20,
                         )->pack('-side' => 'left');
    $show->bind('<KeyPress-Return>', \&show_man);

    $top->Label('-text' => 'Search:'
                )->pack('-side' => 'left', '-padx' => 10);
    $search = $top->Entry ('-width' => 20,
                           )->pack('-side' => 'left');
    $search->bind('<KeyPress-Return>', \&search);
}

sub is_valid_section {
    my $section= $_[0];
    return 0 unless $section =~ /\((.*?)\)/;
    my $section = $1;
    my $s;
    foreach $s (keys %sections) {
        if (lc($s) eq lc($section)) {
            return 1;
        }
    }
    0;
}

sub pick_word {
    my $start_index = $text->index('insert wordstart');
    my $end_index = $text->index('insert lineend');
    my $line = $text->get($start_index, $end_index);
    my ($page, $section) = ($line =~ /^(\w+)(\(.*?\))?/); 
    return unless $page;
    $show->delete('0', 'end');
    if ($section && is_valid_section($section)) {
        $show->insert('end', "$page${section}");
    } else {
        $show->insert('end', $page);
    }
    show_man();
}

sub show_section_contents {
    my $current_section = $_[0];
    $text->delete('1.0', 'end');
    $menu_headings->menu()->delete(0,'end');
    my ($i, $len);
    return unless exists $sections{$current_section};
    my $spaces = " " x 40;
    my $words_in_line = 0;  # New line when this goes to three
    my $man;
    foreach $man (@{$sections{$current_section}}) {
        $text->insert('end', $man . substr($spaces,0, 24 - length($man)));
        if (++$words_in_line  == 3) {
            $text->insert('end', "\n");
            $words_in_line = 0;
        }
    }
}

sub search {
    my $search_pattern = $search->get();
    $text->tagDelete('search');
    $text->tagConfigure('search', 
                        '-background' => 'yellow', 
                        '-foreground' => 'red');

    my $current = '1.0'; my $length = '0';
    while (1) {
        if ($ignore_case) {
            $current = $text->search('-count' => \$length,
                                     $match_type, 
                                     '-nocase',
                                     '--',
                                     $search_pattern,
                                     $current,
                                     'end');
        } else {
            $current = $text->search('-count' => \$length,
                                     $match_type, 
                                     '--',
                                     $search_pattern,
                                     $current,
                                     'end');
        }
        last if (!$current);
        $text->tagAdd('search', $current, "$current + $length char");
        $current = $text->index("$current + $length char");
    }
}


use Cwd;
sub scout_man_dirs {
    my (@man_dirs,$man_dir, $section);
    if ($ENV{MANPATH}) {
        @man_dirs = split (/:/, $ENV{MANPATH});
    } else {
        push (@man_dirs, "/usr/man");
    }
    # Convert all relative man paths to fully qualified ones, by
    # prepending with $cwd
    my $cwd = cwd();
    foreach $man_dir (@man_dirs) {
        next if ($man_dir =~ m|^/|);
        $man_dir = "$cwd/$man_dir"; # Modifies entry in man_dirs
    }
    foreach $man_dir (@man_dirs) {
        chdir $man_dir || next;
        # Now, in /usr/man, say. Get all the directories
        my @section_dirs = grep {-d $_} <man*>;
        my $section_dir;
        # @section_dirs has man1, man2, man3s etc.
        foreach $section_dir (@section_dirs) {
            chdir $section_dir || next;
            ($section = $section_dir) =~ s/^man//;
            push (@{$sections{$section}}, <*.$section>);
            chdir "..";
        }
        chdir "..";
    }
    # All sections in all man pages have been slurped in. Remove duplicates
    foreach $section (keys %sections) {
        my @new_list;
        my %seen;
        @new_list = sort (grep (!$seen{$_}++, @{$sections{$section}}));
        # Change all entries like cc.1 to cc(1)
        foreach (@new_list) {
            $_ =~ s/[.](.*)/($section)/;
        }
        $sections{$section} = \@new_list;
    }
}
