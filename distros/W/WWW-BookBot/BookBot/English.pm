package WWW::BookBot::English;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);
use base qw(WWW::BookBot);
use vars qw($VERSION);
$VERSION = '0.12';

1;
__END__

=head1 NAME

WWW::BookBot::English - Virtual class of bots to process english e-texts.

=head1 SYNOPSIS

  use WWW::BookBot::Chinese::Novel::DragonSky;
  my $bot=WWW::BookBot::Chinese::Novel::DragonSky->new({work_dir=>'/output'});
  $bot->go_catalog({});

  use WWW::BookBot::Chinese::Novel::ShuKu;
  my $bot=WWW::BookBot::Chinese::Novel::ShuKu->new({});
  $bot->go_catalog({desc=>'NewNovel', cat1=>0, cat2=>1, pageno=>0});

=head1 ABSTRACT

Virtual class of bots to process english e-texts.

=head1 DESCRIPTION

Virtual class of bots to process english e-texts.

to be added.

=head2 EXPORT

None by default.

=head1 BUGS, REQUESTS, COMMENTS

Please report any requests, suggestions or bugs via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-BookBot

=head1 AUTHOR

Qing-Jie Zhou E<lt>qjzhou@hotmail.comE<gt>

=head1 SEE ALSO

L<WWW::BookBot>

=cut
