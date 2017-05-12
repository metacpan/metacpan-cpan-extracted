#!/usr/bin/perl -w
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: 
## Description: 
##----------------------------------------------------------------------------
use strict;
use warnings;
## Cannot use Find::Bin because script may be invoked as an
## argument to another script, so instead we use __FILE__
use File::Basename qw(dirname fileparse basename);
use File::Spec;
## Add script directory
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)));
## Add script directory/lib
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)), qq{lib});
## Add script directory/../lib
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)), qq{..}, qq{lib});
use Readonly;
use Tk::FormUI 1.04;
use Data::Dumper;

## List reference for choices
Readonly::Scalar my $CONTINENT_CHOICES => [
  { label => qq{Asia},            value => 0x01,  },
  { label => qq{Africa},          value => 0x02,  },
  { label => qq{North America},   value => 0x04,  },
  { label => qq{South America},   value => 0x08,  },
  { label => qq{Antarctica},      value => 0x10,  },
  { label => qq{Australia},       value => 0x20,  },
  { label => qq{Europe},          value => 0x40,  },
];

##---------------------------------------
## Hash used to initialize the form
##---------------------------------------
Readonly::Scalar my $SURVEY_FORM => {
  title  => qq{Tk::FormUI Demo},
  message => qq{\nPlease complete this form and click the Submit button\n},
  button_label => qq{&Submit},
  fields => [
    {
      type  => $Tk::FormUI::ENTRY,
      width => 40,
      label => qq{Name},
      key   => qq{name},
      validation =>
        sub
        {
          my $field = shift;
          my $data = $field->value;
          $data =~ s/^\s+//g;  ## Remove leading spaces
          $data =~ s/\s+$//g;  ## Remove trailing spaces
          return if ($data);
          return(qq{The name field cannot be empty!});
        },
    },
    {
      type  => $Tk::FormUI::RADIOBUTTON,
      label => qq{Title},
      key   => qq{title},
      max_per_line => 2,    ## At most, 2 choices per line
      choices => [
        { label => qq{Dr.},   value => qq{Dr.},   },
        { label => qq{Mrs.},  value => qq{Mrs.},  },
        { label => qq{Ms.},   value => qq{Ms.},   },
        { label => qq{Mr.},   value => qq{Mr.},   },
      ],
      validation =>
        sub
        {
          my $field = shift;
          my $data = $field->value;
          return if (defined($data));
          return(qq{You must select a Title!});
        },
    },
    {
      type  => $Tk::FormUI::COMBOBOX,
      label => qq{Current Continent},
      key   => qq{continent_residence},
      choices => $CONTINENT_CHOICES,
      validation =>
        sub
        {
          my $field = shift;
          my $data = $field->value;
          return if (defined($data));
          return(qq{You must select your current continent of residence!});
        },
    },
    {
      type  => $Tk::FormUI::CHECKBOX,
      label => qq{Continents Visited},
      key   => qq{continent_visited},
      max_per_line => 2,    ## At most, 2 choices per line
      choices => $CONTINENT_CHOICES,
    },
    {
      type  => $Tk::FormUI::DIRECTORY,
      width => 40,
      label => qq{Pictures},
      key   => qq{pictures},
      validation =>
        sub
        {
          my $field = shift;
          return if (length($field->value));
          return(qq{The name field cannot be empty!});
        },
    },
  ],
};

##----------------------------------------------------------------------------
## Main code
##----------------------------------------------------------------------------
my $data = Tk::FormUI->new()->initialize($SURVEY_FORM)->show;

print(
  qq{The following data was returned:\n},
  Data::Dumper->Dump([$data,], [qw( data)]),
  qq{\n},
  );

__END__