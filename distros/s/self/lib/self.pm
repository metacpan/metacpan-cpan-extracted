use strict;
use warnings;

package self;
use 5.006;

our $VERSION = '0.36';
use Sub::Exporter;

use B::Hooks::Parser;

my $NO_SELF;

sub import {
    my ($class) = @_;
    my $caller = caller;

    B::Hooks::Parser::setup();

    my $linestr = B::Hooks::Parser::get_linestr();
    my $offset  = B::Hooks::Parser::get_linestr_offset();
    substr($linestr, $offset, 0) = 'use B::OPCheck const => check => \&self::_check;';
    B::Hooks::Parser::set_linestr($linestr);

    my $exporter = Sub::Exporter::build_exporter({
        into_level => 1,
        exports => [qw(self args)],
        groups  => { default =>  [ -all ] }
    });
    $exporter->(@_);
}

sub unimport {
    my ($class) = @_;
    my $caller = caller;
    $NO_SELF = 1;
}

sub _check {
    my $op = shift;
    my $caller = caller;
    return if $NO_SELF;
    return unless ref($op->gv) eq 'B::PV';

    my $linestr = B::Hooks::Parser::get_linestr;
    my $offset  = B::Hooks::Parser::get_linestr_offset;
    my $line = substr($linestr, $offset);

    my $code = 'my($self,@args)=@_;';

    # This cover cases like:
    #     sub foo { ... }
    # Offset is at the first '{' because subroutine name is also a "const"
    if (substr($linestr, $offset, 1) eq '{') {
        if (substr($linestr, 0, $offset) =~ m/sub\s\S+\s*\z/x ) {
            if (index($line, "{$code") < 0) {
                substr($linestr, $offset + 1, 0) = $code;
                B::Hooks::Parser::set_linestr($linestr);
            }
        }
    }
    elsif (substr($linestr, $offset, 3) eq 'sub') {
        if ($line =~ m/^sub\s.*{ /x ) {
            if (index($line, "{$code") < 0) {
                substr($linestr, $offset + index($line, '{') + 1, 0) = $code;
                B::Hooks::Parser::set_linestr($linestr);
            }
        }
    }

    # This elsif block handles:
    # sub foo
    # {
    # ...
    # }
    elsif (index($linestr, 'sub') >= 0) {
        $offset += B::Hooks::Toke::skipspace($offset);
        if ($linestr =~ /(sub.*?\n\s*{)/) {
            my $pos = index($linestr, $1);
            if ($pos + length($1) - 1 == $offset) {
                substr($linestr, $offset + 1, 0) = $code;
                B::Hooks::Parser::set_linestr($linestr);
            }
        }
    }
}

sub _args {
    my $level = 2;
    my @c = ();
    package DB;
    @c = caller($level++)
        while !defined($c[3]) || $c[3] eq '(eval)';
    return @DB::args;
}

sub self {
    (_args)[0];
}

sub args {
    my @a = _args;
    return @a[1..$#a];
}

1;

__END__

=head1 NAME

self - provides '$self' in OO code.

=head1 VERSION

This document describes self version 0.30.

=head1 SYNOPSIS

    package MyModule;
    use self;

    # Write constructor as usual
    sub new {
        return bless({}, shift);
    }

    # '$self' is special now.
    sub foo {
        $self->{foo}
    }

    # '@args' too
    sub set {
        my ($foo, $bar) = @args;
        $self->{foo} = $foo;
        $self->{bar} = $bar;
    }

=head1 DESCRIPTION

This module adds C<$self> and C<@args> variables in your code. So you
don't need to say:

    my $self = shift;

The provided C<$self> and C<@args> are lexicals in your sub, and it's
always the same as saying:

    my ($self, @args) = @_;

... in the first line of sub.

However it is not source filtering, but compile-time code
injection. For more info about code injection, see L<B::Hooks::Parser>.

It also exports a C<self> and a C<args> functions. Basically C<self> is just
equal to C<$_[0]>, and C<args> is just C<$_[1..$#_]>.

For convienence (and backward compatibility), these two functions
are exported by default. If you don't want them to be exported, you
need to say:

    use self ();

Since self.pm uses L<Sub::Exporter>, the exported <self> funciton
can be renamed:

    use self self => { -as => 'this' };

For more information, see L<Sub::Exporter>.

It is recommended to use variables instead, because it's much much
faster. There's a benchmark program under "example" directory compare
them: Here's one example run:

    > perl -Ilib examples/benchmark.pl
              Rate  self $self
    self   46598/s    --  -92%
    $self 568182/s 1119%    --

=head1 INTERFACE

=over

=item $self, or self

Return the current object.

=item @args, or args

Return the argument list.

=back

=head1 CONFIGURATION AND ENVIRONMENT

self.pm requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<B::OPCheck>, C<B::Hooks::Parser>, C<Sub::Exporter>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

In some cases, C<$self> and C<@args> may failed to be injected.

If you're using 0.30, please ensure that your sub declaration has its
'{' at the same line like this:

    sub foo {
    }

Also it's ok to have the entire sub in one line:

    sub foo { }

Please upgrade to 0.31 if you prefer this style of code:

   sub foo
   {
       $self;
   }

Extra spaces around sub declarations are handled as much as possible,
if you found any cases that it failed to work, please send me bug
reports with your test cases.

It does not work on methods generated in runtime. Remember, it's a
compile-time code injection. For those cases, use C<self> function
instead.

Please report any bugs or feature requests to C<bug-self@rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2021 Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
