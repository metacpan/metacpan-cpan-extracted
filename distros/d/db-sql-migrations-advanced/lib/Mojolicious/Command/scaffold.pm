package Mojolicious::Command::scaffold;
use Mojo::Base 'Mojo::Console';

use Getopt::Long;
use List::Util qw(any);
use Mojo::File 'path';

our $VERSION = '0.0.2';

# Short description
has 'description' => <<EOF;
Scaffold a command, controller, migration, routes, task and a template
EOF

has 'options' => sub {
    my %options;
    GetOptions(\%options,
        'base|b:s',
        'name=s',
        'action=s',
        'pretend',
        'preview',
        'routes',
        'create',
        'table=s',
        'template',
        'tests',
    );

    return \%options;
};

has 'piling' => sub {
    my $self = shift;

    my @parts = split('::', $self->options->{ name });

    my $application = ref $self->app;
    my $name = $parts[-1];
    my $package_path = join('/', @parts[0..$#parts - 1]);
    my $package_name = sprintf('%s%s', ($package_path ? $package_path . '::' : ''), $name);
    $package_name =~ s/\//::/g;
    my $template_path = join('/', map(lc($_), @parts)) . '/';

    return {
        application     => $application,
        file_name       => sprintf('%s.pm', $name),
        package_path    => $package_path,
        package_name    => $package_name,
        template_path   => $template_path,
    };
};

# Short usage message
has 'usage' => <<EOF;
Usage:  mojo scaffold
        mojo scaffold controller --name="Mobile" --tests --routes --template
        mojo scaffold routes --name="Mobile" --tests
        mojo scaffold template --name="Mobile"
EOF

=head2 command
    Scaffold a mojolicious command
=cut

sub command {
    my $self = shift;

    $self->options->{ name } ||= $self->required->ask('What is the name of the command?');

    # command
    my $application = $self->piling->{ application };
    my $path = "lib/$application/Command/" . ($self->piling->{ package_path } ? $self->piling->{ package_path } . '/' : '');

    $self->process($path, $self->piling->{ file_name }, $self->stub('stubs/command.pm.stub', [
        'Application::Command'  => $self->piling->{ application } . '::Command',
        Stub                    => $self->piling->{ package_name },
    ]));
}

=head2 controller
    Scaffold a mojolicious controller
=cut

sub controller {
    my $self = shift;

    $self->options->{ name } ||= $self->ask('What is the name of the controller?');
    $self->options->{ action } ||= $self->ask('What is the name of the action?', 'action');
    $self->options->{ tests } ||= $self->confirm(sprintf('Do you want to create tests for <%s> controller?', $self->options->{ name }), 'yes');
    $self->options->{ routes } ||= $self->confirm(sprintf('Do you want to create routes for <%s> controller?', $self->options->{ name }), 'yes');
    $self->options->{ template } ||= $self->confirm(sprintf('Do you want to create default template for <%s> controller?', $self->options->{ name }), 'yes');
    
    # Controller
    my $application = $self->piling->{ application };
    my $controller_path = "lib/$application/Controller/" . ($self->piling->{ package_path } ? $self->piling->{ package_path } . '/' : '');

    my $stub = $self->stub('stubs/Controller.pm.stub', [
        'Application::Controller'   => $self->piling->{ application } . '::Controller',
        Stub                        => $self->piling->{ package_name },
        'sub action'                => sprintf('sub %s', $self->options->{ action }),
        'template/action'           => sprintf('template/%s', $self->options->{ action }),
        'template/'                 => $self->piling->{ template_path },
    ]);

    # Replace base controller
    my $base = $self->options->{ base };
    $stub =~ s/Mojolicious::Controller/$base/g if ($base);

    $self->process($controller_path, $self->piling->{ file_name }, $stub);

    if ($self->options->{ tests }) {
        # Controller Tests
        my $controller_tests_path = "t/lib/TestCase/$application/Controller/" . ($self->piling->{ package_path } ? $self->piling->{ package_path } . '/' : '');

        $self->process($controller_tests_path, $self->piling->{ file_name }, $self->stub('stubs/ControllerTests.pm.stub', [
            'Application::Controller'   => $self->piling->{ application } . '::Controller',
            Stub                        => $self->piling->{ package_name },
            'sub test_action'           => sprintf('sub test_%s', $self->options->{ action }),
        ]));
    }

    $self->routes if ($self->options->{ routes });
    $self->template if ($self->options->{ template });
}

=head2 migration
    Scaffold a migration
=cut

sub migration {
    my $self = shift;

    my @columns;

    $self->options->{ create } ||= $self->confirm('Are you going to create a new table?', 'no');
    $self->options->{ table } ||= $self->required->ask(sprintf("What's the name of the table that you are you going to %s?", ($self->options->{ create } ? 'create' : 'alter')));

    while (my $field = $self->ask("What's the name of the column?")) {
        my $column = { field => $field };

        $column->{ type } = $self->choice("What's the type of '$field' column?", [
            'bigint', 'blob', 'date', 'datetime', 'int', 'longtext', 'mediumblob', 'text', 'timestamp', 'tinyint', 'varchar'
        ]);

        if (any { $_ eq $column->{ type } } qw(bigint int varchar)) {
            $column->{ length } = $self->ask("What's the length for '$field' column?");
        }

        if (any { $_ eq $column->{ type } } qw(bigint int)) {
            $column->{ unsigned } = $self->confirm("Is '$field' an unsigned column?", 'yes') if (!$column->{ length });
            $column->{ autoincrement } = $self->confirm("Is '$field' an auto-increment column?", 'no');
        }

        $column->{ default } = $self->ask("What's the default value for '$field' column?") if (!$column->{ autoincrement });
        $column->{ nullable } = $self->confirm("Allow null values for '$field' column?", 'yes') if (!$column->{ autoincrement } && !$column->{ default });
        $column->{ after } = $self->ask("Create the column '$field' after?") if (!$self->options->{ create });

        push(@columns, $column);
    }

    my @lines;

    for my $column (@columns) {
        push(@lines, sprintf("%s `%s` %s%s %s %s %s %s %s",
            ($self->options->{ create } ? '' : 'ADD COLUMN'),
            $column->{ field },
            $column->{ type },
            ($column->{ length } ? sprintf('(%s)', $column->{ length }) : ''),
            ($column->{ unsigned } ? 'unsigned' : ''),
            ($column->{ nullable } ? 'NULL' : 'NOT NULL'),
            (length($column->{ default }) ? sprintf('DEFAULT %s', $column->{ default }) : $column->{ nullable } ? 'DEFAULT NULL' : ''),
            ($column->{ autoincrement } ? 'AUTO_INCREMENT' : ''),
            ($column->{ after } ? sprintf('AFTER `%s`', $column->{ after }) : ''),
        ));
    }

    if ($self->options->{ create }) {
        push(@lines, sprintf('PRIMARY KEY (`%s`)', $self->required->ask("What's the primary key?")));
    }

    my $sql = $self->options->{ create } ? 
        sprintf("CREATE TABLE `%s` (\n", $self->options->{ table }) : 
        sprintf("ALTER TABLE `%s`\n", $self->options->{ table });

    $sql .= sprintf("%s%s;\n", join(",\n", @lines), ($self->options->{ create } ? "\n)" : ''));

    my $file = sprintf('%s_%s_table_%s.sql',
        $self->app->calendar->ymd,
        ($self->options->{ create } ? 'create' : 'alter'),
        $self->options->{ table },
    );

    $self->process('db_migrations/', $file, $sql);
}

=head2 process
    Process content for a file
=cut

sub process {
    my ($self, $path, $file, $content) = @_;

    my $save = !$self->options->{ pretend };

    if ($self->options->{ pretend } || $self->options->{ preview }) {
        $self->info(sprintf("%s%s\n", $path, $file));
        $self->newline('===================================================');
        $self->warn($content);
    }

    if ($self->options->{ preview }) {
        $save = $self->confirm('Looks good?');
    }

    if ($save) {
        my $template = Mojo::File->new($path)->make_path;
        $template->child($file)->spurt($content);
    }
}

=head2 routes
    Scaffold a mojolicious routes file
=cut

sub routes {
    my $self = shift;

    $self->options->{ name } ||= $self->required->ask('What is the name of the controller?');
    $self->options->{ action } ||= $self->ask('What is the name of the action?', 'action');
    $self->options->{ tests } ||= $self->confirm(sprintf('Do you want to create tests for <%s> routes?', $self->options->{ name }), 'yes');

    # Routes
    my $application = $self->piling->{ application };
    my $routes_path = "lib/$application/Routes/" . ($self->piling->{ package_path } ? $self->piling->{ package_path } . '/' : '');

    $self->process($routes_path, $self->piling->{ file_name }, $self->stub('stubs/Routes.pm.stub', [
        Application             => $self->piling->{ application },
        Stub                    => $self->piling->{ package_name },
        "action => 'action'"    => sprintf("action => '%s'", $self->options->{ action }),
    ]));

    if ($self->options->{ tests }) {
        # Routes Tests
        my $routes_tests_path = "t/lib/TestCase/$application/Routes/" . ($self->piling->{ package_path } ? $self->piling->{ package_path } . '/' : '');

        $self->process($routes_tests_path, $self->piling->{ file_name }, $self->stub('stubs/RoutesTests.pm.stub', [
            Application => $self->piling->{ application },
            Stub        => $self->piling->{ package_name },
        ]));
    }
}

=head2 run
    Run scaffold command
=cut

sub run {
    my ($self, $choice, @args) = @_;
    
    $choice = undef if ($choice eq '--pretend' || $choice eq '--preview');
    $choice ||= $self->choice('What are you looking to scaffold?', ['command', 'controller', 'migration', 'routes', 'task', 'template'], 'controller');

    if ($self->can($choice)) {
        $self->$choice();
        $self->success("Done\n");

        return;
    }

    $self->error("Unknown choice\n");
}

=head2 stub
    Open stub file and replace thing
=cut

sub stub {
    my ($self, $filename, $replacements) = @_;

    my $file = $self->app->home->rel_file($filename);
    my $content;

    if ((-e $file)) {
        $content = $file->slurp;
    } else {
        $content = path(__FILE__)->sibling('resources', $filename)->slurp;
    }

    for (my $i=0; $i < @$replacements; $i++) {
        my ($find, $replace) = ($replacements->[$i], $replacements->[++$i]);
        $content =~ s/$find/$replace/g if $replace;
    }

    return $content;
}

=head2 task
    Scaffold a mojolicious task file
=cut

sub task {
    my $self = shift;
    
    $self->options->{ name } ||= $self->required->ask('What is the name of the task?');
    $self->options->{ tests } ||= $self->confirm(sprintf('Do you want to create tests for <%s> task?', $self->options->{ name }), 'yes');

    # Task
    my $application = $self->piling->{ application };
    my $task_path = "lib/$application/Tasks/" . ($self->piling->{ package_path } ? $self->piling->{ package_path } . '/' : '');

    $self->process($task_path, $self->piling->{ file_name }, $self->stub('stubs/Task.pm.stub', [
        Application => $self->piling->{ application },
        Stub        => $self->piling->{ package_name },
    ]));

    if ($self->options->{ tests }) {
        # Routes Tests
        my $task_tests_path = "t/lib/TestCase/$application/Tasks/" . ($self->piling->{ package_path } ? $self->piling->{ package_path } . '/' : '');

        $self->process($task_tests_path, $self->piling->{ file_name }, $self->stub('stubs/TaskTests.pm.stub', [
            Application => $self->piling->{ application },
            Stub        => $self->piling->{ package_name },
        ]));
    }
}

=head2 task
    Scaffold a mojolicious template file
=cut

sub template {
    my $self = shift;

    $self->options->{ name } ||= $self->required->ask('What is the name of the controller?');
    $self->options->{ action } ||= $self->ask('What is the name of the action?', 'action');


    # Template
    $self->process('templates/' . $self->piling->{ template_path }, $self->options->{ action } . '.html.ep', $self->stub('stubs/template.html.ep', [
        Stub    => $self->piling->{ package_name },
    ]));
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::scaffold - Scaffold command

=head1 SYNOPSIS

    Usage: APPLICATION scaffold [OPTIONS]

        ./myapp.pl scaffold
        ./myapp.pl scaffold controller

    Options:
        'base|b:s',
        'controller',
        'name=s',
        'pretend',
        'preview',
        'routes',
        'table=s',
        'template',
        'tests',

        -b, --base <string>         Base controller

        --name <string>             Name of the controller, command that you are trying to create

        --action <string>           Default action name for controller

        --pretent                   When it's present, the command will just output the content
                                    of the files that are about to be created

        --preview                   When it's present, a confirmation message will appear before
                                    saving a file

        --create                    Tells if you are creating/altering a table
        --table <string>            The name of the table

        --tests                     Will create tests

        --template                  Will create a template

=head1 DESCRIPTION

L<Mojolicious::Command::scaffold> helps you easily create commands, controllers, migrations, routes, tasks and templates

See L<Mojolicious::Commands/"COMMANDS"> for a list of commands that are
available by default.

=head1 ATTRIBUTES

L<Mojolicious::Command::scaffold> inherits all attributes from
L<Mojo::Console> and implements the following new ones.

=head2 description

  my $description   = $scaffold->description;
  $scaffold         = $scaffold->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $scaffold->usage;
  $scaffold = $scaffold->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::scaffold> inherits all methods from
L<Mojo::Console> and implements the following new ones.

=head2 run

  $scaffold->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
