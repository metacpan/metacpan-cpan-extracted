package Perl::Critic::Policy::ProhibitUnusedImports;
$Perl::Critic::Policy::ProhibitUnusedImports::VERSION = '1.003';
# ABSTRACT: An import nobody uses is a dependency nobody knew they had.

use strict;
use warnings;

use 5.014;

use re '/aa';

use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC => q{Unused import};
Readonly::Scalar my $EXPL => q{Remove it, or the prerequisite it drags along outlives the code that wanted it};

Readonly::Scalar my $DEFAULT_ALLOW => join ' ', qw{
  strict warnings utf8 feature lib autodie parent base constant re
  vars subs overload open integer bytes locale sigtrap version experimental
  Filter::Simple Carp::Always FindBin::libs Test::NoWarnings
  Test2::Plugin::NoWarnings Mojo::Base
};


sub supported_parameters {
    return (
        {
            name           => 'allow',
            description    => 'Modules that are never reported as unused, in addition to the built-in list.',
            default_string => $DEFAULT_ALLOW,
            behavior       => 'string list',
        }
    );
}

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    # 'string list' hands us the configured value in place of the default, and
    # a user naming one bootstrap module of their own did not mean to start
    # reporting `use strict`.
    $self->{_allow}{$_} = 1 for split m/\s+/, $DEFAULT_ALLOW;

    return $self->SUPER::initialize_if_enabled($config);
}

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw(maintenance performance) }
sub applies_to       { return 'PPI::Statement::Include' }
sub is_safe          { return 0 }


sub violates {
    my ( $self, $elem, $document ) = @_;

    return if $elem->type() ne 'use';

    # `use 5.014` and friends are a version check, not an import.  PPI gives
    # those an empty module and a version, rather than no module at all.
    my $module = $elem->module();
    return if !defined $module || !length $module;
    return if $elem->version();
    return if $self->{_allow}{$module};

    my @imports = $self->_imported_names( $elem, $module );
    return if !defined $imports[0] && @imports;    # a tag we could not expand

    # Nothing came in, so the only reason to have loaded it is to name it.
    return $self->violation( $DESC, $EXPL, $elem )
      if !@imports && !_module_referenced( $document, $elem, $module );

    return if !@imports;

    # perl calls these when another file uses this package, so no call is written.
    return if grep { $_ eq 'import' || $_ eq 'unimport' } @imports;

    my $used = _used_names( $document, $elem );
    foreach my $name (@imports) {
        return if $used->{$name};
    }

    # Nothing it brought in is called anywhere, and it may still be here for
    # its own name's sake.
    return if _module_referenced( $document, $elem, $module );
    return $self->violation( $DESC, $EXPL, $elem );
}

# The names this statement puts into our namespace.
sub _imported_names {
    my ( $self, $elem, $module ) = @_;

    my @listed = _literal_arguments($elem);

    # `use Module ();` -- an explicit empty list imports nothing.
    return () if !@listed && _has_empty_list($elem);

    if (@listed) {
        my ( @names, @tags );
        foreach my $item (@listed) {
            $item =~ m/\A[:-]/ ? push( @tags, $item ) : push( @names, $item );
        }

        # A tag stands for a list only the module knows.  Expand it if we can
        # load the module, and say so with a single undef if we cannot, so the
        # caller leaves the statement alone rather than guessing.
        foreach my $tag (@tags) {
            next if $tag =~ m/\A-/;    # -norequire and friends are not imports
            my @expanded = _tag_exports( $module, $tag ) or return (undef);
            push @names, @expanded;
        }

        return map { _strip_sigil($_) } @names;
    }

    # No list at all: whatever @EXPORT says, if it will tell us.
    return map { _strip_sigil($_) } _default_exports($module);
}

# The names behind an import tag, out of the module's %EXPORT_TAGS.
sub _tag_exports {
    my ( $module, $tag ) = @_;

    $tag =~ s/\A://;
    return () if !_load($module);

    no strict 'refs';    ## no critic (ProhibitNoStrict)
    my $tags  = \%{"${module}::EXPORT_TAGS"};
    my $names = $tags->{$tag};
    return () if ref $names ne 'ARRAY';
    return @$names;
}

sub _strip_sigil {
    my ($name) = @_;
    $name =~ s/\A[\$\@\%\&\*]//;
    return $name;
}

# Every literal in the import list, from a qw() or a run of quoted strings.
sub _literal_arguments {
    my ($elem) = @_;

    my @args;
    foreach my $token ( $elem->schildren() ) {
        if ( $token->isa('PPI::Token::QuoteLike::Words') ) {
            push @args, $token->literal();
        }
        elsif ( $token->isa('PPI::Token::Quote') ) {
            push @args, $token->string();
        }
        elsif ( $token->isa('PPI::Structure::List') ) {
            foreach my $inner ( $token->find('PPI::Token::Quote') || () ) {
                push @args, $inner->string();
            }
            foreach my $inner ( $token->find('PPI::Token::QuoteLike::Words') || () ) {
                push @args, $inner->literal();
            }
        }
    }

    return grep { defined $_ && length $_ } @args;
}

sub _has_empty_list {
    my ($elem) = @_;

    foreach my $token ( $elem->schildren() ) {
        next if !$token->isa('PPI::Structure::List');
        return !$token->schildren() ? 1 : 0;
    }
    return 0;
}

# Load the module and ask its symbol table, the way Exporter would.
sub _default_exports {
    my ($module) = @_;

    return () if !_load($module);

    no strict 'refs';    ## no critic (ProhibitNoStrict)
    return @{"${module}::EXPORT"};
}

sub _load {
    my ($module) = @_;

    my $path = $module;
    $path =~ s{::}{/}g;
    $path .= '.pm';

    return 1 if $INC{$path};

    local $SIG{__WARN__} = sub { };
    return eval { require $path; 1 } ? 1 : 0;
}

# Is any name imported by $elem actually used elsewhere in the file?
sub _used_names {
    my ( $document, $elem ) = @_;

    my %used;
    foreach my $word ( @{ $document->find('PPI::Token::Word') || [] } ) {
        next if _inside( $word, $elem );
        my $name = $word->content();
        $name =~ s/\A.*:://;
        $used{$name} = 1;
    }
    foreach my $symbol ( @{ $document->find('PPI::Token::Symbol') || [] } ) {
        next if _inside( $symbol, $elem );
        my $name = $symbol->symbol();
        $name =~ s/\A[\$\@\%\&\*]//;
        $name =~ s/\A.*:://;
        $used{$name} = 1;
    }
    foreach my $name ( _interpolated_names( $document, $elem ) ) {
        $name =~ s/\A.*:://;
        $used{$name} = 1;
    }

    return \%used;
}

# Is the module named anywhere else -- Module::thing, Module->new, $Module::VAR?
sub _module_referenced {
    my ( $document, $elem, $module ) = @_;

    # Another `use Foo::Bar;` is not a use of Foo.  Without this, one unused
    # import hides behind a sibling whose name happens to start the same way,
    # which is exactly the case this policy exists to find.
    my %other_modules;
    foreach my $include ( @{ $document->find('PPI::Statement::Include') || [] } ) {
        next if $include == $elem;
        my $name = $include->module();
        $other_modules{$name} = 1 if defined $name && length $name;
    }

    foreach my $word ( @{ $document->find('PPI::Token::Word') || [] } ) {
        next if _inside( $word, $elem );
        my $content = $word->content();
        next     if $other_modules{$content};
        return 1 if $content eq $module || $content =~ m/\A\Q$module\E::/;
    }
    foreach my $symbol ( @{ $document->find('PPI::Token::Symbol') || [] } ) {
        next     if _inside( $symbol, $elem );
        return 1 if $symbol->symbol() =~ m/\A[\$\@\%\&\*]\Q$module\E::/;
    }
    foreach my $name ( _interpolated_names( $document, $elem ) ) {
        return 1 if $name =~ m/\A\Q$module\E::/;
    }

    return 0;
}

# Names that only ever appear inside an interpolating string.  PPI hands those
# back as one token, so "$FindBin::Bin/../lib" contains no Symbol to find and
# the import that provided it reads as unused.
Readonly::Scalar my $INTERPOLATED_RX => qr/ [\$\@] \{? (\w+ (?: ::\w+ )*) /x;

sub _interpolated_names {
    my ( $document, $elem ) = @_;

    my @classes = qw{
      PPI::Token::Quote::Double
      PPI::Token::Quote::Interpolate
      PPI::Token::QuoteLike::Backtick
      PPI::Token::QuoteLike::Command
      PPI::Token::QuoteLike::Readline
      PPI::Token::HereDoc
    };

    my @names;
    foreach my $class (@classes) {
        foreach my $token ( @{ $document->find($class) || [] } ) {
            next if _inside( $token, $elem );
            my $content = $token->can('heredoc') ? join( '', $token->heredoc() ) : $token->content();
            push @names, $content =~ m/$INTERPOLATED_RX/g;
        }
    }

    return @names;
}

sub _inside {
    my ( $token, $ancestor ) = @_;

    for ( my $node = $token; $node; $node = $node->parent() ) {
        return 1 if $node == $ancestor;
    }
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::ProhibitUnusedImports - An import nobody uses is a dependency nobody knew they had.

=head1 VERSION

version 1.003

=head1 Perl::Critic::Policy::ProhibitUnusedImports

A C<use> nobody uses costs load time, drags a prerequisite along behind it, and
tells the next reader something about this file that isn't true:

    use FindBin();          # ...and $FindBin::Bin appears nowhere below
    use POSIX qw{floor};    # ...and floor() is never called

They accumulate. A sub gets rewritten, the import that fed it stays, and a year
later somebody is keeping a module in F<Makefile.PL> for the sake of a line that
does nothing.

This resolves each imported name and looks for a use of it in the rest of the
document:

=over 4

=item C<use Module LIST>

Each name in the list has to appear -- as a call, a symbol, or after an C<&>.

=item C<use Module;>

Whatever C<@EXPORT> says, if the module can be loaded and says anything.  With
an empty C<@EXPORT> this is the same case as the next one.

=item C<use Module ();>

Nothing is imported, so the module's own name has to appear: C<Module::thing>,
C<< Module->method >>, or C<$Module::VAR>.

=back

=head2 PROHIBITED

    use FindBin();
    print "hello\n";                    # nothing named FindBin below

    use List::Util qw{first any};
    my @x = grep { $_ } @y;             # neither one called

=head2 ALLOWED

    use FindBin();
    print $FindBin::Bin;

    use List::Util qw{any};
    return any { $_ } @list;

Pragmas and other modules whose entire job is a side effect are exempt; see
C<allow> below.

=head2 CONFIGURATION

=over 4

=item C<allow>

Space separated list of modules that are never reported, because importing them
I<is> the point. Adds to the built-in list rather than replacing it, so you name
only what is yours:

    [ProhibitUnusedImports]
    allow = My::Company::Bootstrap

The built-in list is the pragmas plus the usual side-effect modules:

    strict warnings utf8 feature lib autodie parent base constant re
    vars subs overload open integer bytes locale sigtrap version experimental
    Filter::Simple Carp::Always FindBin::libs Test::NoWarnings
    Test2::Plugin::NoWarnings Mojo::Base

Test::NoWarnings and Test2::Plugin::NoWarnings install a check of the warnings
of the whole test from their import.  Mojo::Base takes flags, such as C<-base>
and C<-signatures>, which turn on features and set C<@ISA> rather than name
symbols.

An import of C<import> or C<unimport>, as in C<use Exporter qw{import}>, is
never reported, whatever the module.  perl calls those methods when another
file uses or unuses this package, so the file that imports them never calls
them.

=back

=head2 CAVEATS

Modules exporting into a namespace this file only reaches at runtime -- a
symbolic call, a string C<eval>, an C<AUTOLOAD> -- read as unused, because the
source does not say otherwise. Add them to C<allow>.

Loading the module to read its C<@EXPORT> means running its top-level code, so
this policy is unsafe by Perl::Critic's definition and needs
C<--allow-unsafe>. When the module will not load, its default exports are
unknown and the C<use Module;> case is skipped rather than guessed at.

=head2 METHODS

=head3 supported_parameters

C<allow>, the modules that are never reported, added to the built-in list.

=head3 initialize_if_enabled

Folds the built-in exemptions back into whatever C<allow> was configured with,
so a user's list adds to the defaults instead of replacing them.

=head3 default_severity

SEVERITY_LOW

=head3 default_themes

maintenance, performance

=head3 applies_to

PPI::Statement::Include

=head3 is_safe

False. Reading C<@EXPORT> means loading the module, which runs its top-level
code, so this policy needs C<--allow-unsafe>.

=head3 violates

Standard L<Perl::Critic::Policy> interface. Returns a violation for a C<use>
whose imports -- or whose own name, when it imports nothing -- appear nowhere
else in the document.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitunusedimports/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@gmail.com>

=back

=head1 CONTRIBUTOR

=for stopwords troglodyne-robot

troglodyne-robot <trogbot@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
