# Lightweight Gitea

This is a small, single-container Gitea install backed by SQLite. It is intended
for local use with Podman Compose.

## Start

```sh
podman compose up -d
```

Open <http://gitea.127.0.0.1.nip.io:3000/> and create the first administrator
account. `nip.io` maps the hostname to `127.0.0.1`, so no `/etc/hosts` change is
needed.

The SSH clone URL uses port `2222`:

```text
ssh://git@gitea.127.0.0.1.nip.io:2222/OWNER/REPOSITORY.git
```

Data is stored in `./data` and configuration in `./config`. Stop it with
`podman compose down`; removing those directories deletes the instance.

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
