# TODO: Poll DigitalOcean App Platform Deployment Status

## Overview

Add deployment status polling to `scripts/deploy.sh` after pushing to the deploy branch. Uses `doctl` CLI to check deployment progress and report success/failure.

## Implementation

### 1. Add App ID Configuration

Add `digitalocean_app_id` to each site's `config.toml` under `[main]`:

```toml
[main]
site_name = "numeric-eng"
digitalocean_app_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### 2. Update `scripts/deploy.sh`

Add a new function after the git push to poll deployment status:

```bash
poll_deployment_status() {
    local app_id="$1"
    local max_attempts=60  # 5 minutes with 5s interval
    local attempt=0

    # Check doctl is available
    if ! command -v doctl &> /dev/null; then
        printf "\033[0;33mWarning: doctl not installed, skipping deployment status check\033[0m\n"
        return 0
    fi

    # Check authentication
    if [ -z "$DIGITALOCEAN_ACCESS_TOKEN" ]; then
        printf "\033[0;33mWarning: DIGITALOCEAN_ACCESS_TOKEN not set, skipping deployment status check\033[0m\n"
        return 0
    fi

    printf "\033[0;32mPolling deployment status...\033[0m\n"

    # Wait for new deployment to appear (may take a few seconds after push)
    sleep 5

    # Get the latest deployment ID
    local deployment_id
    deployment_id=$(doctl apps list-deployments "$app_id" --output json 2>/dev/null | jq -r '.[0].id')

    if [ -z "$deployment_id" ] || [ "$deployment_id" = "null" ]; then
        printf "\033[0;33mCould not find deployment, skipping status check\033[0m\n"
        return 0
    fi

    while [ $attempt -lt $max_attempts ]; do
        local status
        status=$(doctl apps get-deployment "$app_id" "$deployment_id" --output json 2>/dev/null | jq -r '.phase')

        case "$status" in
            ACTIVE)
                printf "\033[0;32m✓ Deployment successful!\033[0m\n"
                return 0
                ;;
            ERROR|FAILED)
                printf "\033[0;31m✗ Deployment failed!\033[0m\n"
                return 1
                ;;
            PENDING_BUILD)
                printf "  ⏳ Pending build...\r"
                ;;
            BUILDING)
                printf "  🔨 Building...     \r"
                ;;
            DEPLOYING)
                printf "  🚀 Deploying...    \r"
                ;;
            *)
                printf "  Status: %s\r" "$status"
                ;;
        esac

        sleep 5
        attempt=$((attempt + 1))
    done

    printf "\033[0;33mTimeout waiting for deployment status\033[0m\n"
    return 0
}
```

### 3. Extract App ID from Config

Add helper to read app ID from site's config.toml:

```bash
get_app_id() {
    local site="$1"
    local config_file="sites/$site/config.toml"

    if [ ! -f "$config_file" ]; then
        return 1
    fi

    grep -E "^digitalocean_app_id" "$config_file" | sed 's/.*= *"\(.*\)"/\1/' | tr -d ' '
}
```

### 4. Call from Deploy Flow

At end of deploy.sh, after successful push:

```bash
APP_ID=$(get_app_id "$SITE")
if [ -n "$APP_ID" ]; then
    echo ""
    poll_deployment_status "$APP_ID"
fi
```

## Files to Modify

1. `scripts/deploy.sh` - Add polling logic
2. `sites/*/config.toml` - Add `digitalocean_app_id` for each site (optional per-site)

## Dependencies

- `doctl` CLI (gracefully skipped if not installed)
- `jq` for JSON parsing
- `DIGITALOCEAN_ACCESS_TOKEN` environment variable

## Verification

1. Run `make deploy site=numeric_eng`
2. Observe status updates in terminal
3. Confirm final success/failure message matches DigitalOcean dashboard
