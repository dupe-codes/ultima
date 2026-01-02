# Remark42 Comment Server

Self-hosted comment system for Ultima-powered sites.

## Prerequisites

- A VPS or server with Docker and Docker Compose installed
- A domain/subdomain pointed to the server (e.g., `comments.dupe.sh`)
- (Optional) GitHub OAuth app for GitHub login

## Quick Start

### 1. Copy configuration

```bash
cp .env.example .env
```

### 2. Edit `.env` with your settings

Required settings:
- `REMARK_URL` - Full URL where comments will be hosted (e.g., `https://comments.dupe.sh`)
- `REMARK_DOMAIN` - Domain without protocol (e.g., `comments.dupe.sh`)
- `SECRET` - Random string for JWT signing (generate with `openssl rand -base64 32`)
- `SITE_ID` - Site identifier(s), comma-separated for multiple sites
- `ADMIN_SHARED_ID` - Your admin user ID (see below)

### 3. Set up GitHub OAuth (recommended)

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create a new OAuth App:
   - **Application name**: Your site comments
   - **Homepage URL**: `https://comments.dupe.sh`
   - **Authorization callback URL**: `https://comments.dupe.sh/auth/github/callback`
3. Copy the Client ID and Client Secret to your `.env` file

### 4. Find your GitHub user ID

```bash
curl -s https://api.github.com/users/YOUR_USERNAME | jq .id
```

Use this as `ADMIN_SHARED_ID` with format: `github_YOURID`

### 5. Start the server

```bash
docker compose up -d
```

### 6. Verify it's running

```bash
# Check container status
docker compose ps

# Check logs
docker compose logs -f remark42

# Test the API
curl https://comments.dupe.sh/api/v1/config
```

## Configuration

### Multiple Sites

To support multiple Ultima sites, use comma-separated site IDs:

```env
SITE_ID=dupe_sh,rorschach,whwg
```

Each site uses its own `site_id` in the Ultima `config.toml`.

### Authentication Options

| Provider | Environment Variables |
|----------|----------------------|
| GitHub | `AUTH_GITHUB_CID`, `AUTH_GITHUB_CSEC` |
| Anonymous | `AUTH_ANON=true` |
| Email | `AUTH_EMAIL_ENABLE=true`, SMTP settings |

### Notifications

Set `NOTIFY_TYPE` to receive notifications for new comments:

- `telegram` - Requires `NOTIFY_TELEGRAM_TOKEN` and `NOTIFY_TELEGRAM_CHAN`
- `email` - Uses SMTP settings
- `slack` - Requires webhook URL
- `none` - Disabled (default)

## Maintenance

### Backup data

```bash
# Stop containers
docker compose stop

# Backup data directory
tar -czvf remark42-backup-$(date +%Y%m%d).tar.gz data/

# Restart
docker compose start
```

### Update Remark42

```bash
docker compose pull
docker compose up -d
```

### View logs

```bash
docker compose logs -f remark42
docker compose logs -f caddy
```

## Admin Interface

Access the admin panel at: `https://comments.dupe.sh/web/admin`

You must be logged in with an account matching `ADMIN_SHARED_ID`.

## Troubleshooting

### SSL certificate issues

Caddy automatically obtains Let's Encrypt certificates. If issues occur:

```bash
# Check Caddy logs
docker compose logs caddy

# Ensure port 80 and 443 are open
# Ensure DNS is properly configured
```

### CORS errors

The Caddyfile includes CORS headers. If you see CORS errors, verify:
1. The `REMARK_URL` matches the actual URL
2. Your site's domain is accessible

### Comments not loading

1. Check browser console for errors
2. Verify `site_id` matches between Remark42 and Ultima config
3. Check Remark42 logs: `docker compose logs remark42`
