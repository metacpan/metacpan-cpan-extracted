package Test2::Plugin::SpecDeclare;
use strict;
use warnings;

use Devel::Declare;
use B::Hooks::EndOfScope;

use Carp qw/croak/;

our $VERSION = '0.000003';

sub import {
    my $class = shift;
    my $into  = caller;

    my @keywords;
    my %params;
    for my $arg (@_) {
        if ($arg =~ m/^-(.+)$/) {
            $params{$1} = 1;
            next;
        }
        push @keywords => $arg;
    }

    if(delete $params{spec} || !@_) {
        my %seen;
        push @keywords => grep { !$seen{$_}++ && $into->can($_) }
            @Test2::Tools::Spec::EXPORT,
            @Test2::Tools::Spec::EXPORT_OK;
    }

    croak "Unknown parameter(s): " . join(',', map { "-$_" } keys %params)
        if keys %params;

    croak "No keywords (Did you forget to load Test2::Tools::Spec, or specify a list of keywords?)"
        unless @keywords;

    Devel::Declare->setup_for(
        $into,
        {map { $_ => {const => \&parser} } @keywords},
    );
}

sub inject {
    on_scope_end {
        my $linestr = Devel::Declare::get_linestr;
        my $offset  = Devel::Declare::get_linestr_offset;
        substr($linestr, $offset, 0) = ', __LINE__;';
        Devel::Declare::set_linestr($linestr);
    };
}

sub parser {
    my ($declarator, $offset) = @_;
    my @caller = caller(1);

    # Skip the declarator
    $offset += Devel::Declare::toke_move_past_token($offset);
    $offset += Devel::Declare::toke_skipspace($offset);
    my $line = Devel::Declare::get_linestr();

    my $name;
    my $name_offset = $offset;
    my $name_len;

    # Get the block name
    my $start = substr($line, $offset, 1);
    if ($start eq '(') {
        # No changes
        return;
    }
    elsif ($start eq '"' || $start eq "'") {
        # Quoted name
        $name_len = Devel::Declare::toke_scan_str($offset);
        $name     = Devel::Declare::get_lex_stuff();
        Devel::Declare::clear_lex_stuff();
        $offset += $name_len;
    }
    elsif ($name_len = Devel::Declare::toke_scan_word($offset, 1)) {
        # Bareword name
        $name = substr($line, $offset, $name_len);
        $offset += $name_len;
    }

    $offset += Devel::Declare::toke_skipspace($offset);
    $line = Devel::Declare::get_linestr();

    my $meta = "";
    my $meta_offset;
    my $meta_len;

    $start = substr($line, $offset, 1);
    if ($start eq '(') {
        $meta_offset = $offset;
        $meta_len    = Devel::Declare::toke_scan_str($offset);
        $meta        = Devel::Declare::get_lex_stuff();
        Devel::Declare::clear_lex_stuff();
        $line = Devel::Declare::get_linestr();

        die "Syntax error at $caller[1] line $caller[2]: Test2::Plugin::SpecDeclare does not support multiline parameters.\n"
            if $meta =~ m/\n/;

        $offset += $meta_len;
        $offset += Devel::Declare::toke_skipspace($offset);
        $line = Devel::Declare::get_linestr();
        $start = substr($line, $offset, 1);
    }

    # No changes
    return unless $start eq '{';

    # Ok! we are good to munge this thing!
    substr($line, $offset, 1) = " sub { BEGIN { Test2::Plugin::SpecDeclare::inject() }; ";

    if ($meta) {
        substr($line, $meta_offset + $meta_len - 1, 1) = '}, ';
        substr($line, $meta_offset, 1) = ' +{';
    }

    substr($line, $name_offset + $name_len, 0) = ' => __LINE__, ';

    Devel::Declare::set_linestr($line);
    $line = Devel::Declare::get_linestr();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::SpecDeclare - Syntax keywords for L<Test2::Tools::Spec>.

=head1 DESCRIPTION

This adds keywords for all the exports provided by L<Test2::Tools::Spec>. These
keywords add sugar-coating to the Spec tools.

=head1 SYNOPSIS

    use Test2::Tools::Spec;
    use Test2::Plugin::Spec;

    tests foo {
        ...
    }

    describe bar {
        before_each blah { ... }

        case a { ... }
        case b { ... }

        tests x(todo => 'not ready') { ... }
        tests y(skip => 'will die' ) { ... }
    }

    done_testing;

All exports from L<Test2::Tools::Spec> gain keyword status. You can use a
bareword or a quoted string as a name, you can specify options as a signature,
then you provide a block, no trailing semicolon or 'sub' keyword needed.

    KEYWORD NAME { ... }
    KEYWORD NAME(KEY => VAL, ...) { ... }

    KEYWORD 'NAME' { ... }
    KEYWORD 'NAME'(KEY => VAL, ...) { ... }

    KEYWORD "NAME" { ... }
    KEYWORD "NAME"(KEY => VAL, ...) { ... }

Non-keyword forms still work:

    FUNCTION NAME => sub { ... };
    FUNCTION NAME => {...}, sub { ... };

    FUNCTION('NAME', sub { ... });
    FUNCTION('NAME', {...}, sub { ... });

=head1 SOURCE

The source code repository for Test2-Workflow can be found at
F<http://github.com/Test-More/Test2-Workflow/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
