# Configuration Manager runtime prerequisites

Shared by the site server, management point and distribution point roles. Checks .NET Framework 4.8+, installs the x86 and x64 Visual C++ 14.44.35211.0 runtimes and SQL ODBC 18.6.2.1 from controller-cached installers, and reboots only when an installer requires it.

Defaults are in `defaults/main.yml`. The SQL engine remains SQL Server 2022; this role installs connectivity drivers and does not replace the database engine. See [2509 deployment notes](../../docs/2509.md).
