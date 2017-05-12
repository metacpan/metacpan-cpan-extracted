package WebService::Toggl::API::User;

use Sub::Quote qw(quote_sub);
use WebService::Toggl::Role::Item as => 'JsonItem';

use Moo;
with 'WebService::Toggl::Role::API';
use namespace::clean;

with JsonItem(
    bools => [ qw(
        share_experiment send_timer_notifications show_offer
        timeline_enabled sidebar_piechart manual_mode
        used_next send_weekly_report timeline_experiment
        store_start_and_stop_time send_product_emails
        should_upgrade record_timeline openid_enabled
        render_timeline case_studies_experiment achievements_enabled
    ) ],

    strings => [ qw(
        openid_email jquery_timeofday_format fullname
        timeofday_format last_blog_entry timezone duration_format
        image_url created_at email api_token jquery_date_format
        language date_format at
    ) ],

    integers => [ qw(default_wid retention beginning_of_week id) ]
);

has $_ => (is => 'ro', lazy => 1, builder => quote_sub(qq| \$_[0]->raw->{$_} |))
    for (qw(new_blog_post invitation achievements));


sub api_path { 'users' }
sub api_id   { shift->id }


sub time_entries { $_[0]->new_set_from_raw('::TimeEntries', $_[0]->raw->{time_entries}) }
sub projects     { $_[0]->new_set_from_raw('::Projects',    $_[0]->raw->{projects})     }
sub tags         { $_[0]->new_set_from_raw('::Tags',        ($_[0]->raw->{tags} || [])) }
sub workspaces   { $_[0]->new_set_from_raw('::Workspaces',  $_[0]->raw->{workspaces})   }
sub clients      { $_[0]->new_set_from_raw('::Clients',     $_[0]->raw->{clients} || [])      }


1;
__END__

"invitation" : {},

"achievements" : [
   2,
   10,
   11,
   12
],

"new_blog_post" : {
   "pub_date" : "2014-06-17T10:07:45Z",
   "url" : "http://blog.toggl.com/2014/06/top-3-time-management-mistakes-identified-togglers/?utm_source=rss&utm_medium=rss&utm_campaign=top-3-time-management-mistakes-identified-togglers",
   "title" : "Top 3 Time Management Mistakes Identified By Togglers",
   "category" : "Uncategorized"
},
