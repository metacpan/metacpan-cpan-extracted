package XML::MinWriter;
$XML::MinWriter::VERSION = '0.08';
use strict;
use warnings;

use Carp;

require Exporter;
use XML::Writer;

our @ISA = qw(Exporter XML::Writer);

our @EXPORT_OK = qw();

our @EXPORT = qw();

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{PYX_TYPE} = '';
    $self->{PYX_TAG}  = '';
    $self->{PYX_ATTR} = [];

    bless $self, $class; # reconsecrate
}

sub xmlDecl     { my $self = shift; $self->flush_pyx; $self->SUPER::xmlDecl(@_);     }
sub doctype     { my $self = shift; $self->flush_pyx; $self->SUPER::doctype(@_);     }
sub comment     { my $self = shift; $self->flush_pyx; $self->SUPER::comment(@_);     }
sub pi          { my $self = shift; $self->flush_pyx; $self->SUPER::pi(@_);          }
sub startTag    { my $self = shift; $self->flush_pyx; $self->SUPER::startTag(@_);    }
sub emptyTag    { my $self = shift; $self->flush_pyx; $self->SUPER::emptyTag(@_);    }
sub endTag      { my $self = shift; $self->flush_pyx; $self->SUPER::endTag(@_);      }
sub characters  { my $self = shift; $self->flush_pyx; $self->SUPER::characters(@_);  }
sub raw         { my $self = shift; $self->flush_pyx; $self->SUPER::raw(@_);         }
sub cdata       { my $self = shift; $self->flush_pyx; $self->SUPER::cdata(@_);       }
sub dataElement { my $self = shift; $self->flush_pyx; $self->SUPER::dataElement(@_); }
sub end         { my $self = shift; $self->flush_pyx; $self->SUPER::end(@_);         }

sub write_pyx {
    my $self = shift;

    my @inlist;
    for (@_) {
        push @inlist, split m{\n}xms;
    }

    LOOP1: for my $instr (@inlist) {
        if ($instr eq '') {
            next LOOP1;
        }

        my $code = substr($instr, 0, 1);
        my $text = substr($instr, 1);

        $text =~ s{\\(.)}{
          $1 eq '\\' ? "\\" :
          $1 eq 'n'  ? "\n" :
          $1 eq 't'  ? "\t" :
          "\\".$1}xmsge;

        if ($code eq '(') {
            $self->flush_pyx;
            $self->{PYX_TYPE} = '(';
            $self->{PYX_TAG}  = $text;
            $self->{PYX_ATTR} = [];
        }
        elsif ($code eq 'A') {
            my ($key, $val) = $text =~ m{\A (\S+) \s+ (.*) \z}xms;
            unless (defined($key) and defined($val)) {
                carp "Can't parse (key, val) [code = 'A'] in '$text' in write_pyx()";
                next LOOP1;
            }
            push @{$self->{PYX_ATTR}}, $key, $val;
        }
        elsif ($code eq '?') {
            my ($intro, $def) = $text =~ m{\A (\S+) \s+ (.*) \z}xms;
            unless (defined($intro) and defined($def)) {
                carp "Can't parse (intro, def) [code = '?'] in '$text' in write_pyx()";
                next LOOP1;
            }

            if ($intro =~ m{\A xml}xmsi and $intro !~ m{\A xml-stylesheet \z}xmsi) {
                my ($version, $encoding, $standalone);
                my $data = $def;
                while (my ($key, $val, $rest) = $data =~ m{\A (\S+) \s* = \s* ["']([^"']+)["'] \s* (.*) \z}xms) {
                    if    ($key =~ m{\A version    \z}xmsi) { $version    = $val; }
                    elsif ($key =~ m{\A encoding   \z}xmsi) { $encoding   = $val; }
                    elsif ($key =~ m{\A standalone \z}xmsi) { $standalone = $val; }
                    else {
                        carp "Found invalid XML-Declaration (key = '$key') in (intro = '$intro', def = '$def') in write_pyx()";
                        next LOOP1;
                    }
                    unless (defined $version) { $version = '1.0'; }
                    unless ($version eq '1.0') {
                        carp "Found version other than 1.0 ('$version') in (intro = '$intro', def = '$def') in write_pyx()";
                        next LOOP1;
                    }
                    $data = $rest;
                }
                $self->xmlDecl($encoding, $standalone);
            }
            else {
                $self->pi($intro, $def);
            }
        }
        elsif ($code eq '!') {
            my ($intro, $def) = $text =~ m{\A (\S+) \s+ (.*) \z}xms;
            unless (defined($intro) and defined($def)) {
                carp "Can't parse (intro, def) [code = '!'] in '$text' in write_pyx()";
                next LOOP1;
            }

            if ($def =~ m{\A PUBLIC}xmsi) {
                my ($public, $system) = $def =~ m{\A PUBLIC \s+ ["']([^"']+)["'] \s+ ["']([^"']+)["'] \s* \z}xmsi;
                unless (defined($public) and defined($system)) {
                    carp "Can't parse DOCTYPE PUBLIC in (intro = '$intro', def = '$def') in write_pyx()";
                    next LOOP1;
                }
                $self->doctype($intro, $public, $system);
            }
            elsif ($def =~ m{\A SYSTEM}xmsi) {
                my ($system) = $def =~ m{\A SYSTEM \s+ ["']([^"']+)["'] \s* \z}xmsi;
                unless (defined($system)) {
                    carp "Can't parse DOCTYPE SYSTEM in (intro = '$intro', def = '$def') in write_pyx()";
                    next LOOP1;
                }
                $self->doctype($intro, undef, $system);
            }
            else {
                carp "Can't find neither PUBLIC nor SYSTEM in DOCTYPE (intro = '$intro', def = '$def') in write_pyx()";
                next LOOP1;
            }
        }
        elsif ($code eq ')') { $self->endTag($text);     }
        elsif ($code eq '-') { $self->characters($text); }
        elsif ($code eq '#') { $self->comment($text);    }
        else {
            carp "Invalid code = '$code' in write_pyx()";
            next LOOP1;
        }
    }
}

sub flush_pyx {
    my $self = shift;

    if ($self->{PYX_TYPE} eq '(') {
        $self->SUPER::startTag($self->{PYX_TAG}, @{$self->{PYX_ATTR}});
    }

    $self->{PYX_TYPE}    = '';
    $self->{PYX_TAG}     = '';
    $self->{PYX_ATTR}    = [];
}

1;

__END__

=head1 NAME

XML::MinWriter - Perl extension for writing XML in PYX format.

=head1 SYNOPSIS

Here is a simple example of how to use XML::MinWriter:

  use XML::MinWriter;

  open my $fh, '>', \my $xml or die $!;
  my $wrt = XML::MinWriter->new(OUTPUT => $fh, DATA_MODE => 1, DATA_INDENT => 2);

  $wrt->xmlDecl('iso-8859-1');
  $wrt->startTag('alpha');
  $wrt->startTag('beta', p1 => 'dat1', p2 => 'dat2');
  $wrt->characters('abcdefg');
  $wrt->endTag('beta');
  $wrt->write_pyx('(gamma');
  $wrt->write_pyx('-hijklmn');
  $wrt->write_pyx(')gamma');
  $wrt->endTag('alpha');

  $wrt->end;
  close $fh;

  print "The XML generated is as follows:\n\n";
  print $xml, "\n";

...and this is the output:

  <?xml version="1.0" encoding="iso-8859-1"?>
  <alpha>
    <beta p1="dat1" p2="dat2">abcdefg</beta>
    <gamma>hijklmn</gamma>
  </alpha>

=head1 DESCRIPTION

=head2 Introduction

XML::MinWriter is a module to write XML in PYX Format. It inherits from XML::Writer and adds a new
method C<write_pyx>. Modules XML::TiePYX and XML::Reader produce PYX which can then be fed into
XML::MinWriter to generate XML using the write_pyx() method.

=head2 Pyx

Pyx is a line-oriented text format to represent XML. The first character of a line in Pyx represents the
type. This first character type can be:

  '(' => a Start tag,          '(item'             translates into '<item>'
  ')' => an End  tag,          ')item'             translates into '</item>'
  '-' => Character data,       '-data'             translates into 'data'
  'A' => Attributes,           'Aattr v1'          translates into '<... attr="v1">'
  '?' => Process Instructions, '?xml dat="p1"'     translates into '<?xml dat="p1"?>'
  '#' => Comments,             '#remark'           translates into '<!-- remark -->'
  '!' => Doctype,              '!tag SYSTEM "abc"' translates into '<!DOCTYPE tag SYSTEM "abc">'

=head2 Example using Pyx

For example the following PYX code:

  use XML::MinWriter;

  open my $fh, '>', \my $xml or die $!;
  my $wrt = XML::MinWriter->new(OUTPUT => $fh, DATA_MODE => 1, DATA_INDENT => 2);

  $wrt->write_pyx('?xml version="1.0" encoding="iso-8859-1"');
  $wrt->write_pyx('(data');
  $wrt->write_pyx('(item');
  $wrt->write_pyx('Aattr1 p1');
  $wrt->write_pyx('Aattr2 p2');
  $wrt->write_pyx('-line');
  $wrt->write_pyx(')item');
  $wrt->write_pyx('(level');
  $wrt->write_pyx('#remark');
  $wrt->write_pyx(')level');
  $wrt->write_pyx(')data');

  $wrt->end;
  close $fh;

  print "The XML generated is as follows:\n\n";
  print $xml, "\n";

...generates the following XML:

  <?xml version="1.0" encoding="iso-8859-1"?>
  <data>
    <item attr1="p1" attr2="p2">line</item>
    <level>
      <!-- remark -->
    </level>
  </data>

=head2 Example using XML::Reader

A sample code fragment that uses XML::Reader together with XML::MinWriter:

  use XML::Reader;
  use XML::MinWriter;

  my $line = q{
  <data>
    <order>
      <database>
        <customer name="aaa" >one</customer>
        <customer name="bbb" >two</customer>
        <other>iuertyieruyt</other>
        <customer name="ccc" >three</customer>
        <customer name="ddd" >four</customer>
      </database>
    </order>
  </data>
  };

  my $rdr = XML::Reader->new(\$line, {
              using => '/data/order/database/customer',
              mode  => 'pyx',
            });

  open my $fh, '>', \my $xml or die "Error-0010: Can't open > xml because $!";
  my $wrt = XML::MinWriter->new(OUTPUT => $fh, DATA_MODE => 1, DATA_INDENT => 2);

  $wrt->xmlDecl('iso-8859-1');
  $wrt->doctype('delta', 'public', 'system');
  $wrt->startTag('delta');

  while ($rdr->iterate) {
      $wrt->write_pyx($rdr->pyx);
  }

  $wrt->endTag('delta');
  $wrt->end;

  close $fh;

  print $xml, "\n";

This is the resulting XML:

  <?xml version="1.0" encoding="iso-8859-1"?>
  <!DOCTYPE delta PUBLIC "public" "system">
  <delta>
    <customer name="aaa">one</customer>
    <customer name="bbb">two</customer>
    <customer name="ccc">three</customer>
    <customer name="ddd">four</customer>
  </delta>

=head1 AUTHOR

Klaus Eichner, October 2011

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Klaus Eichner

XML::MinWriter is free software; you can redistribute and/or modify XML::MinWriter
under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::TiePYX>,
L<XML::Reader>,
L<XML::Writer>.

=cut
