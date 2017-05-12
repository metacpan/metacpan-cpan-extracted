package Test::Text::Keywords::Standard;

use Moo;

use Text::Keywords;
use Text::Keywords::Container;
use Text::Keywords::List;

has setup => (
	is => 'ro',
	required => 1,
);

has name => (
	is => 'ro',
	required => 1,
);

has tests => (
	is => 'ro',
	required => 1,
);

has _text_keywords => (
	is => 'rw',
);

sub BUILD {
	my ( $self ) = @_;
	if (!$self->_text_keywords) {
		$self->setup_text_keywords(@{$self->setup});
	}
	$self->run_test;
}

sub setup_text_keywords {
	my ( $self, @setup_containers ) = @_;
	my @containers;
	for my $setup_container (@setup_containers) {
		my @keywordlists;
		for my $setup_keywordlist (@{$setup_container->{lists}}) {
			push @keywordlists, Text::Keywords::List->new(
				keywords => $setup_keywordlist,
			);
		}
		my $cnt = 0;
		for (@keywordlists) {
			$cnt++;
			::isa_ok($_,'Text::Keywords::List','Checking generated '.$cnt.'. Text::Keywords::List for proper class of testsetup '.$self->name);
		}
		delete $setup_container->{lists};
		$setup_container->{lists} = \@keywordlists;
		push @containers, Text::Keywords::Container->new($setup_container);
	}
	my $cnt = 0;
	for (@containers) {
		$cnt++;
		::isa_ok($_,'Text::Keywords::Container','Checking generated '.$cnt.'. Text::Keywords::Container for proper class of testsetup '.$self->name);
	}
	$self->_text_keywords(Text::Keywords->new(
		containers => \@containers,
	));
	::isa_ok($self->_text_keywords,'Text::Keywords','Checking class of generated Text::Keywords on testsetup '.$self->name);
	::is(scalar @{$self->_text_keywords->containers},scalar @containers,'Checking right count of KeywordContainer on Text::Keywords on testsetup '.$self->name);
}

sub run_test {
	my ( $self ) = @_;
	my $cnt = 0;
	for (@{$self->tests}) {
		my ( $text, $content, @results ) = @{$_};
		$cnt++;
		my @founds;
		if ($content) {
			@founds = $self->_text_keywords->from($text, $content);
		} else {
			@founds = $self->_text_keywords->from($text);
		}
		my $fcnt = 0;
		for (@founds) {
			$fcnt++;
			::is($_->found,shift @results,'Checking found word of '.$fcnt.'. found of '.$cnt.'. test on testsetup '.$self->name);
			::is($_->keyword,shift @results,'Checking keyword used for finding of '.$fcnt.'. found of '.$cnt.'. test on testsetup '.$self->name);
			::is_deeply($_->matches,shift @results,'Checking found matches of '.$fcnt.'. found of '.$cnt.'. test on testsetup '.$self->name);
			::is($_->in_primary ? 1 : 0,shift @results,'Checking in_primary of '.$fcnt.'. found of '.$cnt.'. test on testsetup '.$self->name);
			::is($_->in_secondary ? 1 : 0,shift @results,'Checking in_secondary of '.$fcnt.'. found of '.$cnt.'. test on testsetup '.$self->name);
			my $container_number = shift @results;
			::is($_->container,$self->_text_keywords->containers->[$container_number],'Checking right container of '.$fcnt.'. found of '.$cnt.'. test on testsetup '.$self->name);
			::is($_->list,$self->_text_keywords->containers->[$container_number]->lists->[shift @results],'Checking right list of '.$fcnt.'. found of '.$cnt.'. test on testsetup '.$self->name);
		}
	}
}

1;