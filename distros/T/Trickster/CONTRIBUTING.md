# Contributing to Trickster

Thank you for your interest in contributing to Trickster! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help maintain a welcoming environment

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/trickster.git`
3. Install dependencies: `cpanm --installdeps .`
4. Create a branch: `git checkout -b feature/your-feature-name`

## Development Workflow

### Running Tests

```bash
# Run all tests
prove -l t/

# Run specific test
prove -l t/01-basic.t

# Run with verbose output
prove -lv t/

# Use the test runner script
./run_tests.sh
```

### Code Style

- Follow Perl Best Practices
- Use `strict` and `warnings`
- Minimum Perl version: 5.14
- Use 4 spaces for indentation
- Keep lines under 100 characters when reasonable
- Add POD documentation for public methods

Example:

```perl
package Trickster::Component;

use strict;
use warnings;
use v5.14;

sub new {
    my ($class, %opts) = @_;
    
    return bless {
        option => $opts{option} || 'default',
    }, $class;
}

1;

__END__

=head1 NAME

Trickster::Component - Brief description

=head1 SYNOPSIS

    use Trickster::Component;
    
    my $comp = Trickster::Component->new;

=head1 DESCRIPTION

Detailed description here.

=cut
```

## Making Changes

### Adding a New Feature

1. **Discuss First**: Open an issue to discuss the feature
2. **Write Tests**: Add tests in `t/` directory
3. **Implement**: Write the code
4. **Document**: Update POD and README.md
5. **Test**: Ensure all tests pass
6. **Submit**: Create a pull request

### Fixing a Bug

1. **Create Test**: Add a failing test that demonstrates the bug
2. **Fix**: Implement the fix
3. **Verify**: Ensure the test now passes
4. **Document**: Update Changes file
5. **Submit**: Create a pull request

### Adding Documentation

- Update POD in module files
- Update README.md for user-facing changes
- Update ARCHITECTURE.md for design changes
- Add examples in `examples/` directory
- Update QUICKSTART.md for common use cases

## Testing Guidelines

### Test Structure

```perl
use strict;
use warnings;
use Test::More;

use_ok('Trickster::Component');

# Test basic functionality
{
    my $comp = Trickster::Component->new;
    ok($comp, 'Component created');
    is($comp->method, 'expected', 'Method returns expected value');
}

# Test edge cases
{
    my $comp = Trickster::Component->new(option => 'value');
    is($comp->option, 'value', 'Option set correctly');
}

# Test error conditions
{
    eval {
        Trickster::Component->new(invalid => 'option');
    };
    ok($@, 'Dies with invalid option');
}

done_testing;
```

### Test Coverage

- Aim for high test coverage
- Test happy paths and error conditions
- Test edge cases
- Test integration between components

## Pull Request Process

1. **Update Documentation**: Ensure all docs are updated
2. **Add Tests**: Include tests for new functionality
3. **Update Changes**: Add entry to Changes file
4. **Run Tests**: Ensure all tests pass
5. **Clean Commits**: Use clear, descriptive commit messages
6. **Submit PR**: Create pull request with description

### Commit Messages

Use clear, descriptive commit messages:

```
Add validation for email fields

- Implement email validation rule
- Add tests for email validation
- Update documentation
```

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] All tests pass
- [ ] New tests added
- [ ] Manual testing completed

## Documentation
- [ ] POD updated
- [ ] README updated
- [ ] Examples added/updated

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Changes file updated
```

## Component Guidelines

### Creating New Components

New components should:

1. Have a single, well-defined responsibility
2. Follow existing naming conventions
3. Include comprehensive POD documentation
4. Have thorough test coverage
5. Integrate cleanly with existing components

Example structure:

```
lib/Trickster/NewComponent.pm
t/XX-new-component.t
```

### API Design

- Keep APIs simple and intuitive
- Use method chaining where appropriate
- Provide sensible defaults
- Make common tasks easy, complex tasks possible
- Follow Perl conventions

## Documentation Standards

### POD Documentation

Every module should include:

- NAME section
- SYNOPSIS with usage examples
- DESCRIPTION with detailed explanation
- Method documentation with parameters and return values
- EXAMPLES section for complex usage
- SEE ALSO for related modules

### README Updates

Update README.md when:

- Adding new features
- Changing public APIs
- Adding new dependencies
- Changing installation process

## Release Process

(For maintainers)

1. Update version in lib/Trickster.pm
2. Update Changes file with release date
3. Run full test suite
4. Update documentation
5. Create git tag
6. Build distribution: `perl Makefile.PL && make dist`
7. Upload to CPAN

## Questions?

- Open an issue for questions
- Check existing issues and documentation
- Reach out to maintainers

## Recognition

Contributors will be:

- Listed in the Changes file
- Credited in release notes
- Acknowledged in documentation

Thank you for contributing to Trickster! 🎩✨
