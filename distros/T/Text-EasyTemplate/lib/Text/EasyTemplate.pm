package Text::EasyTemplate;

use warnings;
use strict;

our $VERSION = '0.01';
my $BASE = '';

sub new {
	my $proto = shift;
	my ($file) = @_;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self,$class);
	$self->{'FILE'} = $file;
	$self->{'HTML'} = $self->_read_file();
	return $self;
}

sub replace {
	my $self = shift;
	my ($hashref) = @_;
	my %hash;
	%hash = %$hashref if ref($hashref) eq 'HASH';
	my $data = $self->{'HTML'};

	while ($data =~ /\[\[IF (.*?)\]\](.*?)\[\[ENDIF\]\]/s) {
		my $token = $1;
		my $else = $2;
		if ($else =~ /\[\[ELSE\]\]/) {
			if ($hash{$token}) {
				$data =~ s/\[\[IF $token\]\](.*?)\[\[ELSE\]\].*?\[\[ENDIF\]\]/$1/s;
			}
			else {
				$data =~ s/\[\[IF $token\]\].*?\[\[ELSE\]\](.*?)\[\[ENDIF\]\]/$1/s;
			}
		}
		else {
			if ($hash{$token}) {
				$data =~ s/\[\[IF $token\]\](.*?)\[\[ENDIF\]\]/$1/s;
			}
			else {
				$data =~ s/\[\[IF $token\]\].*?\[\[ENDIF\]\]//s;
			}
		}
	}

	while ($data =~ /\[\[(.*?)\]\]/g) {
		my $token = $1;
		my $key = $token;
		my $value = $hash{$key};
		if (defined $value) {
			$data =~ s/\[\[$token\]\]/$value/mg;
		}
		else {
			$data =~ s/\[\[$token\]\]//mg;
		}
	}

	return $data;
}

sub _read_file {
	my $self = shift;
	my $file = $self->{'FILE'};
	my $CHUNK_SIZE = 4096;
	my ($chunk, $data);

	open(FILE, "$file") || return $self->_template_not_found($!,$file);
	binmode(FILE) || return $self->_template_not_found($!);
	$data = '';
	while (read(FILE, $chunk, $CHUNK_SIZE)) {
		$data .= $chunk;
	}
	close(FILE) || return $self->_template_not_found($!);
	return $data;
}

sub _template_not_found {
	my $self = shift;
	my ($error) = @_;
	return qq|Error: template not found!\n\t$error ($self->{'FILE'})\n|;
}

1;

__END__

=head1 NAME

Text::EasyTemplate - A simple text template system.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

A simple text template system without a lot of complex and unnecessary features
present in other existing template systems. It aims at ease of use without the
need of setting up lots of configurations or complex frameworks. Ideal for
simple applications, it can be used for any type of purpose: web, merge mail,
or any other type of text.

Here is an example:

	use Text::EasyTemplate;

	my $template = Text::EasyTemplate->new("templates_dir/template_file.txt");
	my $data = {
		VALUE1 => "value",
		VALUE2 => 2,
		CONDITIONAL => 1,
		VALUE3 => localtime()
	};
	my $string = $template->replace($data);

=head1 DESCRIPTION

This module is a simple and straightforward alternative to much more complex
template toolkits and frameworks. I began development on it because existing
Perl modules for handling templates were too complex to use in simple
applications. 

Templates are used to separate content from presentation. EasyTemplate is
simple enough and does not care where the template will be used, so it is not
just for web templates; it can be used anyplace dynamic values need to be
placed over a pre-defined page layout. A placeholder label is used wherever
the dynamic text will appear. These placeholders are in the form
C<[[PLACEHOLDER]]>. Although the label can be in either case, uppercase is
recommended to make it stand out more from the contents of the template. Double
square brackets where chosen since these characters are rarely used this way in
documents.

A simple template would look like:

	Hello [[WHO]]!

To create a new EasyTemplate instance, the constructor C<new()> is used and
supply as an argument the name of the file containing the template:

	my $template = Text::EasyTemplate->new("hello_template.txt");

A simple hash needs to be created with all the pair-values of placeholder
labels and their corresponding value to be replaced within the template. For
the example above, the following hash would be used:

	my %data = ( WHO => 'World' );

The C<replace()> method takes as argument a reference to such hash and returns
a string containing the resulting text string:

	my $text = $template->replace(\%data);

A slightly better way to do this would be;

	my $data = { WHO => 'World' };
	my $text = $template->replace($data);

The resulting text string would be, as expected,

	Hello World!

Simple conditionals can also be used with EasyTemplate:

	Good [[IF MORNING]]morning[[ELSE]]day[[ENDIF]]!

and when creating the hash with the label-value pairs, any true value will
do:

	my $data = { MORNING => 1 };

The end result:

	Good morning!

Complex document layouts can be achieved by concatenating the results from
several template replacements:

	my $header = Text::EasyTemplate->new("header.txt");
	my $body = Text::EasyTemplate->new("body.txt");
	my $row = Text::EasyTemplate->new("row.txt");
	my $footer = Text::EasyTemplate->new("footer.txt");
	
	...

	my $string = "";
	$string .= $header->replace($header_data);
	my $rows = "";
	foreach my element (@rowset) {
		$rows .= $row->replace($current_row_data);
	}
	$string .= $body->replace($body_data);
	$string .= $footer->replace($footer_data);

=head1 METHODS

=head2 new

You can create a new instance with this constructor. It takes as an argument
the name of the template file. This name is in string form and can contain
either the absolute or relative path to the file. The contents of the file are
kept in memory in case the same template will be used multiple times on the
same page.

	my $template = Text::EasyTemplate->new("templates_dir/template_file.txt");

=head2 replace

Takes as an argument a reference to a hash. Each key in the hash is the
placeholder used in the template file and will be replaced with its value. If
using conditionals, the values for true and false are the same as those
used in Perl.

	my $text = $template->replace($data);

=head1 AUTHOR

Luis Chavez, C<< <lchavez at andrew.cmu.edu> >>

=head1 TODO

Things that needs to be done in future versions:

=over 4

=item * Better error handling and syntax checking for labels and
if-else-endif structures.

=item * Nested conditionals.

=item * Supply template as string, as an additional option to a file.

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-simpletemplate at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SimpleTemplate>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::EasyTemplate

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-EasyTemplate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-EasyTemplate>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-EasyTemplate>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-EasyTemplate>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Luis Chavez, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut

