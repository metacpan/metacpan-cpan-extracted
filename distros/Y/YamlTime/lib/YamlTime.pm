# TODO:
# - Write::Excel reporting plugin
# - Git plugin
# - Add option to round numbers

package YamlTime;
our $VERSION = '0.19';

# Requires
BEGIN { $ENV{PERL_RL} = 'Gnu o=0' }
use Mouse;
use MouseX::App::Cmd;

use Capture::Tiny;
use DateTime::Format::Natural;
use File::ShareDir;
use Term::ReadLine;
use Text::CSV_XS;
use Text::ParseWords;

#-----------------------------------------------------------------------------#
# package YamlTime::Extension;
#-----------------------------------------------------------------------------#
package YamlTime::Command;
use App::Cmd::Setup -command;
use Mouse;
extends qw[MouseX::App::Cmd::Command];

use IO::All;
use Cwd qw[cwd abs_path];
# use XXX;

# _ keeps these from becoming cli options
has _conf => (
    is => 'ro',
    lazy => 1,
    reader => 'conf',
    builder => sub {
        my ($self) = @_;
        return $YamlTime::Conf =
            YamlTime::Conf->new(base => $self->base);
    },
);
has _base => (
    is => 'ro',
    reader => 'base',
    default => sub {
        my $base =
            $ENV{YAMLTIME_BASE} ? $ENV{YAMLTIME_BASE} :
            -d "$ENV{HOME}/.yamltime/" ? "$ENV{HOME}/.yamltime/" :
            '.';
        $base =~ s!/+$!!;
        return abs_path $base;
    },
);

# Not validating any args. Checking the working environment.
sub validate_args {
    my ($self) = @_;
    my $base = $self->base;
    chdir $base
        or $self->error__cant_chdir_base;
    if (ref($self) !~ /::init$/) {
        $self->error__not_init
            unless -e 'conf' and glob('20*');
        $self->conf;
    }
}

# Semi-brutal hack to suppress extra options I don't care about.
around usage => sub {
    my $orig = shift;
    my $self = shift;
    my $opts = $self->{usage}->{options};
    @$opts = grep { $_->{name} ne 'help' } @$opts;
    return $self->$orig(@_);
};

#-----------------------------------------------------------------------------#
package YamlTime;
use App::Cmd::Setup -app;
use Mouse;
extends 'MouseX::App::Cmd';

use Module::Pluggable
  require     => 1,
  search_path => [ 'YamlTime' ];
YamlTime->plugins;

use YamlTime::Conf;
use YamlTime::Task;

# Global pointer to the YamlTime::Conf singleton object.
our $Conf;

# App::Cmd help helpers
use constant usage => 'YamlTime';
use constant text => "yt command [<options>] [<arguments>]\n";

sub default_args {
    my $default = $ENV{YAMLTIME_DEFAULT_ARGS} or return [];
    return [ Text::ParseWords::shellwords($default) ];
}

#-----------------------------------------------------------------------------#
# A role for time/tag range options
#-----------------------------------------------------------------------------#
package YamlTime::RangeOpts;
use Mouse::Role;

my $time = time;

has from => (
    is => 'ro',
    isa => 'Str',
    default => 0,
    documentation =>
        'Range start date/time (natural format) default(midnight)',
);
has to => (
    is => 'ro',
    isa => 'Str',
    default => 0,
    documentation =>
        'Range end date/time (natural format) default(now)',
);
has tags => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub{[]},
    documentation =>
        'Comma separated tags. Can be used more than once',
    trigger => sub {
        my ($self, $new, $old) = @_;
        $self->{tags} = [
            map {
                [ split /\s*,\s*/ ]
            } @$new
        ];
    },
);

#-----------------------------------------------------------------------------#
# YamlTime (yt) Commands
#
# This is the set of App::Cmd classes that support each command.
#-----------------------------------------------------------------------------#
package YamlTime::Command::init;
YamlTime->import( -command );
use Mouse;
extends qw[YamlTime::Command];

use constant abstract => 'Initialize a new YamlTime store directory';
use constant usage_desc => 'yt init [--force]';

has force => (
    is => 'ro',
    isa => 'Bool',
    documentation => 'Force an init operation',
);

sub execute {
    my ($self, $opt, $args) = @_;
    if ($self->empty_directory or $self->force) {
        my $share = $self->share;
        $self->copy_files("$share/conf", "./conf");
        mkdir($self->date('now')->year);
    }
    else {
        $self->error__wont_init;
    }

    $self->log(sprintf "Initialized YamlTime directory: %s", $self->base);
    $self->log("\nNow edit the conf files and run 'yt help'.")
}

#-----------------------------------------------------------------------------#
package YamlTime::Command::new;
use Mouse;
YamlTime->import( -command );
extends qw[YamlTime::Command];

use constant abstract => 'Create a new task and start the timer';
use constant usage_desc => 'yt new ["Task description"]';

sub execute {
    my ($self, $opt, $args) = @_;
    $self->error__already_in_progress
        if $self->current_task and
            $self->current_task->in_progress;

    my $task = YamlTime::Task->new(id => undef);
    $self->populate($task, $args);
    $task->start;

    $self->log(sprintf "Started task %s.", $task->id);
    $self->log("\nGet to work!")
        unless $self->conf->be_serious;
}

#-----------------------------------------------------------------------------#
package YamlTime::Command::stop;
use Mouse;
YamlTime->import( -command );
extends qw[YamlTime::Command];

use constant abstract => 'Stop the timer on a running task';
use constant usage_desc => 'yt stop';

sub execute {
    my ($self, $opt, $args) = @_;
    my $task = $self->current_task or
        $self->error__no_current_task;
    $self->error__not_in_progress
        unless $task->in_progress;

    $task->stop;
    $self->log(sprintf "Stopped task %s. Time: %s", $task->id, $task->elapsed);
    $self->log("\nSTOP! ... YAML TIME!")
        unless $self->conf->be_serious;
}

#-----------------------------------------------------------------------------#
package YamlTime::Command::go;
use Mouse;
YamlTime->import( -command );
extends qw[YamlTime::Command];

use constant abstract => 'Restart the timer on a task';
use constant usage_desc => 'yt go [<task-id>]';

sub execute {
    my ($self, $opt, $args) = @_;
    my $id = $args->[0];
    my $task = $self->get_task(@$args)
        or $self->error__no_current_task;
    $self->error__already_in_progress
        if $task->in_progress;

    $task->start;
    $self->log(sprintf "Restarted task %s - %s.", $task->id, $task->task);
    $self->log("\nGet back to work!")
        unless $self->conf->be_serious;
}

#-----------------------------------------------------------------------------#
package YamlTime::Command::status;
use Mouse;
YamlTime->import( -command );
extends qw[YamlTime::Command];
with 'YamlTime::RangeOpts';

use constant abstract => 'Show the status of a range of tasks';
use constant usage_desc => do { $_ = <<'...'; chomp; $_ };
yt                      # today's tasks
yt status [<task-ids>]
yt status [--from=...] [--to=...]
...

sub execute {
    my ($self, $opt, $args) = @_;
    my $total = 0;
    for my $task ($self->get_task_range(@$args)) {
        if ($task->elapsed =~ /^(\d+):(\d+)$/) {
            $total += $1 * 60 + $2;
        }
        printf "%1s %12s %5s  %s\n",
            ($task->in_progress ? '+' : '-'),
            $task->id,
            $task->elapsed,
            $task->task;
    }
    my $hours = int($total / 60);
    my $mins = $total % 60;
    printf ' ' x 11 . "Total: % 2d:%02d\n", $hours, $mins
        if $total;
}

#-----------------------------------------------------------------------------#
package YamlTime::Command::check;
use Mouse;
YamlTime->import( -command );
extends qw[YamlTime::Command];
with 'YamlTime::RangeOpts';
use IO::All;

use constant abstract => 'Check the validity of a range of tasks';
use constant usage_desc => 'yt check [--verbose] [--from=...] [--to=...]';

has verbose => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    documentation => 'Increase output verbosity',
);

sub execute {
    my ($self, $opt, $args) = @_;
    my $errors = 0;
    for my $task ($self->get_task_range(@$args)) {
        my @errors = $task->check;
        if (@errors) {
            $errors++;
            printf "\n%s - found errors:\n", $task->id;
            my $dump = YAML::XS::Dump \@errors;
            $dump =~ s/^---\n//;
            my $text = io($task->id)->all;
            $text =~ s/^/    |/gm;
            print $dump, $text;
        }
        elsif ($self->verbose) {
            printf "%s - no errors found\n", $task->id;
        }
    }
    if ($self->verbose and not $errors) {
        print "No errors found\n";
    }
}

#-----------------------------------------------------------------------------#
package YamlTime::Command::report;
use Mouse;
YamlTime->import( -command );
extends 'YamlTime::Command';
with 'YamlTime::RangeOpts';
use Text::CSV_XS;
use Cwd qw[abs_path];

use constant abstract => 'Produce a billing report from a range of tasks';
use constant usage_desc => 'yt report [--file=...] [--from=...] [--to=...]';

has file => (
    is => 'ro',
    isa => 'Str',
    default => abs_path('report.csv'),
    documentation => 'Name of file to write the report to',
);

sub execute {
    my ($self, $opt, $args) = @_;
    my $report_file = $self->file;
    my $csv = Text::CSV_XS->new ({ binary => 1 }) or die;
    $csv->eol ("\r\n");
    open my $fh, ">:encoding(utf8)", $report_file or die "new.csv: $!";
    $csv->print(
        $fh,
        [qw(Date Time Hours Project Task Tags Refs Notes)]
    );
    for my $task ($self->get_task_range(@$args)) {
        $task->id =~ m!^(.*)/(\d\d)(\d\d)$! or die $task->id;
        my $date = $1;
        my $time = "$2:$3";
        my $row = [
            $date,
            $time,
            $task->time,
            $task->proj,
            $task->task,
            join(', ', @{$task->tags}),
            join(', ', @{$task->refs}),
            $task->note || '',
        ];
        $csv->print ($fh, $row);
    }
    close $fh or die "report.csv: $!";
    print "Created $report_file\n";
}

#-----------------------------------------------------------------------------#
package YamlTime::Command::edit;
use Mouse;
YamlTime->import( -command );
extends qw[YamlTime::Command];

use constant abstract => 'Edit a task\'s YAML in $EDITOR';
use constant usage_desc => 'yt edit [<task-id>]';

sub execute {
    my ($self, $opt, $args) = @_;
    my $editor = $ENV{EDITOR}
        or $self->error('You need to set $EDITOR env var to edit');
    my $task = $self->get_task(@$args)
        or $self->error("No task to edit");
    exec $editor . " " . $task->id;
}

#-----------------------------------------------------------------------------#
package YamlTime::Command::base;
use Mouse;
YamlTime->import( -command );
extends qw[YamlTime::Command];
use IO::All;

use constant abstract => 'Print the YamlTime base directory to STDOUT';
use constant usage_desc => 'yt base';

sub execute {
    my ($self, $opt, $args) = @_;
    print $self->base . "\n";
}

#-----------------------------------------------------------------------------#
package YamlTime::Command::dump;
use Mouse;
YamlTime->import( -command );
extends qw[YamlTime::Command];
use IO::All;

use constant abstract => 'Print a task file to STDOUT';
use constant usage_desc => 'yt dump [<task-id>]';

sub execute {
    my ($self, $opt, $args) = @_;
    my $task = $self->get_task(@$args)
        or $self->error("No task to dump");
    print io($task->id)->all;
}

#-----------------------------------------------------------------------------#
package YamlTime::Command::create;
use Mouse;
YamlTime->import( -command );
extends qw[YamlTime::Command];

use constant abstract => 'Create a new task for a particular date/time';
use constant usage_desc => 'yt create <new-task-id>';

sub execute {
    my ($self, $opt, $args) = @_;
    $self->error("Requires a task-id of the form '2011/12/31/1234'")
        unless @$args == 1 and $args->[0] =~ m!^(20\d\d/\d\d/\d\d/\d\d\d\d)$!;
    my $id = $args->[0];
    my $task = $self->get_task($id);
    $self->error("Task '$id' already exists")
        if $task->exists;

    $self->populate($task, []);
    $task->write;

    $self->log("Created task $id");
}

#-----------------------------------------------------------------------------#
package YamlTime::Command::delete;
use Mouse;
YamlTime->import( -command );
extends qw[YamlTime::Command];

use constant abstract => 'Delete an entry by task-id';
use constant usage_desc => 'yt delete <task-id>';

sub execute {
    my ($self, $opt, $args) = @_;

    my $id = $args->[0];
    $self->error("'yt delete' require a single task-id") if
        @$args != 1 or
        $id !~ m!^20\d{2}/\d{2}/\d{2}/\d{4}! or
        not(-f $id);

    my $task = $self->get_task($id);

    $self->error("'$id' is in progress. Run 'stop' first")
        if $task->in_progress;

    $task->delete();
}

#-----------------------------------------------------------------------------#
# Guts of the machine
#-----------------------------------------------------------------------------#
package YamlTime::Command;

sub run {
    my ($self, $cmd, $options) = @_;
    my $error;
    my $output = Capture::Tiny::capture_merged {
        system($cmd) == 0 or $error = 1;
    };
    print $output;
    if ($error) {
        return 0;
    }
    return 1;
}

sub current_task {
    my ($self) = @_;
    return $self->get_task;
}

sub get_task {
    my ($self, $id) = @_;
    $id ||= readlink('_') or return;
    return YamlTime::Task->new(id => $id);
}

sub get_task_range {
    my $self = shift;
    my @files;
    if (@_) {
        @files = @_;
    }
    else {
        my $from = $self->format_date($self->from || 'today');
        my $to = $self->format_date($self->to || 'now');
    OUTER:
        for my $dir (sort grep /^20\d\d$/, glob("20*")) {
            for my $file (sort map $_->name, -d $dir ? io->dir($dir)->All_Files : ()) {
                next if $file lt $from;
                last OUTER if $file gt $to;
                push @files, $file;
            }
        }
    }
    return grep {
        $self->match_tags($_);
    } map {
        $self->get_task($_);
    } sort @files;
}

sub match_tags {
    my ($self, $task) = @_;
    my $want = $self->tags;
    return 1 unless @$want;
    my $have = $task->tags;
    return 0 unless @$have;
  OUTER:
    for my $w (@$want) {
        for my $t (@$w) {
            next OUTER unless grep {$_ eq $t} @$have;
        }
        return 1;
    }
    return 0;
}

sub format_date {
    my ($self, $str) = @_;
    my $date = DateTime::Format::Natural->new(
        time_zone => $self->conf->timezone,
    )->parse_datetime($str);
    return sprintf "%4d/%02d/%02d/%02d%02d",
        $date->year,
        $date->month,
        $date->day,
        $date->hour,
        $date->minute;
}

my $date_parser = DateTime::Format::Natural->new;

sub date {
    my ($self, $string) = @_;
    return eval {
        $date_parser->parse_datetime($string);
    } || undef;
}

sub empty_directory {
    io('.')->empty;
}

sub share {
    my $class = shift;
    my $path = $INC{'YamlTime.pm'} or die;
    if ($path =~ s!(\S.*?)[\\/]?\bb?lib\b.*!$1! and
        -e "$path/Makefile.PL" and
        -e "$path/share"
    ) {
        return abs_path "$path/share";
    }
    else {
        return File::ShareDir::dist_dir('YamlTime');
    }
}

sub copy_files {
    my ($self, $source, $target) = @_;
    for my $file (io($source)->All_Files) {
        my $short = $file->name;
        $short =~ s!^\Q$source\E/?!! or die $short;
        next if $short =~ /^\./;
        io("$target/$short")->assert->print($file->all);
    }
}

my $prompts = {
    task => 'Task Description: ',
    cust => 'Customer Id: ',
    tags => 'A Tag Word: ',
    proj => 'Project Id: ',
};

sub prompt {
    my ($self, $key, $default, $task) = @_;
    my $prompt = $prompts->{$key};
    my $term = new Term::ReadLine 'YamlTime';
    $term->Attribs->{completion_function} = sub{
        return sort keys %{$self->conf->{$key}}
            if $key =~ /^(cust|tags)$/;
        return sort keys %{$self->conf->{proj}{$task->{cust}}}
            if $key =~ /^(proj)$/;
        return ();
    };
    my $val = $term->readline($prompt, $default);
    exit unless defined $val;
    $val =~ s/\A\s*(.*?)\s*\z/$1/s;
    $term->addhistory($val) if $val =~ /\S/;

    return $val;
}

# Prompt the user for the info needed in a task
sub populate {
    my ($self, $task, $args) = @_;
    my $old = $self->current_task || {};
    $task->{task} = join ' ', @$args if @$args;
    for my $key (qw[task cust proj tags]) {
        my $val = $task->$key;
        my $list = ref($val);
        my $default = $list ? '' : ($task->{$key} || $old->{$key});
        while (1) {
            my $new_val = $self->prompt($key, $default, $task);

            if (not length $new_val) {
                if ($key =~ /^(task|cust)$/) {
                    warn "    Required field.\n";
                    next;
                }
                else {
                    last;
                }
            }
            elsif ($key =~ /^(cust|tags)$/) {
                if (not exists $self->conf->{$key}{$new_val}) {
                    warn "    '$new_val' is invalid.\n";
                    next;
                }
            }
            elsif ($key =~ /^(proj)$/) {
                if (not exists $self->conf->{proj}{$task->{cust}}{$new_val}) {
                    warn "    '$new_val' is invalid.\n";
                    next;
                }
            }

            if ($list) {
                push @$val, $new_val;
            }
            else {
                $task->$key($new_val);
                last;
            }
        }
    }
}

sub log {
    my $self = shift;
    print "@_\n";
}

#-----------------------------------------------------------------------------#
# Errors happen
sub error {
    my ($self, $msg) = splice(@_, 0, 2);
    chomp $msg;
    $msg .= $/;
    die sprintf($msg, @_);
}

sub error__cant_chdir_base {
    my ($self) = @_;
    my $base = $self->base;
    $self->error(<<"...");
Can't chdir to '$base'.
YAMLTIME_BASE is set to '$base',
but it does not yet exist. You should create it and rerun your command.
...
}

sub error__not_init {
    my ($self) = @_;
    my $base = $self->base;
    if ($ENV{YAMLTIME_BASE} or $self->empty_directory) {
        $self->error(<<"...");
'$base' not yet initialized.
Run 'yt init'.
...
    }
    else {
        $self->error(<<"...");
'$base' is not a yt directory and it's not empty.

You should mkdir and cd into a new directory, or set the YAMLTIME_BASE
environment variable to such a directory.
...
    }
}

sub error__wont_init {
    my ($self) = @_;
    $self->error(
        "Won't 'init' in a non empty directory, unless you use --force"
    );
}

sub error__already_in_progress {
    my ($self) = @_;
    $self->error(<<'...');
Command invalid.
A task is already in progress.
Stop the current one first.
...
}

sub error__not_in_progress {
    my ($self) = @_;
    $self->error(<<'...');
Command invalid.
There is no task is currently in progress.
...
}

sub error__no_current_task {
    my ($self) = @_;
    $self->error(<<'...');
Command invalid.
There is no current task.
You may need to specify one.
...
}

1;
