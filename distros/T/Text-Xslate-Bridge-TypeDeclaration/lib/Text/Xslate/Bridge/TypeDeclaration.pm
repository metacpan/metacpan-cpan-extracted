package Text::Xslate::Bridge::TypeDeclaration;
use strict;
use warnings;
use parent qw(Text::Xslate::Bridge);

use Carp qw(croak);
use Data::Dumper;
use List::MoreUtils qw(all);
use Scalar::Util qw(blessed);
use Text::Xslate qw(mark_raw);
use Text::Xslate::Bridge::TypeDeclaration::Registry;
use Type::Registry ();
use Type::Tiny qw();
use Types::Standard qw(Any Dict slurpy);

our $VERSION = '0.13';

# Set truthy value to skip validation for local scope.
our $DISABLE_VALIDATION = 0;

our $IMPORT_DEFAULT_ARGS = {
    method         => 'declare',
    validate       => 1,
    print          => 1,
    on_mismatch    => 'die', # Cannot give a subroutine reference >_<
    registry_class => undef, # Class name for Type::Registry to lookup types
};

sub export_into_xslate {
    my $class     = shift;
    my $funcs_ref = shift;

    my $args = @_ == 1 ? shift : { @_ };
    croak sprintf '%s can receive either a hash or a hashref.', $class
        unless ref $args && ref($args) eq 'HASH';

    for my $key (keys %$IMPORT_DEFAULT_ARGS) {
        $args->{$key} = $IMPORT_DEFAULT_ARGS->{$key} unless defined $args->{$key};
    }

    my $registry = defined $args->{registry_class}
        ? Type::Registry->for_class($args->{registry_class})
        : Text::Xslate::Bridge::TypeDeclaration::Registry->new;

    $class->bridge(function => { $args->{method} => _declare_func($args, $registry) });
    $class->SUPER::export_into_xslate($funcs_ref, @_);
}

sub _declare_func {
    my ($args, $registry) = @_;

    return sub {
        return if $DISABLE_VALIDATION || !$args->{validate};

        while (my ($key, $declaration) = splice(@_, 0, 2)) {
            my $type = _type($declaration, $registry);
            my $value = Text::Xslate->current_vars->{$key};

            unless ($type->check($value)) {
                my $msg = sprintf(
                    "Declaration mismatch for `%s`\n  %s\n", $key, $type->get_message($value)
                );
                _print($msg) if $args->{print};
                last if _on_mismatch($msg, $args->{on_mismatch});
            }
        };

        return;
    };
}

# This treats unknown types as a declaration error.
sub _get_invalid_type {
    my ($name_or_struct) = @_;

    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Maxdepth = 2;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Useqq    = 1;

    my $name = Dumper($name_or_struct);
    return Type::Tiny->new(
        display_name => $name,
        constraint   => sub { },
        message      => sub { "$name is not a known type" },
    );
}

# returns: Type::Tiny
sub _type {
    my ($name_or_struct, $registry) = @_;

    return _get_invalid_type($name_or_struct)
        if !defined $name_or_struct || $name_or_struct eq '';

    if (my $ref = ref $name_or_struct) {
        return _hash_structure($name_or_struct, $registry) if $ref eq 'HASH';
        return _get_invalid_type($name_or_struct);
    } else {
        my $type = eval { $registry->lookup($name_or_struct) };
        return ($type && blessed($type) && $type->can('check'))
            ? $type : _get_invalid_type($name_or_struct);
    }
}

sub _hash_structure {
    my ($hash, $registry) = @_;

    return Dict[
        (map { $_ => _type($hash->{$_}, $registry) } keys %$hash),
        slurpy Any
    ];
}

sub _print {
    my ($msg) = @_;

    my $is_html = (Text::Xslate->current_engine->{type} || '') ne 'text';

    my @outputs = $is_html
        ? (mark_raw("<pre class=\"type-declaration-mismatch\">\n"), $msg, mark_raw("</pre>\n"))
        : (mark_raw($msg));

    Text::Xslate->print(@outputs);
}

sub _on_mismatch {
    my ($msg, $func) = @_;

    my $h = +{
        die  => [ 'die_handler',  1 ],
        warn => [ 'warn_handler', 0 ],
        none => [ undef,          0 ]
    }->{$func};

    if ($h->[0]) {
        my $handler = Text::Xslate->current_engine->{$h->[0]};
        $handler->($msg) if $handler;
    }
    return $h->[1];
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::Xslate::Bridge::TypeDeclaration - A Type Validator in Xslate.

=head1 SYNOPSIS

    my $xslate = Text::Xslate->new(
        module => [ 'Text::Xslate::Bridge::TypeDeclaration' ],
    );

    # @@ template.tx
    # <:- declare(
    #   user  => 'Some::Model::User',
    #   drink => 'Enum["Cocoa", "Cappuchino", "Tea"]'
    # ) -:>
    # <: user.name :> is drinking a cup of <: $drink :>.

    # Success!
    $xslate->render('template.tx', {
        user  => Some::Model::User->new(name => 'pokutuna'),
        drink => 'Cocoa',
    });
    # Output:
    #   pokutuna is drinking a cup of Cocoa.


    # A string 'Oil' is not a drink
    $xslate->render('template.tx', {
        user  => Some::Model::User->new(name => 'pokutuna'),
        drink => 'Oil',
    });
    # Output:
    #   <pre class="type-declaration-mismatch">
    #   Declaration mismatch for `drink`
    #     Value "Oil" did not pass type constraint "Enum["Cocoa", "Cappuchino", "Tea"]"
    #   </pre>
    #   pokutuna is drinking a cup of Oil.

=head1 DESCRIPTION

Text::Xslate::Bridge::TypeDeclaration is a type validator module for L<Text::Xslate> templates.

Type validation of this module is base on L<Type::Tiny>.

L<Type::Tiny> type constraints are compatible with Moo, Moose and Mouse.

You can use this even if you do not use these type libraries.

If the library-based type is not found, treats as a class type of the name.


=head1 DECLARATIONS

This module looks for a type name that was written in the template from L<Text::Xslate::Bridge::TypeDeclaration::Registry> by default.

The following behaviors can be replaced by specifying the registry in C<registry_class_name> option.

=head2 Types::Standard

See L<Types::Standard>.

=over 4

=item C<< declare(name => 'Str') >>

=item C<< declare(user_ids => 'ArrayRef[Int]') >>

=item C<< declare(person_hash => 'Dict[name => Str, age => Int]') >>

=back

=head2 Class-Type

It will be treated as a class type when a type of the given name is not found.

=over 4

=item C<< declare(engine => 'Text::Xslate') >>

=item C<< declare(visitor => 'Maybe[My::Model::UserAccount]') >>

=back

=head2 Hashref

Hashref is treated as C<Dict[... slurpy Any]>.

This is a B< slurpy > match. Less value is error. Extra values are ignored.

=over 4

=item C<< declare(account_summary => { name => 'Str', subscriber_count => 'Int', icon => 'My::Image' }) >>

=item C<< declare(sidebar => { profile => { name => 'Str', followers => 'Int' }, recent_entries => 'ArrayRef[My::Entry]' }) >>

=back

=head1 OPTIONS

    Text::Xslate->new(
        module => [
            'Text::Xslate::Bridge::TypeDeclaration' => [
                # defaults
                method         => 'declare', # method name to export
                validate       => 1,         # enable validation when truthy
                print          => 1,         # enable printing errors to the output buffer when truthy
                on_mismatch    => 'die',     # error handler ('die', 'warn' or 'none')
                registry_class => undef,     # package name for specifying Type::Registry
            ]
        ]
    );


=head1 APPENDIX

=head2 Disable Validation on Production

Perhaps you want to disable validation in production to prevent spoiling performance on a L<Plack> application.

    Text::Xslate->new(
        module => [
            'Text::Xslate::Bridge::TypeDeclaration' => [
                validate => $ENV{PLACK_ENV} ne 'production',
            ],
        ],
    );

=head2 Use C<< type-declaration-mismatch >> class name

Highlight by css

    .type-declaration-mismatch { color: crimson; }


Lint with L<Test::WWW::Mechanize>

    # in subclass of Test::WWW::Mechanize
    sub _lint_content_ok {
        my ($self, $desc) = @_;

        if (my $mismatch = $self->scrape_text_by_attr('class', 'type-declaration-mismatch')) {
            $Test::Builder::Test->ok(0, $mismatch);
        };

        return $self->SUPER::_lint_content_ok($desc);
    }

=head1 SEE ALSO

L<Text::Xslate>, L<Text::Xslate::Bridge>

L<Type::Tiny>, L<Types::Standard>, L<Type::Registry>

L<Smart::Args>, L<Test::WWW::Mechanize>

=head1 LICENSE

Copyright (C) pokutuna.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

pokutuna E<lt>popopopopokutuna@gmail.comE<gt>

=cut
