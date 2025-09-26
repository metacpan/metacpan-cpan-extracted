package Text::HTML::Turndown::Rules 0.08;
use 5.020;
use Moo;
use experimental 'signatures';
use stable 'postderef';
use Carp 'croak';

has 'options' => (
    is => 'ro',
    required => 1,
);

has 'rules' => (
    is => 'ro',
    required => 1,
);

has '_preprocess' => (
    is => 'lazy',
    default => sub { [] },
);

has '_keep' => (
    is => 'lazy',
    default => sub { [] },
);

has '_remove' => (
    is => 'lazy',
    default => sub { [] },
);

has 'array' => (
    is => 'lazy',
    default => sub($self) {
        my @arr;
        my $r = $self->rules // {};
        for my $rule ( sort keys $r->%*) {
            push @arr, $r->{$rule};
        }
        return \@arr;
    },
);

has 'defaultReplacement' => (
    is => 'lazy',
    default => sub {
        sub( $content, $node, $options, $context ) {
            $node->isBlock ? "\n\n" . $content . "\n\n" : $content
        }
    }
);

has 'blankReplacement' => (
    is => 'lazy',
    default => sub {
        sub( $content, $node, $options, $context ) {
            $node->isBlock ? "\n\n" : ''
        }
    }
);

sub add( $self, $key, $rule ) {
    unshift $self->array->@*, $rule
}

sub preprocess( $self, $processor ) {
    unshift $self->_preprocess->@*, $processor
}

sub keep( $self, $filter ) {
    unshift $self->_keep->@*, $filter
}

sub remove( $self, $filter ) {
    unshift $self->_remove->@*, {
        filter => $filter,
        replacement => sub {
            return '';
        },
    };
}

sub blankRule( $self ) {
    return {
        replacement => $self->blankReplacement,
    }
}

sub defaultRule( $self ) {
    return {
        replacement => $self->defaultReplacement
    }
}

sub forNode( $self, $node ) {
    if ($node->isBlank) {
        return $self->blankRule };
    my $rule;
    if ($rule = $self->findRule($self->array,   $node, $self->options)) { return $rule; }
    if ($rule = $self->findRule($self->_keep,   $node, $self->options)) { return $rule; }
    if ($rule = $self->findRule($self->_remove, $node, $self->options)) { return $rule; }

    return $self->defaultRule
};

sub forEach($self, $fn) {
    my $arr = $self->array;
    $fn->( $arr->[ $_ ] )
        for (0..$#{$arr});
}

sub findRule( $self, $rules, $node, $options ) {
    for my $r ($rules->@*) {
        return $r
            if( $self->filterValue( $r, $node, $options ))
    }
    return $self->defaultRule
}

sub filterValue( $self, $rule, $node, $options ) {
    my $filter = $rule->{filter};
    if( ! ref $filter ) {
        return $filter eq lc($node->nodeName)
    } elsif( ref $filter eq 'ARRAY' ) {
        my $nn = lc $node->nodeName;
        return scalar grep { $nn eq $_ } $filter->@*
    } elsif( ref $filter eq 'CODE' ) {
        return $filter->( $rule, $node, $options )
    } else {
        croak "Unknown filter type '$filter'";
    }
}

1;
=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Text-HTML-Turndown>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/Text-HTML-Turndown/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2025- by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the Artistic License 2.0.

=cut
