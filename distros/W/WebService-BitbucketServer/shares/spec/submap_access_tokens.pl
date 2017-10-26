# Map endpoints to subroutine names in AccessTokens::V1.
use strict;
{
    'access-tokens/1.0/users/{userSlug} GET' => 'get_tokens',
    'access-tokens/1.0/users/{userSlug} PUT' => 'create_token',
    'access-tokens/1.0/users/{userSlug}/{tokenId} DELETE' => 'delete_token',
    'access-tokens/1.0/users/{userSlug}/{tokenId} GET' => 'get_token',
    'access-tokens/1.0/users/{userSlug}/{tokenId} POST' => 'update_token',
};
