package WWW::WikiSpaces;

use strict;
use warnings;
use WWW::Mechanize;

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(post);

our $VERSION = '0.01';

sub new() {
	my ($class, $home, $user, $pass) = @_;
	my $self = {
	        mech	=> WWW::Mechanize->new(agent => 'Windows IE 6', cookie_jar => {}),
		home	=> $home,
	        user	=> $user,
		pass	 => $pass
	};
	
	$self->{mech}->get('http://www.wikispaces.com/');
	$self->{mech}->follow_link(url => 'http://www.wikispaces.com/site/signin');
	$self->{mech}->submit_form(
		form_number => 2,
		fields      => {
			username	=> $self->{user},
			password	=> $self->{pass},
			},
		button => 'go');
			
	bless $self, $class;
	return $self;
};

sub post($$) {
	my ($self, $title, $text) = @_;
	
	# go to input title page for new post
	#$self->{mech}->get('http://' . $self->{home} . '.wikispaces.com/');
	$self->{mech}->get('http://' . $self->{home} . '.wikispaces.com/space/page');

	# fill title
	$self->{mech}->form('newpage');
	$self->{mech}->set_fields(page => $title);
	$self->{mech}->click();

	# fill post
	$self->{mech}->form('rte');
	$self->{mech}->set_fields(WikispacesEditorContent => $text, comment => '', tagInput => '');
	$self->{mech}->click_button(value => 'Save');
};

1;

__END__

=head1 NAME

WWW::WikiSpaces - Perl extension to posting on WikiSpaces

=head1 SYNOPSIS

  use WWW::WikiSpaces;

        my $ws = WWW::WikiSpaces->new(
                'test',
                'admin',
                'pass!'
        );

        # post new topic
        $ws->post(
                "Hello, World!",
                "<h1>Posted via Perl</h1>"
        );

=head1 DESCRIPTION

Post on WikiSpaces using Perl

=head2 EXPORT

post()

=head1 AUTHOR

Leonty Chudinov, E<lt>leonty-A!T-inbox.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008: Leonty Chudinov / Web: http://cleonty.narod.ru

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.



=cut
