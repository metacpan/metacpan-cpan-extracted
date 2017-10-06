package WebService::Qiita::V2::Client::Methods;
use strict;
use warnings;
use parent 'WebService::Qiita::V2::Client::Base';

# https://qiita.com/api/v2/docs#get-apiv2oauthauthorize
sub authorize {
    my ($self, $params, $args) = @_;
    $self->get("oauth/authorize", $params, $args);
}

# https://qiita.com/api/v2/docs#post-apiv2access_tokens
sub create_access_token {
    my ($self, $params, $args) = @_;
    $self->post("access_tokens", $params, $args);
}

# https://qiita.com/api/v2/docs#delete-apiv2access_tokensaccess_token
sub delete_access_token {
    my ($self, $token, $args) = @_;
    $self->delete("access_tokens/$token", undef, $args);
}

# https://qiita.com/api/v2/docs#delete-apiv2commentscomment_id
sub delete_comment {
    my ($self, $comment_id, $args) = @_;
    $self->delete("comments/$comment_id", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2commentscomment_id
sub get_comment {
    my ($self, $comment_id, $args) = @_;
    $self->get("comments/$comment_id", undef, $args);
}

# https://qiita.com/api/v2/docs#patch-apiv2commentscomment_id
sub update_comment {
    my ($self, $comment_id, $comment, $args) = @_;
    $self->patch("comments/$comment_id", { body => $comment }, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2itemsitem_idcomments
sub get_item_comments {
    my ($self, $item_id, $args) = @_;
    $self->get("items/$item_id/comments", undef, $args);
}

# https://qiita.com/api/v2/docs#post-apiv2itemsitem_idcomments
sub add_comment {
    my ($self, $item_id, $comment, $args) = @_;
    $self->post("items/$item_id/comments", { body => $comment }, $args);
}

# https://qiita.com/api/v2/docs#post-apiv2itemsitem_idtaggings
sub add_tag {
    my ($self, $item_id, $params, $args) = @_;
    $self->post("items/$item_id/taggings", $params, $args);
}

# https://qiita.com/api/v2/docs#delete-apiv2itemsitem_idtaggingstagging_id
sub delete_tag {
    my ($self, $item_id, $tagging_id, $args) = @_;
    $self->delete("items/$item_id/taggings/$tagging_id", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2tags
sub get_tags {
    my ($self, $params, $args) = @_;
    $self->get("tags", $params, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2tagstag_id
sub get_tag {
    my ($self, $tag_id, $args) = @_;
    $self->get("tags/$tag_id", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2usersuser_idfollowing_tags
sub get_following_tags {
    my ($self, $user_id, $params, $args) = @_;
    $self->get("users/$user_id/following_tags", $params, $args);
}

# https://qiita.com/api/v2/docs#delete-apiv2tagstag_idfollowing
sub unfollow_tag {
    my ($self, $tag_id, $args) = @_;
    $self->delete("tags/$tag_id/following", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2tagstag_idfollowing
sub is_tag_following {
    my ($self, $tag_id, $args) = @_;
    my $code = $self->get_response_code("tags/$tag_id/following", undef, $args);
    return $code == 204 ? 1 : 0;
}

# https://qiita.com/api/v2/docs#put-apiv2tagstag_idfollowing
sub follow_tag {
    my ($self, $tag_id, $args) = @_;
    $self->put("tags/$tag_id/following", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2teams
sub get_teams {
    my ($self, $args) = @_;
    $self->get("teams", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2templates
sub get_templates {
    my ($self, $params, $args) = @_;
    $self->get("templates", $params, $args);
}

# https://qiita.com/api/v2/docs#delete-apiv2templatestemplate_id
sub delete_template {
    my ($self, $template_id, $args) = @_;
    $self->delete("templates/$template_id", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2templatestemplate_id
sub get_template {
    my ($self, $template_id, $args) = @_;
    $self->get("templates/$template_id", undef, $args);
}

# https://qiita.com/api/v2/docs#post-apiv2templates
sub add_template {
    my ($self, $params, $args) = @_;
    $self->post("templates", $params, $args);
}

# https://qiita.com/api/v2/docs#patch-apiv2templatestemplate_id
sub update_template {
    my ($self, $template_id, $params, $args) = @_;
    $self->patch("templates/$template_id", $params, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2projects
sub get_projects {
    my ($self, $params, $args) = @_;
    $self->get("projects", $params, $args);
}

# https://qiita.com/api/v2/docs#post-apiv2projects
sub add_project {
    my ($self, $params, $args) = @_;
    $self->post("projects", $params, $args);
}

# https://qiita.com/api/v2/docs#delete-apiv2projectsproject_id
sub delete_project {
    my ($self, $project_id, $args) = @_;
    $self->delete("projects/$project_id", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2projectsproject_id
sub get_project {
    my ($self, $project_id, $args) = @_;
    $self->get("projects/$project_id", undef, $args);
}

# https://qiita.com/api/v2/docs#patch-apiv2projectsproject_id
sub update_project {
    my ($self, $project_id, $params, $args) = @_;
    $self->patch("projects/$project_id", $params, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2itemsitem_idstockers
sub get_item_stockers {
    my ($self, $item_id, $params, $args) = @_;
    $self->get("items/$item_id/stockers", $params, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2users
sub get_users {
    my ($self, $params, $args) = @_;
    $self->get("users", $params, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2usersuser_id
sub get_user {
    my ($self, $user_id, $args) = @_;
    $self->get("users/$user_id", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2usersuser_idfollowees
sub get_followees {
    my ($self, $user_id, $params, $args) = @_;
    $self->get("users/$user_id/followees", $params, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2usersuser_idfollowers
sub get_followers {
    my ($self, $user_id, $params, $args) = @_;
    $self->get("users/$user_id/followers", $params, $args);
}

# https://qiita.com/api/v2/docs#delete-apiv2usersuser_idfollowing
sub unfollow_user {
    my ($self, $user_id, $args) = @_;
    $self->delete("users/$user_id/following", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2usersuser_idfollowing
sub is_user_following {
    my ($self, $user_id, $args) = @_;
    my $code = $self->get_response_code("users/$user_id/following", undef, $args);
    return $code == 204 ? 1 : 0;
}

# https://qiita.com/api/v2/docs#put-apiv2usersuser_idfollowing
sub follow_user {
    my ($self, $user_id, $args) = @_;
    $self->put("users/$user_id/following", undef, $args);
}

# https://qiita.com/api/v2/docs#post-apiv2expanded_templates
sub expanded_templates {
    my ($self, $params, $args) = @_;
    $self->post("expanded_templates", $params, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2authenticated_useritems
sub get_authenticated_user_items {
    my ($self, $params, $args) = @_;
    $self->get("authenticated_user/items", $params, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2items
sub get_items {
    my ($self, $params, $args) = @_;
    $self->get("items", $params, $args);
}

# https://qiita.com/api/v2/docs#post-apiv2items
sub add_item {
    my ($self, $params, $args) = @_;
    $self->post("items", $params, $args);
}

# https://qiita.com/api/v2/docs#delete-apiv2itemsitem_id
sub delete_item {
    my ($self, $item_id, $args) = @_;
    $self->delete("items/$item_id", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2itemsitem_id
sub get_item {
    my ($self, $item_id, $args) = @_;
    $self->get("items/$item_id", undef, $args);
}

# https://qiita.com/api/v2/docs#patch-apiv2itemsitem_id
sub update_item {
    my ($self, $item_id, $params, $args) = @_;
    $self->patch("items/$item_id", $params, $args);
}

# https://qiita.com/api/v2/docs#put-apiv2itemsitem_idstock
sub stock {
    my ($self, $item_id, $args) = @_;
    $self->put("items/$item_id/stock", undef, $args);
}

# https://qiita.com/api/v2/docs#delete-apiv2itemsitem_idstock
sub unstock {
    my ($self, $item_id, $args) = @_;
    $self->delete("items/$item_id/stock", undef, $args);
}
# https://qiita.com/api/v2/docs#get-apiv2itemsitem_idstock
sub is_stock {
    my ($self, $item_id, $args) = @_;
    my $code = $self->get_response_code("items/$item_id/stock", undef, $args);
    return $code == 204 ? 1 : 0;
}

# https://qiita.com/api/v2/docs#get-apiv2tagstag_iditems
sub get_tagged_items {
    my ($self, $tag_id, $params, $args) = @_;
    $self->get("tags/$tag_id/items", $params, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2usersuser_iditems
sub get_user_items {
    my ($self, $user_id, $params, $args) = @_;
    $self->get("users/$user_id/items", $params, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2usersuser_idstocks
sub get_user_stocks {
    my ($self, $user_id, $params, $args) = @_;
    $self->get("users/$user_id/stocks", $params, $args);
}

# https://qiita.com/api/v2/docs#post-apiv2commentscomment_idreactions
sub add_reaction_to_comment {
    my ($self, $comment_id, $params, $args) = @_;
    $self->post("comments/$comment_id/reactions", $params, $args);
}

# https://qiita.com/api/v2/docs#post-apiv2itemsitem_idreactions
sub add_reaction_to_item {
    my ($self, $item_id, $params, $args) = @_;
    $self->post("items/$item_id/reactions", $params, $args);
}

# https://qiita.com/api/v2/docs#post-apiv2projectsproject_idreactions
sub add_reaction_to_project {
    my ($self, $project_id, $params, $args) = @_;
    $self->post("projects/$project_id/reactions", $params, $args);
}

# https://qiita.com/api/v2/docs#delete-apiv2commentscomment_idreactionsreaction_name
sub remove_reaction_from_comment {
    my ($self, $comment_id, $reaction_name, $args) = @_;
    $self->delete("comments/$comment_id/reactions/$reaction_name", undef, $args);
}

# https://qiita.com/api/v2/docs#delete-apiv2itemsitem_idreactionsreaction_name
sub remove_reaction_from_item {
    my ($self, $item_id, $reaction_name, $args) = @_;
    $self->delete("items/$item_id/reactions/$reaction_name", undef, $args);
}

# https://qiita.com/api/v2/docs#delete-apiv2projectsproject_idreactionsreaction_name
sub remove_reaction_from_project {
    my ($self, $project_id, $reaction_name, $args) = @_;
    $self->delete("projects/$project_id/reactions/$reaction_name", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2commentscomment_idreactions
sub get_reactions_of_comment {
    my ($self, $comment_id, $args) = @_;
    $self->get("comments/$comment_id/reactions", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2itemsitem_idreactions
sub get_reactions_of_item {
    my ($self, $item_id, $args) = @_;
    $self->get("items/$item_id/reactions", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2projectsproject_idreactions
sub get_reactions_of_project {
    my ($self, $project_id, $args) = @_;
    $self->get("projects/$project_id/reactions", undef, $args);
}

# https://qiita.com/api/v2/docs#get-apiv2authenticated_user
sub get_authenticated_user {
    my ($self, $args) = @_;
    $self->get("authenticated_user", undef, $args);
}

1;
