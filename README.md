# openclaw-extensions

This repo contains my extensions and mods to OpenClaw for my docker setup.

## Contents

### Docker Fixes

#### Problem Statement
I run OpenClaw in a docker environment on an Ubuntu vm. The OpenClaw docker-setup.sh presented a number of limitations and problems for me. 

Re-running the script would wipe environment variables like OPENCLAW_DOCKER_APT_PACKAGES. I was not comfortable with exporting all of these, and the existing approach seemed inconsistent as to where this is truly mastered.

In many cases I just needed to rebuild the image. I didn't want to customize Dockerfile directly, only to have it wiped on an update. 

Skills were not installable from the OpenClaw Console - any skill with dependencies (such as linuxbrew) could not be installed.

There are a bunch of packages and binaries that are needed for Tools and Skills to function. e.g. there is no browser installed.


#### The Approach
My approach is to build Dockerfile.local, layering on top of the stock openclaw:local image.

Dockerfile.local - custom dockerfile.
Key features:
- Install user defined apt packages. List is mastered here. Bypasses use of OPENCLAW_DOCKER_APT_PACKAGES.
- Install and set up the runtime environments (npm/uv/go/brew) so that skills can install from the console at runtime and are persistent.
- Installs Google Chrome, which is needed by the OpenClaw "browser" tool.
- Sets ownership of /home/node/.config so that Chrome works.
- Customize the whisper install for tiny model as the default is gigantic.
- Installs user defined skills. Add your own here.


docker-update.sh - This script was created to manage the image build. I use this instead of calling docker-setup directly.
Key features:
- installs linuxbrew if needed. linuxbrew is bindmounted for persistence, refer to docker-compose.override.yml.
- command line argument to build the image or perform an update with the latest from github.
- builds the image from Dockerfile.local.
- restarts the gateway.


docker-compose.override.yml - overrides to compose file.
Key features:
- bind mount for linuxbrew so installs are persisted.
- bind mount for gog /home/node/.config/gogcli so keyring is persisted.
- sets timezone so that tools such as browser get correct ltz. **Modify this for your timezone**
- gog keyring environment variables. In your .env set `GOG_KEYRING_BACKEND=file` and `GOG_KEYRING_PASSWORD=your-password`
- environment variables for site-specific integrations (in my case, HomeAssistant api token HA_TOKEN).


#### Summary Files

The following docker files were added:

| File | Description |
|------|---------|
| `docker-compose.override.yml` | Overrides to compose. |
| `docker-update.sh` | Script to build or update the docker image. Don't run docker-setup.sh directly. |
| `Dockerfile.local` | Custom dockerfile. |

Place these in your openclaw installation directory (e.g. ~/openclaw).

#### Residual Problems

Some of the brew skills (e.g. summarize) are arm64 and can fail install (without a meaningful error message) depending on your environment.


### Skills
The set of custom and modified skills.

#### Bundled Skill Overrides
Skill overrides mechanism - mirroring the skill at .openclaw/skills/<name>/SKILL.md overrides the bundled version without a rebuild.

weather - the bundled weather skill failed for me most of the time, with timeouts. Modified for wttr.in retries with a fallback to using Open-Meteo.

whisper - skill trigger enhancements.

#### Custom Skills
These are my adds.

home_weatherstation - serves as an example for calling the Home Assistant api to obtain weatherstation info. HA_TOKEN is defined in .env.

my_location - serves as an example for calling the Home Assistant api to obtain location info from OwnTracks. HA_TOKEN is defined in .env.


## Environment

Ubuntu,  x86_64/amd64

## License

MIT
