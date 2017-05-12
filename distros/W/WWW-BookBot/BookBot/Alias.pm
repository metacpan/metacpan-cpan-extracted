package WWW::BookBot::Alias;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);
use base qw(Exporter);
use vars qw($VERSION @EXPORT @EXPORT_OK);
$VERSION = "1.02";
@EXPORT = qw(
	alias2class
);
@EXPORT_OK = @EXPORT;

our %aliases;

sub alias2class {
	return $aliases{lc($_[0])};
}

%aliases=(
#Alias Begin
agr_cast				=> 'WWW::BookBot::Chinese::Agriculture::Cast',
agr_cngreen_market		=> 'WWW::BookBot::Chinese::Agriculture::GreenHouse::Market',
agr_cngreen_tech		=> 'WWW::BookBot::Chinese::Agriculture::GreenHouse::Tech',
dragonsky				=> 'WWW::BookBot::Chinese::Novel::DragonSky',
shuku					=> 'WWW::BookBot::Chinese::Novel::ShuKu',
wanfang					=> 'WWW::BookBot::Chinese::Periodical::WanFang',
#Alias End
);

1;
__END__

=head1 NAME

WWW::BookBot::Alias - Aliases of inherited bot of WWW::BookBot.

=head1 SYNOPSIS

  use WWW::BookBot::Alias;
  
  print alias2class('dragonsky');

=head1 ABSTRACT

  Aliases of inherited bot of WWW::BookBot.

=head1 DESCRIPTION

  Aliases of inherited bot of WWW::BookBot.

=head2 EXPORT

  alias2class($classalias)	=> $classname

=head1 BUGS, REQUESTS, COMMENTS

Please report any requests, suggestions or bugs via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-BookBot

=head1 AUTHOR

Qing-Jie Zhou E<lt>qjzhou@hotmail.comE<gt>

=head1 SEE ALSO

L<WWW::BookBot>

=cut