package Version::libversion::PP;

use feature ':5.10';
use strict;
use utf8;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
    version_compare
    version_compare2
    version_compare4
);

our @EXPORT_OK = qw(
    VERSIONFLAG_P_IS_PATCH
    VERSIONFLAG_ANY_IS_PATCH
    VERSIONFLAG_LOWER_BOUND
    VERSIONFLAG_UPPER_BOUND

    P_IS_PATCH
    ANY_IS_PATCH
    LOWER_BOUND
    UPPER_BOUND
);

our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

our $VERSION = '1.00';

use overload ('""' => \&value, cmp => \&cmp, '<=>' => \&cmp, fallback => 1);

use constant VERSIONFLAG_P_IS_PATCH   => 0x1;
use constant VERSIONFLAG_ANY_IS_PATCH => 0x2;
use constant VERSIONFLAG_LOWER_BOUND  => 0x4;
use constant VERSIONFLAG_UPPER_BOUND  => 0x8;

use constant P_IS_PATCH   => 0x1;
use constant ANY_IS_PATCH => 0x2;
use constant LOWER_BOUND  => 0x4;
use constant UPPER_BOUND  => 0x8;

use constant METAORDER_LOWER_BOUND   => 0;
use constant METAORDER_PRE_RELEASE   => 1;
use constant METAORDER_ZERO          => 2;
use constant METAORDER_POST_RELEASE  => 3;
use constant METAORDER_NONZERO       => 4;
use constant METAORDER_LETTER_SUFFIX => 5;
use constant METAORDER_UPPER_BOUND   => 6;

use constant KEYWORD_UNKNOWN      => 0;
use constant KEYWORD_PRE_RELEASE  => 1;
use constant KEYWORD_POST_RELEASE => 2;

sub new {

    my ($class, $value, $flags) = @_;
    my $self = {value => $value, flags => $flags};

    return bless $self, $class;

}

*parse = \&new;

sub value { shift->{value} }
sub flags { shift->{flags} }

sub cmp {

    my ($left, $right) = @_;

    unless (ref($right)) {
        $right = __PACKAGE__->new($right);
    }

    return version_compare($left->value, $right->value, ($left->flags || 0), ($right->flags || 0));

}

sub _skip_separator {

    my $string = shift;

    $string =~ s/^[^[:alnum:]]+//;
    return $string;

}

sub _split_alpha {

    my $string = shift;

    if ($string =~ /^([[:alpha:]]+)/) {
        return ($1, substr($string, length($1)));
    }

    return ('', $string);

}

sub _split_number {

    my $string = shift;

    if ($string =~ /^([[:digit:]]+)/) {
        my $num  = $1;
        my $rest = substr($string, length($1));

        $num =~ s/^0+//;    # skip_zeroes
        return ($num, $rest);
    }

    return ('', $string);

}

sub _classify_keyword {

    my ($string, $flags) = @_;

    $string = lc($string);

    return KEYWORD_PRE_RELEASE  if ($string =~ /^(alpha|beta|rc)$/);
    return KEYWORD_PRE_RELEASE  if ($string =~ /^pre/);
    return KEYWORD_POST_RELEASE if ($string =~ /^(post|patch)/);
    return KEYWORD_POST_RELEASE if ($string =~ /^(pl|errata)$/);
    return KEYWORD_POST_RELEASE if ($string eq 'p' && ($flags & VERSIONFLAG_P_IS_PATCH));

    return KEYWORD_UNKNOWN;

}

sub _parse_token_to_component {

    my ($string, $flags) = @_;

    my $component = {};

    if ($string =~ /^[[:alpha:]]/) {

        my ($alpha, $rest) = _split_alpha($string);

        my $keyword_class = _classify_keyword($alpha, $flags);

        if ($keyword_class == KEYWORD_UNKNOWN) {
            $component->{order} = ($flags & VERSIONFLAG_ANY_IS_PATCH) ? METAORDER_POST_RELEASE : METAORDER_PRE_RELEASE;
        }

        $component->{order} = METAORDER_PRE_RELEASE  if $keyword_class == KEYWORD_PRE_RELEASE;
        $component->{order} = METAORDER_POST_RELEASE if $keyword_class == KEYWORD_POST_RELEASE;

        $component->{value} = lc(substr($alpha, 0, 1));

        return ($component, $rest);
    }
    else {

        my ($number, $rest) = _split_number($string);

        $component->{value} = $number;
        $component->{order} = (length($number) == 0) ? METAORDER_ZERO : METAORDER_NONZERO;

        return ($component, $rest);

    }

}

sub _make_default_component {

    my $flags = shift || 0x0;

    my $order
        = ($flags & VERSIONFLAG_LOWER_BOUND) ? METAORDER_LOWER_BOUND
        : ($flags & VERSIONFLAG_UPPER_BOUND) ? METAORDER_UPPER_BOUND
        :                                      METAORDER_ZERO;

    return {order => $order, value => ''};
}

sub _get_next_version_component {

    my ($string, $flags) = @_;

    $string = _skip_separator($string);

    return ([_make_default_component($flags)], $string) if (length($string) == 0);

    my ($component, $rest) = _parse_token_to_component($string, $flags);

    my @components = ($component);

    # Special case for letter suffix:
    #  - We taste whether the next component is alpha not followed by a number,
    #    e.g 1a, 1a.1, but not 1a1
    #  - We check whether it's known keyword (in which case it's treated normally)
    #  - Otherwise, it's treated as letter suffix

    if ($rest =~ /^[[:alpha:]]/) {

        my ($alpha, $alpha_rest) = _split_alpha($rest);

        if ($alpha_rest !~ /^[[:digit:]]/) {

            my $keyword_class = _classify_keyword($alpha, $flags);

            my $order
                = ($keyword_class == KEYWORD_UNKNOWN)     ? METAORDER_LETTER_SUFFIX
                : ($keyword_class == KEYWORD_PRE_RELEASE) ? METAORDER_PRE_RELEASE
                :                                           METAORDER_POST_RELEASE;

            push @components, {value => lc(substr($alpha, 0, 1)), order => $order};

            $rest = $alpha_rest;

        }
    }

    return (\@components, $rest);

}

sub _compare_components {

    my ($u1, $u2) = @_;

    my $o1 = $u1->{order} // 0;
    my $o2 = $u2->{order} // 0;

    return -1 if $o1 < $o2;
    return 1  if $o1 > $o2;

    my $v1 = $u1->{value} // '';
    my $v2 = $u2->{value} // '';

    my $u1_is_empty = length($v1) == 0;
    my $u2_is_empty = length($v2) == 0;

    return 0  if $u1_is_empty && $u2_is_empty;
    return -1 if $u1_is_empty;
    return 1  if $u2_is_empty;

    my $u1_is_alpha = ($v1 =~ /^[[:alpha:]]/);
    my $u2_is_alpha = ($v2 =~ /^[[:alpha:]]/);

    if ($u1_is_alpha && $u2_is_alpha) {

        return -1 if $v1 lt $v2;
        return 1  if $v1 gt $v2;
        return 0;

    }

    return -1 if $u1_is_alpha;
    return 1  if $u2_is_alpha;

    my $len1 = length($v1);
    my $len2 = length($v2);

    return -1 if $len1 < $len2;
    return 1  if $len1 > $len2;

    return ($v1 cmp $v2);

}

sub version_compare2 {
    my ($v1, $v2) = @_;
    return version_compare4($v1, $v2, 0, 0);
}

sub version_compare4 {

    my ($v1, $v2, $v1_flags, $v2_flags) = @_;

    return 0 if $v1 eq $v2 && $v1_flags == $v2_flags;

    my @v1_components = ();
    my @v2_components = ();

    my $v1_extra_components = ($v1_flags & (VERSIONFLAG_LOWER_BOUND | VERSIONFLAG_UPPER_BOUND)) ? 1 : 0;
    my $v2_extra_components = ($v2_flags & (VERSIONFLAG_LOWER_BOUND | VERSIONFLAG_UPPER_BOUND)) ? 1 : 0;

    while (1) {

        _components(\@v1_components, \$v1, $v1_flags, \$v1_extra_components);
        _components(\@v2_components, \$v2, $v2_flags, \$v2_extra_components);

        my $c1 = shift @v1_components;
        my $c2 = shift @v2_components;

        my $res = _compare_components($c1, $c2);
        return $res if $res != 0;

        return 0
            if (!length($v1)
            && !length($v2)
            && $v1_extra_components == 0
            && $v2_extra_components == 0
            && !@v1_components
            && !@v2_components);

    }

    return 0;

}

sub _components {

    my ($v_components, $v_string, $v_flags, $v_extra) = @_;

    return if @{$v_components};

    if (length(${$v_string})) {

        my ($components, $rest) = _get_next_version_component(${$v_string}, $v_flags);

        push @{$v_components}, @{$components};
        ${$v_string} = $rest;

        return;

    }

    # Fill extra components
    my $component = _make_default_component();

    if (${$v_extra} > 0) {
        ${$v_extra}--;
        $component = _make_default_component($v_flags);
    }

    push @{$v_components}, $component;

    return;

}

sub version_compare {
    (@_ == 2) ? version_compare2(@_) : version_compare4(@_);
}

1;
__END__
=head1 NAME

Version::libversion::PP - pure-Perl porting of libversion

=head1 SYNOPSIS

  use Version::libversion::PP;

  # OO-interface

  if ( Version::libversion::PP->new($v1) == Version::libversion::PP->new($v2) ) {
      # do stuff
  }

  # Sorting mixed version styles

  @ordered = sort { Version::libversion::PP->new($a) <=> Version::libversion::PP->new($b) } @list;


  # Functional interface

  use Version::libversion::PP ':all';

  say '0.99 < 1.11' if(version_compare2('0.99', '1.11') == -1);

  say '1.0 == 1.0.0' if(version_compare2('1.0', '1.0.0') == 0);

  say '1.0alpha1 < 1.0.rc1' if(version_compare2('1.0alpha1', '1.0.rc1') == -1);

  say '1.0 > 1.0.rc1' if(version_compare2('1.0', '1.0-rc1') == 1);

  say '1.2.3alpha4 is the same as 1.2.3~a4' if(version_compare2('1.2.3alpha4', '1.2.3~a4') == 0);

  # by default, 'p' is treated as 'pre' ...
  say '1.0p1 == 1.0pre1'  if(version_compare2('1.0p1', '1.0pre1') == 0);
  say '1.0p1 < 1.0post1'  if(version_compare2('1.0p1', '1.0post1') == -1);
  say '1.0p1 < 1.0patch1' if(version_compare2('1.0p1', '1.0patch1') == -1);

  # ... but this is tunable: here it's handled as 'patch'
  say '1.0p1 > 1.0pre1'    if(version_compare4('1.0p1', '1.0pre1', VERSIONFLAG_P_IS_PATCH, 0) == 1);
  say '1.0p1 == 1.0post1'  if(version_compare4('1.0p1', '1.0post1', VERSIONFLAG_P_IS_PATCH, 0) == 0);
  say '1.0p1 == 1.0patch1' if(version_compare4('1.0p1', '1.0patch1', VERSIONFLAG_P_IS_PATCH, 0) == 0);

  # a way to check that the version belongs to a given release
  if(
      (version_compare4('1.0alpha1', '1.0', 0, VERSIONFLAG_LOWER_BOUND) == 1) &&
      (version_compare4('1.0alpha1', '1.0', 0, VERSIONFLAG_UPPER_BOUND) == -1) &&
      (version_compare4('1.0.1', '1.0', 0, VERSIONFLAG_LOWER_BOUND) == 1) &&
      (version_compare4('1.0.1', '1.0', 0, VERSIONFLAG_UPPER_BOUND) == -1)
  ) {
    say '1.0alpha1 and 1.0.1 belong to 1.0 release, e.g. they lie between' .
        '(lowest possible version in 1.0) and (highest possible version in 1.0)';
  }

=head1 DESCRIPTION

L<Version::libversion::PP> provides fast, powerful and correct generic
version string comparison algorithm.

See C<libversion> repository for more details on the algorithm.

L<https://github.com/repology/libversion>

=head2 FUNCTIONAL INTERFACE

They are exported by default:

=over

=item version_compare2 ( $v1, $v2 )

  say '0.99 < 1.11' if(version_compare2('0.99', '1.11') == -1);

  say '1.0 == 1.0.0' if(version_compare2('1.0', '1.0.0') == 0);

  say '1.0alpha1 < 1.0.rc1' if(version_compare2('1.0alpha1', '1.0.rc1') == -1);

  say '1.0 > 1.0.rc1' if(version_compare2('1.0', '1.0-rc1') == 1);

  say '1.2.3alpha4 is the same as 1.2.3~a4' if(version_compare2('1.2.3alpha4', '1.2.3~a4') == 0);

  # by default, 'p' is treated as 'pre' (see version_compare4)
  say '1.0p1 == 1.0pre1'  if(version_compare2('1.0p1', '1.0pre1') == 0);
  say '1.0p1 < 1.0post1'  if(version_compare2('1.0p1', '1.0post1') == -1);
  say '1.0p1 < 1.0patch1' if(version_compare2('1.0p1', '1.0patch1') == -1);

=item version_compare4 ( $v1, $v2, $v1_flags, $v2_flags )

  # Export all constants
  use Version::libversion::PP ':all';

  # by default, 'p' is treated as 'pre' but this is tunable: here it's handled as 'patch'
  say '1.0p1 > 1.0pre1' if(version_compare4('1.0p1', '1.0pre1', VERSIONFLAG_P_IS_PATCH, 0) == 1);
  say '1.0p1 == 1.0post1' if(version_compare4('1.0p1', '1.0post1', VERSIONFLAG_P_IS_PATCH, 0) == 0);
  say '1.0p1 == 1.0patch1' if(version_compare4('1.0p1', '1.0patch1', VERSIONFLAG_P_IS_PATCH, 0) == 0);

  # a way to check that the version belongs to a given release
  if(
      (version_compare4('1.0alpha1', '1.0', 0, VERSIONFLAG_LOWER_BOUND) == 1) &&
      (version_compare4('1.0alpha1', '1.0', 0, VERSIONFLAG_UPPER_BOUND) == -1) &&
      (version_compare4('1.0.1', '1.0', 0, VERSIONFLAG_LOWER_BOUND) == 1) &&
      (version_compare4('1.0.1', '1.0', 0, VERSIONFLAG_UPPER_BOUND) == -1)
  ) {
    say '1.0alpha1 and 1.0.1 belong to 1.0 release, e.g. they lie between' .
        '(lowest possible version in 1.0) and (highest possible version in 1.0)';
  }


=item version_compare ( $v1, $v2, [ $v1_flags, $v2_flags ] )

Alias of C<version_compare4>

=back

=head2 CONSTANTS

Flags

=over

=item VERSIONFLAG_P_IS_PATCH

=item VERSIONFLAG_ANY_IS_PATCH

=item VERSIONFLAG_LOWER_BOUND

=item VERSIONFLAG_UPPER_BOUND

=back

Flags alias:

=over

=item P_IS_PATCH

=item ANY_IS_PATCH

=item LOWER_BOUND

=item UPPER_BOUND

=back

=head2 OBJECT-ORIENTED INTERFACE

=over

=item Version::libversion::PP->new( $version, [ $flags ])

=item $v->version

=item $v->flags

=back

=head3 How to compare version objects

C<Version::libversion::PP> objects overload the C<cmp> and C<< <=> >> operators.
Perl automatically generates all of the other comparison operators based on those
two so all the normal logical comparisons will work.

  if ( Version::libversion::PP->new($v1) == Version::libversion::PP->new($v2) ) {
    # do stuff
  }

If a version object is compared against a non-version object, the non-object
term will be converted to a version object using C<new()>.  This may give
surprising results:

  $v1 = Version::libversion::PP->new("v0.95.0");
  $bool = $v1 < 0.94; # TRUE

Always comparing to a version object will help avoid surprises:

  $bool = $v1 < Version::libversion::PP->new("v0.94.0"); # FALSE

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Version-libversion-PP/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Version-libversion-PP>

    git clone https://github.com/giterlizzi/perl-Version-libversion-PP.git

=head1 SEE ALSO

L<Version::libversion::XS>

=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
