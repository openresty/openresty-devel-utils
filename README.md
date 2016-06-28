NAME
====

nginx-devel-utils - Development utilities for NGINX and OpenResty

Table of Contents
=================

* [NAME](#name)
* [Description](#description)
* [generate short-name symlinks for src/ngx_http_*.[ch]](#generate-short-name-symlinks-for-srcngx_http_ch)
* [build a custom nginx 1.0.5 (with cache)](#build-a-custom-nginx-105-with-cache)
* [build a custom nginx 1.0.5 (without cache)](#build-a-custom-nginx-105-without-cache)
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

Copyright & License
===================

The bundle itself is licensed under the 2-clause BSD license.

Copyright (c) 2011-2016, Yichun "agentzh" Zhang (章亦春) <agentzh@gmail.com>, CloudFlare Inc.

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

