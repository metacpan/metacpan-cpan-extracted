package Trickster::CLI;

use strict;
use warnings;
use v5.14;

use File::Path qw(make_path);
use File::Spec;
use Cwd qw(getcwd);
use Getopt::Long qw(GetOptionsFromArray);

our $VERSION = '0.01';

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub run {
    my ($class, @args) = @_;
    
    my $self = $class->new;
    
    unless (@args) {
        $self->show_help;
        return;
    }
    
    my $command = shift @args;
    
    my $method = "cmd_$command";
    if ($self->can($method)) {
        $self->$method(@args);
    } else {
        say "Unknown command: $command";
        say "Run 'trickster help' for usage information.";
        exit 1;
    }
}

sub cmd_help {
    my ($self) = @_;
    $self->show_help;
}

sub show_help {
    say "🎩 Trickster v$VERSION - Modern Perl Web Framework";
    say "";
    say "Usage: trickster <command> [options]";
    say "";
    say "Commands:";
    say "  new <name>              Create a new Trickster application";
    say "  generate <type> <name>  Generate a component (controller, model, template)";
    say "  server [options]        Start the development server";
    say "  routes                  Display all registered routes";
    say "  version                 Show Trickster version";
    say "  help                    Show this help message";
    say "";
    say "Examples:";
    say "  trickster new myapp";
    say "  trickster generate controller User";
    say "  trickster server --port 3000";
    say "  trickster routes";
}

sub cmd_version {
    my ($self) = @_;
    say "🎩 Trickster v$VERSION";
    say "🐪 Perl $^V";
}

sub cmd_new {
    my ($self, $name, @args) = @_;
    
    unless ($name) {
        say "Error: Application name required";
        say "Usage: trickster new <name>";
        exit 1;
    }
    
    if (-e $name) {
        say "Error: Directory '$name' already exists";
        exit 1;
    }
    
    say "🎩 Creating new Trickster application: $name";
    say "";
    
    # Create directory structure
    my @dirs = (
        $name,
        "$name/lib",
        "$name/lib/$name",
        "$name/lib/$name/Controller",
        "$name/lib/$name/Model",
        "$name/templates",
        "$name/templates/layouts",
        "$name/public",
        "$name/public/css",
        "$name/public/js",
        "$name/t",
    );
    
    for my $dir (@dirs) {
        make_path($dir);
        say "  📁 Created: $dir/";
    }
    
    # Create files
    $self->create_app_file($name);
    $self->create_cpanfile($name);
    $self->create_gitignore($name);
    $self->create_readme($name);
    $self->create_layout($name);
    $self->create_home_template($name);
    $self->create_test($name);
    
    say "";
    say "✓ Application created successfully!";
    say "";
    say "Next steps:";
    say "  cd $name";
    say "  cpanm --installdeps .";
    say "  plackup app.psgi";
    say "";
    say "Visit http://localhost:5678";
}

sub create_app_file {
    my ($self, $name) = @_;
    
    my $content = <<"EOF";
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "\$FindBin::Bin/lib";

use Trickster;
use Trickster::Template;

my \$app = Trickster->new(debug => 1);

# Initialize template engine
my \$template = Trickster::Template->new(
    path => ["\$FindBin::Bin/templates"],
    cache => 0,
    layout => 'layouts/main.tx',
    default_vars => {
        app_name => '$name',
    },
);

# Routes
\$app->get('/', sub {
    my (\$req, \$res) = \@_;
    
    # Home page is a complete HTML document, no layout needed
    my \$html = \$template->render('home.tx', {
        app_name => '$name',
        no_layout => 1,
    });
    
    return \$res->html(\$html);
});

\$app->to_app;
EOF
    
    my $file = "$name/app.psgi";
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh $content;
    close $fh;
    chmod 0755, $file;
    
    say "  📄 Created: $file";
}

sub create_cpanfile {
    my ($self, $name) = @_;
    
    my $content = <<'EOF';
requires 'perl', '5.014';
requires 'Trickster';
requires 'Text::Xslate';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Plack::Test';
};
EOF
    
    my $file = "$name/cpanfile";
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh $content;
    close $fh;
    
    say "  📄 Created: $file";
}

sub create_gitignore {
    my ($self, $name) = @_;
    
    my $content = <<'EOF';
*.swp
*.bak
*~
.DS_Store
local/
.carton/
EOF
    
    my $file = "$name/.gitignore";
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh $content;
    close $fh;
    
    say "  📄 Created: $file";
}

sub create_readme {
    my ($self, $name) = @_;
    
    my $content = <<"EOF";
# $name

A Trickster web application.

## Installation

```bash
cpanm --installdeps .
```

## Running

```bash
plackup app.psgi
```

Visit http://localhost:5678

## Development

```bash
plackup -R lib,templates app.psgi
```

## Testing

```bash
prove -l t/
```
EOF
    
    my $file = "$name/README.md";
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh $content;
    close $fh;
    
    say "  📄 Created: $file";
}

sub create_layout {
    my ($self, $name) = @_;
    
    my $content = <<'EOF';
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>[% title || app_name %]</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header>
        <h1>[% app_name %]</h1>
    </header>
    
    <main>
        [% content %]
    </main>
    
    <footer>
        <p>Powered by Trickster</p>
    </footer>
</body>
</html>
EOF
    
    my $file = "$name/templates/layouts/main.tx";
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh $content;
    close $fh;
    
    say "  📄 Created: $file";
}

sub create_home_template {
    my ($self, $name) = @_;
    
    my $content = <<'EOF';
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>[% app_name %] • Powered by Trickster</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: #0d1117;
            color: #c9d1d9;
            display: grid;
            place-items: center;
            min-height: 100vh;
            padding: 2rem;
        }
        .card {
            background: #161b22;
            padding: 3rem 4rem;
            border-radius: 12px;
            border: 1px solid #30363d;
            text-align: center;
            max-width: 520px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
        }
        h1 {
            margin: 0 0 1rem;
            font-size: 3rem;
            background: linear-gradient(135deg, #ffa657, #f0575b);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            font-weight: 700;
        }
        .emoji { font-size: 3.5rem; margin-bottom: 1rem; }
        p {
            margin: 1rem 0;
            line-height: 1.7;
            font-size: 1.05rem;
        }
        strong { color: #fff; }
        code {
            background: #21262d;
            padding: 0.3em 0.6em;
            border-radius: 6px;
            font-size: 0.95em;
            color: #ffa657;
            font-family: 'SF Mono', Monaco, monospace;
        }
        .features {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 0.5rem;
            margin: 2rem 0;
            text-align: left;
        }
        .feature {
            background: #0d1117;
            padding: 0.75rem 1rem;
            border-radius: 6px;
            font-size: 0.9rem;
            border: 1px solid #21262d;
        }
        .feature::before {
            content: '✓';
            color: #3fb950;
            font-weight: bold;
            margin-right: 0.5rem;
        }
        footer {
            margin-top: 2.5rem;
            font-size: 0.9rem;
            opacity: 0.6;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="emoji">🎩</div>
        <h1>[% app_name %]</h1>
        <p><strong>Congratulations!</strong> Your Trickster app is running.</p>
        
        <div class="features">
            <div class="feature">Fast routing</div>
            <div class="feature">Zero deps</div>
            <div class="feature">Stateless sessions</div>
            <div class="feature">Built for 2025</div>
        </div>
        
        <p>Get started:</p>
        <p><code>trickster generate controller Home</code></p>
        
        <footer>Powered by <strong>Trickster</strong></footer>
    </div>
</body>
</html>
EOF
    
    my $file = "$name/templates/home.tx";
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh $content;
    close $fh;
    
    say "  📄 Created: $file";
}

sub create_test {
    my ($self, $name) = @_;
    
    my $content = <<'EOF';
use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

require './app.psgi';
my $app = do './app.psgi';

test_psgi $app, sub {
    my $cb = shift;
    
    my $res = $cb->(GET '/');
    is $res->code, 200, 'GET / returns 200';
    like $res->content, qr/Welcome/, 'Home page contains welcome message';
};

done_testing;
EOF
    
    my $file = "$name/t/01-basic.t";
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh $content;
    close $fh;
    
    say "  📄 Created: $file";
}

sub cmd_generate {
    my ($self, $type, $name, @args) = @_;
    
    unless ($type && $name) {
        say "Error: Type and name required";
        say "Usage: trickster generate <type> <name>";
        say "Types: controller, model, template";
        exit 1;
    }
    
    my $method = "generate_$type";
    if ($self->can($method)) {
        $self->$method($name, @args);
    } else {
        say "Error: Unknown type '$type'";
        say "Available types: controller, model, template";
        exit 1;
    }
}

sub generate_controller {
    my ($self, $name) = @_;
    
    my $app_name = $self->detect_app_name;
    
    my $content = <<"EOF";
package ${app_name}::Controller::${name};

use strict;
use warnings;
use v5.14;

sub new {
    my (\$class) = \@_;
    return bless {}, \$class;
}

sub index {
    my (\$self, \$req, \$res) = \@_;
    
    return \$res->json({ message => 'Hello from ${name} controller' });
}

sub show {
    my (\$self, \$req, \$res) = \@_;
    my \$id = \$req->param('id');
    
    return \$res->json({ id => \$id });
}

1;
EOF
    
    my $file = "lib/${app_name}/Controller/${name}.pm";
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh $content;
    close $fh;
    
    say "✓ Created controller: $file";
    say "";
    say "Add to your app.psgi:";
    say "  use ${app_name}::Controller::${name};";
    say "  my \$${name}_controller = ${app_name}::Controller::${name}->new;";
    say "  \$app->get('/${name}', sub { \$${name}_controller->index(\@_) });";
}

sub generate_model {
    my ($self, $name) = @_;
    
    my $app_name = $self->detect_app_name;
    
    my $content = <<"EOF";
package ${app_name}::Model::${name};

use strict;
use warnings;
use v5.14;

sub new {
    my (\$class, %opts) = \@_;
    
    return bless {
        data => {},
        %opts,
    }, \$class;
}

sub find {
    my (\$self, \$id) = \@_;
    return \$self->{data}{\$id};
}

sub all {
    my (\$self) = \@_;
    return [values %{\$self->{data}}];
}

sub create {
    my (\$self, \$data) = \@_;
    
    my \$id = time . int(rand(1000));
    \$self->{data}{\$id} = { id => \$id, %\$data };
    
    return \$self->{data}{\$id};
}

sub update {
    my (\$self, \$id, \$data) = \@_;
    
    return unless exists \$self->{data}{\$id};
    
    \$self->{data}{\$id} = { %{\$self->{data}{\$id}}, %\$data };
    
    return \$self->{data}{\$id};
}

sub delete {
    my (\$self, \$id) = \@_;
    return delete \$self->{data}{\$id};
}

1;
EOF
    
    my $file = "lib/${app_name}/Model/${name}.pm";
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh $content;
    close $fh;
    
    say "✓ Created model: $file";
    say "";
    say "Use in your app:";
    say "  use ${app_name}::Model::${name};";
    say "  my \$${name}_model = ${app_name}::Model::${name}->new;";
}

sub generate_template {
    my ($self, $name) = @_;
    
    my $content = <<'EOF';
<div class="page">
    <h2>[% title %]</h2>
    <p>Template content goes here.</p>
</div>
EOF
    
    my $file = "templates/${name}.tx";
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh $content;
    close $fh;
    
    say "✓ Created template: $file";
    say "";
    say "Render in your route:";
    say "  my \$html = \$template->render('${name}.tx', { title => 'Page Title' });";
}

sub detect_app_name {
    my ($self) = @_;
    
    my $cwd = getcwd;
    my $app_name = (split '/', $cwd)[-1];
    
    # Capitalize first letter
    $app_name = ucfirst($app_name);
    
    return $app_name;
}

sub cmd_server {
    my ($self, @args) = @_;
    
    my $port = 5678;
    my $host = '0.0.0.0';
    my $reload = 0;
    
    GetOptionsFromArray(\@args,
        'port|p=i' => \$port,
        'host|h=s' => \$host,
        'reload|r' => \$reload,
    );
    
    unless (-f 'app.psgi') {
        say "Error: app.psgi not found";
        say "Run this command from your application directory";
        exit 1;
    }
    
    say "🎩 Starting Trickster development server...";
    say "🌐 Listening on http://$host:$port";
    say "⚡ Press Ctrl+C to stop";
    say "";
    
    my @cmd = ('plackup', '--port', $port, '--host', $host);
    push @cmd, '-R', 'lib,templates' if $reload;
    push @cmd, 'app.psgi';
    
    exec @cmd;
}

sub cmd_routes {
    my ($self) = @_;
    
    unless (-f 'app.psgi') {
        say "Error: app.psgi not found";
        exit 1;
    }
    
    say "Loading routes from app.psgi...";
    say "";
    
    # This is a simplified version - in a real implementation,
    # we'd need to parse the app.psgi file or load the app
    say "Note: Route inspection requires loading the application.";
    say "This feature will be enhanced in future versions.";
    say "";
    say "For now, check your app.psgi file for route definitions.";
}

1;

__END__

=head1 NAME

Trickster::CLI - Command-line interface for Trickster framework

=head1 SYNOPSIS

    use Trickster::CLI;
    
    Trickster::CLI->run(@ARGV);

=head1 DESCRIPTION

Trickster::CLI provides command-line tools for creating and managing
Trickster web applications.

=head1 COMMANDS

=head2 new <name>

Creates a new Trickster application with the following structure:

    myapp/
    ├── app.psgi
    ├── cpanfile
    ├── lib/
    │   └── MyApp/
    │       ├── Controller/
    │       └── Model/
    ├── templates/
    │   └── layouts/
    ├── public/
    │   ├── css/
    │   └── js/
    └── t/

=head2 generate <type> <name>

Generates a new component:

=over 4

=item * controller - Creates a new controller class

=item * model - Creates a new model class

=item * template - Creates a new template file

=back

=head2 server [options]

Starts the development server.

Options:

=over 4

=item * --port, -p - Port number (default: 5678)

=item * --host, -h - Host address (default: 0.0.0.0)

=item * --reload, -r - Auto-reload on file changes

=back

=head2 routes

Displays all registered routes in the application.

=head2 version

Shows the Trickster version.

=cut
