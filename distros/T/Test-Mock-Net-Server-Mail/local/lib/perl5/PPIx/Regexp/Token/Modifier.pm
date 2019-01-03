=head1 NAME

PPIx::Regexp::Token::Modifier - Represent modifiers.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo}smx' )
     ->print();

The trailing C<smx> will be represented by this class.

This class also represents the whole of things like C<(?ismx)>. But the
modifiers in something like C<(?i:foo)> are represented by a
L<PPIx::Regexp::Token::GroupType::Modifier|PPIx::Regexp::Token::GroupType::Modifier>.

=head1 INHERITANCE

C<PPIx::Regexp::Token::Modifier> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::Modifier> is the parent of
L<PPIx::Regexp::Token::GroupType::Modifier|PPIx::Regexp::Token::GroupType::Modifier>.

=head1 DESCRIPTION

This class represents modifier characters at the end of the regular
expression.  For example, in C<qr{foo}smx> this class would represent
the terminal C<smx>.

=head2 The C<a>, C<aa>, C<d>, C<l>, and C<u> modifiers

The C<a>, C<aa>, C<d>, C<l>, and C<u> modifiers, introduced starting in
Perl 5.13.6, are used to force either Unicode pattern semantics (C<u>),
locale semantics (C<l>) default semantics (C<d> the traditional Perl
semantics, which can also mean 'dual' since it means Unicode if the
string's UTF-8 bit is on, and locale if the UTF-8 bit is off), or
restricted default semantics (C<a>). These are mutually exclusive, and
only one can be asserted at a time. Asserting any of these overrides
the inherited value of any of the others. The C<asserted()> method
reports as asserted the last one it sees, or none of them if it has seen
none.

For example, given C<PPIx::Regexp::Token::Modifier> C<$elem>
representing the invalid regular expression fragment C<(?dul)>,
C<< $elem->asserted( 'l' ) >> would return true, but
C<< $elem->asserted( 'u' ) >> would return false. Note that
C<< $elem->negated( 'u' ) >> would also return false, since C<u> is not
explicitly negated.

If C<$elem> represented regular expression fragment C<(?i)>,
C<< $elem->asserted( 'd' ) >> would return false, since even though C<d>
represents the default behavior it is not explicitly asserted.

=head2 The caret (C<^>) modifier

Calling C<^> a modifier is a bit of a misnomer. The C<(?^...)>
construction was introduced in Perl 5.13.6, to prevent the inheritance
of modifiers. The documentation calls the caret a shorthand equivalent
for C<d-imsx>, and that it the way this class handles it.

For example, given C<PPIx::Regexp::Token::Modifier> C<$elem>
representing regular expression fragment C<(?^i)>,
C<< $elem->asserts( 'd' ) >> would return true, since in the absence of
an explicit C<l> or C<u> this class considers the C<^> to explicitly
assert C<d>.

The caret handling is complicated by the fact that the C<'n'> modifier
was introduced in 5.21.8, at which point the caret became equivalent to
C<d-imnsx>. I did not feel I could unconditionally add the C<-n> to the
expansion of the caret, because that would produce confusing output from
methods like L<explain()|PPIx::Regexp::Element/explain>. Nor could I
make it conditional on the minimum perl version, because that
information is not available early enough in the parse. What I did was
to expand the caret into C<d-imnsx> if and only if C<'n'> was in effect
at some point in the scope in which the modifier was parsed.

Continuing the above example, C<< $elem->asserts( 'n' ) >> and
C<< $elem->modifier_asserted( 'n' ) >> would both return false, but
C<< $elem->negates( 'n' ) >> would return true if and only if the C</m>
modifier has been asserted somewhere before and in-scope from this
token. The
L<modifier_asserted( 'n' )|PPIx::Regexp::Element/modifier_asserted>
method is inherited from L<PPIx::Regexp::Element|PPIx::Regexp::Element>.

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Token::Modifier;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use Carp;
use PPIx::Regexp::Constant qw{
    MINIMUM_PERL
    MODIFIER_GROUP_MATCH_SEMANTICS
    @CARP_NOT
};

our $VERSION = '0.063';

# Define modifiers that are to be aggregated internally for ease of
# computation.
my %aggregate = (
    a	=> MODIFIER_GROUP_MATCH_SEMANTICS,
    aa	=> MODIFIER_GROUP_MATCH_SEMANTICS,
    d	=> MODIFIER_GROUP_MATCH_SEMANTICS,
    l	=> MODIFIER_GROUP_MATCH_SEMANTICS,
    u	=> MODIFIER_GROUP_MATCH_SEMANTICS,
);
my %de_aggregate;
foreach my $value ( values %aggregate ) {
    $de_aggregate{$value}++;
}

# Note that we do NOT want the /o modifier on regexen that make use of
# this, because it is already compiled.
my $capture_group_leader = qr{ [?/(] }smx;	# );

use constant TOKENIZER_ARGUMENT_REQUIRED => 1;

sub __new {
    my ( $class, $content, %arg ) = @_;

    my $self = $class->SUPER::__new( $content, %arg )
	or return;

    $content =~ m{ \A $capture_group_leader* \^ }smx	# no /o!
	and defined $arg{tokenizer}->modifier_seen( 'n' )
	and $self->{__caret_undoes_n} = 1;

    $arg{tokenizer}->modifier_modify( $self->modifiers() );

    return $self;
}

=head2 asserts

 $token->asserts( 'i' ) and print "token asserts i";
 foreach ( $token->asserts() ) { print "token asserts $_\n" }

This method returns true if the token explicitly asserts the given
modifier. The example would return true for the modifier in
C<(?i:foo)>, but false for C<(?-i:foo)>.

Starting with version 0.036_01, if the argument is a
single-character modifier followed by an asterisk (intended as a wild
card character), the return is the number of times that modifier
appears. In this case an exception will be thrown if you specify a
multi-character modifier (e.g.  C<'ee*'>).

If called without an argument, or with an undef argument, all modifiers
explicitly asserted by this token are returned.

=cut

sub asserts {
    my ( $self, $modifier ) = @_;
    $self->{modifiers} ||= $self->_decode();
    if ( defined $modifier ) {
	return __asserts( $self->{modifiers}, $modifier );
    } else {
	return ( sort grep { defined $_ && $self->{modifiers}{$_} }
	    map { $de_aggregate{$_} ? $self->{modifiers}{$_} : $_ }
	    keys %{ $self->{modifiers} } );
    }
}

# This is a kluge for both determining whether the object asserts
# modifiers (hence the 'ductype') and determining whether the given
# modifier is actually asserted. The signature is the invocant and the
# modifier name, which must not be undef. The return is a boolean.
*__ducktype_modifier_asserted = \&asserts;

sub __asserts {
    my ( $present, $modifier ) = @_;
    my $wild = $modifier =~ s/ [*] \z //smx;
    not $wild
	or 1 == length $modifier
	or croak "Can not use wild card on multi-character modifier '$modifier*'";
    if ( my $bin = $aggregate{$modifier} ) {
	my $aggr = $present->{$bin};
	$wild
	    or return ( defined $aggr && $modifier eq $aggr );
	defined $aggr
	    or return 0;
	$aggr =~ m/ \A ( (?: \Q$modifier\E )* ) \z /smx
	    or return 0;
	return length $1;
    }
    if ( $wild ) {
	return $present->{$modifier} || 0;
    }
    my $len = length $modifier;
    $modifier = substr $modifier, 0, 1;
    return $present->{$modifier} && $len == $present->{$modifier};
}

sub can_be_quantified { return };

{
    my %explanation = (
	'm'	=> 'm: ^ and $ match within string',
	'-m'	=> '-m: ^ and $ match only at ends of string',
	's'	=> 's: . can match newline',
	'-s'	=> '-s: . can not match newline',
	'i'	=> 'i: do case-insensitive matching',
	'-i'	=> '-i: do case-sensitive matching',
	'x'	=> 'x: ignore whitespace and comments',
	'xx'	=> 'xx: ignore whitespace even in bracketed character classes',
	'-x'	=> '-x: regard whitespace as literal',
	'p'	=> 'p: provide ${^PREMATCH} etc (pre 5.20)',
	'-p'	=> '-p: no ${^PREMATCH} etc (pre 5.20)',
	'a'	=> 'a: restrict non-Unicode classes to ASCII',
	'aa'	=> 'aa: restrict non-Unicode classes & ASCII-Unicode matches',
	'd'	=> 'd: match using default semantics',
	'l'	=> 'l: match using locale semantics',
	'u'	=> 'u: match using Unicode semantics',
	'n'	=> 'n: parentheses do not capture',
	'-n'	=> '-n: parentheses capture',
	'c'	=> 'c: preserve current position on match failure',
	'g'	=> 'g: match repeatedly',
	'e'	=> 'e: substitution string is an expression',
	'ee'	=> 'ee: substitution is expression to eval()',
	'o'	=> 'o: only interpolate once',
	'r'	=> 'r: aubstitution returns modified string',
    );

    sub explain {
	my ( $self ) = @_;
	my @rslt;
	my %mods = $self->modifiers();
	if ( defined( my $val = delete $mods{match_semantics} ) ) {
	    push @rslt, $explanation{$val};
	}
	foreach my $key ( sort keys %mods ) {
	    if ( my $val = $mods{$key} ) {
		push @rslt, $explanation{ $key x $val };
	    } else {
		push @rslt, $explanation{ "-$key" };
	    }
	}
	return wantarray ? @rslt : join '; ', @rslt;
    }
}

=head2 match_semantics

 my $sem = $token->match_semantics();
 defined $sem or $sem = 'undefined';
 print "This token has $sem match semantics\n";

This method returns the match semantics asserted by the token, as one of
the strings C<'a'>, C<'aa'>, C<'d'>, C<'l'>, or C<'u'>. If no explicit
match semantics are asserted, this method returns C<undef>.

=cut

sub match_semantics {
    my ( $self ) = @_;
    $self->{modifiers} ||= $self->_decode();
    return $self->{modifiers}{ MODIFIER_GROUP_MATCH_SEMANTICS() };
}

=head2 modifiers

 my %mods = $token->modifiers();

Returns all modifiers asserted or negated by this token, and the values
set (true for asserted, false for negated). If called in scalar context,
returns a reference to a hash containing the values.

=cut

sub modifiers {
    my ( $self ) = @_;
    $self->{modifiers} ||= $self->_decode();
    my %mods = %{ $self->{modifiers} };
    foreach my $bin ( keys %de_aggregate ) {
	defined ( my $val = delete $mods{$bin} )
	    or next;
	$mods{$bin} = $val;
    }
    return wantarray ? %mods : \%mods;
}

=head2 negates

 $token->negates( 'i' ) and print "token negates i\n";
 foreach ( $token->negates() ) { print "token negates $_\n" }

This method returns true if the token explicitly negates the given
modifier. The example would return true for the modifier in
C<(?-i:foo)>, but false for C<(?i:foo)>.

If called without an argument, or with an undef argument, all modifiers
explicitly negated by this token are returned.

=cut

sub negates {
    my ( $self, $modifier ) = @_;
    $self->{modifiers} ||= $self->_decode();
    # Note that since the values of hash entries that represent
    # aggregated modifiers will never be false (at least, not unless '0'
    # becomes a modifier) we need no special logic to handle them.
    defined $modifier
	or return ( sort grep { ! $self->{modifiers}{$_} }
	    keys %{ $self->{modifiers} } );
    return exists $self->{modifiers}{$modifier}
	&& ! $self->{modifiers}{$modifier};
}

sub perl_version_introduced {
    my ( $self ) = @_;
    return ( $self->{perl_version_introduced} ||=
	$self->_perl_version_introduced() );
}

sub _perl_version_introduced {
    my ( $self ) = @_;
    my $content = $self->content();
    my $is_statement_modifier = ( $content !~ m/ \A [(]? [?] /smx );
    my $match_semantics = $self->match_semantics();

    $self->asserts( 'xx' )
	and return '5.025009';

    # Disabling capture with /n was introduced in 5.21.8
    $self->asserts( 'n' )
	and return '5.021008';

    # Match semantics modifiers became available as regular expression
    # modifiers in 5.13.10.
    defined $match_semantics
	and $is_statement_modifier
	and return '5.013010';

    # /aa was introduced in 5.13.10.
    defined $match_semantics
	and 'aa' eq $match_semantics
	and return '5.013010';

    # /a was introduced in 5.13.9, but only in (?...), not as modifier
    # of the entire regular expression.
    defined $match_semantics
	and not $is_statement_modifier
	and 'a' eq $match_semantics
	and return '5.013009';

    # /d, /l, and /u were introduced in 5.13.6, but only in (?...), not
    # as modifiers of the entire regular expression.
    defined $match_semantics
	and not $is_statement_modifier
	and return '5.013006';

    # The '^' reassert-defaults modifier in embedded modifiers was
    # introduced in 5.13.6.
    not $is_statement_modifier
	and $content =~ m/ \^ /smx
	and return '5.013006';

    $self->asserts( 'r' ) and return '5.013002';
    $self->asserts( 'p' ) and return '5.009005';
    $self->content() =~ m/ \A [(]? [?] .* - /smx
			and return '5.005';
    $self->asserts( 'c' ) and return '5.004';
    return MINIMUM_PERL;
}

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };


# $present => __aggregate_modifiers( 'modifiers', ... );
#
# This subroutine is private to the PPIx::Regexp package. It may change
# or be retracted without notice. Its purpose is to support defaulted
# modifiers.
#
# Aggregate the given modifiers left-to-right, returning a hash of those
# present and their values.

sub __aggregate_modifiers {
    my ( @mods ) = @_;
    my %present;
    foreach my $content ( @mods ) {
	$content =~ s{ \A $capture_group_leader+ }{}smxg;	# no /o!
	if ( $content =~ m/ \A \^ /smx ) {
	    @present{ MODIFIER_GROUP_MATCH_SEMANTICS(), qw{ i s m x } }
		= qw{ d 0 0 0 0 };
	}

	# Have to do the global match rather than a split, because the
	# expression modifiers come through here too, and we need to
	# distinguish between s/.../.../e and s/.../.../ee. But the
	# modifiers can be randomized (that is, /eie is the same as
	# /eei), so we reorder the content first.

	# The following line is WRONG because it ignores the
	# significance of '-'. This bug was introduced in version 0.035,
	# specifically by the change that handled multi-character
	# modifiers.
	# $content = join '', sort split qr{}smx, $content;

	# The following is better because it re-orders the modifiers
	# separately. It does not recognize multiple dashes as
	# representing an error (though it could!), and modifiers that
	# are both asserted and negated (e.g. '(?i-i:foo)') are simply
	# considered to be negated (as Perl does as of 5.20.0).
	$content = join '-',
	    map { join '', sort split qr{}smx }
	    split qr{-}smx, $content;
	my $value = 1;
	while ( $content =~ m/ ( ( [[:alpha:]-] ) \2* ) /smxg ) {
	    if ( '-' eq $1 ) {
		$value = 0;
	    } elsif ( my $bin = $aggregate{$1} ) {
		# Yes, technically the match semantics stuff can't be
		# negated in a regex. But it can in a 'use re', which
		# also comes through here, so we have to handle it.
		$present{$bin} = $value ? $1 : undef;
	    } else {
		# TODO have to think about this, since I need asserts(
		# 'e' ) to be 2 if we in fact have 'ee'. Is this
		# correct?
#		$present{$1} = $value;
		$present{$2} = $value * length $1;
	    }
	}
    }
    return \%present;
}

# This must be implemented by tokens which do not recognize themselves.
# The return is a list of list references. Each list reference must
# contain a regular expression that recognizes the token, and optionally
# a reference to a hash to pass to make_token as the class-specific
# arguments. The regular expression MUST be anchored to the beginning of
# the string.
sub __PPIX_TOKEN__recognize {
    return (
	[ qr{ \A [(] [?] [[:lower:]]* -? [[:lower:]]* [)] }smx ],
	[ qr{ \A [(] [?] \^ [[:lower:]]* [)] }smx ],
    );
}

{

    # Called by the tokenizer to modify the current modifiers with a new
    # set. Both are passed as hash references, and a reference to the
    # new hash is returned.
    sub __PPIX_TOKENIZER__modifier_modify {
	my ( @args ) = @_;

	my %merged;
	foreach my $hash ( @args ) {
	    while ( my ( $key, $val ) = each %{ $hash } ) {
		if ( $val ) {
		    $merged{$key} = $val;
		} else {
		    delete $merged{$key};
		}
	    }
	}

	return \%merged;

    }

    # Decode modifiers from the content of the token.
    sub _decode {
	my ( $self ) = @_;
	my $mod = __aggregate_modifiers( $self->content() );
	$self->{__caret_undoes_n}
	    and $mod->{n} = 0;
	return $mod;
    }
}

1;

__END__

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
