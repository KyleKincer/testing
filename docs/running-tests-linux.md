# Running 4D Unit Tests on Linux

The repository now includes automated tooling to fetch and install the experimental Linux build of **tool4d** and its required dependencies. The `Makefile` handles everything for you.

## Quick start

```bash
make test
```

On the first run this will:

1. Install the libraries `libc++1`, `uuid-runtime`, `libfreeimage3`, `xdg-user-dirs`, `libtinfo5`, and `libncurses5` if they are missing.
2. Download and install the latest Linux `tool4d` package to `/opt/tool4d`.
3. Execute the project's test suite, automatically skipping tests tagged `no-linux`.

You can also bootstrap the environment without running the tests:

```bash
make tool4d
```

Once the setup has completed, subsequent invocations of `make test` reuse the installed tooling and run quickly.

## Manual installation

The steps above are sufficient for most scenarios. If you need to perform the setup manually (for example, in a container without `make`), the commands executed by the `Makefile` are:

```bash
apt-get update
apt-get install -y curl libc++1 uuid-runtime libfreeimage3 xdg-user-dirs
curl -L -o /tmp/libtinfo5.deb http://archive.ubuntu.com/ubuntu/pool/main/n/ncurses/libtinfo5_6.1-1ubuntu1_amd64.deb
curl -L -o /tmp/libncurses5.deb http://archive.ubuntu.com/ubuntu/pool/main/n/ncurses/libncurses5_6.1-1ubuntu1_amd64.deb
dpkg -i /tmp/libtinfo5.deb /tmp/libncurses5.deb
curl -L -o /tmp/tool4d.deb https://resources-download.4d.com/release/20%20Rx/latest/latest/linux/tool4d.deb
dpkg --force-depends -i /tmp/tool4d.deb
```

After installation, run the tests manually:

```bash
/opt/tool4d/tool4d --project /workspace/testing/testing/Project/testing.4DProject \
  --skip-onstartup --dataless --startup-method test \
  --user-param "excludeTags=no-linux"
```

The output should end with a summary similar to:

```
=== Test Results Summary ===
Total Tests: 131
Passed: 131
Failed: 0
Pass Rate: 100.0%
```

## Notes
- Tests tagged `no-linux` are excluded by default on Linux (for example, `_TaggingExampleTest.test_file_system_access`).
- The Linux build runs headlessly and does **not** require Wine or a graphical environment.
- Previous attempts to run the Windows build via Wine were unstable and are not recommended.
