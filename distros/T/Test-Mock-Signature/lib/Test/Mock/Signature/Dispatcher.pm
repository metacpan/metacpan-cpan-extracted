package Test::Mock::Signature::Dispatcher;

use strict;
use warnings;

use Data::PatternCompare;

sub new {
    my $class  = shift;
    my $method = shift;

    my $params = {
        _method  => $method,
        _list    => [],
        _cmp     => Data::PatternCompare->new,
        _default => undef,
    };
    return bless($params, $class);
}

sub add {
    my $self = shift;
    my $meta = shift;
    my $list = $self->{'_list'};
    my $cmp  = $self->{'_cmp'};

    @$list = sort { $cmp->compare_pattern($a->params, $b->params) } @$list, $meta;
}

sub delete {
    my $self = shift;
    my $meta = shift;
    my $list = $self->{'_list'};
    my $cmp  = $self->{'_cmp'};

    @$list = grep { !$cmp->eq_pattern($_->params, $meta->params) } @$list;
}

sub compile {
    my $self = shift;
    return if defined $self->{'_default'};

    my $list = $self->{'_list'};
    my $cmp  = $self->{'_cmp'};

    $self->{'_default'} ||= do {
        no strict 'refs';

        *{$self->{'_method'}}{'CODE'}
    };
    my $default = $self->{'_default'};

    my $code = sub {
        my ($self, @params) = @_;

        for my $meta ( @$list ) {
            if ($cmp->pattern_match(\@params, $meta->params)) {
                my $cb = $meta->callback;

                goto &$cb;
            }
        }

        goto &$default;
    };

    no strict 'refs';
    no warnings 'redefine';
    *{$self->{'_method'}} = $code;
}

sub DESTROY {
    my $self   = shift;
    my $method = $self->{'_method'};

    no strict 'refs';
    no warnings 'redefine';
    *$method = $self->{'_default'};
}

42;

__END__

=head1 NAME

Test::Mock::Signature::Dispatcher - method dispatcher class.

=head1 SYNOPSIS

You can add one more metadata to you dispatcher:

    my $dispatcher = $mock->dispatcher('my_method_name');
    $dispatcher->add($meta);

Or delete some meta:

    $dispatcher->delete($meta);

Also you can compile your dispatcher meta information:

    $dispatcher->compile;

=head1 DESCRIPTION

Provides a dispatching mechanism for main mock module L<Test::Mock::Signature>.

=head1 METHODS

=head2 new($method_name)

Takes C<$method_name> fully qualifed method name e.g.: Real::Module::method.
Returns instance of the L<Test::Mock::Signature::Dispatcher> class.

=head2 add($meta)

Takes object of the L<Test::Mock::Signature::Meta> class and put it into
dispatching list.

=head2 delete($meta)

Takes object of the L<Test::Mock::Signature::Meta> class and remove it from
dispatching list.

=head2 compile

Mocks the method in real class and put dispatching mechanism - on.

=head2 DESTROY

Removes mocked method and put back default behavior.

=head1 AUTHOR

cono E<lt>cono@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014 - cono

=head1 LICENSE

Artistic v2.0

=head1 SEE ALSO

L<Test::Mock::Signature>
