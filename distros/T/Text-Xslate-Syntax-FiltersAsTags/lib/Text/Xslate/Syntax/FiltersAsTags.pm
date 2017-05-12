package Text::Xslate::Syntax::FiltersAsTags;

=head1 NAME

Text::Xslate::Syntax::FiltersAsTags - easily add more template tags which are mapped onto filters

=head1 VERSION

version 0.1

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

    package My::Own::Syntax;
    use Mouse;

    extends 'Text::Xslate::Syntax::TTerse';     # or ::Kolon
    with 'Text::Xslate::Syntax::FiltersAsTags'; # this module!

    my @more_symbols = qw(TL R_table R_vtable R_svg R_collect_tables); # additional tags
    sub more_symbols { @more_symbols } # you must provide this method

    no Mouse;
    __PACKAGE__->meta->make_immutable;
    1

in your controller:

    my $tx = Text::Xslate->new(
	syntax => 'My::Own::Syntax',
	function => +{
		tl      => html_builder(\&translate_switch),
		r_table => html_builder { &fixup_filter_parser; make_R_table($_[0]) },
		r_svg   => html_builder { &fixup_filter_parser; make_R_svg($_[0]); },
		r_collect_tables =>
			   html_builder { &fixup_filter_parser;
			eval_R_lines('r=list()');
			eval_R_lines($_[0]);
			R_merge_tables()
		},
	   },
   );

    sub fixup_filter_parser {
	for (@_) {
		s/^\s*<!\[CDATA\[(.*)\]\]>\s*$/$1/s;
		s/(\n\s*)*$//; s/^(\s*\n)*//;
	}
    }

in your template:

    [% TL %][_en] observation period [_de] Beobachtungszeitraum[% END %]

    [% R_table %]
    summary(md_real$region)
    [% END %]

    [% R_svg %]
    boxplot(md_real$[% data %], log="y", main="[% data %]")
    [% END %]

    [% R_collect_tables %]<![CDATA[
    r$`[% TL %] at beginning     [% END %]` <- table(md_real[md_real$appeared.on$mday<4,]$appeared.on$hour)
    r$`[% TL %] not at beginning [% END %]` <- table(md_real[md_real$appeared.on$mday>=4,]$appeared.on$hour)
    ]]>[% END %]


=head1 DESCRIPTION

this L<role|Mouse::Role> helps you to quickly add more template tags
to your Xslate template, which are then mapped to filters in your
parse run.

You only need to provide a single method in your own syntax class,
C<more_symbols>. It must return a list of additional tags allowed in
the template. You connect to those tags, which are a simple
convenience for a filter call, from your controller.

Note that you do need to make an own class for every domain specific
template, and it does need to use L<Mouse> because that's what
L<Text::Xslate> uses. You will get weird errors when trying to use
Moo.

=cut

use Mouse::Role;
requires 'init_symbols';
requires 'more_symbols';

after init_symbols => sub {
    my($parser) = @_;
    my @intros = grep { $parser->symbol_table->{$_}->is_block_end &&
                        $parser->symbol_table->{$_}->id !~ /^\(/  &&
                        length $parser->symbol_table->{$_}->counterpart }
                 keys %{ $parser->symbol_table };
    my ($intro, $outro);
    $intro = $parser->symbol_table->{ $intros[0] }->counterpart if @intros;
    $outro = $parser->symbol_table->{ $intros[0] }->id if @intros;

	my $std_sb = sub {
		my($parser, $symbol) = @_;

		my $filter = lc $symbol->id;

		my $proc = $parser->lambda($symbol);

		$proc->second([]);
		$parser->advance($intro) if length $intro;
		$proc->third( $parser->statements() );
		$parser->advance(length $outro ? $outro : 'END');

		my $callmacro  = $parser->call($proc->first);

		my $callfilter = $parser->call($filter, $callmacro);
		return( $proc, $parser->print($callfilter) );
	};

	$parser->symbol($_)->set_std($std_sb)
		for $parser->more_symbols;
	
	return;
};

=head1 AUTHOR

Ailin Nemui E<lt>ailin at devio dot usE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ailin Nemui.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

no Mouse::Role;
1
