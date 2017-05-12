package ctflags::check;

our $VERSION = '0.02';

use 5.006;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

# this package is supposed to be private to ctflags and companion
# packages, not used from any other module so it uses directly
# @EXPORT.
our @EXPORT = qw( chack_identifier
		  check_ns
		  check_flag
		  check_value
		  check_flagset
		  check_flagsetext
		  check_alias
		  check_defopt
		  check_envname
		  check_cntprefix
		  check_package
		  check_sub
		  $identifier_re
		  $ns_re
		  $flag_re
		  $value_re
		  $flagset_re
		  $flagsetext_re
		  $alias_re
		  $envname_re
		  $cntprefix_re
		  $package_re
		);


sub myquote ($ ) {
  my $v=shift;
  defined $v ? "'$v'" : "'undef'";
}


our $identifier_re = qr|[a-zA-Z_]\w*|;
sub check_identifier ($ ) {
  (defined $_[0] and $_[0]=~/^$identifier_re$/o)
    or die "invalid perl identifier ".myquote($_[0])."\n";
}

our $ns_re=qr|$identifier_re(?::$identifier_re)*|;
sub check_ns ($ ) {
  (defined $_[0] and $_[0]=~/^$ns_re$/o)
    or die "invalid namespace specification ".myquote($_[0])."\n";
}

our $flag_re=qr|[a-zA-Z]|;
sub check_flag ($ ) {
  (defined $_[0] and $_[0]=~/^$flag_re$/o)
    or die "invalid ctflag specification ".myquote($_[0])."\n";
}

our $value_re=qr|\d+|;
sub check_value ($ ) {
  (!defined $_[0] or $_[0]=~/^$value_re$/o)
    or die "invalid ctflag value ".myquote($_[0])."\n";
}

our $flagset_re=qr|(?:$flag_re)*|;
sub check_flagset ($ ) {
  (defined $_[0] and $_[0]=~/^$flagset_re$/o)
    or die "invalid ctflags set ".myquote($_[0])."\n";
}

our $flagsetext_re=qr{\*|!?$flagset_re};
sub check_flagsetext ($) {
  (defined $_[0] and $_[0]=~/^$flagsetext_re$/o)
    or die "invalid ctflags set ".myquote($_[0])."\n";
}

our $alias_re=$identifier_re;
sub check_alias($ ) {
  (defined $_[0] and $_[0]=~/^$identifier_re$/o)
    or die "invalid alias specification ".myquote($_[0])."\n";
}

sub check_defopt($$) {
  defined $_[0]
    or die "'undef' is not a valid value for option '$_[1]'\n";
}

our $envname_re=$identifier_re;
sub check_envname($ ) {
  (defined $_[0] and $_[0]=~/^$envname_re$/o)
    or die "invalid environment variable name ".myquote($_[0])."\n";
}

our $cntprefix_re=qr/(?:$identifier_re)?/;
sub check_cntprefix ($ ) {
  (defined $_[0] and $_[0]=~/^$cntprefix_re$/o)
    or die "invalid constant prefix ".myquote($_[0])."\n";
}

our $package_re=qr|$identifier_re(?:::$identifier_re)*|;
sub check_package ($ ) {
  (defined $_[0] and $_[0]=~/^$package_re$/o)
    or die "invalid package name ".myquote($_[0])."\n";
}

sub check_sub ($) {
  (defined $_[0] and UNIVERSAL::isa($_[0], 'CODE'))
    or die "invalid sub ".myquote($_[0])."\n";
}

1;
__END__

=head1 NAME

ctflags::check - extension private to ctflags package

=head1 SYNOPSIS

  use ctflags::check;

  eval {
    check_identifier $perlidentifier;
    check_ns $namespace;
    check_flag $flag;
    check_value $value;
    check_flagset $flagset;
    check_alias $alias;
    check_defopt $option_value, $option_name;
    check_envname $environment_var_name;
    check_cntprefix $constant prefix;
    check_package $package;
  };
  if ($@) { chomp $@; croak $@ }

=head1 ABSTRACT

  ctflags::check defines a set of funcions used by the ctflags package
  and friends to check for argument validity in its subrutines.

=head1 DESCRIPTION

Only if you are changing the ctflags package or developing an
extension for it should you use this module. It is private to ctflag
and its public interface is not guaranteed to remain unchanged.

See the package source code to see the rules for every type of
argument.

check_* functions die if its argument do not match the predefined
rules.

=head2 EXPORT

Subrutines:
C<check_identifier>,
C<check_ns>,
C<check_flag>,
C<check_value>,
C<check_flagset>,
C<check_alias>,
C<check_defopt>,
C<check_envname>,
C<check_cntprefix>
C<check_package>;

Regular expresions:
C<$identifier_re>,
C<$ns_re>,
C<$flag_re>,
C<$value_re>,
C<$flagset_re>,
C<$alias_re>,
C<$envname_re>,
C<$cntprefix_re>,
C<$package_re>.

=head1 SEE ALSO

L<ctflags>

=head1 AUTHOR

Salvador FandiE<241>o Garcia, E<lt>sfandino@yahoo.comE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador FandiE<241>o Garcia

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
