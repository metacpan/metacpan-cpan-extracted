package WWW::BookBot::Chinese::Agriculture::GreenHouse::Tech;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);
use base qw(WWW::BookBot::Chinese);
our $VERSION='1.02';

sub default_settings {
	my $self = shift->SUPER::default_settings;
	$self->{text_paragraph_type}='cr';
	$self->{book_has_chapters}=0;
	$self->{get_trunk_size}=2500;
	$self->{get_trunk_fresh_size}=250;
	$self;
}
sub msg_init {
	my $self = shift;
	my $msg=$self->SUPER::msg_init;
	$msg->{CatalogURL}='http://www.chinagreenhouse.com/chinagreenhouse/maindoc/newproducts/subject_newproducts_display.asp?direction=next';
	$msg->{CatalogInfo}='==>中国温室网新产品新技术：';
}

sub get_alias {
	'agr_cngreen_tech';
}
sub argv_default {
	qw();
}
sub argv_process {
	my ($self, $pargs)=@_;
	$self->go_catalog($pargs);
}
sub argv_process_all {
	my ($self, $pargs)=@_;
	for($pargs->{pageno}=1; $pargs->{pageno}<=$self->{catalog_max_pages}; $pargs->{pageno}++) {
		last if $self->go_catalog({})==0;
	}
}
sub getpattern_catalog_head_data {
	<<'DATA';
<p><font size="2"><b>page
DATA
}
sub getpattern_catalog_end_data {
	<<'DATA';
<p><a href="subject_newproducts_display.asp
DATA
}
sub getpattern_catalog_get_next_data {
	<<'DATA';
>Next Page<
DATA
}

1;
__END__

=head1 NAME

WWW::BookBot::Chinese::Agriculture::GreenHouse::Tech - Bot to fetch from http://www.chinagreenhouse.com/

=head1 SYNOPSIS

  use WWW::BookBot::Chinese::Agriculture::GreenHouse::Tech;
  my $bot=WWW::BookBot::Chinese::Agriculture::GreenHouse::Tech->new({work_dir=>'/output'});
  $bot->go_catalog({});

  bookbot --bot=agr_cngreen_tech
  bookbot --bot=agr_cngreen_tech all

=head1 ABSTRACT

Bot to fetch from http://www.chinagreenhouse.com/chinagreenhouse/maindoc/newproducts/subject_newproducts_display.asp

=head1 DESCRIPTION

Bot to fetch from http://www.chinagreenhouse.com/chinagreenhouse/maindoc/newproducts/subject_newproducts_display.asp

=head2 EXPORT

None by default.

=head1 BUGS, REQUESTS, COMMENTS

Please report any requests, suggestions or bugs via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-BookBot

=head1 AUTHOR

Qing-Jie Zhou E<lt>qjzhou@hotmail.comE<gt>

=head1 SEE ALSO

L<WWW::BookBot>, L<bookbot>

=cut
