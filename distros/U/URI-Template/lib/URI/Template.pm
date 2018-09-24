package URI::Template;

use strict;
use warnings;

our $VERSION = '0.24';

use URI;
use URI::Escape        ();
use Unicode::Normalize ();
use overload '""' => \&template;

use Exporter 'import';

our @EXPORT = qw ( );

our @EXPORT_OK = qw (
    template_process
    template_process_to_string
);

our %EXPORT_TAGS = (
    'all' => \@EXPORT_OK,
);

my $RESERVED = q(:/?#\[\]\@!\$\&'\(\)\*\+,;=);
my %TOSTRING = (
    ''  => \&_tostring,
    '+' => \&_tostring,
    '#' => \&_tostring,
    ';' => \&_tostring_semi,
    '?' => \&_tostring_query,
    '&' => \&_tostring_query,
    '/' => \&_tostring_path,
    '.' => \&_tostring_path,
);

sub new {
    my $class = shift;
    my $templ = shift;
    $templ = '' unless defined $templ;
    my $self  = bless { template => $templ, _vars => {} } => $class;

    $self->_study;

    return $self;
}

sub _quote {
    my ( $val, $safe ) = @_;
    $safe ||= '';
    my $unsafe = '^A-Za-z0-9\-\._' . $safe;

    ## Where RESERVED are allowed to pass-through, so are
    ## already-pct-encoded values
    if( $safe ) {
        my (@chunks) = split(/(%[0-9A-Fa-f]{2})/, $val);

        # even chunks are not %xx, odd chunks are
        return join '',
            map { $_ % 2
                  ? $chunks[$_]
                  : URI::Escape::uri_escape_utf8( Unicode::Normalize::NFKC($chunks[$_]), $unsafe ) } 0..$#chunks;

    }

    # try to mirror python's urllib quote
    return URI::Escape::uri_escape_utf8( Unicode::Normalize::NFKC( $val ),
        $unsafe );
}

sub _tostring {
    my ( $var, $value, $exp ) = @_;
    my $safe = $exp->{ safe };

    if ( ref $value eq 'ARRAY' ) {
        return join( ',', map { _quote( $_, $safe ) } @$value );
    }
    elsif ( ref $value eq 'HASH' ) {
        return join(
            ',',
            map {
                _quote( $_, $safe )
                    . ( $var->{ explode } ? '=' : ',' )
                    . _quote( $value->{ $_ }, $safe )
                } sort keys %$value
        );
    }
    elsif ( defined $value ) {
        return _quote(
            substr( $value, 0, $var->{ prefix } || length( $value ) ),
            $safe );
    }

    return;
}

sub _tostring_semi {
    my ( $var, $value, $exp ) = @_;
    my $safe = $exp->{ safe };
    my $join = $exp->{ op };
    $join = '&' if $exp->{ op } eq '?';

    if ( ref $value eq 'ARRAY' ) {
        if ( $var->{ explode } ) {
            return join( $join,
                map { $var->{ name } . '=' . _quote( $_, $safe ) } @$value );
        }
        else {
            return $var->{ name } . '='
                . join( ',', map { _quote( $_, $safe ) } @$value );
        }
    }
    elsif ( ref $value eq 'HASH' ) {
        if ( $var->{ explode } ) {
            return join(
                $join,
                map {
                    _quote( $_, $safe ) . '='
                        . _quote( $value->{ $_ }, $safe )
                    } sort keys %$value
            );
        }
        else {
            return $var->{ name } . '=' . join(
                ',',
                map {
                    _quote( $_, $safe ) . ','
                        . _quote( $value->{ $_ }, $safe )
                    } sort keys %$value
            );
        }
    }
    elsif ( defined $value ) {
        return $var->{ name } unless length( $value );
        return
            $var->{ name } . '='
            . _quote(
            substr( $value, 0, $var->{ prefix } || length( $value ) ),
            $safe );
    }

    return;
}

sub _tostring_query {
    my ( $var, $value, $exp ) = @_;
    my $safe = $exp->{ safe };
    my $join = $exp->{ op };
    $join = '&' if $exp->{ op } =~ /[?&]/;

    if ( ref $value eq 'ARRAY' ) {
        return if !@$value;
        if ( $var->{ explode } ) {
            return join( $join,
                map { $var->{ name } . '=' . _quote( $_, $safe ) } @$value );
        }
        else {
            return $var->{ name } . '='
                . join( ',', map { _quote( $_, $safe ) } @$value );
        }
    }
    elsif ( ref $value eq 'HASH' ) {
        return if !keys %$value;
        if ( $var->{ explode } ) {
            return join(
                $join,
                map {
                    _quote( $_, $safe ) . '='
                        . _quote( $value->{ $_ }, $safe )
                    } sort keys %$value
            );
        }
        else {
            return $var->{ name } . '=' . join(
                ',',
                map {
                    _quote( $_, $safe ) . ','
                        . _quote( $value->{ $_ }, $safe )
                    } sort keys %$value
            );
        }
    }
    elsif ( defined $value ) {
        return $var->{ name } . '=' unless length( $value );
        return
            $var->{ name } . '='
            . _quote(
            substr( $value, 0, $var->{ prefix } || length( $value ) ),
            $safe );
    }
}

sub _tostring_path {
    my ( $var, $value, $exp ) = @_;
    my $safe = $exp->{ safe };
    my $join = $exp->{ op };

    if ( ref $value eq 'ARRAY' ) {
        return unless @$value;
        return join(
            ( $var->{ explode } ? $join : ',' ),
            map { _quote( $_, $safe ) } @$value
        );
    }
    elsif ( ref $value eq 'HASH' ) {
        return join(
            ( $var->{ explode } ? $join : ',' ),
            map {
                _quote( $_, $safe )
                    . ( $var->{ explode } ? '=' : ',' )
                    . _quote( $value->{ $_ }, $safe )
                } sort keys %$value
        );
    }
    elsif ( defined $value ) {
        return _quote(
            substr( $value, 0, $var->{ prefix } || length( $value ) ),
            $safe );
    }

    return;
}

sub _study {
    my ( $self ) = @_;
    my @hunks = grep { defined && length } split /(\{.+?\})/, $self->template;
    my $pos = 1;
    for ( @hunks ) {
        next unless /^\{(.+?)\}$/;
        $_ = $self->_compile_expansion( $1, $pos++ );
    }
    $self->{ studied } = \@hunks;
}

sub _compile_expansion {
    my ( $self, $str, $pos ) = @_;

    my %exp = ( op => '', vars => [], str => $str );
    if ( $str =~ /^([+#.\/;?&|!\@])(.+)/ ) {
        $exp{ op }  = $1;
        $exp{ str } = $2;
    }

    $exp{ safe } = $RESERVED if $exp{ op } =~ m{[+#]};

    for my $varspec ( split( ',', delete $exp{ str } ) ) {
        my %var = ( name => $varspec );
        if ( $varspec =~ /=/ ) {
            @var{ 'name', 'default' } = split( /=/, $varspec, 2 );
        }
        if ( $var{ name } =~ s{\*$}{} ) {
            $var{ explode } = 1;
        }
        elsif ( $var{ name } =~ /:/ ) {
            @var{ 'name', 'prefix' } = split( /:/, $var{ name }, 2 );
            if ( $var{ prefix } =~ m{[^0-9]} ) {
                die 'Non-numeric prefix specified';
            }
        }

        # remove "optional" flag (for opensearch compatibility)
        $var{ name } =~ s{\?$}{};
        $self->{ _vars }->{ $var{ name } } = $pos;

        push @{ $exp{ vars } }, \%var;
    }

    my $join  = $exp{ op };
    my $start = $exp{ op };

    if ( $exp{ op } eq '+' ) {
        $start = '';
        $join  = ',';
    }
    elsif ( $exp{ op } eq '#' ) {
        $join = ',';
    }
    elsif ( $exp{ op } eq '?' ) {
        $join = '&';
    }
    elsif ( $exp{ op } eq '&' ) {
        $join = '&';
    }
    elsif ( $exp{ op } eq '' ) {
        $join = ',';
    }

    if ( !exists $TOSTRING{ $exp{ op } } ) {
        die 'Invalid operation "' . $exp{ op } . '"';
    }

    return sub {
        my $variables = shift;

        my @return;
        for my $var ( @{ $exp{ vars } } ) {
            my $value;
            if ( exists $variables->{ $var->{ name } } ) {
                $value = $variables->{ $var->{ name } };
            }
            $value = $var->{ default } if !defined $value;

            next unless defined $value;

            my $expand = $TOSTRING{ $exp{ op } }->( $var, $value, \%exp );

            push @return, $expand if defined $expand;
        }

        return $start . join( $join, @return ) if @return;
        return '';
    };
}

sub template {
    my $self = shift;
    my $templ = shift;

    #   Update template
    if ( defined $templ && $templ ne $self->{ template } ) {
        $self->{ template } = $templ;
        $self->{ _vars } = {};
        $self->_study;
        return $self;
    }

    return $self->{ template };
}

sub variables {
    my @vars = sort {$_[ 0 ]->{ _vars }->{ $a } <=> $_[ 0 ]->{ _vars }->{ $b } } keys %{ $_[ 0 ]->{ _vars } };
    return @vars;
}

sub expansions {
    my $self = shift;
    return grep { ref } @{ $self->{ studied } };
}

sub process {
    my $self = shift;
    return URI->new( $self->process_to_string( @_ ) );
}

sub process_to_string {
    my $self = shift;
    my $arg  = @_ == 1 ? $_[ 0 ] : { @_ };
    my $str  = '';

    for my $hunk ( @{ $self->{ studied } } ) {
        if ( !ref $hunk ) { $str .= $hunk; next; }

        $str .= $hunk->( $arg );
    }

    return $str;
}

sub template_process {
    __PACKAGE__->new(shift)->process(@_)
}

sub template_process_to_string {
    __PACKAGE__->new(shift)->process_to_string(@_)
}

1;

__END__

=head1 NAME

URI::Template - Object for handling URI templates (RFC 6570)

=head1 SYNOPSIS

    use URI::Template;
   
    my $template = URI::Template->new( 'http://example.com/{x}' );
    my $uri      = $template->process( x => 'y' );
    
    # or
    
    my $template = URI::Template->new();
    $template->template( 'http://example.com/{x}' );
    my $uri      = $template->process( x => 'y' );
    
    # uri is a URI object with value 'http://example.com/y'

or

    use URI::Template ':template_process'
    
    my $uri = template_process ( 'http://example.com/{x}', x => 'y' );

=head1 DESCRIPTION

This module provides a wrapper around URI templates as described in RFC 6570: 
L<< http://tools.ietf.org/html/rfc6570 >>.

=head1 INSTALLATION

    perl Makefile.PL
    make
    make test
    make install

=head1 METHODS

=head2 new( $template )

Creates a new L<URI::Template> instance with the template passed in
as the first parameter (optional).

=head2 template( $template )

This method returns the original template string. If provided, it will also set and parse a 
new template string.

=head2 variables

Returns an array of unique variable names found in the template (in the order of appearance).

=head2 expansions

This method returns an list of expansions found in the template.  Currently,
these are just coderefs.  In the future, they will be more interesting.

=head2 process( \%vars )

Given a list of key-value pairs or an array ref of values (for
positional substitution), it will URI escape the values and
substitute them in to the template. Returns a URI object.

=head2 process_to_string( \%vars )

Processes input like the C<process> method, but doesn't inflate the result to a
URI object.

=head1 EXPORTED FUNCTIONS

=head2 template_process( $template => \%vars )

This is the same as C<< URI::Template->new($template)->process(\%vars) >> But
shorter, and usefull for quick and easy genrating a nice URI form parameters.

Returns an L<URI> object

=head2 template_process_as_string( $template => \%vars )

Same as above, but obviously, returns a string.

=head1 AUTHORS

=over 4

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=item * Ricardo SIGNES E<lt>rjbs@cpan.orgE<gt>

=back

=head1 CONTRIBUTERS

=over 4

=item * Theo van Hoesel E<lt>Th.J.v.Hoesel@THEMA-MEDIA.nlE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2018 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
