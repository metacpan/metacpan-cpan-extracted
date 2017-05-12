# Attributes.pm - attribute class for Perl PVCS module
#
# Copyright (c) 1998  Bill Middleton
#
#

=head1 NAME

VCS::PVCS::Attributes - Attributes class for for VCS::PVCS

=head1 SYNOPSIS

  use VCS::PVCS::Project;

  $proj = new VCS::PVCS::Project("ProjectName");

  $members = $proj->members(".*");

  foreach $f (@$members){
    $attrs = $f->getAttributes();
    print $attrs->Archive; # Archive name
    print $attrs->Workfile; # Workfile name
    print $attrs->Owner; # Owner of archive
    print $attrs->Archive_created; # Date archive created
    print $attrs->Last_trunk_rev; # Most recent trunk rev
    print $attrs->Locks; # current locks on all versions
    print $attrs->Groups; # current groups assoc with this archive
    print $attrs->Rev_count; # number of revisions
    print $attrs->Attributes; # attributes
    print $attrs->Version_labels; # version labels on this archive
    print $attrs->Description;  # checkin description
    print $attrs->history;      # history and comments

  }

=head1 DESCRIPTION

This class is intended for use as an companion to the
VCS::PVCS::* classes.  The Archive objects inherits Attribute 
methods, and augment them.

=head1 METHODS

=over 5

=item B<getAttributes>

  print $attrs->getAttributes(1);

repopulate the attibutes object 

=item B<Archive>

  print $attrs->Archive; # Archive name

=item B<Workfile

  print $attrs->Workfile; # Workfile name

=item B<Owner

  print $attrs->Owner; # Owner of archive

=item B<Archive_created

  print $attrs->Archive_created; # Date archive created

=item B<Last_trunk_rev

  print $attrs->Last_trunk_rev; # Most recent trunk rev

=item B<Locks

  print $attrs->Locks; # current locks on all versions

=item B<Groups

  print $attrs->Groups; # current groups assoc with this archive

=item B<Rev_count

  print $attrs->Rev_count; # number of revisions

=item B<Attributes

  print $attrs->Attributes; # attributes

=item B<Version_labels

  print $attrs->Version_labels; # version labels on this archive

=item B<Description

  print $attrs->Description;  # checkin description

=item B<history

  print $attrs->history;      # history and comments

=back

=head1 COPYRIGHT

The PVCS module is Copyright (c) 1998 Bill Middleton.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 AUTHOR

Bill Middleton, wjm@metronet.com

=head1 SUPPORT / WARRANTY

The VCS::PVCS modules are free software.

B<THEY COME WITHOUT WARRANTY OF ANY KIND.>

Commercial support agreements for Perl can be arranged via
The Perl Clinic. See http://www.perl.co.uk/tpc for more details.

=head1 SEE ALSO

VCS::PVCS::Project

=cut


package VCS::PVCS::Attributes;
use strict;
use Carp;
require Exporter;
use VCS::PVCS;
use vars qw($VERSION %EXPORT_TAGS @EXPORT_OK @ISA $AUTOLOAD);
$VERSION = "0.01";
@ISA = qw(Exporter );

sub getAttributes{
my($self) = shift;
my($arpath) = $self->archive();
my($attrs) = {};
my($force) = shift;

($^O ne "MSWin32") and translatePath2Unix(\$arpath);

if((ref($self->{'Attributes'}) !~ /VCS::PVCS::Attributes/) or $force){
    VCS::PVCS::Commands::vlog("-I -Q", $arpath);
}
else{
    return $self->{'Attributes'};
}

if($PVCSERR){
    warn $PVCSOUTPUT;
    $PVCSOUTPUT = "";
    return undef;
}

my(@log)= split(/-----------------------------------/,$PVCSOUTPUT);

$log[0] =~ m/Archive:\s*(.*)[\r?\n]Workfile:\s*(.*)[\r?\n]Archive created:\s*(.*)[\r?\n]Owner:\s*(.*)[\r?\n]Last trunk rev:\s*(.*)[\r?\n]Locks:\s*(.*)[\r?\n]Groups:\s*(.*)[\r?\n]Rev count:\s*(.*)[\r?\n]Attributes:\s*(.*)[\r?\n]Version labels:\s*(.*)[\r?\n]Description:\s*(.*)[\r?\n]/s;

$attrs = {
"Archive" => $1,
"Workfile" => $2,
"Archive_created" => $3,
"Owner" => $4, 
"Last_trunk_rev" => $5,
"Locks" => $6,
"Groups" => $7,
"Rev_count" => $8,
"Attributes" => $9,
"Version_labels" => $10,
"Description" => $11
};

#for($i=1;$i<$#log;$i++){
#$log[$i] =~ m/Rev\s+(\d+\.\d+)[\r?\n]Checked in:\s+(.*)[\r?\n]Last modified:\s+(.*)[\r?\n]Author id:\s+(.*)\s+lines deleted\/added\/moved:\s+(\d+\/\d+\/\d+)\s*[\r?\n](.*)/s;
#print "$1 $2 $3 $4 $5 $6\n"
#}

$attrs->{'History'} = join('-' x 35,@log[1 .. $#log]);

bless($attrs,"VCS::PVCS::Attributes");
$self->{'Attributes'} = $attrs;
$PVCSOUTPUT = "";
return $attrs;
}

sub AUTOLOAD{
my($self) = shift;
return undef unless ref($self);
my($method) = $AUTOLOAD;

$method =~ s/.*:://;

if(defined $self->{$method}){
    return $self->{$method};
}

}

1;
__END__
