# XClient API Reference

Complete API reference for all endpoints and rate limits.

## Table of Contents

- [Tweets](#tweets)
- [Media](#media)
- [Users](#users)
- [Friendships](#friendships)
- [Favorites](#favorites)
- [Direct Messages](#direct-messages)
- [Search](#search)
- [Lists](#lists)
- [Account](#account)
- [Trends](#trends)
- [Geo](#geo)
- [Help](#help)
- [Application](#application)

---

## Tweets

### POST statuses/update
**Function:** `XClient.Tweets.update/3`  
**Rate Limit:** 300 per 3 hours (combined with retweet)

Post a new tweet.

**Parameters:**
- `status` (required) - Tweet text
- `in_reply_to_status_id` - ID of tweet to reply to
- `auto_populate_reply_metadata` - Auto-add @mentions
- `media_ids` - List of media IDs (max 4)
- `lat` / `long` - Geolocation coordinates
- `place_id` - Place ID
- And more...

### POST statuses/destroy/:id
**Function:** `XClient.Tweets.destroy/3`  
**Rate Limit:** No specific limit

Delete a tweet.

### POST statuses/retweet/:id
**Function:** `XClient.Tweets.retweet/3`  
**Rate Limit:** 300 per 3 hours (combined with update)

Retweet a tweet.

### POST statuses/unretweet/:id
**Function:** `XClient.Tweets.unretweet/3`  
**Rate Limit:** No specific limit

Remove a retweet.

### GET statuses/show/:id
**Function:** `XClient.Tweets.show/3`  
**Rate Limit:** 900 per 15 min (user), 900 per 15 min (app)

Get a single tweet by ID.

### POST statuses/lookup
**Function:** `XClient.Tweets.lookup/3`  
**Rate Limit:** 900 per 15 min (user), 300 per 15 min (app)

Get up to 100 tweets by IDs.

### GET statuses/user_timeline
**Function:** `XClient.Tweets.user_timeline/2`  
**Rate Limit:** 900 per 15 min (user), 1500 per 15 min (app)

Get a user's timeline.

**Parameters:**
- `user_id` or `screen_name` (required)
- `count` - Number of tweets (max 200)
- `since_id` - Return tweets after this ID
- `max_id` - Return tweets before this ID
- `exclude_replies` - Exclude replies
- `include_rts` - Include retweets

### GET statuses/mentions_timeline
**Function:** `XClient.Tweets.mentions_timeline/2`  
**Rate Limit:** 75 per 15 min (user only)

Get mentions of the authenticated user.

### GET statuses/retweets_of_me
**Function:** `XClient.Tweets.retweets_of_me/2`  
**Rate Limit:** 75 per 15 min (user only)

Get tweets that have been retweeted.

### GET statuses/retweets/:id
**Function:** `XClient.Tweets.retweets/3`  
**Rate Limit:** 75 per 15 min (user), 300 per 15 min (app)

Get up to 100 retweets of a tweet.

### GET statuses/retweeters/ids
**Function:** `XClient.Tweets.retweeters_ids/3`  
**Rate Limit:** 75 per 15 min (user), 300 per 15 min (app)

Get user IDs who retweeted a tweet.

---

## Media

### POST media/upload
**Function:** `XClient.Media.upload/3`  
**Rate Limit:** No specific limit

Upload media (images, videos, GIFs).

**Parameters:**
- `media` - File path or binary data (required)
- `media_type` - MIME type
- `media_category` - Category (tweet_image, tweet_video, etc.)
- `additional_owners` - User IDs who can use media
- `alt_text` - Accessibility text

**Size Limits:**
- Images: 5 MB
- GIFs: 15 MB
- Videos: 512 MB

### POST media/upload (chunked)
**Function:** `XClient.Media.chunked_upload/3`  
**Rate Limit:** No specific limit

Upload large media files in chunks.

### GET media/upload (STATUS)
**Function:** `XClient.Media.upload_status/2`  
**Rate Limit:** No specific limit

Check processing status of uploaded media.

### POST media/metadata/create
**Function:** `XClient.Media.add_metadata/3`  
**Rate Limit:** No specific limit

Add alt text to uploaded media.

---

## Users

### GET users/show
**Function:** `XClient.Users.show/2`  
**Rate Limit:** 900 per 15 min

Get information about a user.

**Parameters:**
- `user_id` or `screen_name` (required)
- `include_entities` - Include entities

### POST users/lookup
**Function:** `XClient.Users.lookup/2`  
**Rate Limit:** 900 per 15 min (user), 300 per 15 min (app)

Get up to 100 users.

**Parameters:**
- `user_id` or `screen_name` - List or comma-separated (required)
- `include_entities` - Include entities

### GET users/search
**Function:** `XClient.Users.search/3`  
**Rate Limit:** 900 per 15 min (user only)

Search for users.

**Parameters:**
- `q` - Search query (required)
- `page` - Page number
- `count` - Users per page (max 20)

### GET users/suggestions
**Function:** `XClient.Users.suggestions/2`  
**Rate Limit:** 15 per 15 min

Get suggested user categories.

### GET users/suggestions/:slug
**Function:** `XClient.Users.suggestions_slug/3`  
**Rate Limit:** 15 per 15 min

Get users in a suggested category.

### GET users/suggestions/:slug/members
**Function:** `XClient.Users.suggestions_members/2`  
**Rate Limit:** 15 per 15 min

Get members of a suggested category.

---

## Friendships

### POST friendships/create
**Function:** `XClient.Friendships.create/2`  
**Rate Limit:** 400 per 24 hours (user), 1000 per 24 hours (app)

Follow a user.

**Parameters:**
- `user_id` or `screen_name` (required)
- `follow` - Enable notifications

### POST friendships/destroy
**Function:** `XClient.Friendships.destroy/2`  
**Rate Limit:** No specific limit

Unfollow a user.

### GET friendships/show
**Function:** `XClient.Friendships.show/2`  
**Rate Limit:** 180 per 15 min (user), 15 per 15 min (app)

Get relationship between two users.

**Parameters:**
- Source user: `source_id` or `source_screen_name` (required)
- Target user: `target_id` or `target_screen_name` (required)

### GET followers/ids
**Function:** `XClient.Friendships.followers_ids/2`  
**Rate Limit:** 15 per 15 min

Get follower IDs.

**Parameters:**
- `user_id` or `screen_name`
- `cursor` - Pagination cursor
- `count` - IDs per page (max 5000)

### GET followers/list
**Function:** `XClient.Friendships.followers_list/2`  
**Rate Limit:** 15 per 15 min

Get follower details.

**Parameters:**
- `user_id` or `screen_name`
- `cursor` - Pagination cursor
- `count` - Users per page (max 200)

### GET friends/ids
**Function:** `XClient.Friendships.friends_ids/2`  
**Rate Limit:** 15 per 15 min

Get IDs of users being followed.

### GET friends/list
**Function:** `XClient.Friendships.friends_list/2`  
**Rate Limit:** 15 per 15 min

Get details of users being followed.

---

## Favorites

### POST favorites/create
**Function:** `XClient.Favorites.create/3`  
**Rate Limit:** 1000 per 24 hours

Like a tweet.

**Parameters:**
- `id` - Tweet ID (required)
- `include_entities` - Include entities

### POST favorites/destroy
**Function:** `XClient.Favorites.destroy/3`  
**Rate Limit:** No specific limit

Unlike a tweet.

### GET favorites/list
**Function:** `XClient.Favorites.list/2`  
**Rate Limit:** 75 per 15 min

Get liked tweets.

**Parameters:**
- `user_id` or `screen_name`
- `count` - Tweets per page (max 200)
- `since_id` - Return tweets after this ID
- `max_id` - Return tweets before this ID

---

## Direct Messages

### POST direct_messages/events/new
**Function:** `XClient.DirectMessages.send/4`  
**Rate Limit:** 1000 per 24 hours (user), 15000 per 24 hours (app)

Send a direct message.

**Parameters:**
- `recipient_id` - Recipient user ID (required)
- `text` - Message text (required)
- `media_id` - Attached media ID
- `quick_reply_options` - List of quick reply options

### DELETE direct_messages/events/destroy
**Function:** `XClient.DirectMessages.destroy/2`  
**Rate Limit:** No specific limit

Delete a direct message.

### GET direct_messages/events/list
**Function:** `XClient.DirectMessages.list/2`  
**Rate Limit:** No specific limit

Get direct messages.

**Parameters:**
- `count` - Events to return (max 50)
- `cursor` - Pagination cursor

### GET direct_messages/events/show
**Function:** `XClient.DirectMessages.show/2`  
**Rate Limit:** No specific limit

Get a single direct message.

---

## Search

### GET search/tweets
**Function:** `XClient.Search.tweets/3`  
**Rate Limit:** 180 per 15 min (user), 450 per 15 min (app)

Search for tweets.

**Parameters:**
- `q` - Search query (required)
- `geocode` - Location filter (lat,long,radius)
- `lang` - Language code
- `result_type` - mixed, recent, or popular
- `count` - Results per page (max 100)
- `until` - Date limit (YYYY-MM-DD)
- `since_id` - Return tweets after this ID
- `max_id` - Return tweets before this ID

**Search Operators:**
- `word1 word2` - Both words
- `"exact phrase"` - Exact phrase
- `word1 OR word2` - Either word
- `word1 -word2` - word1 but not word2
- `#hashtag` - Hashtag
- `from:user` - From user
- `to:user` - To user
- `@user` - Mentions user
- `:)` or `:(` - Positive or negative
- `?` - Questions
- `filter:links` - Contains links

---

## Lists

### GET lists/list
**Function:** `XClient.Lists.list/2`  
**Rate Limit:** 15 per 15 min

Get all lists for a user.

### GET lists/statuses
**Function:** `XClient.Lists.statuses/2`  
**Rate Limit:** 900 per 15 min

Get tweets from a list.

**Parameters:**
- `list_id` or (`slug` and `owner_screen_name/owner_id`) (required)
- `since_id` - Return tweets after this ID
- `max_id` - Return tweets before this ID
- `count` - Tweets per page (max 200)

### GET lists/show
**Function:** `XClient.Lists.show/2`  
**Rate Limit:** 75 per 15 min

Get list information.

### GET lists/members
**Function:** `XClient.Lists.members/2`  
**Rate Limit:** 900 per 15 min (user), 75 per 15 min (app)

Get list members.

**Parameters:**
- `list_id` or (`slug` and `owner_screen_name/owner_id`) (required)
- `count` - Members per page (max 5000)
- `cursor` - Pagination cursor

### GET lists/members/show
**Function:** `XClient.Lists.members_show/2`  
**Rate Limit:** 15 per 15 min

Check if user is a list member.

### GET lists/memberships
**Function:** `XClient.Lists.memberships/2`  
**Rate Limit:** 75 per 15 min

Get lists a user is a member of.

### GET lists/ownerships
**Function:** `XClient.Lists.ownerships/2`  
**Rate Limit:** 15 per 15 min

Get lists owned by a user.

### GET lists/subscribers
**Function:** `XClient.Lists.subscribers/2`  
**Rate Limit:** 180 per 15 min (user), 15 per 15 min (app)

Get list subscribers.

### GET lists/subscribers/show
**Function:** `XClient.Lists.subscribers_show/2`  
**Rate Limit:** 15 per 15 min

Check if user is subscribed to a list.

### GET lists/subscriptions
**Function:** `XClient.Lists.subscriptions/2`  
**Rate Limit:** 15 per 15 min

Get lists a user is subscribed to.

---

## Account

### GET account/verify_credentials
**Function:** `XClient.Account.verify_credentials/2`  
**Rate Limit:** 75 per 15 min (user only)

Verify credentials and get user info.

**Parameters:**
- `include_entities` - Include entities
- `skip_status` - Exclude status
- `include_email` - Include email

### POST account/update_profile
**Function:** `XClient.Account.update_profile/2`  
**Rate Limit:** No specific limit

Update profile information.

**Parameters:**
- `name` - Display name (max 50 chars)
- `url` - Website (max 100 chars)
- `location` - Location (max 30 chars)
- `description` - Bio (max 160 chars)

### POST account/update_profile_image
**Function:** `XClient.Account.update_profile_image/3`  
**Rate Limit:** No specific limit

Update profile image.

**Requirements:**
- Less than 700KB
- GIF, JPG, or PNG
- Square recommended

### POST account/update_profile_banner
**Function:** `XClient.Account.update_profile_banner/3`  
**Rate Limit:** No specific limit

Update profile banner.

**Requirements:**
- Less than 5MB
- JPG, PNG, or GIF
- 1500x500 recommended

### POST account/remove_profile_banner
**Function:** `XClient.Account.remove_profile_banner/1`  
**Rate Limit:** No specific limit

Remove profile banner.

### GET account/settings
**Function:** `XClient.Account.settings/1`  
**Rate Limit:** No specific limit

Get account settings.

### POST account/settings
**Function:** `XClient.Account.update_settings/2`  
**Rate Limit:** No specific limit

Update account settings.

---

## Trends

### GET trends/place
**Function:** `XClient.Trends.place/3`  
**Rate Limit:** 75 per 15 min

Get trending topics for a location.

**Parameters:**
- `id` - WOEID (required)
- `exclude` - Exclude hashtags

**Common WOEIDs:**
- Worldwide: 1
- United States: 23424977
- United Kingdom: 23424975

### GET trends/available
**Function:** `XClient.Trends.available/1`  
**Rate Limit:** 75 per 15 min

Get all available trend locations.

### GET trends/closest
**Function:** `XClient.Trends.closest/2`  
**Rate Limit:** 75 per 15 min

Get closest trend locations.

**Parameters:**
- `lat` - Latitude (required)
- `long` - Longitude (required)

---

## Geo

### GET geo/id/:place_id
**Function:** `XClient.Geo.id/2`  
**Rate Limit:** 75 per 15 min (user only)

Get place information.

---

## Help

### GET help/configuration
**Function:** `XClient.Help.configuration/1`  
**Rate Limit:** 15 per 15 min

Get X configuration.

### GET help/languages
**Function:** `XClient.Help.languages/1`  
**Rate Limit:** 15 per 15 min

Get supported languages.

### GET help/privacy
**Function:** `XClient.Help.privacy/1`  
**Rate Limit:** 15 per 15 min

Get privacy policy.

### GET help/tos
**Function:** `XClient.Help.tos/1`  
**Rate Limit:** 15 per 15 min

Get terms of service.

---

## Application

### GET application/rate_limit_status
**Function:** `XClient.Application.rate_limit_status/2`  
**Rate Limit:** 180 per 15 min

Get current rate limit status.

**Parameters:**
- `resources` - Comma-separated resource families

**Resource Families:**
- statuses
- users
- search
- friends
- followers
- lists
- direct_messages
- favorites
- trends
- geo
- account
- application
- help

---

## Rate Limit Summary

### 15-Minute Windows

| Endpoint | User | App |
|----------|------|-----|
| GET statuses/show | 900 | 900 |
| GET statuses/user_timeline | 900 | 1500 |
| GET statuses/mentions_timeline | 75 | - |
| GET statuses/lookup | 900 | 300 |
| GET search/tweets | 180 | 450 |
| GET users/show | 900 | 900 |
| GET users/lookup | 900 | 300 |
| GET friendships/show | 180 | 15 |
| GET followers/ids | 15 | 15 |
| GET friends/ids | 15 | 15 |
| GET favorites/list | 75 | 75 |
| GET lists/statuses | 900 | 900 |
| GET trends/place | 75 | 75 |
| GET account/verify_credentials | 75 | - |
| GET application/rate_limit_status | 180 | 180 |

### Longer Windows

| Endpoint | Window | User | App |
|----------|--------|------|-----|
| POST statuses/update | 3 hours | 300 | 300 |
| POST statuses/retweet | 3 hours | 300 | 300 |
| POST favorites/create | 24 hours | 1000 | 1000 |
| POST friendships/create | 24 hours | 400 | 1000 |
| POST direct_messages/events/new | 24 hours | 1000 | 15000 |

---

## Error Codes

| Code | Description |
|------|-------------|
| 32 | Could not authenticate |
| 34 | Sorry, that page does not exist |
| 50 | User not found |
| 63 | User has been suspended |
| 64 | Your account is suspended |
| 68 | The X REST API v1 is no longer active |
| 88 | Rate limit exceeded |
| 89 | Invalid or expired token |
| 99 | Unable to verify credentials |
| 130 | Over capacity |
| 131 | Internal error |
| 135 | Could not authenticate |
| 136 | You have been blocked |
| 144 | No status found with that ID |
| 179 | Sorry, you are not authorized |
| 185 | User is over daily status update limit |
| 186 | Tweet needs to be a bit shorter |
| 187 | Status is a duplicate |
| 215 | Bad authentication data |
| 226 | This request looks like it might be automated |
| 231 | User must verify login |
| 251 | This endpoint has been retired |
| 261 | Application cannot perform write actions |
| 271 | You can't mute yourself |
| 272 | You are not muting this user |
| 354 | DM length exceeds max length |

---

For more details, see the [X API documentation](https://developer.x.com/en/docs/x-api/v1).