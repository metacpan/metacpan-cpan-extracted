# Trickster CLI Guide

The Trickster command-line tool helps you quickly scaffold and manage web applications.

## Installation

After installing Trickster, the `trickster` command will be available:

```bash
perl Makefile.PL
make
make install
```

Or with cpanm:

```bash
cpanm Trickster
```

## Commands

### new - Create New Application

Create a complete application structure with all necessary files:

```bash
trickster new myapp
```

This creates:

```
myapp/
├── app.psgi              # Main application file
├── cpanfile              # Dependencies
├── README.md             # Documentation
├── .gitignore           # Git ignore rules
├── lib/
│   └── Myapp/
│       ├── Controller/   # Controllers go here
│       └── Model/        # Models go here
├── templates/
│   ├── layouts/
│   │   └── main.tx      # Default layout
│   └── home.tx          # Home page template
├── public/
│   ├── css/             # Stylesheets
│   └── js/              # JavaScript files
└── t/
    └── 01-basic.t       # Basic tests
```

After creation:

```bash
cd myapp
cpanm --installdeps .
plackup app.psgi
```

### generate - Generate Components

Generate controllers, models, or templates:

#### Generate Controller

```bash
trickster generate controller User
```

Creates `lib/Myapp/Controller/User.pm`:

```perl
package Myapp::Controller::User;

use strict;
use warnings;
use v5.14;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub index {
    my ($self, $req, $res) = @_;
    return $res->json({ message => 'Hello from User controller' });
}

sub show {
    my ($self, $req, $res) = @_;
    my $id = $req->param('id');
    return $res->json({ id => $id });
}

1;
```

Use in your app:

```perl
use Myapp::Controller::User;

my $user_controller = Myapp::Controller::User->new;

$app->get('/users', sub { $user_controller->index(@_) });
$app->get('/users/:id', sub { $user_controller->show(@_) });
```

#### Generate Model

```bash
trickster generate model Post
```

Creates `lib/Myapp/Model/Post.pm` with CRUD methods:

- `find($id)` - Find by ID
- `all()` - Get all records
- `create($data)` - Create new record
- `update($id, $data)` - Update record
- `delete($id)` - Delete record

Use in your app:

```perl
use Myapp::Model::Post;

my $post_model = Myapp::Model::Post->new;

$app->get('/posts', sub {
    my ($req, $res) = @_;
    return $res->json($post_model->all);
});

$app->post('/posts', sub {
    my ($req, $res) = @_;
    my $post = $post_model->create($req->json);
    return $res->json($post, 201);
});
```

#### Generate Template

```bash
trickster generate template about
```

Creates `templates/about.tx`:

```html
<div class="page">
    <h2>[% title %]</h2>
    <p>Template content goes here.</p>
</div>
```

Use in your app:

```perl
$app->get('/about', sub {
    my ($req, $res) = @_;
    my $html = $template->render('about.tx', {
        title => 'About Us',
    });
    return $res->html($html);
});
```

### server - Development Server

Start the development server:

```bash
# Default (port 5678, host 0.0.0.0)
trickster server

# Custom port
trickster server --port 3000

# Custom host
trickster server --host 127.0.0.1

# Auto-reload on file changes
trickster server --reload

# Combined options
trickster server --port 8080 --reload
```

Options:

- `--port, -p` - Port number (default: 5678)
- `--host, -h` - Host address (default: 0.0.0.0)
- `--reload, -r` - Auto-reload when files change

The `--reload` option watches `lib/` and `templates/` directories and automatically restarts the server when files are modified.

### routes - Display Routes

Display all registered routes in your application:

```bash
trickster routes
```

**Note:** This feature requires loading the application and will be enhanced in future versions.

### version - Show Version

Display Trickster and Perl versions:

```bash
trickster version
```

Output:
```
Trickster v0.01
Perl v5.40.1
```

### help - Show Help

Display help information:

```bash
trickster help
```

## Workflow Examples

### Creating a Blog Application

```bash
# Create application
trickster new myblog
cd myblog

# Install dependencies
cpanm --installdeps .

# Generate components
trickster generate model Post
trickster generate controller Post
trickster generate template post/list
trickster generate template post/show
trickster generate template post/form

# Start development server with auto-reload
trickster server --reload
```

### Creating an API

```bash
# Create application
trickster new myapi
cd myapi

# Generate models
trickster generate model User
trickster generate model Product
trickster generate model Order

# Generate controllers
trickster generate controller User
trickster generate controller Product
trickster generate controller Order

# Start server
trickster server --port 3000
```

## Tips

### Project Structure

Keep your code organized:

```
myapp/
├── lib/
│   └── Myapp/
│       ├── Controller/      # HTTP handlers
│       ├── Model/           # Business logic
│       ├── Service/         # External services
│       └── Util/            # Utilities
├── templates/
│   ├── layouts/             # Page layouts
│   ├── partials/            # Reusable components
│   └── [feature]/           # Feature templates
└── public/
    ├── css/
    ├── js/
    └── images/
```

### Development Workflow

1. **Start with auto-reload:**
   ```bash
   trickster server --reload
   ```

2. **Generate components as needed:**
   ```bash
   trickster generate controller Feature
   ```

3. **Test frequently:**
   ```bash
   prove -l t/
   ```

4. **Use version control:**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   ```

### Production Deployment

For production, use a production-grade PSGI server:

```bash
# Install Starman
cpanm Starman

# Run with multiple workers
starman --workers 10 --port 5678 app.psgi
```

Or with uWSGI:

```bash
uwsgi --http :5678 --psgi app.psgi --master --processes 4
```

## Troubleshooting

### Command not found

If `trickster` command is not found after installation:

```bash
# Check if it's installed
which trickster

# If not, ensure Perl bin directory is in PATH
export PATH="$HOME/perl5/bin:$PATH"

# Or use full path
perl -Ilib bin/trickster
```

### Permission denied

Make sure the script is executable:

```bash
chmod +x bin/trickster
```

### Module not found

Install dependencies:

```bash
cpanm --installdeps .
```

## Future Enhancements

Planned features for future versions:

- Interactive mode for project creation
- Database migration commands
- Test generation
- API documentation generation
- Deployment helpers
- Plugin management
- Route inspection and testing
- Performance profiling

## Contributing

Have ideas for CLI improvements? Contributions are welcome!

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
