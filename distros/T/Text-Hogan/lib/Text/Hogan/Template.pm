package Text::Hogan::Template;
$Text::Hogan::Template::VERSION = '2.03';
use strict;
use warnings;

use Clone qw(clone);
use Ref::Util qw( is_ref is_arrayref is_coderef is_hashref);
use Scalar::Util qw(looks_like_number);

sub new {
    my ($orig, $code_obj, $text, $compiler, $options) = @_;

    $code_obj ||= {};

    return bless {
        r   => $code_obj->{'code'} || (is_hashref($orig) && $orig->{'r'}),
        c   => $compiler,
        buf => "",
        options  => $options || {},
        text     => $text || "",
        partials => $code_obj->{'partials'} || {},
        subs     => $code_obj->{'subs'} || {},
        numeric_string_as_string => !!$options->{'numeric_string_as_string'},
    }, ref($orig) || $orig;
}

sub r {
    my ($self, $context, $partials, $indent) = @_;

    if ($self->{'r'}) {
        return $self->{'r'}->($self, $context, $partials, $indent);
    }

    return "";
}

my %mapping = ( 
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    q{'} => '&#39;',
    '"' => '&quot;',
);

# create regex once
my $mapping_re = join('', '[', ( sort keys %mapping ), ']');

sub v {
    my ($self, $str) = @_;
    $str //= "";
    $str =~ s/($mapping_re)/$mapping{$1}/ge;

    return $str;
}

sub t {
    my ($self, $str) = @_;
    return defined($str) ? $str : "";
}

sub render {
    my ($self, $context, $partials, $indent) = @_;
    return $self->ri([ $context ], $partials || {}, $indent);
}

sub ri {
    my ($self, $context, $partials, $indent) = @_;
    return $self->r($context, $partials, $indent);
}

sub ep {
    my ($self, $symbol, $partials) = @_;
    my $partial = $self->{'partials'}{$symbol};

    # check to see that if we've instantiated this partial before
    my $template = $partials->{$partial->{'name'}};
    if ($partial->{'instance'} && $partial->{'base'} eq $template) {
        return $partial->{'instance'};
    }

    if (! is_ref($template) ) {
        die "No compiler available" unless $self->{'c'};
        
        $template = $self->{'c'}->compile($template, $self->{'options'});
    }

    return undef unless $template;

    $self->{'partials'}{$symbol}{'base'} = $template;

    if ($partial->{'subs'}) {
        # make sure we consider parent template now
        $partials->{'stack_text'} ||= {};

        for my $key (sort keys %{ $partial->{'subs'} }) {
            if (!$partials->{'stack_text'}{$key}) {
                $partials->{'stack_text'}{$key} =
                    $self->{'active_sub'} && $partials->{'stack_text'}{$self->{'active_sub'}}
                        ? $partials->{'stack_text'}{$self->{'active_sub'}}
                        : $self->{'text'};
            }
        }
        $template = create_specialized_partial($template, $partial->{'subs'}, $partial->{'partials'}, $self->{'stack_subs'}, $self->{'stack_partials'}, $self->{'stack_text'});
    }
    $self->{'partials'}{$symbol}{'instance'} = $template;

    return $template;
}

# tries to find a partial in the current scope and render it
sub rp {
    my ($self, $symbol, $context, $partials, $indent) = @_;

    my $partial = $self->ep($symbol, $partials) or return "";

    return $partial->ri($context, $partials, $indent);
}

# render a section
sub rs {
    my ($self, $context, $partials, $section) = @_;
    my $tail = $context->[-1];
    if (! is_arrayref($tail) ) {
        $section->($context, $partials, $self);
        return;
    }

    for my $t (@$tail) {
        push @$context, $t;
        $section->($context, $partials, $self);
        pop @$context;
    }
}

# maybe start a section
sub s {
    my ($self, $val, $ctx, $partials, $inverted, $start, $end, $tags) = @_;
    my $pass;

    return 0 if (is_arrayref($val)) && !@$val;

    if (is_coderef($val)) {
        $val = $self->ms($val, $ctx, $partials, $inverted, $start, $end, $tags);
    }

    $pass = !!$val;

    if (!$inverted && $pass && $ctx) {
        push @$ctx, (is_arrayref($val) || is_hashref($val)) ? $val : $ctx->[-1];
    }

    return $pass;
}

# find values with dotted names
sub d {
    my ($self, $key, $ctx, $partials, $return_found) = @_;
    my $found;

    # JavaScript split is super weird!!
    #
    # GOOD:
    # > "a.b.c".split(".")
    # [ 'a', 'b', 'c' ]
    #
    # BAD:
    # > ".".split(".")
    # [ '', '' ]
    #
    my @names = $key eq '.' ? ( '' ) x 2 : split /\./, $key;

    my $val = $self->f($names[0], $ctx, $partials, $return_found);

    my $cx;

    if ($key eq '.' && is_arrayref($ctx->[-2])) {
        $val = $ctx->[-1];
    }
    else {
        for my $name (@names[1..$#names] ) {
            $found = find_in_scope($name, $val);
            if (defined $found) {
                $cx = $val;
                $val = $found;
            }
            else {
                $val = "";
            }
        }
    }

    return 0 if $return_found && !$val;

    if (!$return_found && is_coderef($val)) {
        push @$ctx, $cx;
        $val = $self->mv($val, $ctx, $partials);
        pop @$ctx;
    }

    return $self->_check_for_num($val);
}

# handle numerical interpolation for decimal numbers "properly"...
#
# according to the mustache spec 1.210 should render as 1.21
#
# unless the optional numeric_string_as_string was passed
sub _check_for_num {
    my $self = shift;
    my $val = shift;
    return $val if ($self->{'numeric_string_as_string'} == 1);

    $val += 0 if looks_like_number($val);

    return $val;
}

# find values with normal names
sub f {
    my ($self, $key, $ctx, $partials, $return_found) = @_;
    my ( $val, $found ) = ( 0 );

    for my $v ( reverse @$ctx ) {
        $val = find_in_scope($key, $v);

        next unless defined $val;

        $found = 1;
        last;
    }

    return $return_found ? 0 : "" unless $found;

    if (!$return_found && is_coderef($val)) {
        $val = $self->mv($val, $ctx, $partials);
    }

    return $self->_check_for_num($val);
}

# higher order templates
sub ls {
    my ($self, $func, $cx, $ctx, $partials, $text, $tags) = @_;
    my $old_tags = $self->{'options'}{'delimiters'};

    $self->{'options'}{'delimiters'} = $tags;
    $self->b($self->ct($func->($text), $cx, $partials));
    $self->{'options'}{'delimiters'} = $old_tags;

    return 0;
}

# compile text
sub ct {
    my ($self, $text, $cx, $partials) = @_;

    die "Lambda features disabled"
        if $self->{'options'}{'disable_lambda'};

    return $self->{'c'}->compile($text, $self->{'options'})->render($cx, $partials);
}

# template result buffering
sub b {
    my ($self, $s) = @_;
    $self->{'buf'} .= $s;
}

sub fl {
    my ($self) = @_;
    my $r = $self->{'buf'};
    $self->{'buf'} = "";
    return $r;
}

# method replace section
sub ms {
    my ($self, $func, $ctx, $partials, $inverted, $start, $end, $tags) = @_;

    return 1 if $inverted;

    my $text_source = ($self->{'active_sub'} && $self->{'subs_text'} && $self->{'subs_text'}{$self->{'active_sub'}})
        ? $self->{'subs_text'}{$self->{'active_sub'}}
        : $self->{'text'};

    my $s = substr($text_source,$start,($end-$start));

    $self->ls($func, $ctx->[-1], $ctx, $partials, $s, $tags);

    return 0;
}

# method replace variable
sub mv {
    my ($self, $func, $ctx, $partials) = @_;
    my $cx = $ctx->[-1];
    my $result = $func->($self,$cx);

    return $self->ct($result, $cx, $partials);
}

sub sub {
    my ($self, $name, $context, $partials, $indent) = @_;
    my $f = $self->{'subs'}{$name} or return;

    $self->{'active_sub'} = $name;
    $f->($context,$partials,$self,$indent);
    $self->{'active_sub'} = 0;
}

################################################

sub find_in_scope {
    my ($key, $scope) = @_;

    return eval { $scope->{$key} };
}

sub create_specialized_partial {
    my ($instance, $subs, $partials, $stack_subs, $stack_partials, $stack_text) = @_;

    my $Partial = clone($instance);
    $Partial->{'buf'} = "";

    $stack_subs ||= {};
    $Partial->{'stack_subs'} = $stack_subs;
    $Partial->{'subs_text'} = $stack_text;

    for my $key (sort keys %$subs) {
        if (!$stack_subs->{$key}) {
            $stack_subs->{$key} = $subs->{$key};
        }
    }
    for my $key (sort keys %$stack_subs) {
        $Partial->{'subs'}{$key} = $stack_subs->{$key};
    }

    $stack_partials ||= {};
    $Partial->{'stack_partials'} = $stack_partials;

    for my $key (sort keys %$partials) {
        if (!$stack_partials->{$key}) {
            $stack_partials->{$key} = $partials->{$key};
        }
    }
    for my $key (sort keys %$stack_partials) {
        $Partial->{'partials'}{$key} = $stack_partials->{$key};
    }

    return $Partial;
}


sub coerce_to_string {
    my ($str) = @_;
    return defined($str) ? $str : "";
}

1;

__END__

=head1 NAME

Text::Hogan::Template - represent and render compiled templates

=head1 VERSION

version 2.03

=head1 SYNOPSIS

Use Text::Hogan::Compiler to create Template objects.

Then call render passing in a hashref for context.

    use Text::Hogan::Compiler;

    my $template = Text::Hogan::Compiler->new->compile("Hello, {{name}}!");

    say $template->render({ name => $_ }) for (qw(Fred Wilma Barney Betty));

Optionally takes a hashref of partials.

    use Text::Hogan::Compiler;

    my $template = Text::Hogan::Compiler->new->compile("{{>hello}}");

    say $template->render({ name => "Dino" }, { hello => "Hello, {{name}}!" });

=head1 AUTHORS

Started out statement-for-statement copied from hogan.js by Twitter!

Initial translation by Alex Balhatchet (alex@balhatchet.net)

Further improvements from:

Ed Freyfogle
Mohammad S Anwar
Ricky Morse
Jerrad Pierce
Tom Hukins
Tony Finch
Yanick Champoux

=cut
