package fake_response;
use strict;

my $internal_content_list = [
    { title => 'test 1', form_fields => '<input type="hidden" name="foo_hid" value="sneaky"/>' },
    { title => 'test 2', form_fields => '<select name="select_foo"><option value="aaa">aaa</option><option value="bbb" selected="selected">BBB</option></select>' },
    ];

sub new {
    return bless({ content => shift @$internal_content_list }, shift);
}

sub next_response {
    my $self = shift;
    $self->{content} = shift @$internal_content_list;
}

sub content {
    my $content = shift->{content};
    return '<html><head><title>'.$content->{title}.'</title></head><body><h1>'.$content->{title}.'</h1><form name="foo">'.$content->{form_fields}.'</form></body></html>';
}

sub decoded_content {
    return content();
}

1;
