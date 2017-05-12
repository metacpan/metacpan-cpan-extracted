package WordPress::Base::Date;
use strict;
use Exporter;
use vars qw(@ISA @EXPORT $VERSION);
@EXPORT = ('dateCreated');
@ISA = qw/Exporter/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /(\d+)/g;
#use Smart::Comments '###';
no warnings 'redefine';

sub dateCreated {
   my($self,$val) = @_;
   ### DATE
   if(defined $val){
      ### $val

      # is it a valid date?
      require Date::Manip;  
      my $date = Date::Manip::ParseDate($val) 
            or croak("dateCreated value $val is not a valid date");
      
      ### $date

      my $wpdate = 
         Date::Manip::UnixDate($date,"%Y%m%dT%H:%M:%S");
      
      ### $wpdate

      $self->structure_data->{dateCreated} = $wpdate;

      # TODO maybe we should clear date_created_gmt, since server will set that for us?
      $self->structure_data->{date_created_gmt} = undef;
   }

   return $self->structure_data->{dateCreated};
}

1;


__END__


=pod

=head1 NAME

WordPress::Base::Date

=head1 DESCRIPTION

Wordpress dates are tricky.
This uses Date::Manip to allow dateCreated() method to be validated before accepting. 
This method is present in WordPress::API::Post and WordPress::API::Page.


=head1 SEE ALSO

Date::Manip
WordPress::API
WordPress::API::Page
WordPress::API::Post

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

