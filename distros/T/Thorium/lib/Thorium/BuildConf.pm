package Thorium::BuildConf;
{
  $Thorium::BuildConf::VERSION = '0.510';
}
BEGIN {
  $Thorium::BuildConf::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Configuration management class

use Thorium::Protection;

BEGIN {

    # these environment variables influence how dialog returns exit codes, and
    # other options which may cause unwanted side effects, so delete them to
    # avoid any unwanted side effects
    foreach my $v (
        qw(DIALOGOPTS DIALOG_CANCEL DIALOG_ERROR DIALOG_ESC
        DIALOG_EXTRA DIALOG_HELP DIALOG_ITEM_HELP DIALOG_OK)
      ) {
        delete($ENV{$v});
    }
}

use Moose;
use Moose::Util::TypeConstraints qw(enum);

with qw(Thorium::Roles::Logging);

# core
use File::Basename qw();
use File::Spec qw();
use FindBin qw();
use Getopt::Long qw();
use Scalar::Util qw();

# CPAN
use Class::MOP qw();
use File::Find::Rule;
use Hobocamp::Dialog;
use Hobocamp;
use IO::Interactive qw();
use Template;
use Try::Tiny;

# local
use Thorium::SystemInfo;
use Thorium::Types qw(:all);

has 'conf_type' => (
    'isa'           => 'Str',
    'is'            => 'rw',
    'required'      => 1,
    'documentation' => 'Class name of the Thorium::Conf based configuration object.'
);

has 'files' => (
    'isa'           => 'ArrayRef|Str',
    'is'            => 'rw',
    'required'      => 1,
    'documentation' => 'String or list of files to be processed (Template Toolkit format).'
);

has 'root' => (
    'isa'           => 'Str',
    'is'            => 'rw',
    'default'       => $FindBin::Bin,
    'documentation' => 'Directory root of the configuration files.'
);

has 'conf' => (
    'isa'           => 'Any',
    'is'            => 'rw',
    'documentation' => 'Reference to configuration object (Thorium::Conf or a sub-class of Thorium::Conf).'
);

has 'preset' => (
    'isa'           => 'Str',
    'is'            => 'rw',
    'documentation' => 'Full file path to the preset.'
);

has 'preset_path' => (
    'isa'           => 'ArrayRef',
    'is'            => 'ro',
    'default'       => sub { [ 'conf', 'presets' ] },
    'documentation' => q(Relative directory path to the presets from root e.g. ['conf','presets'].)
);

has 'preset_root' => (
    'isa'     => 'Str',
    'is'      => 'rw',
    'default' => '',
    'documentation' =>
      'Directory root of the presets e.g. $self->root + "conf/presets". Normally built with root + preset_path.'
);

has 'action' => (
    'isa'           => enum([qw(load list save preview)]),
    'is'            => 'rw',
    'documentation' => 'Action type as set via configure command line options. Either load, list or save.'
);

has 'fixup' => (
    'isa'           => 'Str',
    'is'            => 'rw',
    'documentation' => 'Fixup class name.'
);

has 'auto_fixup_module' => (
    'isa'           => 'Str',
    'is'            => 'rw',
    'documentation' => 'Pre-template process fixup class name.'
);

has 'is_interactive' => (
    'isa'           => 'Bool',
    'is'            => 'rw',
    'lazy'          => 1,
    'default'       => sub { IO::Interactive::is_interactive },
    'documentation' => 'Whether or not we are connected to a terminal that accepts standard in.'
);

has 'in_gui' => (
    'isa'           => 'Bool',
    'is'            => 'rw',
    'default'       => 0,
    'documentation' => 'Whether or not we are using the based console GUI.'
);

has 'script_name' => (
    'isa'           => 'Str',
    'is'            => 'ro',
    'default'       => sub { File::Basename::basename($FindBin::RealScript) },
    'documentation' => 'File name of the script that instantiated us.'
);

has 'type' => (
    'isa'           => 'Str',
    'is'            => 'ro',
    'default'       => '?',
    'documentation' => 'Component type.'
);

has 'knobs' => (
    'isa'           => 'ArrayRef[Any]',
    'is'            => 'ro',
    'default'       => sub { [] },
    'documentation' => 'List of knob objects.'
);

sub _print_to_stdout {
    my (@msg) = @_;

    if (-t STDOUT) {
        say(@msg);
    }
}

sub BUILD {
    my ($self) = @_;

    $self->preset_root(File::Spec->catfile($self->root, @{$self->preset_path}));

    my %opts;
    Getopt::Long::GetOptions(\%opts, qw(verbose:1 help load=s list fixup:s preview!)) or $self->usage();

    $self->usage() if (exists($opts{'help'}));

    try {
        Class::MOP::load_class($self->conf_type);
    }
    catch {
        my $error = $_;

        my $msg = 'Failed to load ' . $self->conf_type . ' with error: ' . $error;
        $self->log->error($msg);
        die($msg);
    };

    if ($self->conf_type) {
        $self->conf($self->conf_type->new);
        my $objref = $self->conf;
        $self->log->trace('New configuration object of type ', $self->conf_type, ' at ',
            Scalar::Util::refaddr($objref));
    }

    if ($opts{'load'}) {
        my $preset_file_name = File::Spec->catfile($self->preset_root, $opts{'load'} . '.yaml');

        unless (-e -r -s $preset_file_name) {
            my $msg = "$preset_file_name does not exist, is not readable or is 0 bytes in size.";
            $self->log->error($msg);
            die($msg);
        }

        $self->preset($preset_file_name);

        $self->is_interactive(0);
        $self->action('load');
    }
    elsif ($opts{'list'}) {
        $self->action('list');
    }
    elsif ($opts{'save'}) {
        $self->action('save');
        $self->preset($opts{'save'});
    }
    elsif ($opts{'preview'}) {
        $self->action('preview');
    }

    if ($opts{'fixup'}) {
        $self->fixup($opts{'fixup'});
    }

    return;
}

sub _set_question_values {
    my ($self) = @_;

    my $qs = $self->knobs;

    foreach my $q (@{$qs}) {
        my $set_value;
        $set_value = $self->conf->data($q->conf_key_name);

        next if ($set_value =~ /^\.{3}$/);
        next unless ($set_value);

        $self->log->trace('setting value to ', $set_value);
        $q->value($set_value);
    }
}

# applies changes from answered knobs to backing configuration object
sub _set_conf_values {
    my ($self) = @_;

    my $qs = $self->knobs;

    foreach my $q (@{$qs}) {
        my $set_value;
        given ($q->ui_type) {
            when ('Menu') {
                $set_value = $q->value || $q->data->[ $q->selected ]->{'name'};
            }
            when ('RadioList') {
                $set_value = $q->value || $q->data->[ $q->selected ]->{'name'};
            }
            default {
                $set_value = $q->value || $q->data;
            }
        }

        $self->log->trace('setting ', $q->name, ' to ', $set_value);
        $self->conf->set($q->conf_key_name, $set_value);
    }
}

sub save {
    my ($self, $filename) = @_;

    if ($filename) {
        $filename = $filename . '.yaml';
    }
    else {
        $filename = File::Spec->catfile($self->preset_root, '..', 'local.yaml');
    }

    return $self->conf->save($filename);
}

# A few notes:
#
# 1. Yes, at first glance this may look like spaghetti code with the liberal use
#    of labels, but given the global nature how dialog(1) deals with its
#    internal data and the desired simplicity for the configuration process this
#    was a deliberate choice. Otherwise a proper event loop would have been used
#
# 2. Showing multiple widgets on the screen at one time creates some problems as
#    you can not hide specific widgets, but only clear the entire screen. This
#    is due to dialog(1)s global data approach
#
# 3. In a perfect world, there would be only one GUI toolkit and only one
#    console UI toolkit that had no bugs and allowed us to write really great
#    software without common artifacts (clipping, wrapping, scaling, etc) in a
#    fraction of the time. Sadly, this isn't the case, but maybe it will be that
#    way in a thousand years, so until then, this is what we got.
#
# Glossary
#
# - value - user input
# - data - default data displayed in ui
sub ask {
    my ($self) = @_;

    return unless ($self->is_interactive);
    $self->in_gui(1);

    my $main_window = Hobocamp->new;
    $main_window->init;

    my $main_menu = Hobocamp::Menu->new(
        'title'       => $self->type . ' Configuration',
        'menu_height' => 12,
        'width'       => 75,
        'items'       => [
            {'name' => 'Configure', 'text' => 'Configure'},
            {'name' => '---',       'text' => '---'},
            {'name' => 'Load',      'text' => 'Load values from a given preset'},
            {'name' => 'Save',      'text' => 'Save to a preset file'},
            {'name' => 'List',      'text' => 'List available presets'},
            {'name' => '---',       'text' => '---'},
            {'name' => 'Help',      'text' => 'User guide'},
            {'name' => '---',       'text' => '---'},
            {'name' => 'Exit',      'text' => 'Exit'}
        ]
    );

    INTERACT: {
        my $state = $main_menu->run;

        given ($state) {
            when (
                $_ ~~ [
                    Hobocamp::Dialog::DLG_EXIT_ESC(),     Hobocamp::Dialog::DLG_EXIT_CANCEL(),
                    Hobocamp::Dialog::DLG_EXIT_UNKNOWN(), Hobocamp::Dialog::DLG_EXIT_ERROR()
                ]
              ) {
                last INTERACT;
            }
            when ($_ == Hobocamp::Dialog::DLG_EXIT_OK()) {
                $main_menu->hide;
            }
            default {
                $main_window->destroy;
                die("I don't know what the error code $_ is!");
            }
        }

        given ($main_menu->value->{'name'}) {
            when ('Introduction') {
                my $msg_box = Hobocamp::MessageBox->new(
                    'title'  => 'Welcome',
                    'prompt' => sprintf(
                        qq(Welcome!

Before configuring the %s component, there are a couple of things you should
know.

Keyboard and Mouse
==================

1. Use the tab key to used to change focus.
2. Use the arrow keys to select items.
3. If you're terminal supports it, you may be able to use the mouse to select
items and change focus.
4. To select items use the return key with the focus on the 'OK' button.

Keyboard Control From Directory or File Selection
=================================================

These are the most frustrating widgets to navigate in. The dialog(1) man page
explains how to use them

    Use tab or arrow keys to move between the windows.  Within the directory
    window, use the up/down arrow keys to scroll the current selection.  Use the
    space-bar to copy the current selection into the text-entry window.

    Typing any printable characters switches focus to the text-entry window,
    entering that character as well as scrolling the directory window to the
    closest match.

    Use a carriage return or the "OK" button to accept the current value in the
    text-entry window and exit.

Configuring and Saving
======================

Go to the 'Configure' option from the main menu. You will be taken to a menu of
configurable items. Choose the options you want to modify and select it. Upon
input of invalid data, an error message will be thrown and you should
re-input. The right column will contain the current value. When values are
complex data types (e.g. non-scalars) then their value will be represented as
'...'. When you are done, scroll to the bottom and choose 'Done'. Now you should
save your changes to a preset file from the 'Save' option in the main menu.

Loading
=======

When you want to load a preset, go to the 'Load' option from the main menu. Here
you will be presented with a list of available presets. Upon selection, the file
will be loaded and the template files will be processed. When successful a
dialog will pop up and notify you of which files were successfully
processed. This functionality is also available via the '--load <preset-name>'
option from configure.

), $self->type
                    )
                );
                $msg_box->run;
                $msg_box->hide;
            }
            when ('Configure') {
                my $qs = $self->knobs;

                unless (scalar(@{$qs})) {
                    my $em = Hobocamp::MessageBox->new(
                        'title'  => 'Error!',
                        'prompt' => 'There is nothing to configure, aborting!'
                    );
                    $em->run;
                    $em->hide;
                    redo INTERACT;
                }

                # set question defaults from config
                $self->conf->from($self->preset);
                $self->conf->reload;
                $self->_set_question_values;

                my $conf_menu;
                CONFIGURE: {
                    $conf_menu = Hobocamp::Menu->new(
                        'title'       => 'Configure',
                        'prompt'      => 'Select a parametere to configure',
                        'menu_height' => 12,
                        'width'       => 75
                    );

                    foreach my $q (@{$self->knobs}) {
                        my $value;
                        if ($q->value) {
                            if (ref($q->value)) {
                                $value = '...';
                            }
                            else {
                                $value = $q->value;
                            }
                        }
                        elsif ($q->data) {
                            if (ref($q->data)) {
                                $value = '...';
                            }
                            else {
                                $value = $q->data;
                            }
                        }

                        $conf_menu->add_item({'name' => $q->name, 'text' => $value});
                    }

                    $conf_menu->add_item({'name' => '---',  'text' => '---'});
                    $conf_menu->add_item({'name' => 'Done', 'text' => 'Exit this menu'});

                    my $state = $conf_menu->run;
                    my $q;
                    my $widget;

                    given ($state) {
                        when ($_ != Hobocamp::Dialog::DLG_EXIT_OK()) {
                            last CONFIGURE;
                        }
                    }

                    if ($conf_menu->value->{'name'} eq 'Done') {
                        $self->_set_conf_values;

                        last CONFIGURE;
                    }

                    # find what question the user requested
                    FIND_QUESTION: {
                        foreach my $cq (@{$self->knobs}) {
                            if ($cq->name eq $conf_menu->value->{'name'}) {
                                $q = $cq;
                                last FIND_QUESTION;
                            }
                        }
                    }

                    my $title = $q->conf_key_name;
                    my $default = $q->value || $q->data;

                    given ($q->ui_type) {
                        when ('DirectorySelect') {
                            $widget = Hobocamp::DirectorySelect->new(
                                'title'  => $title,
                                'prompt' => $q->question,
                                'path'   => $default
                            );
                        }
                        when ('FileSelect') {
                            $widget = Hobocamp::FileSelect->new(
                                'title'  => $title,
                                'prompt' => $q->question,
                                'path'   => $default
                            );
                        }
                        when ('InputBox') {
                            $widget = Hobocamp::InputBox->new(
                                'title'  => $title,
                                'prompt' => $q->question,
                                'init'   => $default
                            );
                        }
                        when ('Menu') {
                            $widget = Hobocamp::Menu->new(
                                'title'  => $title,
                                'prompt' => $q->question,
                                'items'  => $q->data
                            );
                        }
                        when ('RadioList') {
                            $widget = Hobocamp::RadioList->new(
                                'title'    => $title,
                                'subtitle' => $q->question,
                                'items'    => $q->data
                            );
                        }
                        default {
                            my $em = Hobocamp::MessageBox->new(
                                'title'  => 'Error',
                                'prompt' => "UI type $_ not yet supported. Consider adding it to Thorium::BuildConf."
                            );
                            $em->run;
                            $em->hide;
                        }
                    }

                    my $valid = 0;

                    until ($valid) {
                        my $valstate = $widget->run;

                        my $value;

                        given ($valstate) {
                            when ($_ != Hobocamp::Dialog::DLG_EXIT_OK()) {
                                redo CONFIGURE;
                            }
                        }

                        given ($q->ui_type) {
                            when ('CheckList') {
                                if ($widget->value) {
                                    $value = $widget->value;
                                }
                                else {
                                    $value = undef;
                                }
                            }
                            when ('Menu') {
                                if ($widget->value) {
                                    $value = $widget->value->{'name'};
                                }
                                else {
                                    $value = undef;
                                }
                            }
                            when ('RadioList') {
                                if ($widget->value) {
                                    $value = $widget->value->[0]->{'name'};
                                }
                                else {
                                    $value = undef;
                                }
                            }
                            default {
                                $value = $widget->value;
                            }
                        }

                        eval { $q->value($value); };

                        if (my $e = $@) {
                            my $filename = __FILE__;
                            $e =~ s/at $filename.*//sm;
                            $value //= 'undef';
                            my $em = Hobocamp::MessageBox->new(
                                'title'  => 'Error',
                                'prompt' => "Validation failed with user input: $value\n\nError: $e"
                            );
                            $em->run;
                        }
                        else {
                            $valid = 1;
                        }
                    }
                    redo CONFIGURE;
                }
                $conf_menu->hide;
            }
            when ('List') {
                my @presets = $self->list_presets;

                my @items;

                foreach my $preset (sort(@presets)) {
                    push(@items, {'name' => $preset, 'text' => ''});
                }

                my $menu = Hobocamp::Menu->new(
                    'title'       => 'Available Presets',
                    'menu_height' => 12,
                    'width'       => 55,
                    'items'       => \@items
                );

                $menu->run;
                $menu->hide;

                redo INTERACT;
            }
            when ('Load') {
                my @presets = $self->list_presets;

                my @items;

                foreach my $preset (@presets) {
                    push(@items, {'name' => $preset, 'text' => "Load $preset"});
                }

                my $menu = Hobocamp::Menu->new(
                    'title'       => 'Load A Preset',
                    'menu_height' => 12,
                    'width'       => 55,
                    'items'       => \@items
                );

                my $state = $menu->run;

                given ($state) {
                    when (
                        $_ ~~ [
                            Hobocamp::Dialog::DLG_EXIT_CANCEL(), Hobocamp::Dialog::DLG_EXIT_ESC(),
                            Hobocamp::Dialog::DLG_EXIT_ERROR(),  Hobocamp::Dialog::DLG_EXIT_UNKNOWN()
                        ]
                      ) {
                        $menu->hide;
                        redo INTERACT;
                    }
                }

                $self->conf->_delete_local;
                $self->conf->from(File::Spec->catfile($self->preset_root, $menu->value->{'name'} . '.yaml'));
                $self->conf->reload;

                $self->save;

                my @processed = $self->process;

                my $msg;
                if (@processed) {
                    $msg = Hobocamp::MessageBox->new(
                        'title'  => 'Successfully Processed',
                        'prompt' => "Successfully processed:\n\n"
                          . join(", ", map { File::Basename::basename($_) . "\n" } @processed)
                    );
                }
                else {
                    $msg = Hobocamp::MessageBox->new(
                        'title'  => 'Failed Processing',
                        'prompt' => "Failed to process:\n\n"
                          . join(", ", map { File::Basename::basename($_) . "\n" } @processed)
                    );
                }

                $msg->run;
                $msg->hide;

                $menu->hide;

                redo INTERACT;
            }
            when ('Save') {
                $self->_set_conf_values;

                my $preset_name_input = Hobocamp::InputBox->new(
                    'title' => 'Preset Name',
                    'prompt' =>
qq(What do you want to name this preset? You don't need to include the .yaml extension or a full path)
                );

                $preset_name_input->run;
                $preset_name_input->hide;

                my $preset_name = $preset_name_input->value;

                $preset_name =~ s/\.yaml$//;

                my $files_saved = $self->save(File::Spec->catfile($self->preset_root, $preset_name));

                my $msgbox;
                if ($files_saved == 1) {
                    $msgbox = Hobocamp::MessageBox->new(
                        'title'  => "Saved",
                        'prompt' => "Successfully saved the $preset_name preset."
                    );
                }
                else {
                    $msgbox = Hobocamp::MessageBox->new(
                        'title'  => "Error",
                        'prompt' => "Failed to saved the $preset_name preset. Check there is write permission to "
                          . $self->preset_root
                    );
                }

                $msgbox->run;
                $msgbox->hide;

                redo INTERACT;
            }
            when ('Exit') {
                last INTERACT;
            }
        }
        redo INTERACT;
    }

    $main_window->destroy;

    $self->in_gui(0);

    return;
}

sub process {
    my ($self, $preview_flag) = @_;

    my $fs = $self->files;

    unless (ref($fs)) {
        $fs = [$fs];
    }

    {
        my $saveout;

        if ($self->in_gui) {
            open($saveout, ">&STDOUT");
            open(STDOUT, '>', File::Spec->devnull);
        }

        if ($self->auto_fixup_module) {

            # 'Staging' and 'Production' are special case fixups we don't want any
            # autoset magic to apply to

            my $production = 0;

            if ($self->fixup) {
                $production = ($self->fixup =~ /(?:Staging|Production)/);
            }

            unless ($production) {
                $self->apply_fixup($self->auto_fixup_module);
            }
        }

        if ($self->in_gui) {
            open(STDOUT, ">&", $saveout);
        }
    }

    if ($self->fixup) {
        $self->apply_fixup($self->fixup);
    }

    my $vars = $self->conf->data;

    my $i = Thorium::SystemInfo->new;

    # Add in system information that we only be useful to the template and not
    # in the component configuration
    $vars->{'system_info'}->{'eth0_ipv4'} = $i->eth0_ipv4;

    my @processed;

    foreach my $file (@{$fs}) {
        my $template = Template->new(
            {
                'ABSOLUTE' => 1,
                'STRICT'   => 1
            }
        );

        my ($output, $output_file);

        unless ($preview_flag) {
            $file = File::Spec->catfile($self->root, $file);

            $output_file = $file;
            $output_file =~ s/\.tt2$//;

            # remove the file before operating on it as it most likely exists and
            # set to 0444
            unlink($output_file);

            $output = $output_file;
        }

        unless ($template->process($file, $vars, $preview_flag ? \$output : $output)) {
            $self->log->error($template->error);
            if ($self->in_gui) {
                my $em = Hobocamp::MessageBox->new(
                    'title'  => 'Template Toolkit Error',
                    'prompt' => $file . ": \n\n" . $template->error->as_string
                );
                $em->run;
                Hobocamp->destroy;
            }
            die("Processing the file $file generated an error:\n", $template->error->as_string, "\n");
        }

        $self->log->info("Processed $file");
        push(@processed, $file);

        if ($preview_flag) {
            _print_to_stdout("# ---------- $file ----------");
            _print_to_stdout($output, "\n");
        }
        else {
            my $mode = 0444;
            chmod($mode, $output_file);
        }
    }

    wantarray ? return @processed : \@processed;
}

sub run {
    my ($self) = @_;

    my $ret;

    given ($self->action) {
        when ('list') {
            my @presets = $self->list_presets;
            if (@presets) {
                _print_to_stdout("Preset Configruations:\n\n  ", join("\n  ", sort(@presets)), "\n");
            }
            else {
                _print_to_stdout('No preset configurations.');
            }

            $ret = scalar(@presets);

            my @fixups = $self->list_fixups;
            if (@fixups) {
                _print_to_stdout("Available Fixups:\n\n  ", join("\n  ", sort(@fixups)), "\n");
            }

            $ret &= scalar(@fixups);
        }
        when ('load') {
            $self->conf->_delete_local;
            $self->conf->from($self->preset);
            $self->conf->reload;
            $self->_set_question_values;
            $self->_set_conf_values;
            $self->save;

            my @changed = $self->process;

            if (@changed) {
                _print_to_stdout(
                    "Processed:\n\n  ",
                    join(
                        "\n  ",
                        map {
                            my $f = File::Spec->abs2rel($_, $FindBin::Bin);
                            my $f2 = $f;

                            $f2 =~ s/\.tt2$//;

                            $_ = $f . ' -> ' . $f2;
                          } @changed
                    ),
                    "\n"
                );
            }
            else {
                _print_to_stdout('No config files processed!');
            }

            $ret = scalar(@changed);
        }
        when ('preview') {
            $self->conf->_delete_local;
            $self->conf->reload;
            $self->_set_question_values;
            $self->_set_conf_values;
            $ret = $self->process(1);
        }
        default {
            if ($self->is_interactive) {
                $ret = $self->ask;
            }
        }
    }

    return $ret;
}

sub apply_fixup {
    my ($self, $module_name) = @_;

    return unless ($module_name);

    _print_to_stdout("Applying fixup $module_name");
    $self->log->trace("Applying fixup $module_name");

    Class::MOP::load_class($module_name);

    my $ret;
    try {
        $ret = $module_name->refresh($self->conf);
        $self->save;
    }
    catch {
        my $msg = "Error: trying to call refresh() in $module_name produced: " . shift;
        $self->log->error($msg);
        die($msg);
    };

    $ret //= 1;

    return $ret;
}

sub list_presets {
    my ($self) = @_;

    my @presets;

    my $rule = File::Find::Rule->file->name('*.yaml')->start($self->preset_root);
    while (defined(my $preset = $rule->match)) {
        next if ($preset =~ /local\/?$/);

        # File::Find::Rule adds the top level directory
        next if ($preset =~ /presets\/?$/);

        my $fn = File::Basename::basename($preset);
        $fn =~ s/\.yaml$//;

        push(@presets, $fn);
    }

    wantarray ? return @presets : return \@presets;
}

sub list_fixups {
    my ($self) = @_;

    my @fixups = File::Find::Rule->file->name('*.pm')->relative->in(File::Spec->catdir($FindBin::Bin, 'lib'));
    my @ret;

    foreach my $fixup (@fixups) {
        next unless ($fixup =~ /Fixups\/?/);

        $fixup =~ s/\.pm$//;

        my @names = File::Spec->splitdir($fixup);

        push(@ret, join('::', @names));
    }

    if ($self->auto_fixup_module) {
        my $m = $self->auto_fixup_module;
        @ret = grep { !/$m/ } @ret;
    }

    wantarray ? return sort(@ret) : return [ sort(@ret) ];
}

sub usage {
    my ($self) = @_;

    my $script = $self->script_name;

    print STDERR<<"EOF";
Usage: $script [--help]
       [ --list ] | [ --save <preset> | --load <preset> ]
       [ --fixup <pkg> ]

--help             Show this help screen

--list             List all available presets and fixups
--load <preset>    Load the preset configuration named <preset>

--preview          Print the processed templates to standard out

--fixup <pkg>      The name of a Perl module containing a refresh()
                   class method that can alter configuration data at run time.

EOF

    exit(1);
}

__PACKAGE__->meta->make_immutable;
no Moose;
no Moose::Util::TypeConstraints;

1;


__END__
=pod

=head1 NAME

Thorium::BuildConf - Configuration management class

=head1 VERSION

version 0.510

=head1 SYNOPSIS

This class should be extended and customized to your application.

    package Some::App::BuildConf;

    use Thorium::Protection;

    use Moose;

    extends 'Thorium::BuildConf';

    use Thorium::BuildConf::Knob::URL::HTTP;

    has '+files' => ('default' => 'config.tt2');

    has '+knobs' => (
        'default' => sub {
            [
                Some::App::BuildConf::Knob::URL::HTTP->new(
                    'conf_key_name' => 'some_app.',
                    'name'          => 'favorite web site',
                    'question'      => 'What is your favorite web site?'
                )
            ];
        }
    );

    __PACKAGE__->meta->make_immutable;
    no Moose;

And driven by a F<configure> script

    #!/usr/bin/env perl

    use strict;

    use Some::App::BuildConf;

    Some::App::BuildConf->new(
        'conf_type' => 'Some::App::Conf',
    )->run;

=head1 DESCRIPTION

L<Thorium::BuildConf> consists of two main parts. The configuration console GUI
and the file generator.

The configuration console GUI provides a way someone unfamiliar with your
application to alter the defaults. They may save a version into their own preset
or use a fixup.

=head1 FEATURES

=head2 CONFIGURATION CONSOLE GUI

L<Thorium::BuildConf> uses L<Hobocamp> (bindings for C<dialog(1)>) and it's
widget set for an interactive console user interface.

=head2 FILE GENERATION

You should use

=head2 KNOBS

A knob is anything that is tunable with strict or loose input validation. See
L<Thorium::BuildConf::Knob> for creating your own custom knob.

=head2 PRESETS

A preset is a static YAML data specific to a user or an environment. These are
generally found in the directory 'conf/presets' under your application root.
However these files can be in any location under your application root by
changing preset_path default in your subclass, such as:

  has '+preset_path' => ('default' => sub { [ 'perl', 'conf', 'presets' ] } );

=head1 ATTRIBUTES

=head2 Required Attributes

=over

=item * B<conf> (C<rw>, C<Maybe[Thorium::Conf]>)

Configuration object.

=item * B<files> (C<rw>, C<ArrayRef|Str>)

String or list of files to be processed (L<Template> Toolkit format).

=item * B<knobs> (ro, Any)

L<Thorium::BuildConf::Knobs> derived object.

=back

=head2 Optional Attributes

=over

=item * B<auto_fixup_module> (rw, Str)

Class name of auto fix up module. This fixup will be run last on every
processing of the templates. Even if you specify one on the command line via
<--fixup>.

=item * B<action> (rw, Str)

Name of action (set via configure).

=item * B<fixup> (rw, Str)

Fixup class name.

=item * B<is_interactive> (rw, Bool)

Whether or not we are connected to a terminal that accepts standard in.

=item * B<preset> (rw, Str)

Preset name.

=item * B<preset_root> (rw, Str)

Directory root of the presets e.g. $self->root + "conf/presets".

=item * B<root> (rw, Str)

Directory root of the configuration files.

=item * B<script_name> (ro, Str)

File name of the script that instantiated us.

=back

=head1 PUBLIC API METHODS

=over

=item * B<run()>

This method starts the processing templates, saving/loading of the presets, etc.

=back

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

