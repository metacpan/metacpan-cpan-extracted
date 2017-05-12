package Test::Base::Less;
use strict;
use warnings;
use utf8;

our $VERSION = '0.13';

use parent qw/Test::Builder::Module Exporter/;
use Test::More;
use Data::Section::TestBase ();
use Carp ();

our @EXPORT = (@Test::More::EXPORT, qw/filters blocks register_filter run run_is run_is_deeply/);

our %FILTER_MAP;
our %FILTERS;

sub register_filter($&) {
    my ($name, $code) = @_;
    $FILTERS{$name} = $code;
}

sub filters($) {
    my $data = shift;
    for my $key (keys %$data) {
        $FILTER_MAP{$key} ||= [];
        push @{$FILTER_MAP{$key}}, @{$data->{$key}};
    }
    return;
}

sub blocks() {
    my @blocks = _get_blocks(scalar(caller(0)));
    return @blocks;
}

sub _get_blocks {
    my $package = shift;

    my $d = do { no strict 'refs'; \*{"${package}::DATA"} };
    unless (defined fileno $d) {
        Carp::croak("Missing __DATA__ section in $package.");
    }
    seek $d, 0, 0;

    my $content = join '', <$d>;

    my $parser = Text::TestBase->new();
    my @blocks = $parser->parse($content);
    my @retval;
    for my $block (@blocks) {
        for my $section_name ($block->get_section_names) {
            my @data = $block->get_section($section_name);
            if (my $filter_names = $FILTER_MAP{$section_name}) {
                for my $filter_stuff (@$filter_names) {
                    if (ref $filter_stuff eq 'CODE') { # filters { input => [\&code] };
                        @data = $filter_stuff->(@data);
                    } else { # filters { input => [qw/eval/] };
                        my $filter = $FILTERS{$filter_stuff};
                        unless ($filter) {
                            Carp::croak "Unknown filter name: $filter_stuff";
                        }
                        @data = $filter->(@data);
                    }
                }
            }
            $block->set_section($section_name => @data);
        }
        if ($block->has_section('ONLY')) {
            __PACKAGE__->builder->diag("I found ONLY: maybe you're debugging?");
            return $block;
        }
        if ($block->has_section('SKIP')) {
            next;
        }
        push @retval, $block;
        if ($block->has_section('LAST')) {
            return @retval;
        }
    }
    return @retval;
}

sub run(&) {
    my $code = shift;

    for my $block (_get_blocks(scalar(caller(0)))) {
        __PACKAGE__->builder->subtest($block->name || 'L: ' . $block->get_lineno, sub {
            $code->($block);
        });
    }
}

sub run_is($$) {
    my ($a, $b) = @_;

    for my $block (_get_blocks(scalar(caller(0)))) {
        __PACKAGE__->builder->is_eq(
            $block->get_section($a),
            $block->get_section($b),
            $block->name || 'L: ' . $block->get_lineno
        );
    }
}

sub run_is_deeply($$) {
    my ($a, $b) = @_;

    for my $block (_get_blocks(scalar(caller(0)))) {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        Test::More::is_deeply(
            $block->get_section($a),
            $block->get_section($b),
            $block->name || 'L: ' . $block->get_lineno
        );
    }
}

package Test::Base::Less::Filter;

Test::Base::Less::register_filter(eval => \&_eval);

sub _eval {
    my $src = shift;
    no warnings;
    my @return = CORE::eval $src;
    return $@ if $@;
    return @return;
}

Test::Base::Less::register_filter(chomp => \&_chomp);
sub _chomp {
    map { CORE::chomp; $_ } @_;
}

Test::Base::Less::register_filter(uc => \&_uc);
sub _uc {
    map { CORE::uc($_) } @_;
}

Test::Base::Less::register_filter(trim => \&_trim);
sub _trim {
    map {
        s/\A([ \t]*\n)+//;
        s/(?<=\n)\s*\z//g;
        $_;
    } @_;
}

Test::Base::Less::register_filter(lines => \&_lines);
sub _lines {
    my $src = shift;
    return () unless length $src;
    my @lines = ($src =~ /^(.*\n?)/gm);
    return @lines;
}

1;
__END__

=head1 NAME

Test::Base::Less - Limited version of Test::Base.

=head1 SYNOPSIS

    use Test::Base::Less;

    filters {
        input => [qw/eval/],
    };

    for my $block (blocks) {
        is($block->input, $block->expected);
    }
    done_testing;

    __DATA__

    ===
    --- input: 4*2
    --- expected: 8

=head1 DESCRIPTION

This is a less clever version of Test::Base.

=head1 FUNCTIONS

This module exports all Test::More's exportable functions, and following functions:

=over 4

=item filters(+{ } : HashRef);

    filters {
        input => [qw/eval/],
    };

Set a filter for the section name.

=item blocks()

Get a list of Text::TestBase::Block as filtered.

=item register_filter($name: Str, $code: CodeRef)

Register a filter for $name using $code.

=back

=head1 DEFAULT FILTERS

This module provides only few filters. If you want to add more filters, pull-reqs welcome.
(I only merge a patch using no depended modules)

=over 4

=item eval

eval() the code.

=item chomp

C<chomp()> the arguments.

=item uc

C<uc()> the arguments.

=item trim

Remove extra blank lines from the beginning and end of the data. This
allows you to visually separate your test data with blank lines.

=item lines

Break the data into an anonymous array of lines.
Each line (except possibly the last one if the chomp filter came first)
will have a newline at the end.

=back

=head1 REGISTER YOUR OWN FILTER

You can register your own filter by following form:

    use Digest::MD5 qw/md5_hex/;
    Test::Base::Less::register_filter(md5_hex => \&md5_hex);

=head1 USE CODEREF AS FILTER

You can use a CodeRef as filter.

    use Digest::MD5 qw/md5_hex/;
    filters {
        input => [\&md5_hex],
    };

=head1 SEE ALSO

Most of code is taken from L<Test::Base>. Thanks Ingy.
