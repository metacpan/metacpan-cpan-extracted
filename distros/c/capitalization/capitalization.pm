package capitalization;

use strict;
use vars qw($VERSION);
$VERSION = 0.03;

use Devel::Symdump;

my %done;

sub unimport {
    my($class, @mods) = @_;
    for my $mod (@mods) {
	next if $done{$mod};

	my $file = mod2file($mod);
	require $file unless $INC{$file};

	my $dump = Devel::Symdump->new($mod);
	for my $meth (map { s/^\Q$mod\E:://; $_ } $dump->functions) {
	    my $new = nocap($meth);
	    if ($new ne $meth) {
		no strict 'refs';
		*{"$mod\::$new"} = \&{"$mod\::$meth"};
	    }
	}
	$done{$mod} = 1;
    }
}

sub nocap {
    my $method = shift;
    $method =~ s/(?<=[a-z])([A-Z]+)/"_" . lc($1)/eg;
    $method =~ tr/A-Z/a-z/;
    return $method;
}

sub mod2file {
    my $mod = shift;
    $mod =~ s!::!/!g;
    return "$mod.pm";
}

1;
__END__

=head1 NAME

capitalization - no capitalization on method names

=head1 SYNOPSIS

  use XML::DOM;
  no capitalization 'XML::DOM';

  my $parser = XML::DOM::Parser->new;

  # no capitalization ..
  my $nodes = $parser->get_elements_by_tag_name("Foo");

  # this can be OK
  my $nodes = $parser->getElementsByTagName("Foo");


=head1 DESCRIPTION

capitalization.pm allows you to use familiar style on method naming.

=head1 RULES

=over 1

=item Lower case character followed by upper case sequence would be
splitted with C<_> and upper case sequence would be lower cased.
Example: C<fooBar> would be C<foo_bar>.

=item All other upper case characters would be lower cased.
Examples: C<FOOs> would be C<foos>, C<_Foo> would be C<_foo>.

=back

=head1 CAVEATS

=head2 C<no capitalization __PACKAGE__;>

If you want use capitalization pragma in module and add lower case
API in the module itself, then you should use pragma after all subs
are defined.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Symbol::Approx::Sub>

=cut
