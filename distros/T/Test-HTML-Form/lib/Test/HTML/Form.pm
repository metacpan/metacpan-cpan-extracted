package Test::HTML::Form;
use strict;
use warnings;
no warnings 'redefine';

=head1 NAME

Test::HTML::Form - HTML Testing and Value Extracting

=head1 VERSION

0.05

=head1 SYNOPSIS

  use Test::HTML::Form;

  my $filename = 't/form_with_errors.html';

  my $response = $ua->request($request)

  # test functions

  title_matches($filename,'Foo Bar','title matches');

  no_title($filename,'test site','no english title');

  tag_matches($response,
       'p',
       { class => 'formError',
	 _content => 'There is an error in this form.' },
       'main error message appears as expected' );

  no_tag($filename,
       'p',
       { class => 'formError',
	 _content => 'Error' },
       'no unexpected errors' );


  text_matches($filename,'koncerty','found text : koncerty'); # check text found in file

  no_text($filename,'Concert','no text matching : Concert'); # check text found in file

  image_matches($filename,'/images/error.gif','matching image found image in HTML');

  link_matches($filename,'/post/foo.html','Found link in HTML');

  script_matches($response, qr/function someWidget/, 'found widget in JS');

  form_field_value_matches($response,'category_id', 12345678, undef, 'category_id matches');

  form_select_field_matches($filename,{ field_name => $field_name, selected => $field_value, form_name => $form_name}, $description);

  form_checkbox_field_matches($response,{ field_name => $field_name, selected => $field_value, form_name => $form_name}, $description);

  # Data extraction functions

  my $form_values = Test::HTML::Form->get_form_values({filename => $filename, form_name => 'form1'});

  my $posting_id = Test::HTML::Form->extract_text({filename => 'publish.html', pattern => 'Reference :\s(\d+)'});

=head1 DESCRIPTION

Test HTML pages and forms, and extract values.

Developed for and released with permission of Slando (http://www.slando.com)

All test functions will take either a filename or an HTTP::Response compatible object (i.e. any object with a content method)

=cut

use Data::Dumper;
use HTML::TreeBuilder;

use base qw( Exporter Test::Builder::Module);
our @EXPORT = qw(
  link_matches no_link
  image_matches no_image
  tag_matches no_tag
  text_matches no_text
  script_matches
  title_matches no_title
  form_field_value_matches
  form_select_field_matches
  form_checkbox_field_matches
  );


$Data::Dumper::Maxdepth = 2;
my $Test = Test::Builder->new;
my $CLASS = __PACKAGE__;
my %parsed_files = ();
my %parsed_file_forms = ();

our $VERSION = 0.05;

=head1 FUNCTIONS

=head2 image_matches

Test that some HTML contains an img tag with a src attribute matching the link provided.

image_matches($filename,$image_source,'matching image found image in HTML');

Passes when at least one instance found, fails if no matches found.

Takes a list of arguments filename/response, string or quoted-regexp to match, and optional test comment/name

=cut

sub image_matches {
  my ($filename,$link,$name) = (@_);
  local $Test::Builder::Level = 2;
  return tag_matches($filename,'img',{ src => $link },$name);
};


=head2 no_image

Test that some HTML doesn't contain any img tag with a src attribute matching the link provided.

no_image($response,$image_source,'no matching image found in HTML');

Passes when no matches found, fails if any matches found.

Takes a list of arguments filename/response, string or quoted-regexp to match, and optional test comment/name

=cut

sub no_image {
  my ($filename,$link,$name) = (@_);
  local $Test::Builder::Level = 2;
  return no_tag($filename,'img',{ src => $link },$name);
};


=head2 link_matches

Test that some HTML contains a href tag with a src attribute matching the link provided.

link_matches($response,$link_destination,'Found link in HTML');

Passes when at least one instance found, fails if no matches found.

Takes a list of arguments filename/response, string or quoted-regexp to match, and optional test comment/name

=cut

sub link_matches {
  my ($filename,$link,$name) = (@_);
  local $Test::Builder::Level = 2;
  return tag_matches($filename,['a','link'],{ href => $link },$name);
};

=head2 no_link

Test that some HTML does not contain a href tag with a src attribute matching the link provided.

link_matches($filename,$link_destination,'Link not in HTML');

Passes when if no matches found, fails when at least one instance found.

Takes a list of arguments filename/response, string or quoted-regexp to match, and optional test comment/name

=cut

sub no_link {
  my ($filename,$link,$name) = (@_);
  local $Test::Builder::Level = 2;
  return no_tag($filename,'a',{ href => $link },$name);
};

=head2 title_matches

Test that some HTML contains a title tag with content matching the pattern/string provided.

title_matches($filename,'Foo bar home page','title matches');

Passes when at least one instance found, fails if no matches found.

Takes a list of arguments filename/response, string or quoted-regexp to match, and optional test comment/name

=cut

sub title_matches {
  my ($filename,$title,$name) = @_;
  local $Test::Builder::Level = 2;
  return tag_matches($filename,"title", { _content => $title } ,$name);
};

=head2 no_title

Test that some HTML does not contain a title tag with content matching the pattern/string provided.

no_title($filename,'Foo bar home page','title matches');

Passes if no matches found, fails when at least one instance found.

Takes a list of arguments filename/response, string or quoted-regexp to match, and optional test comment/name

=cut

sub no_title {
    my ($filename,$title,$name) = (@_);
    local $Test::Builder::Level = 2;
    return no_tag($filename,'title', sub { shift->as_trimmed_text =~ m/$title/ },$name);
}


=head2 tag_matches

Test that some HTML contains a tag with content or attributes matching the pattern/string provided.

tag_matches($filename,'a',{ href => $link },$name); # check matching tag found in file

Passes when at least one instance found, fails if no matches found.

Takes a list of arguments 

=over 4

=item filename/response - string of path/name of file, or an HTTP::Response object

=item tag type(s) - string or arrarref of strings naming which tag(s) to match

=item attributes - hashref of attributes and strings or quoted-regexps to match

=item comment - an optional test comment/name

=back

=cut

sub tag_matches {
    my ($filename,$tag,$attr_ref,$name) = @_;
    my $count = 0;

    if (ref $tag ) {
	foreach my $this_tag (@$tag) {
	    $count += _tag_count($filename, $this_tag, $attr_ref);
	}
    } else {
	$count = _tag_count($filename, $tag, $attr_ref);
    }

    my $tb = $CLASS->builder;
    my $ok = $tb->ok( $count, $name);
    unless ($ok) {
	my $tagname = ( ref $tag ) ? join (' or ', @$tag) : $tag ;
	$tb->diag("Expected at least one tag of type '$tagname' in file $filename matching condition, but got 0\n");
    }
    return $ok;
}



=head2 no_tag

Test that some HTML does not contain a tag with content or attributes matching the pattern/string provided.

no_tag($filename,'a',{ href => $link },$name); # check matching tag NOT found in file

Passes if no matches found, fails when at least one instance found.

Takes a list of arguments filename/response, hashref of attributes and strings or quoted-regexps to match, and optional test comment/name

=cut

sub no_tag {
  my ($filename,$tag,$attr_ref,$name) = @_;
  my $count = _tag_count($filename, $tag,  $attr_ref);
  my $tb = $CLASS->builder;
  my $ok = $tb->is_eq( $count, 0, $name);
  unless ($ok) {
    $tb->diag("Expected no tags of type $tag matching criteria in file $filename, but got $count\n");
  }
  return $ok;
};

=head2 text_matches

Test that some HTML contains some content matching the pattern/string provided.

text_matches($filename,$text,$name); # check text found in file

Passes when at least one instance found, fails if no matches found.

Takes a list of arguments filename/response, string or quoted-regexp to match, and optional test comment/name

=cut

sub text_matches {
  my ($filename,$text,$name) = @_;
  my $count = _count_text({filename => $filename, text => $text });
  my $tb = $CLASS->builder;
  my $ok = $tb->ok( $count, $name);
  unless ($ok) {
    $tb->diag("Expected HTML to contain at least one instance of text '$text' in file $filename but not found\n");
  }
  return $ok;
};

=head2 no_text

Test that some HTML does not contain some content matching the pattern/string provided.

no_text($filename,$text,$name);  # check text NOT found in file

Passes if no matches found, fails when at least one instance found.

Takes a list of arguments filename/response, string or quoted-regexp to match, and optional test comment/name

=cut

sub no_text {
  my ($filename,$text,$name) = @_;
  my $count = _count_text({filename => $filename, text => $text });
  my $tb = $CLASS->builder;
  my $ok = $tb->is_eq( $count, 0 , $name);
  unless ($ok) {
    $tb->diag("Expected HTML to not contain text '$text' in file $filename but $count instances found\n");
  }
  return $ok;
};


=head2 script_matches

Test that HTML script element contains text matcging that provided.

  script_matches($response, qr/function someWidget/, 'found widget in JS');

Passes when at least one instance found, fails if no matches found.

Takes a list of arguments filename/response, string or quoted-regexp to match, and optional test comment/name

=cut

sub script_matches {
  my ($filename,$text_to_match,$name) = @_;
  my $pattern;
  if (ref($text_to_match) eq 'Regexp')  {
      $pattern = $text_to_match;
  }
  my $tree = _get_tree($filename);

  my @parse_args = sub {
	    my $elem = shift;
	    return 0 unless (ref $elem eq 'HTML::Element' );
	    my $ok = 0;
	    (my $text = $elem->as_HTML) =~ s/<(.|\n)*?>//g;
	    if ($pattern) {
		my $ok = $text =~ m/$pattern/;
		return $ok || $text =~ m/$pattern/;
	    } else {
		$text eq $text_to_match;
	    }
	};

  my $count = $tree->look_down( _tag => 'script', @parse_args );

  my $tb = $CLASS->builder;
  my $ok = $tb->ok( $count, $name);
  unless ($ok) {
      $tb->diag("Expected script tag in file $filename matching $text_to_match, but got 0\n");
  }
  return $ok;
};



=head2 form_field_value_matches

Test that the HTML contains a form element with the value matching that provided.

form_field_value_matches($filename,$field_name, $field_value, $form_name, $description);

form_field_value_matches($filename,$field_name, qr/some pattern/, undef, 'test for foo in bar form field');

Takes a list of arguments : filename/response, string or quoted-regexp to match, optional form_name, and optional test comment/name

Field value argument can be a string (for exact matches) or a quoted regexp (for pattern matches)

Use form_select_field_matches for select elements.

Use form_checkbox_field_matches for checkbox elements

=cut

sub form_field_value_matches {
  my ($filename,$field_name, $field_value, $form_name, $description) = @_;
  my $form_fields = __PACKAGE__->get_form_values({ filename => $filename, form_name => $form_name });
  my $tb = $CLASS->builder;

  my $elems = $form_fields->{$field_name};

  my $ok = 0;
  foreach my $elem (@$elems) {
      my $matches = _compare($elem,$field_value);
      if ($matches) {
	  $ok = $tb->ok( $matches  , $description);
	  last;
      }
  }

  unless ($ok) {
      $tb->ok( 0  , $description);
      $tb->diag("Expected form to contain field '$field_name' and have value of '$field_value' but not found in file $filename\n");
  }
  return $ok;
};

=head2 form_select_field_matches

Test that the HTML contains a form element with the value matching that provided.

form_select_field_matches($filename,{ field_name => $field_name, selected => $field_value, form_name => $form_name}, $description);

Takes a mixed list/ hashref of arguments :

=over 4

=item filename/response,

=item hashref of search attributes, keys are : field_name, selected, form_name (optional)

=item optional test comment/name

=back

Selected field value can be string or quoted regexp

=cut

sub form_select_field_matches {
  my ($filename, $field_value_args, $description) = @_;
  my $form_fields = __PACKAGE__->get_form_values({ filename => $filename, form_name => $field_value_args->{form_name} });
  my $tb = $CLASS->builder;

  my $field_value = $field_value_args->{selected};
  my $field_name = $field_value_args->{field_name};

  my $select_elem = $form_fields->{$field_name}[0];
  unless (UNIVERSAL::can($select_elem,'descendants')) {
    die "$select_elem (",$select_elem->tag,") is not a select html element for field : $field_name - did you mean to call form_checkbox_field_matches ?";
  }
  my $selected_option;
  foreach my $option ( $select_elem->descendants ) {
    next unless (ref($option) && ( lc($option->tag) eq 'option') );
    if ( _compare($option, $field_value) ) {
      $selected_option = $option;
      last;
    }
  }

  my $ok = $tb->ok( $selected_option && scalar grep (m/selected/i && $selected_option->attr($_), $selected_option->all_external_attr_names), $description);
  unless ($ok) {
    $tb->diag("Expected form to contain field '$field_name' and have option with value of '$field_value' selected but not found in file $filename \n");
  }
  return $ok;
}

=head2 form_checkbox_field_matches

Test that the HTML contains a form element with the value matching that provided.

form_checkbox_field_matches($filename,{ field_name => $field_name, selected => $field_value, form_name => $form_name}, $description);

Takes a mixed list/ hashref of arguments :

=over 4

=item filename/response,

=item hashref of search attributes, keys are : field_name, selected, form_name (optional)

=item optional test comment/name

=back

Selected field value can be string or quoted regexp

=cut

sub form_checkbox_field_matches {
  my ($filename, $field_value_args, $description) = @_;
  my $form_fields = __PACKAGE__->get_form_values({ filename => $filename, form_name => $field_value_args->{form_name} });
  my $tb = $CLASS->builder;

  my $field_value = $field_value_args->{selected};
  my $field_name = $field_value_args->{field_name};
  my $selected_box;
  my $checkbox_elems = $form_fields->{$field_name} || [];

  foreach my $checkbox ( @$checkbox_elems ) {
    if ( _compare($checkbox, $field_value) ) {
      $selected_box = $checkbox;
      last;
    }
  }

  my $ok = $tb->ok( $selected_box && scalar grep (m/checked/i && $selected_box->attr($_), $selected_box->all_attr_names), $description);
  unless ($ok) {
    $tb->diag("Expected form to contain field '$field_name' and have option with value of '$field_value' selected but not found in file $filename\n");
  }
  return $ok;
}

=head2 get_form_values

Extract form fields and their values from HTML content

my $form_values = Test::HTML::Form->get_form_values({filename => $filename, form_name => 'form1'});

Takes a hashref of arguments : filename (name of file or an HTTP::Response object, required), form_name (optional).

Returns a hashref of form fields, with name as key, and arrayref of XML elements for that field.

=cut

sub get_form_values {
  my $class = shift;
  my $args = shift;
  no warnings 'uninitialized';
  my $form_name = $args->{form_name};
  my $internal_form_name = $form_name . ' form';
  if ($parsed_file_forms{$args->{filename}}{$internal_form_name}) {
    return $parsed_file_forms{$args->{filename}}{$internal_form_name};
  } else {
    my $tree = _get_tree($args->{filename});
    my $form_fields = { };
    my ($form) = $tree->look_down('_tag', 'form',
				  sub {
				    my $form = shift;
				    if ($form_name) {
				      return 1 if $form->attr('name') eq $form_name;
				    } else {
				      return 1;
				    }
				  }
				 );
    if (ref $form) {
      my @form_nodes = $form->descendants();
      foreach my $node (@form_nodes) {
	next unless (ref($node));
	if (lc($node->tag) =~ /^(input|select|textarea|button)$/i)  {
	  if (lc $node->attr('type')  =~ /(radio|checkbox)/)  {
	    push (@{$form_fields->{$node->attr('name')}},$node);
	  } else {
	    $form_fields->{$node->attr('name')} = [ $node ];
	  }
	}
      }
    }
    $parsed_file_forms{$args->{filename}}{$internal_form_name} = $form_fields;

    return $form_fields;
  }
}

=head2 extract_text

my $posting_id = Test::HTML::Form->extract_text({filename => 'publish.html', pattern => 'Reference :\s(\d+)'});

=cut

sub extract_text {
  my $class = shift;
  my $args = shift;
  my $tree = _get_tree($args->{filename});
  my $pattern = $args->{pattern};
  my ($node) = $tree->look_down( sub {
				  my $thisnode = shift;
				  $thisnode->normalize_content;
				  return 1 if ($thisnode->as_trimmed_text =~ m/$pattern/i);
				});
  my ($match) = ($node->as_trimmed_text =~ m/$pattern/i);

  return $match;
}



#
##########################################
# Private / Internal methods and functions

sub _compare {
  my ($elem, $field_value) = @_;
  unless ($elem && (ref$elem eq 'HTML::Element') ) {
      warn "_compare passed $elem and value $field_value, $elem should be HTML::Element but is : ", ref $elem, "\n";
      return 0 ;
  }

  my $have_regexp = ( ref($field_value) eq 'Regexp' ) ? 1 : 0;
  my $value = $elem->attr('value') ;
  unless (defined $value) {
    $value = $elem->as_trimmed_text;
  }
  my $ok;
  if ($have_regexp) {
      $ok = ( $elem && $value =~ m/$field_value/ ) ? 1 : 0 ;
  } else {
      $ok = ( $elem && $value eq $field_value ) ? 1 : 0 ;
  }
  return $ok
}

sub _tag_count {
  my ($filename, $tag, $attr_ref) = @_;
  my $tree = _get_tree($filename);
  my @parse_args = ();
  if ( ref $attr_ref eq 'HASH' ) {
    my $pattern;
    if (ref($attr_ref->{_content}) eq 'Regexp')  {
      $pattern = $attr_ref->{_content};
      delete $attr_ref->{_content};
    }

    @parse_args = %$attr_ref ;
    if ($pattern) {
      push( @parse_args, sub {
		return 0 unless (ref $_[0] eq 'HTML::Element' );
		return  $_[0]->as_trimmed_text =~ m/$pattern/;
	    } );
    }
  } else {
    @parse_args = $attr_ref ;
  }
  my $count = $tree->look_down( _tag => $tag, @parse_args );

  return $count || 0;
}


sub _count_text {
  my $args = shift;
  my $tree = _get_tree($args->{filename});
  my $text = $args->{text};
  my $count = $tree->look_down( sub {
				  my $node = shift;
				  $node->normalize_content;
				  return 1 if ($node->as_trimmed_text =~ m/$text/);
				});
  return $count || 0;
}

sub _get_tree {
  my $filename = shift;
  unless ($parsed_files{$filename}) {
      my $tree = HTML::TreeBuilder->new; 
      $tree->store_comments(1);     
      if (ref $filename && $filename->can('content')) {
	  $tree->parse_content($filename->decoded_content);
      } else {
	  die "can't find file $filename" unless (-f $filename);
	  $tree->parse_file($filename);
      }
    $parsed_files{$filename} = $tree;
  }
  return $parsed_files{$filename};
}


=head1 SEE ALSO

=over 4

=item Test::HTML::Content

=item HTML::TreeBuilder

=item Test::HTTP::Response

=back

=head1 AUTHOR

Aaron Trevena

=head1 BUGS

Please report any bugs or feature requests to http://rt.cpan.org

=head1 COPYRIGHT & LICENSE

Copyright 2008 Slando.
Copyright 2009 Aaron Trevena.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;
