package TiddlyWeb::Wikrad;
use strict;
use warnings;
use Curses::UI;
use Carp qw/croak/;
use File::Path qw/mkpath/;
use base 'Exporter';
our @EXPORT_OK = qw/$App/;

our $VERSION = '0.9';

=head1 NAME

TiddlyWeb::Wikrad - efficient wiki browsing and editing

=head1 SYNOPSIS

  my $app = TiddlyWeb::Wikrad->new(rester => $rester);
  $app->set_page( $starting_page );
  $app->run;

=cut

our $App;

sub new {
    my $class = shift;
    $App = { 
        history => [],
        save_dir => "$ENV{HOME}/wikrad",
        @_ ,
    };
    die 'rester is mandatory' unless $App->{rester};
    $App->{rester}->agent_string("wikrad/$VERSION");
    bless $App, $class;
    $App->_setup_ui;
    return $App;
}

sub run {
    my $self = shift;

    my $quitter = sub { exit };
    $self->{cui}->set_binding( $quitter, "\cq");
    $self->{cui}->set_binding( $quitter, "\cc");
    $self->{win}{viewer}->set_binding( $quitter, 'q');

    $self->{cui}->reset_curses;
    $self->{cui}->mainloop;
}

sub save_dir { 
    my $self = shift;
    my $dir = $self->{save_dir};
    unless (-d $dir) {
        mkpath $dir or die "Can't mkpath $dir: $!";
    }
    return $dir;
}

sub set_page {
    my $self = shift;
    my $page = shift;
    my $workspace = shift;
    my $no_history = shift;

    my $pb = $self->{win}{page_box};
    my $wksp = $self->{win}{workspace_box};

    unless ($no_history) {
        push @{ $self->{history} }, {
            page => $pb->text,
            wksp => $wksp->text,
            pos  => $self->{win}{viewer}{-pos},
        };
    }
    $self->set_workspace($workspace) if $workspace;
    $pb->text($page);
    $self->load_page;
}

sub download {
    my $self = shift;
    my $current_page = $self->{win}{page_box}->text;
    $self->{cui}->leave_curses;

    my $r = $self->{rester};
    
    my $dir = $self->_unique_filename($current_page);
    mkdir $dir or die "Error creating directory $dir: $!";

    my %ct = (
        html => 'text/html',
        wiki => 'text/plain',
    );

    while (my ($ext, $ct) = each %ct) {
        $r->accept($ct);
        my $file = "$dir/content.$ext";
        open my $fh, ">$file" or die "Can't open $file: $!";
        print $fh $r->get_page($current_page);
        close $fh or die "Can't open $file: $!";
    }
}

sub _unique_filename {
    my $self = shift;
    my $original = shift;
    my $filename = $original;
    my $i = 0;
    while (-e $filename) {
        $i++;
        $filename = "$original.$i";
    }
    return $filename;
}

sub set_workspace {
    my $self = shift;
    my $wksp = shift;
    $self->{win}{workspace_box}->text($wksp);
    $self->{rester}->workspace($wksp);
}

sub go_back {
    my $self = shift;
    my $prev = pop @{ $self->{history} };
    if ($prev) {
        $self->set_page($prev->{page}, $prev->{wksp}, 1);
        $self->{win}{viewer}{-pos} = $prev->{pos};
    }
}

sub get_page {
    return $App->{win}{page_box}->text;
}

sub load_page {
    my $self = shift;
    my $current_page = $self->{win}{page_box}->text;

    if (! $current_page) {
        $self->{cui}->status('Fetching list of pages ...');
        $self->{rester}->accept('text/plain');
        $self->{rester}->count(250);
        $self->{rester}->order('-modified');
        my @pages = $self->{rester}->get_pages;
        $self->{rester}->count(0);
        $self->{rester}->order('');
        $self->{cui}->nostatus;
        $App->{win}->listbox(
            -title => 'Choose a page',
            -values => \@pages,
            change_cb => sub {
                my $page = shift;
                $App->set_page($page) if $page;
            },
        );
        return;
    }

    $self->{cui}->status("Loading page $current_page ...");
    $self->{rester}->accept('perl_hash');
    my $page = $self->{rester}->get_page($current_page);
    $self->{cui}->nostatus;
    $self->{win}{tag_box}->text(join(', ', @{$page->{tags}}));
    $self->{win}{modified_box}->text($page->{modified});
    $self->{win}{modifier_box}->text($page->{modifier});
    $self->{win}{viewer}->text($page->{text});
    $self->{win}{viewer}->cursor_to_home;
}

sub _setup_ui {
    my $self = shift;
    $self->{cui} = Curses::UI->new( -color_support => 1 );
    $self->{win} = $self->{cui}->add('main', 'TiddlyWeb::Wikrad::Window');
    $self->{cui}->leave_curses;
}

1;
