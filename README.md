# Lightweight Gitea

This is a small, single-container Gitea install backed by SQLite. It is intended
for local use with Podman Compose.

## Start

```sh
./scripts/start-gitea.sh
```

The startup script creates a self-signed certificate in `./config` if one does
not already exist, then starts Gitea on HTTPS port `443`. Git operations use
HTTPS; SSH pulls and pushes are disabled.
Open <https://gitea.127.0.0.1.nip.io/> and create the first administrator
account. `nip.io` maps the hostname to `127.0.0.1`, so no `/etc/hosts` change is
needed.

Clone repositories using their HTTPS URL:

```text
https://gitea.127.0.0.1.nip.io/OWNER/REPOSITORY.git
```

Data is stored in `./data` and configuration in `./config`. Stop it with
`podman compose down`; removing those directories deletes the instance.

## Backups

Create a consistent backup with:

```sh
./scripts/backup-gitea.sh
```

The script briefly stops Gitea, archives `data`, `config`, and `compose.yaml`
into `./backups`, and restarts Gitea if it was running. Keep the resulting
archive somewhere separate from this machine as well.

## Certificates

The current setup uses HTTP. To enable Gitea's built-in HTTPS, place the
certificate and private key in:

```text
config/server.crt
config/server.key
```

Then uncomment the HTTPS environment variables in `compose.yaml`. Port `3000`
will serve HTTPS instead of HTTP. `server.crt` must contain the server certificate first,
followed by any intermediate certificates. Do not include the root CA.

For a private CA used by Gitea when connecting to another service—such as
LDAP, SMTP, OAuth, or an HTTPS endpoint—place the CA certificate at:

```text
ca/my-company-root.crt
```

Then uncomment the custom CA volume in `compose.yaml` and restart the stack:

```sh
podman compose up -d
```

The CA mount is separate from Gitea's server certificate. Clients must also
trust the CA that signed Gitea's server certificate.
