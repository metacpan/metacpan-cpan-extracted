package WWW::DuckDuckGo::ZeroClickInfo;
BEGIN {
  $WWW::DuckDuckGo::ZeroClickInfo::AUTHORITY = 'cpan:DDG';
}
{
  $WWW::DuckDuckGo::ZeroClickInfo::VERSION = '0.016';
}
# ABSTRACT: A DuckDuckGo Zero Click Info definition

use Moo;
use WWW::DuckDuckGo::Link;
use URI;

sub by {
	my ( $class, $result ) = @_;
	my %params;
	if ($result->{RelatedTopics}) {
		$params{related_topics_sections} = {};
		if ($result->{RelatedTopics}->[0]->{Topics}) {
			for (@{$result->{RelatedTopics}}) {
				die "go to irc.freenode.net #duckduckgo and kick yegg, and also tell him your searchterm" if $_->{Name} eq '_';
				my @topics;
				for (@{$_->{Topics}}) {
					push @topics, $class->_link_class->by($_) if ref $_ eq 'HASH' and %{$_};
				}
				$params{related_topics_sections}->{$_->{Name}} = \@topics;
			}
		} else {
			my @topics;
			for (@{$result->{RelatedTopics}}) {
				push @topics, $class->_link_class->by($_) if ref $_ eq 'HASH' and %{$_};
			}
			$params{related_topics_sections}->{_} = \@topics if @topics;
		}
	}
	my @results;
	for (@{$result->{Results}}) {
		push @results, $class->_link_class->by($_) if ref $_ eq 'HASH' and %{$_};
	}
        $params{_json} = $result;
	$params{results} = \@results if @results;
	$params{abstract} = $result->{Abstract} if $result->{Abstract};
	$params{abstract_text} = $result->{AbstractText} if $result->{AbstractText};
	$params{abstract_source} = $result->{AbstractSource} if $result->{AbstractSource};
	$params{abstract_url} = URI->new($result->{AbstractURL}) if $result->{AbstractURL};
	$params{image} = URI->new($result->{Image}) if $result->{Image};
	$params{heading} = $result->{Heading} if $result->{Heading};
	$params{answer} = $result->{Answer} if $result->{Answer};
	$params{answer_type} = $result->{AnswerType} if $result->{AnswerType};
	$params{definition} = $result->{Definition} if $result->{Definition};
	$params{definition_source} = $result->{DefinitionSource} if $result->{DefinitionSource};
	$params{definition_url} = URI->new($result->{DefinitionURL}) if $result->{DefinitionURL};
	$params{type} = $result->{Type} if $result->{Type};
	$params{html} = $result->{HTML} if $result->{HTML};
    $params{redirect} = $result->{Redirect} if $result->{Redirect};
	__PACKAGE__->new(%params);
}

sub _link_class { 'WWW::DuckDuckGo::Link' }

has _json => (
	is => 'ro',
);

has abstract => (
	is => 'ro',
	predicate => 'has_abstract',
);

has abstract_text => (
	is => 'ro',
	predicate => 'has_abstract_text',
);

has abstract_source => (
	is => 'ro',
	predicate => 'has_abstract_source',
);

has abstract_url => (
	is => 'ro',
	predicate => 'has_abstract_url',
);

has image => (
	is => 'ro',
	predicate => 'has_image',
);

has heading => (
	is => 'ro',
	predicate => 'has_heading',
);

has answer => (
	is => 'ro',
	predicate => 'has_answer',
);

has answer_type => (
	is => 'ro',
	predicate => 'has_answer_type',
);

has definition => (
	is => 'ro',
	predicate => 'has_definition',
);

has definition_source => (
	is => 'ro',
	predicate => 'has_definition_source',
);

has definition_url => (
	is => 'ro',
	predicate => 'has_definition_url',
);

has html => (
	is => 'ro',
	predicate => 'has_html',
);

has redirect => (
	is => 'ro',
	predicate => 'has_redirect',
);

sub default_related_topics {
	my ( $self ) = @_;
	$self->related_topics_sections->{_} if $self->has_related_topics_sections;
}

sub has_default_related_topics {
	my ( $self ) = @_;
	$self->has_related_topics_sections and defined $self->related_topics_sections->{_} ? 1 : 0;
}

has related_topics_sections => (
	is => 'ro',
	predicate => 'has_related_topics_sections',
);

# DEPRECATED WARN
sub related_topics {
	warn __PACKAGE__.": usage of the function related_topics is deprecated, use default_related_topics for the same functionality (also see: related_topics_sections)";
	shift->default_related_topics(@_);
}
################

has results => (
	is => 'ro',
	predicate => 'has_results',
);

has type => (
	is => 'ro',
	predicate => 'has_type',
);

has type_long_definitions => (
	is => 'ro',
	lazy => 1,
	default => sub {{
		A => 'article',
		D => 'disambiguation',
		C => 'category',
		N => 'name',
		E => 'exclusive',
	}},
);

sub type_long {
	my ( $self ) = @_;
	return if !$self->type;
	$self->type_long_definitions->{$self->type};
}

1;

__END__

=pod

=head1 NAME

WWW::DuckDuckGo::ZeroClickInfo - A DuckDuckGo Zero Click Info definition

=head1 VERSION

version 0.016

=head1 SYNOPSIS

  use WWW::DuckDuckGo;

  my $zci = WWW::DuckDuckGo->new->zci('duck duck go');
  
  print "Heading: ".$zci->heading if $zci->has_heading;
  
  print "The answer is: ".$zci->answer if $zci->has_answer;
  
  if ($zci->has_default_related_topics) {
    for (@{$zci->default_related_topics}) {
      print $_->url."\n";
    }
  }
  
  if (!$zci->has_default_related_topics and %{$zci->related_topics_sections}) {
    print "Disambiguatious Related Topics:\n";
    for (keys %{$zci->related_topics_sections}) {
      print "  Related Topics Groupname: ".$_."\n";
        for (@{$zci->related_topics_sections->{$_}}) {
          print "  - ".$_->first_url->as_string."\n" if $_->has_first_url;
        }
      }
    }
  }

=head1 DESCRIPTION

This package reflects the result of a zeroclickinfo API request.

=head1 METHODS

=head2 has_abstract

=head2 abstract

=head2 has_abstract_text

=head2 abstract_text

=head2 has_abstract_source

=head2 abstract_source

=head2 has_abstract_url

=head2 abstract_url

Gives back a URI::http

=head2 has_image

=head2 image

Gives back a URI::http

=head2 has_heading

=head2 heading

=head2 has_answer

=head2 answer

=head2 has_answer_type

=head2 answer_type

=head2 has_definition

=head2 definition

=head2 has_definition_source

=head2 definition_source

=head2 has_definition_url

=head2 definition_url

=head2 has_html

=head2 html

Gives back a URI::http

=head2 has_related_topics_sections

=head2 related_topics_sections

Gives back a hash reference of related topics with its Name as key and as value an array reference of L<WWW::DuckDuckGo::Link> objects. If there is a specific topic, a so called default topic, which is the case in all non disambigious search results, then this topic has the name "_", but you can access it with the method I<default_related_topics> directly.

=head2 default_related_topics

Gives back an array reference of L<WWW::DuckDuckGo::Link> objects. Can be undef, check with I<has_default_related_topics>.

=head2 has_results

=head2 results

Gives back an array reference of L<WWW::DuckDuckGo::Link> objects. Can be undef, check with I<has_results>.

=head2 has_type

=head2 type

=head2 type_long

Gives back a longer version of the type.

=head2 has_redirect

=head2 redirect

Access the URL it would redirect you to (for !bangs)

=encoding utf8

=head1 METHODS

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-www-duckduckgo
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-duckduckgo/issues

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=item *

Michael Smith <crazedpsyc@duckduckgo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by L<DuckDuckGo, Inc.|https://duckduckgo.com/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
