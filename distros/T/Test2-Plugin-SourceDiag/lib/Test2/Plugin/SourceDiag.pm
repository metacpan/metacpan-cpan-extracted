package Test2::Plugin::SourceDiag;
use strict;
use warnings;

our $VERSION = '0.000004';

use Test2::Event::Diag;

use Scalar::Util();

use Test2::API qw{
    test2_add_callback_post_load
    test2_stack
};

my %SEEN;

sub import {
    my $class  = shift;
    my %params = @_;

    $params{show_source} = 1 unless defined $params{show_source};

    test2_add_callback_post_load(
        sub {
            my $hub = test2_stack()->top;
            $hub->filter(\&filter, inherit => 1) if $params{show_source} || $params{inject_name};
            $hub->listen(\&listener, inherit => 1) if $params{show_source} || $params{show_args};
            $hub->add_context_init(\&context_init) if $params{show_args};
        }
    );
}

sub context_init {
    my $ctx = shift;

    package DB;

    my @caller = caller(1);
    my %args   = @DB::args;
    my $level  = $args{level} || 1;

    @caller = caller(1 + $level);

    $ctx->trace->{args} = [grep { !Scalar::Util::blessed($_) || !$_->isa('Test::Builder')} @DB::args];
}

sub filter {
    my ($hub, $event) = @_;
    return $event unless $event->causes_fail;

    my $trace = $event->trace           or return $event;
    my $code  = get_assert_code($trace) or return $event;

    if ($event->can('name') && !$event->name && $event->can('set_name')) {
        my $text = join "\n" => @{$code->{source}};
        $text =~ s/^\s*//;
        $event->set_name($text);
    }
    else {
        my $start = $code->{start};
        my $end   = $code->{end};
        my $len   = length("$end");
        my $text = join "\n" => map { sprintf("% ${len}s: %s", $start++, $_) } @{$code->{source}};
        $event->meta(__PACKAGE__, {})->{code} = $text;
    }

    return $event;
}

sub listener {
    my ($hub, $event) = @_;

    return unless $event->causes_fail;

    my $trace = $event->trace;
    my $meta  = $event->get_meta(__PACKAGE__);
    my $code  = $meta ? $meta->{code} : undef;
    my $args  = $trace ? $trace->{args} : undef;

    return unless $code || $args;

    my $msg = '';

    $msg .= "Failure source code:\n------------\n$code\n------------\n"
        if $code;

    $msg .= "Failure Arguments: (" . join(', ', map { defined($_) ? "'$_'" : 'undef' } @$args) . ")"
        if $args;

    $hub->send(
        Test2::Event::Diag->new(
            trace   => $trace,
            message => $msg,
        )
    );
}

my %CACHE;

sub get_assert_code {
    my ($trace) = @_;

    my $file = $trace->file    or return;
    my $line = $trace->line    or return;
    my $sub  = $trace->subname or return;
    my $short_sub = $sub;
    $short_sub =~ s/^.*:://;
    return if $short_sub eq '__ANON__';

    my %subs = ($sub => 1, $short_sub => 1);

    require PPI::Document;
    my $pd = $CACHE{$file} ||= PPI::Document->new($file);
    $pd->index_locations;

    my $it = $pd->find(sub { !$_[1]->isa('PPI::Token::Whitespace') && $_[1]->logical_line_number == $line }) or return;

    my $found = $it->[0] or return;

    my $thing = $found;
    while ($thing) {
        if (($thing->can('children') && $subs{($thing->children)[0]->content}) || $subs{$thing->content}) {
            $found = $thing;
            last;
        }

        $thing = $thing->parent;
    }

    my @source;

    push @source => split /\r?\n/, $found->content;

    # Add in any indentation we may have cut off.
    my $prefix = $thing->previous_sibling;
    if ($prefix && $prefix->isa('PPI::Token::Whitespace') && $prefix->content ne "\n") {
        my $space = $prefix->content;
        $space =~ s/^.*\n//s;
        $source[0] = $space . $source[0] if length($space);
    }

    my $start = $found->logical_line_number;
    return {
        start  => $start,
        end    => $start + $#source,
        source => \@source,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::SourceDiag - Output the lines of code that resulted in a
failure.

=head1 DESCRIPTION

This plugin injects diagnostics messages that include the lines of source that
executed to produce the test failure. This is a less magical answer to Damian
Conway's L<Test::Expr> module, that has the benefit of working on any Test2
based test.

=head1 SYNOPSIS

This test:

    use Test2::V0;
    use Test2::Plugin::SourceDiag;

    ok(0, "fail");

    done_testing;

Produces the output:

    not ok 1 - fail
    Failure source code:
    # ------------
    # 4: ok(0, "fail");
    # ------------
    # Failed test 'fail'
    # at test.pl line 4.

=head1 IMPORT OPTIONS

=head2 show_source

    use Test2::Plugin::SourceDiag show_source => $bool;

C<show_source> is set to on by default. You can specify C<0> if you want to
turn it off.

Source output:

    not ok 1 - fail
    Failure source code:
    # ------------
    # 4: ok(0, "fail");
    # ------------
    # Failed test 'fail'
    # at test.pl line 4.

=head2 show_args

    use Test2::Plugin::SourceDiag show_args => $bool

C<show_args> is set to off by default. You can turn it on with a true value.

Args output:

    not ok 1 - fail
    Failure source code:
    # ------------
    # 4: ok($x, "fail");
    # ------------
    # Failure Arguments: (0, 'fail')      <----- here
    # Failed test 'fail'
    # at test.pl line 4.

=head2 inject_name

    use Test2::Plugin::SourceDiag inject_name => $bool

C<inject_name> is off by default. You may turn it on if desired.

This feature will inject the source as the name of your assertion if the name
has not already been set. When this happens the failure source diag will not be
seen as the name is sufficient.

    not ok 1 - ok($x eq $y);
    # Failed test 'ok($x eq $y);'
    # at test.pl line 4.

B<note:> This works perfectly fine with multi-line statements.

=head1 SOURCE

The source code repository for Test2-Plugin-SourceDiag can be found at
F<http://github.com/Test-More/Test2-Plugin-SourceDiag/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2017 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
