##############################################################################
##
##  Web::Reactor application machinery
##  2013-2016 (c) Vladi Belperchinov-Shabanski "Cade"
##  <cade@bis.bg> <cade@biscom.net> <cade@cpan.org>
##
##  LICENSE: GPLv2
##
##############################################################################
package Web::Reactor::HTML::FormEngine;
use strict;
use Exporter;
use Exception::Sink;
use Data::Dumper;

our @ISA = qw( Exporter );

our @EXPORT = qw(
                html_form_engine_import_input
                html_form_engine_display
                );


=pod

$form_def = [

            {
              NAME    => 'form entry name',
              TYPE    => 'entry type = string|bool|combo|button',
              VALUE   => 'visible value',
              DATA    => 'actual data, sometimes equal to value',
              RE      => 'regexp to check input',
              RE_HELP => 'help hint text when RE fails',
              IN_CB   => 'input data filter callback',
            },

            ];

=cut

sub html_form_engine_import_input
{
  my $reo      = shift; # reactor object, mandatory!
  my $form_def = shift; # form definition (array ref)
  my %opt      = @_;    # form options

  my $form_name = $opt{ 'NAME' } || 'FORM'; # TODO: hash upcase

  boom "missing/wrong first argument, expected Web::Reactor object" unless ref( $reo ) eq 'Web::Reactor';
  boom "missing FORM_NAME" unless $form_name;

  my %data;
  my $errors; # errors count
  my %errors; # fields with errors

  my $user_input_hr   = $reo->get_user_input();
  my $safe_input_hr   = $reo->get_safe_input();
  my $page_session_hr = $reo->get_page_session();

  %data = %{ $page_session_hr->{ 'FORM_INPUT_DATA' }{ $form_name } } if exists $page_session_hr->{ 'FORM_INPUT_DATA' }{ $form_name };

  # print STDERR Dumper( 'html_form_engine_import_input: safe/user input hrs:', $user_input_hr, $safe_input_hr );

  for my $er ( @$form_def )
    {
    my $name    = uc $er->{ 'NAME' };
    my $safe    =    $er->{ 'SAFE' };
    my $re      =    $er->{ 'RE'      };

    my $data;

    # FIXME: checkboxes! usual checkboxes does not return input data if unchecked! so exists below won't work

    my $exists = 0;
    if( $safe )
      {
      $exists = exists $safe_input_hr->{ $name };
      $data = $safe_input_hr->{ $name } if $exists;
      }
    else
      {
      $exists = exists $user_input_hr->{ $name };
      $data = $user_input_hr->{ $name } if $exists;
      }

    next unless $exists;
    next if ref( $data ); # strip objects, i.e. file uploads

# print STDERR " form iiiiiiiiiiiiiiiiiiiiiiiiiiii [$name] [$data] [$re] [$exists] {".ref($data)."}\n";

#    next unless $exists;  # FIXME: should be an option

    my $ok = 0;
    # FIXME: callback check per type
    if( $re )
      {
      my $qr = qr/$re/;
      if( $data =~ $qr )
        {
        $ok = 1;
        }
      else
        {
        $errors++;
        $errors{ $name } = 1;
        }
      }
    else
      {
      $ok = 1;
      }

    next unless $ok;
    $data{ $name } = $data;
    }

  $page_session_hr->{ 'FORM_INPUT_DATA' }{ $form_name } = \%data;

print STDERR Dumper( 'html_form_engine_import_input: data and errors hrs:', \%data, \%errors );

  my $reterr = $errors > 0 ? \%errors : undef;
  return ( \%data, $reterr );
}


# arg1 array ref of form entities
sub html_form_engine_display
{
  my $reo      = shift; # reactor object, mandatory!
  my $form_def = shift; # form definition (array ref)
  my %opt      = @_;    # form options

  my $form_name = $opt{ 'NAME' } || 'FORM'; # TODO: hash upcase
  my $form_input_data = $opt{ 'INPUT_DATA' } || {}; # TODO: warning: missing/invalid input data
  my $form_input_errors = $opt{ 'INPUT_ERRORS' } || {}; # TODO: warning: missing/invalid input errors

  boom "invalid form definition argument 2, expected ARRAY REF" unless ref( $form_def ) eq 'ARRAY';
  boom "missing/wrong first argument, expected Web::Reactor object" unless ref( $reo ) eq 'Web::Reactor';
  boom "missing FORM_NAME" unless $form_name;

  my $text;
  my $errors;

  #my $page_session = $reo->get_page_session();

  #my $state_keeper = $reo->args( FORM_NAME => $form_name ); # keep state and more args
  #$text .= "<form action=? method=post>";
  #$text .= "<input type=hidden name=_ value=$state_keeper>";


  my $form = $reo->new_form();

  $text .= $form->begin( NAME => $form_name );

  my %values;

  $text .= "<table border=0>";
  for my $er ( @$form_def )
    {
    my $name    = uc $er->{ 'NAME'    };
    my $type    = uc $er->{ 'TYPE'    };
    my $label   = $er->{ 'LABEL'   };
    my $size    = $er->{ 'SIZE'    } || $er->{ 'LEN' };
    my $maxlen  = $er->{ 'MAXLEN'  };
    my $value   = $er->{ 'VALUE'   };
    my $re_help = $er->{ 'RE_HELP' };
    my $pass    = $er->{'PASS'};
    my $rows    = $er->{'ROWS'};
    my $cols    = $er->{'COLS'};

    my $data    = $form_input_data->{ $name };
    my $error   = $form_input_errors->{ $name };

    $text .= "</tr>";
    $text .= "<td align=right>$label</td>";
    $text .= "<td align=left>";

    # print STDERR " form ffffffffffffffffffffffffffff [$name] [$value] [$re_help]\n";

    if( $type =~ /^(STRING|STR|CHAR|TEXT|INPUT)$/ )
      {
      $text .= $form->input( NAME => $name, SIZE => $size, MAXLEN => $maxlen, VALUE=> $data, PASS => $pass );
      }
    elsif( $type =~ /^(TEXT)$/ )
      {
      $text .= $form->textarea( NAME => $name, SIZE => $size, MAXLEN => $maxlen, VALUE=> $data,  ROWS => $rows, COLS => $cols);
      }

    elsif( $type =~ /^(CB|CHECK|CHECKBOX)$/ )
      {
      $text .= $form->checkbox( NAME => $name, VALUE=> $data );
      }
    elsif( $type =~ /^(SELECT)$/ )
      {
      $text .= $form->select( NAME => $name, DATA => $value, SELECTED => { $data => 1 } );
      }
    elsif( $type =~ /^(BUTTON|SUBMIT)$/ )
      {
      $text .= $form->button( NAME => $name, VALUE => $value );
      }
    elsif( $type =~ /^(FILE)$/ )
      {
      my $form_id = $form->get_id();
      $text .= "<input type='file' name='$name' size='16' form=$form_id>";
      }
    else
      {
      boom "invalid form entry type [$type]\n"; # TODO: dump and function arguments
      }
    $text .= "<span style='color: #f00'>$re_help</span>" if $error;
    $text .= "</td>";
    $text .= "</tr>";
    }

  $text .= "</table>";

  $text .= $form->end();

  return $text;
}

1;
