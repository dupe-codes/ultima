# Comment System Options for Ultima

This document outlines three options for adding comments to Ultima-powered sites: Staticman, Hyvor Talk, and Remark42.

---

## Option 1: Staticman

Staticman is a unique approach where comments become static data files in the repository. When a visitor submits a comment, Staticman creates a pull request (or direct commit) with the comment as a YAML/JSON file.

### How It Works

```
┌─────────────┐     POST      ┌─────────────┐     PR/Commit     ┌─────────────┐
│   Visitor   │ ────────────► │  Staticman  │ ────────────────► │   GitHub    │
│ (comment    │               │    API      │                   │    Repo     │
│   form)     │               │             │                   │             │
└─────────────┘               └─────────────┘                   └──────┬──────┘
                                                                       │
                              ┌─────────────┐     rebuild       ┌──────▼──────┐
                              │   Static    │ ◄──────────────── │  Merge PR   │
                              │    Site     │                   │  (or auto)  │
                              └─────────────┘                   └─────────────┘
```

### Implementation Plan

#### 1. Staticman Configuration

Create `staticman.yml` in repo root:

```yaml
comments:
  allowedFields: ["name", "email", "message"]
  branch: "main"
  commitMessage: "New comment on {options.slug}"
  filename: "{@timestamp}"
  format: "yaml"
  moderation: true  # creates PR for approval
  path: "sites/{options.site}/content/{options.path}/comments"
  requiredFields: ["name", "message"]
  transforms:
    email: md5  # hash for Gravatar, privacy
```

#### 2. Comment Data Structure

Comments stored alongside posts:

```
sites/dupe_sh/content/manuscripts/my-post/
├── my-post.md
└── comments/
    ├── 1704067200.yml
    └── 1704153600.yml
```

Each comment file:

```yaml
name: "Jane Doe"
email: "5d41402abc4b2a76b9719d911017c592"  # md5 hash
message: "Great post! I especially liked..."
date: "2025-01-02T10:30:00Z"
```

#### 3. Modify `find_content()` in `ultima.lua`

```lua
-- When processing a post, also look for comments/ subdirectory
local comments_dir = source_path:gsub("%.md$", "") .. "/comments"
if lfs.attributes(comments_dir, "mode") == "directory" then
    metadata.comments = load_comments(comments_dir)
end
```

#### 4. New Helper Function

```lua
local function load_comments(comments_dir)
    local comments = {}
    for file in lfs.dir(comments_dir) do
        if file:match("%.ya?ml$") then
            local content = file_utils.read_file(comments_dir .. "/" .. file)
            local comment = yaml.parse(content)
            table.insert(comments, comment)
        end
    end
    table.sort(comments, function(a, b) return a.date < b.date end)
    return comments
end
```

#### 5. Update `post.htmlua` Template

```html
{% if metadata.comments and #metadata.comments > 0 then }}
    <div class="comments">
        <h2>Comments</h2>
        {% for _, comment in ipairs(metadata.comments) do }}
            <div class="comment">
                <span class="comment-author">{{ comment.name }}</span>
                <span class="comment-date">{{ comment.date }}</span>
                <p>{{ comment.message }}</p>
            </div>
        {% end }}
    </div>
{% end }}

<form class="comment-form" method="POST"
      action="https://staticman.example.com/v3/entry/github/USER/REPO/main/comments">
    <input type="hidden" name="options[slug]" value="{{ slug }}">
    <input type="text" name="fields[name]" placeholder="Name" required>
    <input type="email" name="fields[email]" placeholder="Email">
    <textarea name="fields[message]" placeholder="Comment" required></textarea>
    <button type="submit">Submit</button>
</form>
```

### Hosting Options for Staticman

1. **Public Staticman API** - Free but unreliable/rate-limited
2. **Self-host on Heroku/Fly.io** - More reliable, some setup required
3. **GitHub Actions workflow** - Use a bot to process comment submissions

### Pros

- Comments are part of our repo (portable, ours forever)
- No JavaScript required for display
- Full control over rendering
- Works offline (comments in repo)
- Privacy-friendly
- Truly static

### Cons

- Requires Staticman instance (public API often overloaded)
- Self-hosting adds complexity
- Moderation = manual PR merges
- Spam management is manual
- Slower feedback loop (rebuild required after each comment)
- Need to add YAML parsing dependency to Ultima

### Effort

| Task | Time |
|------|------|
| Initial setup | 2-3 hours |
| Staticman hosting (if self-hosted) | 1-2 hours |
| Ultima code changes | 1-2 hours |
| **Ongoing maintenance** | Manual PR reviews for each comment |

---

## Option 2: Hyvor Talk

Hyvor Talk is a privacy-focused, hosted commenting platform. Integration is simple - embed a JavaScript widget.

### How It Works

Visitors see an embedded comment widget on posts. Comments are stored on Hyvor's servers. We manage moderation through their dashboard.

### Implementation Plan

#### 1. Setup

1. Sign up at [hyvor.com/talk](https://hyvor.com/talk)
2. Create account, add our site
3. Get our website ID (a number)
4. Configure moderation, appearance in their dashboard

#### 2. Site Configuration

Add to `config.toml`:

```toml
[comments]
provider = "hyvor"
hyvor_website_id = "OUR_WEBSITE_ID"
```

#### 3. Update `post.htmlua` Template

```html
<div class="post-content">
    {{ content }}
</div>

{% if config.comments and config.comments.provider == "hyvor" then }}
    <div id="hyvor-talk-view"></div>
    <script>
        var HYVOR_TALK_WEBSITE = {{ config.comments.hyvor_website_id }};
        var HYVOR_TALK_CONFIG = {
            url: '{{ config.main.site_url }}{{ link }}',
            id: '{{ link }}'
        };
    </script>
    <script async src="https://talk.hyvor.com/embed/embed.js"></script>
{% end }}
```

#### 4. Optional Per-Post Control

In frontmatter:

```yaml
---
title: "My Post"
comments: true  # or false to disable
---
```

Template check:

```html
{% if metadata.comments ~= false and config.comments then }}
    <!-- embed script -->
{% end }}
```

### Features

- **Dashboard**: Moderation, spam filtering, analytics
- **Auth options**: Guest, social login, SSO
- **Appearance**: Customizable to match our theme
- **Features**: Reactions, upvotes, nested replies, email notifications
- **Privacy**: GDPR compliant, no ads, no tracking beyond comments

### Pros

- Very easy setup (just a script tag)
- No server maintenance
- Good moderation tools
- Privacy-focused (no ads, GDPR compliant)
- Multiple auth options (not just GitHub)

### Cons

- Data stored on their servers (not ours)
- Dependent on their uptime/business continuity
- Paid service (starts at $18/mo)
- Less control over rendering

### Effort

| Task | Time |
|------|------|
| Initial setup | 15-30 minutes |
| Ultima code changes | 15 minutes |
| **Ongoing maintenance** | None (moderation via dashboard) |

---

## Option 3: Remark42

Remark42 is a self-hosted, privacy-focused comment engine written in Go. We run it on our own server.

### Architecture

```
┌─────────────┐         ┌─────────────────────────────────┐
│   Visitor   │ ◄─────► │  Our Server (VPS/Cloud)         │
│  (browser)  │         │  ┌─────────────────────────┐    │
└─────────────┘         │  │  Remark42 (Docker)      │    │
                        │  │  - Go backend           │    │
┌─────────────┐         │  │  - BoltDB storage       │    │
│ Static Site │         │  │  - REST API             │    │
│ (GitHub     │         │  └─────────────────────────┘    │
│  Pages)     │         │                                 │
└─────────────┘         └─────────────────────────────────┘
```

### Implementation Plan

#### 1. Server Setup

Get a small VPS (~$5/mo):
- DigitalOcean, Linode, Vultr, Hetzner
- 1GB RAM is sufficient
- Or use a free tier (Oracle Cloud, Fly.io)

#### 2. Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3'

services:
  remark42:
    image: umputun/remark42:latest
    container_name: remark42
    restart: always
    ports:
      - "8080:8080"
    environment:
      - REMARK_URL=https://comments.dupe.sh
      - SECRET=our-secret-key-here
      - SITE=dupe_sh
      - ADMIN_SHARED_ID=github_our-github-id
      # Auth providers (enable what we want)
      - AUTH_GITHUB_CID=our-github-oauth-client-id
      - AUTH_GITHUB_CSEC=our-github-oauth-secret
      - AUTH_ANON=true  # allow anonymous comments
      # Optional notifications
      - NOTIFY_TYPE=telegram  # or email
      - NOTIFY_TELEGRAM_TOKEN=...
    volumes:
      - ./data:/srv/var
```

#### 3. Reverse Proxy

Using Caddy:

```
# Caddyfile
comments.dupe.sh {
    reverse_proxy localhost:8080
}
```

#### 4. DNS

Point `comments.dupe.sh` (or similar subdomain) to our VPS.

#### 5. Site Configuration

Add to `config.toml`:

```toml
[comments]
provider = "remark42"
remark_url = "https://comments.dupe.sh"
site_id = "dupe_sh"
```

#### 6. Update `post.htmlua` Template

```html
{% if config.comments and config.comments.provider == "remark42" then }}
    <div id="remark42"></div>
    <script>
        var remark_config = {
            host: '{{ config.comments.remark_url }}',
            site_id: '{{ config.comments.site_id }}',
            url: '{{ config.main.site_url }}{{ link }}',
            theme: 'light',
            locale: 'en'
        };
    </script>
    <script>
        !function(e,n){for(var o=0;o<e.length;o++){
        var r=n.createElement("script"),c=".js",d=n.head||n.body;
        "noModule"in r?(r.type="module",c=".mjs"):r.async=!0,
        r.defer=!0,r.src=remark_config.host+"/web/"+e[o]+c,
        d.appendChild(r)}}(["embed"],document);
    </script>
{% end }}
```

### Features

- **Auth**: GitHub, Google, Facebook, Twitter, Telegram, email, anonymous
- **Moderation**: Admin UI, email notifications, Telegram bot
- **Privacy**: No tracking, GDPR-friendly, data export
- **Anti-spam**: Rate limiting, basic spam detection
- **Styling**: Themeable, dark mode support
- **Data**: Full export/import, backup via Docker volume

### Cost Breakdown

| Component | Cost |
|-----------|------|
| VPS (1GB) | ~$5/mo |
| Domain (optional subdomain) | Free if we own domain |
| SSL | Free (Let's Encrypt via Caddy) |
| **Total** | **~$5/mo** |

### Pros

- Full data ownership
- Privacy-focused
- Multiple auth providers
- Good admin UI
- Active development
- No external dependencies once running

### Cons

- Requires server maintenance
- Initial setup complexity
- We handle backups
- Need to keep Docker updated
- Another service to monitor

### Effort

| Task | Time |
|------|------|
| VPS setup | 30 minutes |
| Docker/Remark42 setup | 30 minutes |
| OAuth app creation | 15 min per provider |
| Ultima code changes | 15 minutes |
| **Ongoing maintenance** | ~5-10 min/month (updates, monitoring) |

---

## Final Comparison

| Aspect | Staticman | Hyvor Talk | Remark42 |
|--------|-----------|------------|----------|
| **Type** | Static files in repo | Hosted SaaS | Self-hosted |
| **Monthly cost** | Free (or hosting cost) | $18+ | ~$5 (VPS) |
| **Data ownership** | Full (in our repo) | Theirs | Full (our server) |
| **Setup complexity** | High | Low | Medium |
| **Maintenance** | PR reviews per comment | None | Server updates |
| **Auth options** | None (anonymous) | Multiple | Multiple |
| **Moderation UI** | GitHub PRs | Dashboard | Admin panel |
| **Privacy** | Excellent | Good | Excellent |
| **JavaScript required** | No (display) / Yes (submit) | Yes | Yes |
| **Offline resilience** | Full (static) | Their uptime | Our uptime |
| **Rebuild required** | Yes (per comment) | No | No |
