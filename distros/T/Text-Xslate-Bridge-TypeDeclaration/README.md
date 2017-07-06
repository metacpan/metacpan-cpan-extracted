[![Build Status](https://travis-ci.org/pokutuna/p5-Text-Xslate-Bridge-TypeDeclaration.svg?branch=master)](https://travis-ci.org/pokutuna/p5-Text-Xslate-Bridge-TypeDeclaration) [![Coverage Status](https://img.shields.io/coveralls/pokutuna/p5-Text-Xslate-Bridge-TypeDeclaration/master.svg?style=flat)](https://coveralls.io/r/pokutuna/p5-Text-Xslate-Bridge-TypeDeclaration?branch=master)
# NAME

Text::Xslate::Bridge::TypeDeclaration - A Mouse-based Type Validator in Xslate.

# SYNOPSIS

    my $xslate = Text::Xslate->new(
        module => [ 'Text::Xslate::Bridge::TypeDeclaration' ],
    );

    # @@ template.tx
    # <:- declare(name => 'Str', engine => 'Text::Xslate') -:>
    # <: $name :> version is <: $engine.VERSION :>.

    # Success!
    $xslate->render('template.tx', {
        name   => 'Text::Xslate',
        engine => $xslate
    });
    # Text::Xslate version is 3.4.0.


    # A string 'TT' is not isa 'Text::Xslate'
    $xslate->render('template.tx', {
        name   => 'Text::Xslate',
        engine => $xslate
    });
    # <pre class="type-declaration-mismatch">
    # Declaration mismatch for `engine`
    #   declaration: 'Text::Xslate'
    #         value: 'TT'
    # </pre>
    # Template::Toolkit version is .

# DESCRIPTION

Text::Xslate::Bridge::TypeDeclaration is a type validator module in [Text::Xslate](https://metacpan.org/pod/Text::Xslate) templates.

The type validation of this module is base on [Mouse::Util::TypeConstraints](https://metacpan.org/pod/Mouse::Util::TypeConstraints).

`declare` interface was implemented with reference to [Smart::Args](https://metacpan.org/pod/Smart::Args).

# DECLARATIONS

## Mouse Defaults

- These are provided by [Mouse::Util::TypeConstraints](https://metacpan.org/pod/Mouse::Util::TypeConstraints).
- `declare(name => 'Str')`
- `declare(user_ids => 'ArrayRef[Int]')`

## Object

- These are defined by `find_or_create_isa_type_constraint` when declared.
- `declare(engine => 'Text::Xslate')`
- `declare(visitor => 'Maybe[My::Model::UserAccount]')`

## Hashref

- These validate a hashref structure recursively.
- This is a ** partial ** match. Less value is error. Extra value is ignored.
- `declare(account_summary => { name => 'Str', subscriber_count => 'Int', icon => 'My::Image' })`
- `declare(sidebar => { profile => { name => 'Str', followers => 'Int' }, recent_entries => 'ArrayRef[My::Entry]' })`

## Arrayref

- These validate a arrayref structure recursively.
- This is a ** exact ** match. All items and length will be validated.
- `declare(pair => [ 'My::UserAccount', 'My::UserAccount' ])`
- `declare(args => [ 'Defined', 'Str', 'Maybe[Int]' ])`

# OPTIONS

    Text::Xslate->new(
        module => [
            'Text::Xslate::Bridge::TypeDeclaration' => [
                # defaults
                method      => 'declare', # method name to export
                validate    => 1,         # enable validation when truthy
                print       => 'html',    # error output format ('html', 'text' or 'none')
                on_mismatch => 'die',     # error handler ('die', 'warn' or 'none')
            ]
        ]
    );

# APPENDIX

## Disable Validation on Production

Perhaps you want to disable validation in production to prevent spoiling performance.

    Text::Xslate->new(
        module => [
            'Text::Xslate::Bridge::TypeDeclaration' => [
                validate => $ENV{PLACK_ENV} ne 'production',
            ],
        ],
    );

## Use `type-declaration-mismatch` class name

Highlight by css

    .type-declaration-mismatch { color: crimson; }

Lint with [Test::WWW::Mechanize](https://metacpan.org/pod/Test::WWW::Mechanize)

    # in subclass of Test::WWW::Mechanize
    sub _lint_content_ok {
        my ($self, $desc) = @_;

        if (my $mismatch = $self->scrape_text_by_attr('class', 'type-declaration-mismatch')) {
            $Test::Builder::Test->ok(0, $mismatch);
        };

        return $self->SUPER::_lint_content_ok($desc);
    }

# SEE ALSO

- [Mouse::Util::TypeConstraints](https://metacpan.org/pod/Mouse::Util::TypeConstraints)
- [Smart::Args](https://metacpan.org/pod/Smart::Args)
- [Test::WWW::Mechanize](https://metacpan.org/pod/Test::WWW::Mechanize)
- [Text::Xslate](https://metacpan.org/pod/Text::Xslate)

# LICENSE

Copyright (C) pokutuna.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

pokutuna <popopopopokutuna@gmail.com>
