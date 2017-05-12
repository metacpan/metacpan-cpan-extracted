package Test::WWW::Mechanize::PhantomJS::Catalyst;

use strict;
use warnings;

use Test::WWW::Mechanize;
use WWW::Mechanize::PhantomJS::Catalyst;

my $file = $INC{"Test/WWW/Mechanize.pm"};
open MECHA, "<", $file or die "Cannot open $file:$!\n";
local $/;
my $text = <MECHA>;
close MECHA;

$text =~ s/(WWW::Mechanize)/$1::PhantomJS::Catalyst/g;
$text =~ s/sub\s+new/sub _new/;
eval $text;
die $@ if $@;
undef $text;


my $default_app;
sub import { (undef, $default_app) = @_ }

sub new {
	my $self = shift->_new(
		app              => $default_app,
		report_js_errors => 1,
		@_
	);
	return UNIVERSAL::isa($self, 'Test::WWW::Mechanize::PhantomJS::Catalyst') ? $self : undef;
};

1;

__END__

=pod

=head1 NAME

Test::WWW::Mechanize::PhantomJS::Catalyst - test extension pack for WWW::Mechanize::PhantomJS::Catalyst

=head1 DESCRIPTION

Same as L<Test::WWW::Mechanize> for L<WWW::Mechanize>, this module adds some extra methods
useful in testing such as C<get_ok> and C<content_contains>. See L<Test::WWW::Mechanize> for
the full description.

=head1 SYNOPSIS

  use Test::More;
  use Test::WWW::Mechanize::PhantomJS::Catalyst 'MyApp';
  ok( my $mech = Test::WWW::Mechanize::PhantomJS::Catalyst->new, "Mechanize object ok");
  $mech->get_ok("/hello.html");

=head1 AUTHOR

Dmitry Karasik E<lt>dmitry@karasik.eu.orgE<gt>.

=head1 COPYRIGHT

This program is distributed under the standard Perl licence.

=cut
