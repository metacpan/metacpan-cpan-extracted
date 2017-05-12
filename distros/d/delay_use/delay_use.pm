######################################################################
# (c) makoto[at]cpan[dot]org and mixi perl community members
# sample:
#   use delay_use;
#   $delay_use::DEBUG	= 1;#実行時にエラーがあった場合STDERRに表示
#   $delay_use::ABORT	= 1;#実行時にエラーがあった場合プログラムを終了(exit-1)。
#
#   ex1)
#     my $pkg	= delay_use('CGI::Session') || delay_use( 'CGI' ) || die;
#     my $q		= $pkg->new;
#     print $q->header;
#
#   ex2)
#     delay_use( 'CGI' ,qw/:standard/ ) or die($delay_use::ERROR);
package delay_use;
use strict;
use warnings;
use base qw(Exporter);
our $VERSION	= '1.00';
our @EXPORT		= qw(delay_use);
our $ERROR		= undef;
our $DEBUG		= 0;
our $ABORT		= 0;
our %INC		= ();
sub delay_use {
	my $pkg		= shift;
	my $caller	= (caller)[0] || 'main';
	my $func	= $INC{$pkg} ||= eval qq{
		sub {
			package $caller;
			eval qq{require $pkg};
			if(\$@){
				\$delay_use::ERROR	= \$@;
				delete \$delay_use::INC{$pkg};
				print STDERR \$delay_use::ERROR if \$delay_use::DEBUG;
				exit(-1) if \$delay_use::ABORT;
				return;
			}
			$pkg->import(\@_) if $pkg->can('import');
			return "$pkg";
		}
	};
	return $func->(@_);
}
1;
__END__

=Head1 NAME

delay_use - Modular loading is delayed.

=Head1 SYNOPSIS

use delay_use;#export delay_use
# When an error message is outputted to STDERR
$delay_use::DEBUG	= 1;#default=0
# When ABORT at the time of an error.
$delay_use::ABORT	= 1;#default=0

ex1)
  my $pkg_name = delay_use('CGI::Session') || delay_use( 'CGI' ) || die;
  my $query    = $pkg_name->new;
  print $query->header;

ex2)
  delay_use( 'CGI' ,qw/:standard/ ) or die($delay_use::ERROR);

=head1 AUTHOR

A. U. Thor, E<lt>makoto@cpan.orgE<lt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by makoto@fes-total.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
