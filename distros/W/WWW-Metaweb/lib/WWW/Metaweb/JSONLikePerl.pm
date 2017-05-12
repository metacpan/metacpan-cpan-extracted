package WWW::Metaweb::JSONLikePerl;

use 5.008006;
use strict;
use warnings;

use Exporter;

our @ISA	 = qw(Exporter);
our @EXPORT	 = qw();
our @EXPORT_OK	 = qw(jsonlp_fetch jsonlp_replace jsonlp_insert jsonlp_quote jsonlp_unquote);
our %EXPORT_TAGS = (standard => [qw(jsonlp_fetch jsonlp_replace jsonlp_insert jsonlp_quote jsonlp_unquote)]);
our $VERSION	= 0.01;

=head1 NAME

WWW::Metaweb::JSONLikePerl - Access a JSON string like a Perl structure

=head1 SYNOPSIS

  use strict;
  use WWW::Metaweb::JSONLikePerl qw(:standard);

  my json = qq({
        "cover_appearances": [
          {
            "part_of_series": "Runaways", 
            "type": "/comic_books/comic_book_issue", 
            "name": "Runaways Vol 1 #1"
          }, 
          {
            "part_of_series": "Runaways", 
            "type": "/comic_books/comic_book_issue", 
            "name": "Runaways Vol. 2 #1"
          }, 
          {
            "part_of_series": "Mystic Arcana", 
            "type": "/comic_books/comic_book_issue", 
            "name": "Mystic Arcana Book IV: Fire"
          }
        ], 
        "name": "Nico Minoru", 
        "created_by": ["Brian K. Vaughan"], 
        "/type/object/creator": "/user/metaweb", 
        "type": "/comic_books/comic_book_character", 
        "id": "/topic/en/nico_minoru"
  });

  my $id = $jsonlp_fetch('->{id}', $json);

  my new_json;

  $new_json = jsonlp_replace('->{cover_appearances}->[2]->{name}', $json, 'Mystic Arcana IV: Sister Grimm');

  $new_json = jsonlp_insert('->{created_by}', $json, 'Adrian Alphona');

  my $second_json = qq({
	  "query":{
		  "country":null,
		  "name":99507,
		  "type":["/location/postal_code"]
	  }
  });

  $new_json = jsonlp_quote('->{query}->{name}', $second_json, '"');

  $new_json = jsonlp_unquote('->{query}->{type}', $second_json);

=head1 ABSTRACT

WWW::Metaweb::JSONLikePerl allows manipulation of a JSON string, referencing items like a perl structure, but without actually converting the string.

=head1 EXPORTABLE FUNCTIONS

=over

=item B<< $value = jsonlp_fetch($structure_path, $json_string, [include_quotes]) >>

Returns the value of the item in C<$json_string> pointed to by C<$structure_path>.

If C<include_quotes> is true then whatever may be quoting the value being fetched will also be included, this may be 'C<{ }>' for a hash, 'C<[ ]>' for an array, 'C<" ">' for a string or make no difference if it's a number or bare word.

=cut

sub jsonlp_fetch  {
	my $pp = shift;
	my $js = shift;
	my $quoted = shift || 0;

	return jsonlp_traverse($pp, $js, { fetch_quoted => $quoted });
} # &jsonlp_fetch

=item B<< $new_json = jsonlp_replace($structure_path, $json_string, $replacement_value) >>

Replaces the specified JSON node with C<$replacement_value>.

=cut

sub jsonlp_replace  {
	my $pp = shift;
	my $js = shift;
	my $replacement = shift;

	return jsonlp_traverse($pp, $js, { replace => $replacement });
} # &jsonlp_replace

=item B<< $new_json = jsonlp_insert($structure_path, $json_string, $text_to_insert) >>

Inserts C<$text_to_insert> into the specified JSON node.

=cut

sub jsonlp_insert  {
	my $pp = shift;
	my $js = shift;
	my $insert = shift;

	return jsonlp_traverse($pp, $js, { insert => $insert });
} # &jsonlp_insert

=item B<< $new_json = jsonlp_quote($structure_path, $json_string, $quote_characters) >>

Quotes the specified node as specified by C<$quote_characters>.

If C<$quote_characters> has a length of 1 (such as 'C<">') the specified node will be surrounded by that character (eg. C<"994002">). If it has a length of 2 (such as 'C<{}>') the first character will go before the specified node, the second character will go acter the specified node (eg. C<{994002}>). Any other number o characters and C<undef> will be returned.

=cut

# Actually that's a lie, you can pass an empty string for $char and it will
# behave the same as unquote().

sub jsonlp_quote  {
	my $pp = shift;
	my $js = shift;
	my $char = shift;

	return (length $char >= 0 && length $char <= 2) ? jsonlp_traverse($pp, $js, { quote => $char }) : undef;
} # &jsonlp_quote

=item B<< $new_json = jsonlp_unquote($structure_path, $json_string) >>

Removes quotes from the specified node.

=cut

sub jsonlp_unquote  {
	my $pp = shift;
	my $js = shift;

	return jsonlp_traverse($pp, $js, { quote => '' });
} # &jsonlp_unquote

=back

=head1 BUGS AND TODO

None of either as of yet.

=head1 ACCKNOWLEDGEMENTS

Mainly the Barcelona weather for keeping me up late enough to come up with this crazy idea.

=head1 SEE ALSO

JSON, WWW::Metaweb

=head1 AUTHORS

Hayden Stainsby E<lt>hds@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Hayden Stainsby

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

# jsonlp_traverse - Json like-perl traverse
# This function accepts a perl-like dereferencing / accessing string and a JSON
# string. It will either return the item pointed to - or set that item with a
# replacement and return the new string.
sub jsonlp_traverse  {
	my $pp = shift; # Perl path
	my $js = shift; # JSON string
	my $action = shift; # Replacement for JSON segment
	my $super_inside = shift; # What we're inside
	my ($path_segment, $path_index, $json_segment, $remaining_pp, $parsed_js);

	# This means we've hit the bottom of our parsing.
	if (length $pp == 0)  {
		if (defined $action->{replace})  {
			return $action->{replace};
		}
		elsif (defined $action->{insert})  {
			my $insert = $action->{insert};
			$insert .= ',' if length $js > 0;
			$js =~ s/^(\s*)/$1$insert$1/;
			return $js;
		}
		elsif (defined $action->{quote}) {
			my ($lq, $rq);
			if (length $action->{quote} == 2)  {
				$lq = substr $action->{quote}, 0, 1;
				$rq = substr $action->{quote}, 1, 1;
			}
			elsif (length $action->{quote} == 1)  {
				$lq = $rq = substr $action->{quote}, 0, 1;
			}
			else  {
				$lq = $rq = '';
			}
			
			return $lq.$js.$rq;
		}
		else  {
			return $js;
		}
	}

	# Parse perl path
	$remaining_pp = '';
	if ($pp =~ /^->(\{.+?\})(.*)$/)  {
		$path_segment = $1;
		$remaining_pp = $2;
		$path_segment =~ s/[\{\}]//g;
	}
	elsif ($pp =~ /^->(\[\d+\])(.*)$/)  {
		$path_index = $1;
		$remaining_pp = $2;
		$path_index =~ s/[\[\]]//g;
	}
	elsif ($pp eq '->')  {
		$pp = '';
	}

	# Parse JSON
	my $isquoted = 0;
	my $cur = { curly => 0, square => 0 };
	my $begin = undef;
	my $inside = undef;
	my $am_a = undef;
	my $depth = 0;
	my $content = undef;
	my $current_name = undef;
	my $current_value = undef;
	my $value_index = undef;
	my $parse_value;
	for (my $i = 0; $i < (length $js)+1; $i++)  {
		my $c = substr($js, $i, 1);
		# Get the beginning count for brackets before this character.
		$begin = { posn => $i,
			   curly => $cur->{curly},
			   square => $cur->{square} } unless defined $begin;
		
		# Count the openning and closing of curly and square brackets,
		# they don't count if they're in quotes.
		if ($isquoted)  {
			if ($c eq '"')  {
				$isquoted = 0;
			}
		}
		else  {
			   if ($c eq '{')  { $cur->{curly}++; }
			elsif ($c eq '}')  { $cur->{curly}--; }
			elsif ($c eq '[')  { $cur->{square}++; }
			elsif ($c eq ']')  { $cur->{square}--; }
			elsif ($c eq '"')  {
				$isquoted = 1;
			}
		}

		# We're not inside any sort of delimiters
		if (not defined $inside)  {
			# Check for the beginning of an object
			if ($c eq '{')  {
				$inside = 'HASH';
			}
			elsif ($c eq '[')  {
				$inside = 'ARRAY';
			}
			elsif ($c eq '"')  {
				$inside = 'STRING';
			}
			elsif ($c =~ /[\d\-\+]/)  {
				$inside = 'NUMBER';
				$depth = 1;
			}
			elsif ($c =~ /\w/)  {
				$inside = 'BARE';
				$depth = 1;
			}

			# We've entered an object, decide whether it's a key or
			# value and set the begin hash to what sort of object
			# we're inside.
			if (defined $inside)  {
				$begin->{inside} = $inside;

				if ((not defined $am_a) && $inside eq 'STRING' && ((not defined $super_inside) || $super_inside ne 'ARRAY'))  {
					$am_a = 'key';
				}
				elsif (not defined $am_a)  {
					$am_a = 'value';
				}
			}
			else  {
				# We're not inside an object, sratch begin, but
				# if we're on a ':' then a value is coming up.
				$begin = undef;
				if ((not defined $am_a) && $c eq ':')  {
					$am_a = 'value';
				}
			}

		}
		else  {
			# We can only end an object (leave inside) if the
			# bracket count is the same as before the object
			# started.
			my $matched = 0;
			$matched = 1 if ($begin->{curly} == $cur->{curly} && $begin->{square} == $cur->{square});

			if ($c eq '}' && $inside eq 'HASH' && $matched)  {
				$inside = undef;
			}
			elsif ($c eq ']' && $inside eq 'ARRAY' && $matched)  {
				$inside = undef;
			}
			elsif ($c eq '"' && $inside eq 'STRING' && $matched)  {
				$inside = undef;
			}
			elsif ($c !~ /[\d\.]/ && $inside eq 'NUMBER' && $matched)  {
				$content = substr($js, $i-$depth, $depth);
				$i--;
				$inside = undef;
			}
			elsif ($c !~ /\w/ && $inside eq 'BARE' && $matched)  {
				$content = substr($js, $i-$depth, $depth);
				$i--;
				$inside = undef;
			}
			else  {
				# We're going deeper into the object (in
				# characters).
				$depth++;
			}

			$content = substr($js, $i-$depth, $depth) unless defined $inside || defined $content;
		}

		# We've left an object (gone outside it), time to work.
		if ((not defined $inside) && (defined $content))  {
#debug			print "$content ($am_a)\n";
			if ($am_a eq 'key')  {
				# If it's a key, not much work to do.
				$current_name = $content;
				$current_value = undef;
				$value_index = 0;

			}
			elsif ($am_a eq 'value')  {
				# If this is an array, increase the value_index.
				if (defined $current_value)  {
					$value_index++;
				}
				else  {
					$value_index = 0;
				}
				$current_value = $content;

				my $returned = undef;
				my $traversed = 0;

				# Or if there's no name for this value and we
				# don't know what our outer structure is.
				if ((not defined $current_name) && (not defined $super_inside))  {
					$returned = jsonlp_traverse($pp, $content, $action, $begin->{inside});
					$traversed = 1
				}
				# If this value's name or index matches the perl
				# path (pp) we're following, recurse into it.
				elsif (((defined $path_index) && $value_index == $path_index) || ((defined defined $path_segment) && $current_name eq $path_segment))  {
					$returned = jsonlp_traverse($remaining_pp, $content, $action, $begin->{inside});
					$traversed = 1;
				}

				if ($traversed)  {
					# A value has been returned, that's
					# good, if we were replacing something
					# then replace it, otherwise return
					# just the value asked for.
					if (defined $returned)  {
						my $replace_delimeters = 0;
						print "fucked off!\n" unless defined $remaining_pp;
						$replace_delimeters = 1 if $begin->{inside} ne 'NUMBER' && $begin->{inside} ne 'BARE' && (length $remaining_pp) == 0;
						if (defined $action->{replace} || defined $action->{insert} || defined $action->{quote})  {
							my ($before, $after) = ('', '');

							$before = substr $js, 0, $begin->{posn} + (length $remaining_pp != 0 || defined $action->{insert});
							$after = substr $js, $begin->{posn} + length($content) + ($replace_delimeters*2) + (length $remaining_pp != 0) - (defined $action->{insert});
							$parsed_js = $before . $returned . $after;
						}
						else  {
							$parsed_js = $returned;
							if (length $remaining_pp == 0 && defined $super_inside && $action->{fetch_quoted})  {
								$parsed_js = substr($js, $begin->{posn}, (length $returned) + $replace_delimeters*2);
							}
						}
					}

					# Once a traversal has been attempted,
					# we're on our way out.
					last;
				}
			} # Finished a value
			
			# Still moving sideways, reset all these values.
			$begin = undef;
			$am_a = undef;
			$content = undef;
			$depth = 0;
		}
	} # iterate through each chacter

	return $parsed_js;
} # &jsonlp_traverse


return 1;
__END__


