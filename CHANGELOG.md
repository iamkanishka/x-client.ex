# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-31

### Added

#### Core Features
- Complete X API v1.1 implementation
- OAuth 1.0a authentication
- Automatic rate limiting with retry
- Comprehensive error handling

#### Tweets Module
- `update/3` - Post tweets
- `destroy/3` - Delete tweets
- `retweet/3` - Retweet functionality
- `unretweet/3` - Remove retweets
- `show/3` - Get single tweet
- `lookup/3` - Get multiple tweets
- `user_timeline/2` - User timeline retrieval
- `mentions_timeline/2` - Mentions timeline
- `retweets_of_me/2` - Retweeted tweets
- `retweets/3` - Get retweets
- `retweeters_ids/3` - Get retweeter IDs

#### Media Module
- Simple media upload
- Chunked upload for large files (>5MB)
- Support for images (JPEG, PNG, GIF, WEBP)
- Support for videos (MP4, up to 512MB)
- Animated GIF support
- Alt text/metadata support
- Automatic media type detection
- Processing status tracking

#### Users Module
- `show/2` - Get user information
- `lookup/2` - Bulk user lookup
- `search/3` - User search
- `suggestions/2` - Get suggested categories
- `suggestions_slug/3` - Category suggestions
- `suggestions_members/2` - Category members

#### Friendships Module
- `create/2` - Follow users
- `destroy/2` - Unfollow users
- `show/2` - Relationship information
- `followers_ids/2` - Follower IDs
- `followers_list/2` - Follower details
- `friends_ids/2` - Following IDs
- `friends_list/2` - Following details

#### Favorites Module
- `create/3` - Like tweets
- `destroy/3` - Unlike tweets
- `list/2` - List liked tweets

#### Direct Messages Module
- `send/4` - Send direct messages
- `destroy/2` - Delete messages
- `list/2` - List messages
- `show/2` - Get single message
- Media attachment support
- Quick reply options

#### Lists Module
- `list/2` - Get all lists
- `statuses/2` - List timeline
- `show/2` - List details
- `members/2` - List members
- `members_show/2` - Check membership
- `memberships/2` - User memberships
- `ownerships/2` - Owned lists
- `subscribers/2` - List subscribers
- `subscribers_show/2` - Check subscription
- `subscriptions/2` - User subscriptions

#### Search Module
- `tweets/3` - Tweet search with advanced operators
- Support for geocoding
- Language filtering
- Result type filtering

#### Account Module
- `verify_credentials/2` - Credential verification
- `update_profile/2` - Profile updates
- `update_profile_image/3` - Avatar updates
- `update_profile_banner/3` - Banner updates
- `remove_profile_banner/1` - Banner removal
- `update_settings/2` - Settings management
- `settings/1` - Get current settings

#### Trends Module
- `place/3` - Get trends for location
- `available/1` - Available trend locations
- `closest/2` - Closest trend locations

#### Geo Module
- `id/2` - Place information lookup

#### Help Module
- `configuration/1` - API configuration
- `languages/1` - Supported languages
- `privacy/1` - Privacy policy
- `tos/1` - Terms of service

#### Application Module
- `rate_limit_status/2` - Rate limit tracking

#### Infrastructure
- GenServer-based rate limiter
- Automatic retry with exponential backoff
- Request authentication with OAuth 1.0a
- Configurable API endpoints
- Environment variable support

### Documentation
- Comprehensive README with examples
- Module documentation with rate limits
- Function documentation with examples
- Installation and configuration guide
- Advanced usage examples

### Dependencies
- `req` - HTTP client
- `jason` - JSON encoding/decoding
- `oauther` - OAuth 1.0a signing
- `ex_rated` - Rate limiting
- `mime` - MIME type detection

## [Unreleased]

### Planned
- Streaming API support
- Additional media processing options
- Retry strategies customization
- Response caching
- Batch operations helpers
- Mock client for testing