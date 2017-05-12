package Util::Properties;

#use warnings;
use strict;
use Carp qw(croak carp confess cluck);

=head1 NAME

Util::Properties - Java.util.properties like class

=head1 DESCRIPTION

rimplement something like ava.util.Properties API.

The main differences with CPAN existant Config::Properties and Data::Properties is file locking & autoload/autosave features


=cut

our $VERSION = '0.18';

=head1 SYNOPSIS

=begin text

use Util::Properties;

my $prop = Util::Properties->new({file=>'file.properties'});
my $xyz=$prop->prop_get('x.y.z');
$prop->prop_set('w', -1);
$prop->save();

=end text

=head1 FUNCTIONS

=head1 METHODS

=head2 Creators

=head3 my $prop=Util::Properties->new()

=head3 my $prop=Util::Properties->new(filename)

=head3 my $prop=Util::Properties->new(\%h)

=head3 my $prop=Util::Properties->new(\$Util::Properties)

Create a new prop system from either:

=over 4

=item empty

=item filename

=item hash ref (key=>values will be taken as property name/value)

=item a copy constructor from another Util::Properties object;

=back

=head2 Accessors/Mutators

=head3 $prop->name([$val])

Get/set a name for the set of prperty (mainly used for debugging or code clarity purpose

=head3 $prop->file_ismirrored([val])

Get/set (set if an argument is passed) a boolean value to determine if the file is to be file with property (if any is defined) is to be kept coherent with the data. This mean that any set of property will be mirrored on the file, and before any get, the file time stamp will be check to see if the data has changed into the file.

=head3 $prop->file_name([path])

Get/set the filename

=head3 $prop->file_md5([hexval])

Get/set the md5 of the file

=head3 $prop->file_locker(bool|\$LockFile::Simple);

Set if  a file locker is to be used (or a file locker is you do not wish to use the default). A die will be thrown if locking fails

=head3 $prop->file_locker();

Get the file locker (or undef).

=head3 $prop->file_isghost([val])

get/set is it is possible for the file not to exist (in this case, no problem not to save...)

=head2 Properties values

=head3 $prop->prop_get(key)

get property defined by key;

=head3 $prop->prop_set(key, value)

Set a property

=head3 $prop->prop_list

return a hash with all the properties

=head3 $prop->prop_clean

Clean the properties list;

=head3 $prop->isEmpty();

return true if the properties does not contain any fields

=head2 I/O

=head3 $prop->load()

load properties from $prop->file_name

=head3 $prop->save()

Save properties from $prop->file_name (comment have been forgotten)

=head1 EXPORT

=head3 $DEFAULT_FILE_LOCKER

If a file_locker is to be defined by default creator [default is 1]

=head3 $DEFAULT_FILE_ISMIRRORED

If data in memory must be consistent with file (based on file maodification time)  [default is 1]

=head3 $VERBOSE

verbose level;

=head1 AUTHOR

Alexandre Masselot, C<< <alexandre.masselot@genebio.com> >>

=head1 TODO

=head3 implement a '+=' notation (to have mult lines defined properties)

=begin text

prop.one=some
prop.one+=thing

=end text

=head3 implement a dependencies between properties

=begin text

prop.one=something
prop.two=other/${prop.one}-thing

=end text


=head1 BUGS

Please report any bugs or feature requests to
C<bug-util-properties@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Util-Properties>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Alexandre Masselot, all rights reserved.

This program is released under the following license: gpl

=cut

our $DEFAULT_FILE_LOCKER=1;
our $DEFAULT_FILE_ISMIRRORED=1;
our $VERBOSE=0;

use Object::InsideOut 'Exporter';
BEGIN{
  our @EXPORT = qw( &getUserList &getCGIUser );
  our @EXPORT_OK = ();
}

my @_file_locker :Field(Accessor => '_file_locker', 'Type' => 'LockFile::Simple', Permission => 'private');
my @_file_md5 :Field(Accessor => '_file_md5', Permission => 'private');
my @file_ismirrored :Field(Accessor => 'file_ismirrored' );
my @file_isghost :Field(Accessor => 'file_isghost');
my @file_name :Field(Accessor => 'file_name');
my @name :Field(Accessor => 'name' );
my @_properties :Field( Accessor => '_properties', Permission => 'private');

my %init_args :InitArgs = (
			   PROPERTIES=>qr/^prop(erties)?$/i,
			   COPY=>qr/^co?py?$/i,
			   FILE=>qr/^file$/i,
			   NEWFILE=>qr/^newfile$/i,
			  );
sub _init :Init{
  my ($self, $h) = @_;

  if(ref($h)eq 'HASH'){
    if ($h->{PROPERTIES}){    #just a set of properties
      $self->prop_clean;
      foreach (keys %{$h->{PROPERTIES}}){
	$self->prop_set($_, $h->{PROPERTIES}{$_});
      }
      $self->file_locker($DEFAULT_FILE_LOCKER);
      $self->file_ismirrored($DEFAULT_FILE_ISMIRRORED);
    }elsif($h->{COPY}){
      my $src= $h->{COPY};
      #copy constructor
      $self->prop_clean;
      $self->_file_locker($src->_file_locker()) if $src->_file_locker();
      $self->file_ismirrored($src->file_ismirrored());
      $self->file_isghost($src->file_isghost());
      $self->file_name($src->file_name());
      $self->name($src->name());
      my %p=$src->prop_list;
      $self->prop_clean;
      while(my ($k, $v)=each %p){
	$self->prop_set($k, $v);
      }
    }elsif($h->{FILE}){
      #thus $h is a file name;
      $self->file_locker($DEFAULT_FILE_LOCKER);
      $self->file_ismirrored($DEFAULT_FILE_ISMIRRORED);
      $self->file_name($h->{FILE});
      unless($h->{NEWFILE} && ! -f $h->{FILE}){
	$self->load() ;
      }else{
	$self->_properties({});
      }
    }elsif(scalar (keys %$h)){
      croak "cannot instanciate constructor if hahs key is not of (properties|copy|file)";
    }else{
      $self->file_locker($DEFAULT_FILE_LOCKER);
      $self->file_ismirrored($DEFAULT_FILE_ISMIRRORED);
      $self->prop_clean;
    }
  }else{
    die "empty init :Init constructor";
  }

}


#our @attr=qw(name file_md5 file_name file_ismirrored file_isghost);
#our $attrStr=join '|', @attr;
#our $attrRE=qr/\b($attrStr)\b/;

#sub AUTOMETHOD{
#  my ($self, $obj_ID, $val)=@_;
#  my $set=exists $_[2];

#  my $name=$_;
#  return undef unless $name=~$attrRE;
#  return sub {
#    $objref{$obj_ID}{$name}=$val; return $val} if($set);
#  return sub {return $objref{$obj_ID}{$name}};
#}

sub DEMOLISH{
  my ($self, $obj_ID) = @_;
}

sub file_locker{
  my $self=shift;
  my $a0=shift;
#  my $self=$objref{ident($a0)};
  my $val=shift;

  return $self->_file_locker()  unless($val);

  if(ref($val) eq 'LockFile::Simple'){
    $self->_file_locker($val);
  }else{
    require LockFile::Simple;
    $self->_file_locker(
			LockFile::Simple->make(-format => '%f.lck',
					       -max => 20,
					       -delay => 1,
					       -nfs => 1,
					       -autoclean => 1
					      )
		       );
  }
  return $self->_file_locker();
}

############### properties

sub prop_set{
  local $_;
  my $self=shift;

  my ($k, $val)=@_;
  croak "must prop_set on a defined property key" unless $k;
  croak "cannot define a key=[$k]" if $k=~/[\s=]/;

  my $valOrig=$self->_properties()->{$k};
  $self->_properties()->{$k}=$val;
  if($self->file_ismirrored && $self->file_name && ($val ne $valOrig)){
    $self->save();
  }
}

sub prop_get{
  local $_;
  my $self=shift;

  my $k=shift or croak "must prop_get on a defined property key";
  if($self->file_ismirrored && $self->file_name && -f $self->file_name && ($self->_file_md5() ne file_md5_hex($self->file_name))){
    warn "loading from [".$self->file_name."] because of file modified for  [$k]\n" if $VERBOSE >=1;
    $self->load();
  }
  return $self->_properties()->{$k};
}

sub prop_list{
  my $self=shift;

  return %{$self->_properties()};
}

sub prop_clean{
  my $self=shift;

  $self->_properties({});
}

sub isEmpty{
  my $self=shift;
  my %h=$self->prop_list();
  return  scalar(keys %h)==0;
}


############### I/O

use Digest::MD5::File qw(file_md5_hex);

sub load{
  my $self=shift;


  my $fname=$self->file_name;
  Carp::confess "cannot read file [$fname]" unless -r $fname;

  eval{
    my $lockmgr=$self->_file_locker;
    $lockmgr->trylock("$fname") || croak "can't lock [$fname]: $!\n" if $lockmgr;
    open (FD, "<$fname") or die "cannot topen for reading [$fname]: $!";
    my @contents=<FD>;
    close FD;
    $self->_file_md5(file_md5_hex($fname));
    $lockmgr->unlock("$fname") || croak "can't unlock [$fname]: $!\n" if $lockmgr;

    $self->prop_clean;
    foreach(@contents){
      next if /^#/;
      next unless /^(\S+?)\s*=\s*(.*?)\s*$/;
      $self->_properties()->{$1}=$2;
    }
  };
  if($@){
    croak $@ unless $self->file_isghost;
  }
}

sub save{
  my $self=shift;

  my $fname=$self->file_name;

  warn "saving to [$fname]\n" if $VERBOSE >=2;
  croak "cannot save file on undefined file" unless defined $fname;

  my $contents;
  my %h=%{$self->_properties()};
  foreach (sort keys %h){
    $contents.="$_=$h{$_}\n";
  }

  my $lockmgr=$self->_file_locker;
  eval{
    $lockmgr->trylock("$fname") || croak "can't lock [$fname]: $!\n" if $lockmgr;
    open (FD, ">$fname") or die "cannot topen for writing [$fname]: $!";
    print FD $contents;
    close FD;
    $self->_file_md5(file_md5_hex($fname)) if $self->file_ismirrored;
    $lockmgr->unlock("$fname") || croak "can't unlock [$fname]: $!\n" if $lockmgr;
  };
  if($@){
    croak $@ unless $self->file_isghost;
  }
}

use overload '""' => \&toSummaryString;

sub toSummaryString{
  my $self=shift;

  my $ret="prop_name=".($self->name or 'NO_NAME')."\t".($self->file_name or '')."\n";
  my %h=$self->prop_list;
  foreach (sort keys %h){
    $ret.="\t$_\t$h{$_}\n";
  }
  return $ret;
}



return 1; # End of Util::Properties
