# install_sql_odbc

Installs the Microsoft **SQL Server client drivers** that ConfigMgr and SQL clients
depend on:

- **Microsoft ODBC Driver 18 for SQL Server** (`msodbcsql18.msi`)
- **Microsoft OLE DB Driver 19 for SQL Server** (`msoledbsql.msi` / MSOLEDBSQL)

The ConfigMgr site server, SQL server, management point, and other site systems expect
these drivers to be present; a missing OLE DB driver in particular trips the site-server
prerequisite checks. This role provides them as a reusable building block so they can be
installed on whichever hosts need them.

It follows the collection's download pattern: the installer is cached on the Ludus host
under `resources/sccm/`, copied to the Windows VM, then installed silently with the EULA
accepted (`IACCEPTMSODBCSQLLICENSETERMS=YES` / `IACCEPTMSOLEDBSQLLICENSETERMS=YES`).
Installs are idempotent (skipped if the driver's product code is already present).

## Usage

Add it to the `roles` list of any SCCM host that needs the drivers — typically the site
server and SQL host — before the site install:

```yaml
roles:
  - synzack.ludus_sccm.install_sql_odbc
  - synzack.ludus_sccm.ludus_sccm_sql
```

## Variables

See `defaults/main.yml`.

| Variable | Purpose | Default |
|---|---|---|
| `ludus_sccm_install_odbc` | Install the ODBC Driver 18 | `true` |
| `ludus_sccm_odbc_url` | ODBC 18 x64 MSI URL (fwlink → latest 18.x) | `https://go.microsoft.com/fwlink/?linkid=2358430` |
| `ludus_sccm_install_msoledbsql` | Install the OLE DB Driver (MSOLEDBSQL) | `true` |
| `ludus_sccm_msoledbsql_url` | OLE DB 19 x64 MSI URL (fwlink → latest 19.x) | `https://go.microsoft.com/fwlink/?linkid=2364027` |
| `ludus_sccm_odbc_host_path` | Staging dir on the Windows host | `C:\ludus\sccm\sqldrivers` |
| `ludus_sccm_odbc_checksum` / `ludus_sccm_msoledbsql_checksum` | Optional `sha256:...` for the cached download (pin the URL to use) | `''` |

> The default URLs are Microsoft `go.microsoft.com/fwlink` permalinks that always resolve
> to the current GA release. Pin `*_url` to a versioned `download.microsoft.com` link and
> set the matching `*_checksum` if you need reproducible builds.
