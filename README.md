# LinuxMSSQL-Toolbox

A collection of scripts to aid working with SQL Server on Linux or even Linux in general based on my personal field experience.
Health check script for a Linux server, includes SQL and Pacemaker checks

Scripts are all provided "as-is" with no waranty.

Tested on the following versions of Linux:

- RHEL

## Scripts folder

This is a general collection of scripts including

| Script Name | Purpose |
| backup_cleanup.sh | A script to clean up SQL Server backup locations as part of regular maintenance |

## HealthCheck folder

This is a script used to check the health of a server. Key features include:

- CPU, Disk, Memory checks
- SQL Server checks
- Pacemaker checks

## Change Log

See the [Change Log](./CHANGELOG.md) for the full changes.

## License

This project is released under the [MIT License](./LICENSE)

## Contributors

- Matticusau [GitHub](https://github.com/Matticusau) | [twitter](https://twitter.com/matticusau)
