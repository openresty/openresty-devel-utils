NAME
====

openresty-devel-utils - Development utilities for NGINX and OpenResty

Table of Contents
=================

* [NAME](#name)
* [Description](#description)
    * [ngx-build](#ngx-build)
    * [reindex](#reindex)
* [Copyright & License](#copyright--license)

Description
===========

This project provides some common tools for Nginx module
development.

```console
cd /path/to/some/module

# generate short-name symlinks for src/ngx_http_*.[ch]
ngx-links src

# build a custom nginx 1.0.5 (with cache)
ngx-build 1.0.5 \
    --add-module=`pwd` \
    --with-debug \
    <other nginx configure options go here>

export PATH=`pwd`/work/nginx/sbin:$PATH
nginx -V

# build a custom nginx 1.0.5 (without cache)
ngx-build -f 1.0.5 \
    --add-module=`pwd` \
    --with-debug \
    <other nginx configure options go here>
```

ngx-build
---------

The `ngx-build` tool is used by almost all our NGINX C module projects for everyday development,
for example, [lua-nginx-module](https://github.com/openresty/lua-nginx-module/).

First of all, you should always add the directory of this tool to your `PATH` system environment,
like this:

```bash
export PATH=/path/to/openresty-devel-utils:$PATH
```

Replace the placeholder `/path/to/` with the real path in your system. You'd better put this line
in your `~/.bashrc` file so that you can always have it.

Usually, we have a `util/build.sh` shell script in each of the NGINX C module project's source
tree, as in:

https://github.com/openresty/lua-nginx-module/blob/master/util/build.sh

And then we create a local shell script, usually called something like `build13`
(the number `13` means nginx 1.13.x) which contains the following:

```bash
#!/usr/bin/env bash

#export NGX_BUILD_DISABLE_NO_POOL=1
#export NGX_BUILD_NO_DEBUG=1

export NGX_BUILD_DTRACE=1
export NGX_BUILD_CC_OPTS="-O1 -I/opt/systemtap/include"

export LUAJIT=/usr/local/openresty-debug/luajit
export LUAJIT_LIB=$LUAJIT/lib
export LUAJIT_INC=$LUAJIT/include/luajit-2.1

export PCRE=/usr/local/openresty/pcre
export PCRE_LIB=$PCRE/lib
export PCRE_INC=$PCRE/include

export OPENSSL=/usr/local/openresty-debug/openssl
export OPENSSL_INC=$OPENSSL/include
export OPENSSL_LIB=$OPENSSL/lib

export NGX_BUILD_CC="gcc"
export NGX_BUILD_JOBS=9

# build using nginx 1.13.6
exec ./util/build.sh 1.13.6
```

The `ngx-build` script will download the specified version of the nginx source release tarball from
nginx.org and caches it under `~/work/` in the local file system, and then builds everything under
`./buildroot/nginx-1.13.6/` and finally, if everything builds fine, it will installs the nginx into
`./work/nginx/`.

The `build13` shell script above assumes that you have installed the `openresty-debug`, `openresty-pcre-devel`,
and `openresty-openssl-debug-devel` pre-built packages (along with their `-debuginfo` packages)
from OpenResty's [official Linux package repositories](https://openresty.org/en/linux-packages.html).
You can surely specify your own local builds of LuaJIT, PCRE, and/or OpenSSL. Just change the path values for
the corresponding system environment variables accordingly.

The `build13` script should never get checked into the git repository. And it should be different for each developer and is subject to frequent edits during
everyday development.

Only those system environments whose names start with the `NGX_BUILD_` prefix are supported by the
`ngx-build` script. Otherwise the environments are interpreted by the `util/build.sh` script of
each nginx C module project.

`ngx-build` always tries to build things incrementally, so it is usually very fast to run. If the previous run of nginx's `./configure`
script fails, then subsequent `ngx-build` invokes would always fail with the following error message:

```
make: *** No rule to make target 'build', needed by 'default'.  Stop.
failed to run command "make -j9"
```

This is completely normal, and to fix this, you need to update the last modified time stamp of your
`config` file like below:

```
touch config
```

Then `ngx-build` will see that the `Makefile` is older than `config` file and will try running nginx's `./configure` script again.

To combine these 2 steps together, we get

```bash
touch config && ./build13
```

Do not touch the `config` file in other cases since it would only slow down your build by compiling everything from scratch.

One thing to note here is that `ngx-build` never tries to add RPATH to the resulting nginx build, so it is each nginx C module
project's responsibility to do that if it is desired. It is usually done in the `util/build.sh` script of each project, as in:

https://github.com/openresty/lua-nginx-module/blob/master/util/build.sh#L34

Sometimes, the project may prefer not hard-coding an RPATH setting for particular dependency libraries like LuaJIT. For example,
the `lua-nginx-module` project only adds RPATH for OpenSSL, PCRE, and Libdrizzle in its `util/build.sh` script:

https://github.com/openresty/lua-nginx-module/blob/master/util/build.sh#L34

And it intentionally omits the RPATH for LuaJIT. This is because the developers of `lua-nginx-module` usually want to run
different builds of LuaJIT when running the test suite in different "test modes" of the Test::Nginx::Socket test scaffold without
the burden of re-linking the local nginx binary.

For example, when running the test suite with Valgrind, the developers of `lua-nginx-module` would set the system environment:

```bash
export LD_LIBRARY_PATH=/usr/local/openresty-valgrind/luajit/lib:$LD_LIBRARY_PATH
export TEST_NGINX_USE_VALGRIND=1
```

Here we use the LuaJIT shipped with OpenResty's official binary package `openresty-valgrind`, which enables the system allocator
which would only work atop Valgrind.

And for normal running modes, we should switch to another LuaJIT at runtime like below:

```bash
export LD_LIBRARY_PATH=/usr/local/openresty-debug/luajit/lib:$LD_LIBRARY_PATH
```

or when running the tests in the "benchmark" test mode, switch to a non-debug build of LuaJIT:

```bash
export LD_LIBRARY_PATH=/usr/local/openresty/luajit/lib:$LD_LIBRARY_PATH
```

Such runtime environment settings are conventionally put into a custom `./go` script at the root
of each nginx C module project's source tree, as in:

```bash
#!/usr/bin/env bash

export PATH=$PWD/work/nginx/sbin:/opt/systemtap/bin:$PATH

export LD_LIBRARY_PATH=/usr/local/openresty/luajit/lib:$LD_LIBRARY_PATH
#export LD_LIBRARY_PATH=/usr/local/openresty-valgrind/luajit/lib:$LD_LIBRARY_PATH
#export TEST_NGINX_USE_VALGRIND=1

export TEST_NGINX_SLEEP=0.002
export TEST_NGINX_PORT=8080
export TEST_NGINX_TIMEOUT=5
export TEST_NGINX_RESOLVER=8.8.4.4

which nginx
nginx -V
ldd work/nginx/sbin/nginx|grep luajit

exec prove -I../test-nginx/lib "$@"
```

It is very convenient to comment or uncomment the environment settings on demand. It is
much harder to mess your environment settings up.

Once the `./go` script is ready, you can always run `./go -r t` to run the full test suite
or `./go t/foo.t` to run a particular test file like `t/foo.t` (one can choose to run
only an individual test block only in the `foo.t` file by temporarily inserting a
`--- ONLY` section to that test block).

Those system environments whose names start with `TEST_NGINX_` are those supported
by the `Test::Nginx::Socket` test scaffold. You can find more details about this test scaffold
here:

https://openresty.gitbooks.io/programming-openresty/content/testing/

The `ngx-build` script would try patching the nginx core with patches in the
[openresty/openresty](https://github.com/openresty/openresty) and
[openresty/no-pool-nginx](https://github.com/openresty/no-pool-nginx)
github repos which are checked out locally as the `../openresty/` and `../no-pool-nginx/`
directories, respectively. But such patching process
only happens when the local `./buildroot/nginx-*` directory does not exist. So
if you want to enforce patching the nginx core all over again (for example, when you
toggle the values of the system environments `NGX_BUILD_NO_DEBUG`, `NGX_BUILD_DTRACE`,
and/or ` NGX_BUILD_DISABLE_NO_POOL`, then you must re-apply the patches for the nginx
core. You can do that by wiping out the `./buildroot/nginx-*` directories like this:

```bash
rm -rf buildroot/nginx-*
```

and then run the `./build13` script previously mentioned.

The Travis CI build files for most of our nginx C module projects are also making use of
this `ngx-build` tool (through `util/build.sh` script, of course) and can serve as more
examples. See for instance:

https://github.com/openresty/lua-nginx-module/blob/master/.travis.yml

[Back to TOC](#table-of-contents)

reindex
---------

The `reindex` is used to unify the index format of the test files of each module under
[Openresty](https://github.com/openresty). These test files are written based on
[Test::Nginx](https://github.com/openresty/test-nginx). And you can install this tool like
[ngx-build](#ngx-build).

The `reindex` will unify the index format of each test file according to the following conditions:
* Ensure that all test cases starting with `=== TEST {$index}` are sequentially numbered starting from `${begin_index}`.
* Ensure 3 newlines between test cases.
* Ensure that there is a line break between the first test case and the separator(`__DATA__` or `__END__`).

You can run `reindex` like this:
```
# -b: the begin index of test cases in each test file.
reindex -b 1 /path/to/module/t*.t
```

[Back to TOC](#table-of-contents)

Copyright & License
===================

The bundle itself is licensed under the 2-clause BSD license.

Copyright (c) 2011-2017, Yichun "agentzh" Zhang (章亦春) <agentzh@gmail.com>, OpenResty Inc.

This module is licensed under the terms of the BSD license.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[Back to TOC](#table-of-contents)

