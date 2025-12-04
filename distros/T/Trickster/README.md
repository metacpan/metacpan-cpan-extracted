<div align="center">

<img src="https://raw.githubusercontent.com/tricksterperl/trickster/main/assets/trickster.png" alt="Trickster Logo" width="300"/>

# 🎭 Trickster

A modern, battle-tested micro-framework for building web applications in Perl.

[![CPAN Version](https://img.shields.io/cpan/v/Trickster.svg?style=flat-square)](https://metacpan.org/pod/Trickster)
[![Perl Version](https://img.shields.io/badge/perl-5.14%2B-blue.svg?style=flat-square)](https://www.perl.org/)
[![License](https://img.shields.io/badge/license-Artistic%202.0%20%7C%20GPL-blue.svg?style=flat-square)](LICENSE)
[![Coverage](https://img.shields.io/codecov/c/github/tricksterperl/trickster?style=flat-square)](https://codecov.io/gh/trickster-perl/trickster)

[Documentation](https://tricksterperl.github.io) • [Quick Start](#quick-start) • [Examples](examples/) • [Contributing](CONTRIBUTING.md)

</div>

---

## Philosophy

Trickster brings contemporary web framework design to Perl while respecting CPAN traditions.

- **Minimal Core** – Light dependencies, focused on essentials
- **PSGI Native** – Built on PSGI/Plack for maximum compatibility
- **Modern Perl** – Uses Perl 5.14+ features while remaining accessible
- **CPAN Friendly** – Integrates seamlessly with existing CPAN modules
- **Battle-Tested** – Production-grade error handling and performance
- **No Magic** – Explicit is better than implicit

## Installation

### Via CPAN

```bash
cpanm Trickster
```

### Via cpanfile

```bash
cpanm --installdeps .
```

### Traditional CPAN

```bash
perl Makefile.PL
make
make test
make install
```

This will also install the `trickster` command-line tool.

---

## Quick Start

### Using the CLI (Recommended)

```bash
# Create a new application
trickster new myapp

# Navigate and install dependencies
cd myapp && cpanm --installdeps .

# Start the development server
trickster server
```

Visit **http://localhost:5678**

### Hello World (Manual)

```perl
use Trickster;

my $app = Trickster->new;

$app->get('/', sub {
    my ($req, $res) = @_;
    return "Welcome to Trickster";
});

$app->get('/hello/:name', sub {
    my ($req, $res) = @_;
    my $name = $req->param('name');
    return "Hello, $name";
});

$app->to_app;
```

Run with any PSGI server:

```bash
plackup app.psgi
```

---

## Features

<table>
<tr>
<td width="50%" valign="top">

**Routing**
- Path parameters: `/user/:id`
- Constraints: `qr/^\d+$/`
- Named routes for URL generation
- Multiple HTTP methods
- Wildcard routes

**Request/Response**
- JSON parsing & serialization
- Cookie handling (secure & signed)
- File uploads
- Response helpers (JSON, HTML, redirects)
- Custom headers & status codes

**Templates**
- Powered by Text::Xslate
- TTerse syntax (Template Toolkit-like)
- Layout support
- Template caching
- Custom functions

</td>
<td width="50%" valign="top">

**Security & Validation**
- Built-in data validation
- Exception handling (typed errors)
- Secure cookie encryption
- CSRF protection ready
- XSS prevention helpers

**Developer Experience**
- CLI for scaffolding & generators
- Hot-reload development server
- Comprehensive logging
- PSGI/Plack middleware compatible
- Extensive test utilities

**Performance**
- Minimal overhead
- Template caching
- Efficient routing engine
- Production-ready out of the box

</td>
</tr>
</table>

---

## Code Examples

### REST API with JSON

```perl
use Trickster;
use Trickster::Request;
use Trickster::Response;

my $app = Trickster->new;

$app->get('/api/users/:id', sub {
    my ($req, $res) = @_;
    $req = Trickster::Request->new($req->env);
    $res = Trickster::Response->new;
    
    my $id = $req->param('id');
    my $user = get_user($id);
    
    return $res->json($user);
});

$app->post('/api/users', sub {
    my ($req, $res) = @_;
    $req = Trickster::Request->new($req->env);
    $res = Trickster::Response->new;
    
    my $data = $req->json;
    my $user = create_user($data);
    
    return $res->json($user, 201);
});
```

### Data Validation

```perl
use Trickster::Validator;

$app->post('/register', sub {
    my ($req, $res) = @_;
    my $data = $req->json;
    
    my $validator = Trickster::Validator->new({
        name  => ['required', ['min', 3], ['max', 50]],
        email => ['required', 'email'],
        age   => ['numeric', ['min', 18]],
    });
    
    unless ($validator->validate($data)) {
        return $res->json({ errors => $validator->errors }, 400);
    }
    
    # Process valid data...
    return $res->json({ success => 1 }, 201);
});
```

### Template Rendering

```perl
use Trickster::Template;

my $template = Trickster::Template->new(
    path => ['templates'],
    cache => 1,
    layout => 'layouts/main.tx',
);

$app->get('/profile/:username', sub {
    my ($req, $res) = @_;
    my $username = $req->param('username');
    
    my $html = $template->render('profile.tx', {
        title => 'User Profile',
        user  => get_user($username),
    });
    
    return $res->html($html);
});
```

### Exception Handling

```perl
use Trickster::Exception;

$app->get('/user/:id', sub {
    my ($req, $res) = @_;
    my $id = $req->param('id');
    
    my $user = find_user($id);
    
    unless ($user) {
        Trickster::Exception::NotFound->throw(
            message => "User not found"
        );
    }
    
    return $res->json($user);
});

# Custom error handler
$app->error_handler(sub {
    my ($error, $req, $res) = @_;
    
    if (ref($error) && $error->isa('Trickster::Exception')) {
        return $res->json($error->as_hash, $error->status)->finalize;
    }
    
    return $res->json({ error => 'Server Error' }, 500)->finalize;
});
```

---

## CLI Commands

Trickster includes a powerful command-line interface:

```bash
# Scaffold new application
trickster new myapp

# Generate components
trickster generate controller User
trickster generate model Post
trickster generate template about

# Development server with hot-reload
trickster server --reload --port 3000

# Show version
trickster version
```

---

## Testing

Comprehensive test suite included:

```bash
# Run all tests
prove -l t/

# With verbose output
prove -lv t/

# Single test file
prove -lv t/01-routing.t
```

Test coverage: **85%+**

---

## Documentation

- **[Getting Started Guide](https://trickster-perl.github.io/guide/)** – Learn the basics
- **[API Reference](https://trickster-perl.github.io/api/)** – Complete API docs
- **[Cookbook](https://trickster-perl.github.io/cookbook/)** – Common recipes
- **[Examples](examples/)** – Working code examples
- **[Migration Guide](https://trickster-perl.github.io/migration/)** – From other frameworks

---

## Examples

Check out the `examples/` directory for complete working applications:

| Example | Description | Run Command |
|---------|-------------|-------------|
| `hello.psgi` | Basic routing & parameters | `plackup examples/hello.psgi` |
| `api.psgi` | Full REST API with CRUD | `plackup examples/api.psgi` |
| `template.psgi` | Template engine demo | `plackup examples/template.psgi` |
| `advanced.psgi` | All features showcase | `plackup examples/advanced.psgi` |
| `middleware.psgi` | Middleware integration | `plackup examples/middleware.psgi` |

---

## Requirements

### Core Dependencies

- **Perl 5.14+** 
- Plack 1.0047+
- JSON::PP (core)
- URI::Escape (core)
- Digest::SHA (core)
- Time::Piece (core)

### Optional

- **Text::Xslate 3.0+** – For template engine support

```bash
cpanm Text::Xslate
# or
cpanm --installdeps . --with-feature=templates
```

---

## Contributing

Contributions are welcome. Please ensure:

- Code follows Perl best practices
- Tests are included for new features
- Documentation is updated
- Changes maintain backward compatibility

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, under the terms of either:

- The **Artistic License 2.0**
- The **GNU General Public License** as published by the Free Software Foundation; either version 1, or (at your option) any later version

See [LICENSE](LICENSE) for more details.

## Author

Trickster Contributors
