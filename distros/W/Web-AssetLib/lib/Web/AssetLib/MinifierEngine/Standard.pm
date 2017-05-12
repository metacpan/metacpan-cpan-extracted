package Web::AssetLib::MinifierEngine::Standard;

use Method::Signatures;
use Moose;
use Carp;

use Web::AssetLib::Util;

use v5.14;
no if $] >= 5.018, warnings => "experimental";

extends 'Web::AssetLib::MinifierEngine';

has 'minifiers' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        my $self = shift;
        {   js => sub {
                my $minifier = \&{ $self->javascript_module . '::minify' };
                return $minifier->( $_[0] );
            },
            css => sub {
                my $minifier = \&{ $self->css_module . '::minify' };
                return $minifier->( $_[0] );
            },
            _else => sub {
                return $_[0];
            }
        };
    }
);

has 'javascript_module' => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,
);

has 'css_module' => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,
);

method _build_css_module {
    return 'CSS::Minifier::XS' if $INC{'CSS/Minifier/XS.pm'};

    return 'CSS::Minifier::XS' if eval { require CSS::Minifier::XS; 1; };
    $self->log->warn(
        'installing CSS::Minifier::XS could yield better performance');
    return 'CSS::Minifier' if eval { require CSS::Minifier; 1 };
    croak
        "no css minifier found (requires CSS::Minifier::XS or CSS::Minifier)";
}

method _build_javascript_module {
    return 'JavaScript::Minifier::XS' if $INC{'JavaScript/Minifier/XS.pm'};

    return 'JavaScript::Minifier::XS'
        if eval { require JavaScript::Minifier::XS; 1; };
    $self->log->warn(
        'installing JavaScript::Minifier::XS could yield better performance');
    return 'JavaScript::Minifier' if eval { require JavaScript::Minifier; 1 };
    croak
        "no Javascript minifier found (requires JavaScript::Minifier::XS or JavaScript::Minifier)";
}

method minify( :$contents!, :$type ) {
    if ( $self->minifiers->{$type} ) {
        return $self->minifiers->{$type}->($contents);
    }
    else {
        $self->minifiers->{'_else'}->($contents);
    }
}

no Moose;
1;

=pod
 
=encoding UTF-8
 
=head1 NAME

Web::AssetLib::MinifierEngine::Standard - basic CSS/Javascript minification engine

=head1 SYNOPSIS

    my $library = My::AssetLib::Library->new(
        minifier_engine => [
            Web::AssetLib::MinifierEngine::Standard->new()
        ]
    );

=head1 DESCRIPTION

Supports types: js, css, stylesheet, javascript.  All other types will pass through
unchanged.  Utilizes either L<CSS::Minifier> and L<JavaScript::Minifier> or 
L<CSS::Minifier::XS> and L<JavaScript::Minifier::XS> depending on availability.

=head1 USAGE

No configuration required. Simply instantiate, and include in your library's
list of input engines.

=head1 SEE ALSO

L<Web::AssetLib::MinifierEngine>

=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut