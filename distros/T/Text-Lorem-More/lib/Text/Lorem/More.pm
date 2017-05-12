package Text::Lorem::More;

use warnings;
use strict;

=head1 NAME

Text::Lorem::More - Generate formatted nonsense using random Latin words.

=head1 VERSION

Version 0.13

=head1 SYNOPSIS

Generate formatted nonsense using random Latin words.

	use Text::Lorem::More;

	my $lorem = Text::Lorem::More->new;
	
	# Greet a friend
	print "Hello, ", $lorem->fullname, "\n";

	# You could also ...
	print $lorem->process("Hello, +fullname\n");

	... or you can use the singleton:

	use Text::Lorem::More qw(lorem);

	# Generate a random latin word
	my $latinwordoftheday = lorem->word;

	# Produce paragaphs in the Text::Lorem compatible manner
	my $content = lorem->paragraphs(3);

	# Print 4 paragraphs, each separated by a single newline and tab:
	print "\t", scalar lorem->paragraph(4, "\n\t");

=cut

our $VERSION = '0.13';

use base qw/Exporter/;

use Carp;
use Parse::RecDescent;

use Text::Lorem::More::Source;
    
our $PARSER = Parse::RecDescent->new(<<'_END_');
content: <rulevar: local @content >
content: <skip:''> pattern(s) { \@content }
pattern: escape | variable | text
escape: '++'  { push @content, \"+" }
variable: '+{' identifier '}' | '+' identifier
identifier: /[A-Za-z0-9_]+/ { push @content, $item[1] }
text: m/[^\+]+/ { push @content, \$item[1] }
_END_

=head1 GENERATORS 

To use a generator, call the method with the same name as the generator, 
To use the name generator, for example:

	my $name = $lorem->name;

Alternatively, you can use the C<generate> or C<process> functions.
To use the hostname generator, for example:

	my $hostname = $lorem->hostname;

	# This will do the same thing ...
	my $otherhostname = $lorem->generate("+hostname");

=head2 word

Generates random latin word.

	dicta
	sed
	repellat

=head2 sentence

Generates between 4 and 9 words, with the first letter of the first word capitalized and a period following
the last word.

=head2 paragraph

Generates between 3 and 6 sentences, 

=head2 words $count

A Text::Lorem compatible words generator.
Will generate $count words joined by " ".

=head2 sentences $count

A Text::Lorem compatible sentences generator.
Will generate $count sentences joined by " ".
Each sentence contains between 4 and 9 words and ends with a period.
B<Passing in 0 for count will still produce a single period!>

=head2 paragraphs $count

A Text::Lorem compatible sentences generator.
Will generate $count paragraphs joined by "\n\n".
Each paragraph contains between 3 and 6 sentences.

=head2 name / firstname / lastname

Generates a random latin word with the first letter capitalized

	Repellat
	Sed
	Ipsum

=head2 fullname

Generates a firstname and lastname separated by a space

	Lorem Dicta

=head2 username

Generates a random latin word

=head2 title

Generates between 1 and 3 words with the first letter of the first word capitalized

=head2 description

Generates between 1 and 3 sentences.

=head2 tld / topleveldomain

Generates a top level domain.
Currently, this will either be "com", "org", or "net".

=head2 domain / domainname

Generates a domainname.
Currently, this will attach "example" to a tld generator result. 

	example.com
	example.net

=head2 host / hostname

Generates a hostname.
Currently, this will either return a plain domainname, as above, or attach a latin word to a domainname result.

	et.example.com
	example.org

=head2 email / mail

=head2 path

=head2 httpurl

=head2 mailto

=cut

our %GENERATOR = (

	name => sub { [ sub { ucfirst lc $_ }, "+word" ] },
	firstname => "name",
	lastname => "name",

	fullname => sub { ["+firstname +lastname"] },

	username => "word",

	word => [ grep { length $_ } map { s/\W//g; lc } split m/\s/, <<_END_ ],
alias consequatur aut perferendis sit voluptatem accusantium doloremque aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis Nemo enim ipsam voluptatem quia voluptas sit suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae  et iusto odio dignissimos ducimus qui blanditiis praesentium laudantium, totam rem voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, Sed ut perspiciatis unde omnis iste natus error similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo porro quisquam est, qui minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? At vero eos et accusamus officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores doloribus asperiores repellat.
_END_

	title => sub { [ sub { ucfirst($_) },  "+word", 1 + int rand 3 ] },

	description => sub { [ "+sentence", 1 + int rand 3 ] },

	sentence => sub { [ sub { ucfirst($_) . "." },  "+word", 4 + int rand 6 ] },

	paragraph => sub { [ "+sentence", 3 + int rand 4 ] }, 

	words => sub {
		$Text::Lorem::More::PRUNE = 1;
		return [ "+word", $Text::Lorem::More::COUNT, " " ];
	},

	sentences => sub {
		my $lorem = shift;
		$Text::Lorem::More::PRUNE = 1;
		my $count = $Text::Lorem::More::COUNT;
		my @sentence;
		while ($count > 0) {
			push @sentence, ucfirst $lorem->words(4 + int rand 6);
			$count--;
		}
		return join(". ", @sentence) . ".";
	},

	paragraphs => sub {
		my $lorem = shift;
		$Text::Lorem::More::PRUNE = 1;
		my $count = $Text::Lorem::More::COUNT;
		my @paragraph;
		while ($count > 0) {
			push @paragraph, $lorem->sentences(3 + int rand 4);
			$count--;
		}
		return join("\n\n", @paragraph);
	},

	email => [ map { [ $_ ] } split m/\n/, <<_END_ ],
+word\@+hostname
+word\@+domainname
_END_

	mail => "email",

	relativepath => '',
	absolutepath => '',

	path => sub { [ "+word", 1 + int rand 6, "/" ] },

	httpurl => [ map { [ $_ ] } split m/\n/, <<_END_ ],
http://+hostname+path
http://+hostname:+port+path
_END_
	port => sub { int rand(1 + (2 ** 15)) },

	mailto => \"mailto:+email",

	tld => "topleveldomain",

	topleveldomain => [ split m/\s/, <<_END_ ],
com org net
_END_

	domain => "domainname",

	domainname => [ map { [ $_ ] } split m/\n/, <<_END_ ],
example.+tld
_END_

	host => "hostname",

	hostname => [ map { [ $_ ] } split m/\n/, <<_END_ ],
+word.+domainname
+domainname
_END_

);

use constant MAXIMUM_RECURSION => 2 ** 12;
use constant GENERATOR => \%GENERATOR;

=head1 EXPORT

=cut

our @EXPORT_OK = qw(lorem);

=head1 FUNCTIONS

=head2 new [$source]

Construct a new Text::Lorem::More object

=cut
sub new {
	my $self = bless {}, shift;
	my $source;
	if (@_) {
		if (ref $_[0] eq "HASH") {
			my $generator = shift;
			my $priority = shift;
			$source = new Text::Lorem::More::Source($source, $priority) if ref $source eq "HASH";
		}
		elsif (UNIVERSAL::isa($_[0], "Text::Lorem::More::Source")) {
			$source = shift;
		}
		elsif (! defined $_[0]) {
			$source = new Text::Lorem::More::Source;
		}
	}
	else {
		$source = $self->_DEFAULT_SOURCE->copy;
	}
	$self->{source} = $source;
	return $self;
}

=head2 generate $pattern [, $count, $separator]

Generate some text using the specified pattern.

C<generate> is faster than C<process>, as C<generate> uses regex to perform substitution.

In list context, return a list with C<$count> number of "words"

In scalar context, return C<$pattern> repeated C<$count> times and joined by C<$separator>.

B<If you do not specify scalar context on the receiving end, then the separator will simply be discarded.>
B<This may change in the future>

The default for C<$count> is 1.

The default for C<$separator> is " ".

A pattern will usually contain one or more generator tokens.  For example:

	+name
	+fullname
	+word+word+word+word

The pattern can also contain other text:

	+name@+domainname
	"+firstname +lastname"

Sometimes you might need to enclose the token identifier between C<+{> and C<}>

For example, the following pattern won't work right:

	prefix+namesuffix

But this will:

	prefix+{name}suffix

If you need to include a '+' in your pattern, you'll have to use C<process> instead.

=cut
sub generate {
	my $self = shift;
	# _generate may recurse any number of times.
	# the RECURSION counter makes sure it doesn't get out of hand.
	local $Text::Lorem::More::RECURSION = 0;
	return $self->_generate(@_);
}

=head2 process $text

Process a block of text, performing pattern substitutions as they're found.

process is slower than generate, as process uses L<Parse::RecDescent>.

To escape '+', simply repeat it. For example, to produce "2 + 2" you would submit:

	2 ++ 2

Please see C<generate> for more information.

=cut
sub process {
	my $self = shift;
	# _process may recurse any number of times.
	# the RECURSION counter makes sure it doesn't get out of hand.
	local $Text::Lorem::More::RECURSION = 0;
	return $self->_process(@_);
}

=head2 source

Return the generator source for this instance.

=cut
sub source {
	my $self = shift;
	return $self->{source};
}

=head2 lorem

A L<Text::Lorem::More> singleton.

=cut
sub lorem() { __PACKAGE__->_singleton }

sub _DEFAULT_SOURCE {
	return our $SOURCE ||= do {
		$SOURCE = new Text::Lorem::More::Source;
		$SOURCE->push(GENERATOR);
		$SOURCE;
	}
}

sub AUTOLOAD {
	my $self = shift->_self;
	my $method = our $AUTOLOAD;
	$method =~ s/.*:://;

	if ($self->{source}->find($method)) {
		no strict 'refs';
		*$AUTOLOAD = sub { my $self = shift; $self->generate("+$method", @_) };
		unshift @_, $self;
		goto &$AUTOLOAD;
	}
	else {
		carp "no such generatelet for \"$method\" found";
		return "";
	}
}

our ($RECURSION, $COUNT, $PRUNE);
sub _process {
	my $self = shift;
	my $content = shift;
	my $count = shift;
	my $separator = shift;

	$RECURSION += 1;
	croak "Too much recursion ($RECURSION) on \"$content\"" if $RECURSION >= MAXIMUM_RECURSION;

	$count = 1 unless defined $count;
    croak "\$count ($count) should be a number" unless $count =~ m/^\d+$/;

	$separator = " " unless defined $separator;

	local $Text::Lorem::More::COUNT = $count; $COUNT = $COUNT;
	local $Text::Lorem::More::PRUNE = 0;

	my @content;
	while ($count >= 0) {
		my $yield = "";
		my $parseryield = $PARSER->content($content);
		for (@$parseryield) {
			$yield .= ref $_ ? $$_ : $self->_replace_pattern($_);
		}
		push @content, $yield if $Text::Lorem::More::PRUNE;
		last if 0 == $count || $Text::Lorem::More::PRUNE;
		push @content, $yield;
		$count--;
	}

	return $content[0] if 1 == @content;
	return wantarray ? @content : join $separator, @content;
}

sub _generate {
	my $self = shift;
	my $pattern = shift;
	my $count = shift;
	my $separator = shift;
	my $fast = shift;

	$RECURSION += 1;
	croak "Too much recursion ($RECURSION) on \"$pattern\"" if $RECURSION >= MAXIMUM_RECURSION;

	$count = 1 unless defined $count;
    croak "\$count ($count) should be a number" unless $count =~ m/^\d+$/;

	$separator = " " unless defined $separator;

	local $Text::Lorem::More::COUNT = $count; $COUNT = $COUNT;
	local $Text::Lorem::More::PRUNE = 0;

        my @content;
        while ($count >= 0) {
		my $pattern = $pattern;
		$pattern =~ s/\+\{(\w+)\}|\+(\w+)/$self->_replace_pattern($1 || $2)/eg;
                push @content, $pattern if $Text::Lorem::More::PRUNE;
                last if 0 == $count || $Text::Lorem::More::PRUNE;
                push @content, $pattern;
		$count--;
	}

	return $content[0] if 1 == @content;
	return wantarray ? @content : join $separator, @content;
}

sub _replace_pattern {
	my $self = shift;
	my $pattern = shift;

	my $generatelet = $self->{source}->find($pattern);

	return $pattern unless $generatelet;

	my $content;
	if (ref $generatelet eq "ARRAY") {
		$content = $generatelet->[int rand @$generatelet];
	}
	elsif (ref $generatelet eq "SCALAR") {
		$content = $$generatelet;
	}
	elsif (ref $generatelet eq "CODE") {
		$content = $generatelet->($self);
	}
	else {
		croak "Don't know how to run/handle generatelet \"$generatelet\"";
	}

	if (ref $content eq "ARRAY") {
		my $filter;
		$filter = shift @$content if ref $content->[0] eq "CODE";
		my ($pattern, $count, $separator) = @$content;
		local $_ = $self->_generate($pattern, $count, $separator);
		$_ = $filter->($_) if $filter;
		$content = $_;
	}

	return $content;
}

sub _self($) { return ref $_[0] ? $_[0] : $_[0]->_singleton }


sub _singleton {
	my $class = shift;
	return our $singleton ||= $class->new;
}

sub DESTROY {
}

=head1 AUTHOR

Robert Krimen, C<< <robertkrimen at gmail.com> >>

=head1 SEE ALSO

L<Text::Lorem>

L<WWW::Lipsum>

L<http://lipsum.com/>

=head1 SOURCE

You can contribute or fork this project via GitHub:

L<http://github.com/robertkrimen/text-lorem-more/tree/master>

    git clone git://github.com/robertkrimen/text-lorem-more.git Text-Lorem-More

=head1 ACKNOWLEDGEMENTS

Thanks to Adeola Awoyemi for writing L<Text::Lorem>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 BUGS

Probaby a lot. Please report them (as below) and I'll take a look.

Please report any bugs or feature requests to
C<bug-text-lorem-more at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Lorem-More>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Lorem::More

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Lorem-More>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Lorem-More>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Lorem-More>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Lorem-More>

=back

=cut

1; # End of Text::Lorem::More
