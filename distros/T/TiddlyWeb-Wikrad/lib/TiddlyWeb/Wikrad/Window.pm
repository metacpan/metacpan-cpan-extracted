package TiddlyWeb::Wikrad::Window;
use strict;
use warnings;
use base 'Curses::UI::Window';
use Curses qw/KEY_ENTER/;
use TiddlyWeb::Wikrad qw/$App/; # XXX cyclic
use TiddlyWeb::EditPage;
use JSON;
use Data::Dumper;
use YAML ();

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->_create_ui_widgets;
    $self->read_config;

    my ($v, $p, $w, $t, $md, $mr) = map { $self->{$_} } 
                          qw/viewer page_box workspace_box tag_box modified_box modifier_box/;
    $v->focus;
    $v->set_binding( \&show_help,                '?' );
    $v->set_binding( \&recently_changed,         'r' );
    $v->set_binding( \&show_uri,                 'u' );
    if ($self->{config}{vim_insert_keys_start_vim}) {
        for my $key (qw(i a o A)) {
            $v->set_binding( sub { editor(
                command => $key,
                line => $v->{-ypos} + 1,
                col => $v->{-xpos} + 1,
            ) }, $key );
        }
    }
    $v->set_binding( \&clone_page,               'c' );
    $v->set_binding( \&show_metadata,            'm' );
    $v->set_binding( \&change_server,            'S' );
    $v->set_binding( \&save_to_file,             'W' );
    $v->set_binding( \&search,                   's' );
    $v->set_binding( \&tag_page,                 'T' );
    $v->set_binding( \&process_macros,           'M' );

    $v->set_binding( sub { editor() },                  'e' );
    $v->set_binding( sub { $v->focus },                 'v' );
    $v->set_binding( sub { $p->focus; $self->{cb}{page}->($p) },      'p' );
    $v->set_binding( sub { $w->focus; $self->{cb}{workspace}->($w) }, 'w' );

    $v->set_binding( sub { $v->viewer_enter }, KEY_ENTER );
    $v->set_binding( sub { $App->go_back }, 'b' );

    # this n/N messes up search next/prev
    $v->set_binding( sub { $v->next_link },    'n' );
    $v->set_binding( sub { $v->prev_link },    'N' );

    $v->set_binding( sub { $v->cursor_down },  'j' );
    $v->set_binding( sub { $v->cursor_up },    'k' );
    $v->set_binding( sub { $v->cursor_right }, 'l' );
    $v->set_binding( sub { $v->cursor_left },  'h' );
    $v->set_binding( sub { $v->cursor_to_home }, '0' );
    $v->set_binding( sub { $v->cursor_to_end },  'G' );

    return $self;
}

sub process_macros {
    my $r = $App->{rester};
    my $viewer = $App->{win}{viewer};
    $App->{cui}->status('Processing Macros ...');
    my $page_text = $viewer->text;
    # deal with <<list filter>>
    while($page_text =~ m/(<<list\s+filter\s+\[(.+?)\[(.+?)\]\]>>)/g) {
        my $matched = $1;
        my $command = $2;
        my $args = $3;
        $r->filter("$command:$args");
        $r->accept('text/plain');
        my @pages = split(/\n/, $r->get_pages());
        $r->filter('');
        my $new_text = '* ' . join("\n* ", map {"[[$_]]"} @pages);
        $page_text =~ s/\Q$matched\E/$command:$args\n$new_text/;
    }
    # deal with <<tiddler includes>>
    while($page_text =~ m/<<tiddler \[?\[?(.+?)\]?\]?>>/g) {
        my $included_page = $1;
        $r->accept('perl_hash');
        my $included_page_info = $r->get_page($included_page);
        my $included_text = $included_page_info->{text};
        my $new_text = "-----Included Tiddler----- [[$included_page]]\n"
                       . "$included_text\n"
                       . "-----End Include----- \n";
        $page_text =~ s/<<tiddler \[?\[?\Q$included_page\E\]?\]?>>/$new_text/;
    }
    $viewer->text($page_text);
    $App->{cui}->nostatus;
}

sub show_help {
    $App->{cui}->dialog( 
        -fg => 'yellow',
        -bg => 'blue',
        -title => 'Help:',
        -message => <<EOT);
Basic Commands:
 j/k/h/l/arrow keys - move cursor
 n/N     - move to next/previous link
 ENTER   - jump to page [under cursor]
 space/- - page down/up
 b       - go back
 e       - open page for edit
 r       - choose from recently changed pages

Awesome Commands:
 0/G - move to beginning/end of page
 w   - set workspace
 p   - set page
 s   - search
 u   - show the uri for the current page
 m   - show page metadata (tags, revision)
 M   - process macros (tiddler, list)
 T   - Tag page
 c   - clone this page
 S   - Change REST server

Find:
 / - find forward
 ? - find backwards 
 (Bad: find n/N conflicts with next/prev link)

Ctrl-q / Ctrl-c / q - quit
EOT
}

sub tag_page {
    my $r = $App->{rester};
    $r->accept('perl_hash');
    my $page_name = $App->get_page;
    my @tags = split(/\s*,\s*/, $App->{win}{tag_box}->text);
    my $question = "Enter new tags, separate with commas, prefix with '-' to remove\n  ";
    if (@tags) {
        $question .= join(", ", @tags) . "\n";
    }
    my $newtags = $App->{cui}->question($question) || '';
    my @new_tags = split(/\s*,\s*/, $newtags);
    my @store_tags;
    if (@new_tags) {
        $App->{cui}->status("Tagging $page_name with @new_tags...");
        for my $t (@new_tags) {
            unless ($t =~ m/^-/) {
                push(@store_tags, $t);
            }
        }
        my $page = $r->get_page($page_name);
        $page->{tags} = \@store_tags;
        eval { $r->put_page($page_name, $page); };
        if ($@) {
            $App->{cui}->dialog("Error: $@");
        }
        $App->{cui}->nostatus;
        $App->set_page($page_name);
    }
}

sub show_metadata {
    my $r = $App->{rester};
    $App->{cui}->status('Fetching page metadata ...');
    $r->accept('application/json');
    my $page_name = $App->get_page;
    my $json_text = $r->get_page($page_name);
    my $page_data = from_json($json_text);
    $App->{cui}->nostatus;
    $App->{cui}->dialog(
        -title => "$page_name metadata",
        -message => Dumper $page_data,
    );
}

sub show_uri {
    my $r = $App->{rester};
    my $uri = $r->server . '/recipes/' . $r->workspace . '/tiddlers/' 
              . $App->get_page;
    $App->{cui}->dialog( -title => "Current page:", -message => " $uri" );
}

sub clone_page {
    my @args = @_; # obj, key, args
    my $template_page = $args[2] || $App->get_page;
    my $r = $App->{rester};
    $r->accept('perl_hash');
    my $template = $r->get_page($template_page);
    my $new_page = $App->{cui}->question("Title for new page:");
    if ($new_page) {
        $App->{cui}->status("Creating page ...");
        eval { $r->put_page($new_page, $template); };
        if ($@) {
            $App->{cui}->dialog("Error: $@");
            $App->set_page($template_page);
        } else {
            $App->set_page($new_page);
        }
    }
}

sub recently_changed {
    my $r = $App->{rester};
    $App->{cui}->status('Fetching recent changes ...');
    $r->accept('text/plain');
    $r->count(250);
    $r->order('-modified');
    my @recent = $r->get_pages();
    $r->count(0);
    $r->order('');
    $App->{cui}->nostatus;
    $App->{win}->listbox(
        -title => 'Choose a page link',
        -values => \@recent,
        change_cb => sub {
            my $link = shift;
            $App->set_page($link) if $link;
        },
    );
}

sub choose_link {
    my $method = shift;
    my $text = shift;
    my $arg = shift;
    my $page = $App->get_page;
    $App->{cui}->status("Fetching ${text}s");
    $App->{rester}->accept('text/plain');
    my @links = $App->{rester}->$method($page, $arg);
    $App->{cui}->nostatus;
    if (@links) {
        $App->{win}->listbox(
            -title => "Choose a $text",
            -values => \@links,
            change_cb => sub {
                my $link = shift;
                $App->set_page($link) if $link;
            },
        );
    }
    else {
        $App->{cui}->error("No ${text}s");
    }
}

sub editor {
    my %extra_args = @_;
    $App->{cui}->status('Editing page');
    $App->{cui}->leave_curses;

    my $ep = TiddlyWeb::EditPage->new( 
        rester => $App->{rester},
        %extra_args,
    );

    my $page = $App->get_page;
    eval {
        $ep->edit_page(
            page => $page,
        );
    };
    if ($@) {
        my ($message) = ($@ =~ /(.*?)\n/);
        $App->{cui}->reset_curses;
        $App->{cui}->dialog("Error, so: $message");
        $App->load_page;
    } else {
        $App->{cui}->reset_curses;
        $App->load_page;
    }

}

sub workspace_change {
    my $new_wksp = $App->{win}{workspace_box}->text;
    my $r = $App->{rester};
    if ($new_wksp) {
        $App->set_page(undef, $new_wksp);
    }
    else {
        $App->{cui}->status('Fetching list of workspaces ...');
        $r->accept('text/plain');
        my @workspaces = $r->get_workspaces;
        $App->{cui}->nostatus;
        $App->{win}->listbox(
            -title => 'Choose a workspace',
            -values => \@workspaces,
            change_cb => sub {
                my $wksp = shift;
                $App->set_page(undef, $wksp);
            },
        );
    }
}

sub search {
    my $r = $App->{rester};

    my $query = $App->{cui}->question( 
        -question => "Search"
    ) || return;

    $App->{cui}->status("Looking for pages matching your query");
    $r->accept('text/plain');
    $r->query($query);
    $r->order('-modified');
    my @matches = $r->get_search;
    $r->query('');
    $r->order('');
    $App->{cui}->nostatus;
    $App->{win}->listbox(
        -title => 'Choose a page link',
        -values => \@matches,
        change_cb => sub {
            my $link = shift;
            $App->set_page($link) if $link;
        },
    );
}

sub change_server {
    my $r = $App->{rester};
    my $old_server = $r->server;
    my $question = <<EOT;
Enter the REST server you'd like to use:
  (Current server: $old_server)
EOT
    my $new_server = $App->{cui}->question( 
        -question => $question,
        -answer   => $old_server,
    ) || '';
    if ($new_server and $new_server ne $old_server) {
        $r->server($new_server);
    }
}

sub save_to_file {
    my $r = $App->{rester};
    my $filename;
    eval {
        my $page_name = $App->get_page;
        $filename = $App->save_dir . "/$page_name.wiki";

        open(my $fh, ">$filename") or die "Can't open $filename: $!";
        print $fh $App->{win}{viewer}->text;
        close $fh or die "Couldn't write $filename: $!";
    };
    my $msg = $@ ? "Error: $@" : "Saved to $filename";
    $App->{cui}->dialog(
        -title => "Saved page to disk",
        -message => $msg,
    );
}

sub toggle_editable {
    my $w = shift;
    my $cb = shift;
    my $readonly = $w->{'-readonly'};

    my $new_text = $w->text;
    $new_text =~ s/^\s*(.+?)\s*$/$1/;
    $w->text($new_text);

    if ($readonly) {
        $w->{last_text} = $new_text;
        $w->cursor_to_home;
        $w->focus;
    }
    else {
        $App->{win}{viewer}->focus;
    }

    $cb->() if $cb and !$readonly;

    if (! $readonly and $w->text =~ m/^\s*$/) {
        $w->text($w->{last_text}) if $w->{last_text};
    }

    $w->readonly(!$readonly);
    $w->set_binding( sub { toggle_editable($w, $cb) }, KEY_ENTER );
}

sub _create_ui_widgets {
    my $self = shift;
    my %widget_positions = (
        workspace_field => {
            -width => 18,
            -x     => 1,
        },
        page_field => {
            -width => 44,
            -x     => 32,
        },
        tag_field => {
            -width => 70,
            -x     => 1,
            -y     => 1,
            label_padding => 5,
        },
        modified_field => {
            -width => 18,
            -x     => 1,
            -y     => 2,
            label_padding => 1,
        },
        modifier_field => {
            -width => 39,
            -x     => 32,
            -y     => 2,
            label_padding => 1,
        },
        help_label => {
            -x => 1,
            -y => 3,
        },
        page_viewer => {
            -y => 4,
        },
    );
    
    my $win_width = $self->width;
#    if ($win_width < 110 and $win_width >= 80) {
#         $widget_positions{tag_field} = {
#             -width => 18,
#             -x     => 1,
#             -y     => 1,
#             label_padding => 6,
#         };
#         $widget_positions{help_label} = {
#             -x => 32,
#             -y => 1,
#         };
#         $widget_positions{page_viewer}{-y} = 2;
#     }

    #######################################
    # Create the Workspace label and field
    #######################################
    my $wksp_cb = sub { toggle_editable( shift, \&workspace_change ) };
    $self->{cb}{workspace} = $wksp_cb;
    $self->{workspace_box} = $self->add_field('Workspace:', $wksp_cb,
        -text => $App->{rester}->workspace,
        %{ $widget_positions{workspace_field} },
    );

    #######################################
    # Create the Page label and field
    #######################################
    my $page_cb = sub { toggle_editable( shift, sub { $App->load_page } ) };
    $self->{cb}{page} = $page_cb;
    $self->{page_box} = $self->add_field('Page:', $page_cb,
        %{ $widget_positions{page_field} },
    );

    #######################################
    # Create the Tag label and field
    #######################################
    my $tag_cb = sub { return };
    $self->{cb}{tag} = $tag_cb;
    $self->{tag_box} = $self->add_field('Tags:', $tag_cb,
        %{ $widget_positions{tag_field} },
    );

    #######################################
    # Create the modified label and field
    #######################################
    my $modified_cb = sub { return };
    $self->{cb}{modified} = $modified_cb;
    $self->{modified_box} = $self->add_field('Modified:', $modified_cb,
        %{ $widget_positions{modified_field} },
    );

    #######################################
    # Create the modifier label and field
    #######################################
    my $modifier_cb = sub { return };
    $self->{cb}{modifier} = $modifier_cb;
    $self->{modifier_box} = $self->add_field('Modifier:', $modifier_cb,
        %{ $widget_positions{modifier_field} },
    );

    $self->add(undef, 'Label',
        -bold => 1,
        -text => "Help: hit '?'",
        %{ $widget_positions{help_label} },
    );

    #######################################
    # Create the page Viewer
    #######################################
    $self->{viewer} = $self->add(
        'viewer', 'TiddlyWeb::Wikrad::PageViewer',
        -border => 1,
        %{ $widget_positions{page_viewer} },
    );
}

sub listbox {
    my $self = shift;
    $App->{win}->add('listbox', 'TiddlyWeb::Wikrad::Listbox', @_)->focus;
}

sub add_field {
    my $self = shift;
    my $desc = shift;
    my $cb = shift;
    my %args = @_;
    my $x = $args{-x} || 0;
    my $y = $args{-y} || 0;
    my $label_padding = $args{label_padding} || 0;

    $self->add(undef, 'Label',
        -bold => 1,
        -text => $desc,
        -x => $x,
        -y => $y,
    );
    $args{-x} = $x + length($desc) + 1 + $label_padding;
    my $w = $self->add(undef, 'TextEntry', 
        -singleline => 1,
        -sbborder => 1,
        -readonly => 1,
        %args,
    );
    $w->set_binding( sub { $cb->($w) }, KEY_ENTER );
    return $w;
}

sub read_config {
    my $self = shift;
    my $file = "$ENV{HOME}/.wikradrc";

    return unless -r $file;
    $self->{config} = YAML::LoadFile($file);
}

1;
