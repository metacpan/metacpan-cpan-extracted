package XS::TCC::Parser;
use strict;
use warnings;

# These regular expressions were derived from Regexp::Common v0.01.
my $RE_comment_C   = q{(?:(?:\/\*)(?:(?:(?!\*\/)[\s\S])*)(?:\*\/))};
my $RE_comment_Cpp = q{(?:\/\*(?:(?!\*\/)[\s\S])*\*\/|\/\/[^\n]*\n)};
my $RE_quoted      = (q{(?:(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\")}
                     .q{|(?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\'))});
my $RE_balanced_brackets;
$RE_balanced_brackets =
  qr'(?:[{]((?:(?>[^{}]+)|(??{$RE_balanced_brackets}))*)[}])';
my $RE_balanced_parens;
$RE_balanced_parens =
  qr'(?:[(]((?:(?>[^()]+)|(??{$RE_balanced_parens}))*)[)])';


sub _normalize_type {
  # Normalize a type for lookup in a typemap.
  my($type) = @_;

  # Remove "extern".
  # But keep "static", "inline", "typedef", etc,
  #  to cause desirable typemap misses.
  $type =~ s/\bextern\b//g;

  # Whitespace: only single spaces, none leading or trailing.
  $type =~ s/\s+/ /g;
  $type =~ s/^\s//; $type =~ s/\s$//;

  # Adjacent "derivative characters" are not separated by whitespace,
  # but _are_ separated from the adjoining text.
  # [ Is really only * (and not ()[]) needed??? ]
  $type =~ s/\*\s\*/\*\*/g;
  $type =~ s/(?<=[^ \*])\*/ \*/g;

  return $type;
}

sub extract_function_metadata {
  my ($code) = @_;

  my $results = {
    function_names => [],
    functions => {},
  };

  # First, we crush out anything potentially confusing.
  # The order of these _does_ matter.
  $code =~ s/$RE_comment_C/ /go;
  $code =~ s/$RE_comment_Cpp/ /go;
  $code =~ s/^\#.*(\\\n.*)*//mgo;
  #$code =~ s/$RE_quoted/\"\"/go; # Buggy, if included.
  $code =~ s/$RE_balanced_brackets/{ }/go;

  # The decision of what is an acceptable declaration was originally
  # derived from Inline::C::grammar.pm version 0.30 (Inline 0.43).

  my $re_plausible_place_to_begin_a_declaration = qr {
    # The beginning of a line, possibly indented.
    # (Accepting indentation allows for C code to be aligned with
    #  its surrounding perl, and for backwards compatibility with
    #  Inline 0.43).
    (?m: ^ ) \s*
  }xo;

  # Instead of using \s , we dont tolerate blank lines.
  # This matches user expectation better than allowing arbitrary
  # vertical whitespace.
  my $sp = qr{[ \t]|\n(?![ \t]*\n)};

  my $re_type = qr {(
    (?: \w+ $sp* )+? # words
    (?: \*  $sp* )*  # stars
  )}xo;

  my $re_identifier = qr{ (\w+) $sp* }xo;
  while( $code =~ m{
          $re_plausible_place_to_begin_a_declaration
          ( $re_type $re_identifier $RE_balanced_parens $sp* (\;|\{) )
         }xgo)
  {
    my($type, $identifier, $args, $what) = ($2,$3,$4,$5);
    $args = "" if $args =~ /^\s+$/;

    my $need_threading_context = 0;
    my $is_decl     = $what eq ';';
    my $function    = $identifier;
    my $return_type = _normalize_type($type);
    my @arguments   = split ',', $args;

    #goto RESYNC if $is_decl && !$self->{data}{AUTOWRAP};
    goto RESYNC if exists $results->{functions}{$function};
    #goto RESYNC if !defined $self->{data}{typeconv}{valid_rtypes}{$return_type};

    my(@arg_names,@arg_types);
    my $dummy_name = 'arg1';

    my $argno = 0;
    foreach my $arg (@arguments) {
      # recognize threading context passing as part of first arg
      if ($argno++ == 0 and $arg =~ s/^\s*pTHX_?\s*//) {
        $need_threading_context = 1;
        next if $arg !~ /\S/;
      }

      my $arg_no_space = $arg;
      $arg_no_space =~ s/\s+//g;

      # If $arg_no_space is 'void', there will be no identifier.
      if( my($type, $identifier) =
          $arg =~ /^\s*$re_type(?:$re_identifier)?\s*$/o )
      {
        my $arg_name = $identifier;
        my $arg_type = _normalize_type($type);

        if((!defined $arg_name) && ($arg_no_space ne 'void')) {
          goto RESYNC if !$is_decl;
          $arg_name = $dummy_name++;
        }
        #goto RESYNC if ((!defined
        #    $self->{data}{typeconv}{valid_types}{$arg_type}) && ($arg_no_space ne 'void'));

        # Push $arg_name onto @arg_names iff it's defined. Otherwise ($arg_no_space
        # was 'void'), push the empty string onto @arg_names (to avoid uninitialized
        # warnings emanating from C.pm).
        defined($arg_name) ? push(@arg_names,$arg_name)
                           : push(@arg_names, '');
        if($arg_name) {push(@arg_types,$arg_type)}
        else {push(@arg_types,'')} # $arg_no_space was 'void' - this push() avoids 'uninitialized' warnings from C.pm
      }
      elsif($arg =~ /^\s*\.\.\.\s*$/) {
        push(@arg_names,'...');
        push(@arg_types,'...');
      }
      else {
        goto RESYNC;
      }
    }

    # Commit.
    push @{$results->{function_names}}, $function;
    $results->{functions}{$function}{return_type}= $return_type;
    $results->{functions}{$function}{arg_names} = [@arg_names];
    $results->{functions}{$function}{arg_types} = [@arg_types];
    $results->{functions}{$function}{need_threading_context} = $need_threading_context if $need_threading_context;

    next;

RESYNC:  # Skip the rest of the current line, and continue.
    $code =~ /\G[^\n]*\n/gc;
  }

  return $results;
}

__END__

=head1 NAME

XS::TCC::Parser - C function signature parsing with regexes

=head1 SYNOPSIS

  my $result = XS::TCC::Parser::extract_function_metadata($code);

=head1 DESCRIPTION

This is internal to C<XS::TCC>.

This module parses the signature of C functions to extract type mapping information.
It is very, very similar to the code in L<Inline::C::ParseRegExp> because that's
where it's originally from.

=head2 AUTHOR

Original code written for Inline::C by Mitchell N Charity <mcharity@vendian.org>.

Modified for this module by Steffen Mueller <smueller@cpan.org>.

=head1 COPYRIGHT

Copyright (c) 2002. Brian Ingerson.

Copyright (c) 2008, 2010-2012. Sisyphus.

Copyright (c) 2013, Steffen Mueller.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
