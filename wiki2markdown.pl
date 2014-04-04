#!/usr/bin/env perl

use strict;
use warnings;

my $infile = shift or
    die "usage: $0 <infile>\n";

my $name;
if ($infile =~ m{([^/]+)\.wiki$}) {
    $name = $1;
    if ($name !~ /^[A-Z]/) {
        undef $name;
    } else {
        warn "Using name $name...\n";
    }
}

open my $in, $infile or
    die "cannot open $infile for reading: $!\n";

my $s = do { local $/; <$in> };

close $in;

my %github_mods = (
    HttpSetMiscModule => 'agentzh/set-misc-nginx-module',
    HttpEchoModule => 'agentzh/echo-nginx-module',
    HttpLuaModule => 'chaoslawful/lua-nginx-module',
    HttpMemcModule => 'agentzh/memc-nginx-module',
    HttpRedis2Module => 'agentzh/redis2-nginx-module',
    HttpChunkinModule => 'agentzh/chunkin-nginx-module',
    HttpArrayVarModule => 'agentzh/array-var-nginx-module',
    HttpSRCacheModule => 'agentzh/srcache-nginx-module',
    HttpEncryptedSessionModule => 'agentzh/encrypted-session-nginx-module',
    HttpHeadersMoreModule => 'agentzh/headers-more-nginx-module',
    HttpDrizzleModule => 'chaoslawful/drizzle-nginx-module',
    HttpRdsJsonModule => 'agentzh/rds-json-nginx-module',
    HttpRdsCsvModule => 'agentzh/rds-csv-nginx-module',
    LuaRdsParser => 'agentzh/lua-rds-parser',
    LuaRedisParser => 'agentzh/lua-redis-parser',
);

my %official_mods = (
    HttpProxyModule => 'http/ngx_http_proxy_module',
    HttpFastcgiModule => 'http/ngx_http_fastcgi_module',
    HttpCoreModule => 'http/ngx_http_core_module',
    HttpUpstreamModule => 'http/ngx_http_upstream_module',
    HttpRewriteModule => 'http/ngx_http_rewrite_module',
    HttpMemcachedModule => 'http/ngx_http_memcached_module',
    HttpHeadersModule => 'http/ngx_http_headers_module',
    HttpLogModule => 'http/ngx_http_log_module',
    HttpAccessModule => 'http/ngx_http_access_module',
    EventsModule => 'ngx_core_module',
    HttpFcgiModule => 'http/ngx_http_fastcgi_module',
    HttpMapModule => 'http/ngx_http_map_module',
    HttpGzipModule => 'http/ngx_http_gzip_module',
    HttpSsiModule => 'http/ngx_http_ssi_module',
    HttpAdditionModule => 'http/ngx_http_addition_module',
);

sub gen_anchor {
    my $link = shift;
    $link =~ s/[^-\w_ ]//g;
    $link =~ s/ /-/g;
    lc($link);
}

sub gen_link {
    my $link = shift;
    if ($link =~ /(Http|Events|Lua)[A-Z]\w+/) {
        my $type = $1;
        my $mod = $&;
        if (my $name = $github_mods{$mod}) {
            $link =~ s/\#(.+)/'#' . gen_anchor($1)/e;
            $link =~ s{\Q$mod\E}{http://github.com/$name};
            $name =~ s{^\w+/}{}g;
            return $link, $name;
        }

        if (my $name = $official_mods{$mod}) {
            if ($link =~ s/\$/var_/) {
                $link =~ s/_[A-Z]+$/_/;
            }
            $link =~ s{\Q$mod\E}{http://nginx.org/en/docs/$name.html};
            $name =~ s{^\w+/}{}g;
            return $link, $name;
        }
    }
    return undef;
}

sub gen_toc ($) {
    my $s = shift;
    my $toc = '';
    open my $in, "<", \$s or die $!;
    while (<$in>) {
        if (/^(=+)\s+(\S[^\n]*?)\s+\1$/) {
            my ($prefix, $title) = ($1, $2);
            my $anchor = gen_anchor($title);
            my $level = length($prefix) - 1;
            $toc .= ("    " x $level) . "* [$title](#$anchor)\n";
        }
    }
    return $toc;
}

my $toc = gen_toc($s);
#warn $toc;

#warn sprintf "%02x (%s)", ord(substr($s, 0, 1)), substr($s, 0, 1);
#warn sprintf "%02x (%s)", ord(substr($s, 1, 1)), substr($s, 1, 1);
#warn sprintf "%02x (%s)", ord(substr($s, 2, 1)), substr($s, 2, 1);
$s =~ s/^\x{ef}\x{bb}\x{bf}//s;

$s =~ s/^=\s+(\S[^\n]*?)\s+=$/"$1\n" . ("=" x length $1)/gmse;
$s =~ s/^==\s+(\S[^\n]*?)\s+==$/"$1\n" . ("-" x length $1)/gmse;
$s =~ s/^===\s+(\S[^\n]*?)\s+===$/### $1\n/gms;
$s =~ s/^====\s+(\S[^\n]*?)\s+====$/#### $1\n/gms;
$s =~ s/^=====\s+(\S[^\n]*?)\s+=====$/##### $1\n/gms;
$s =~ s!<geshi([^\n>]*)>\n*(.*?)</geshi>!
    my ($lang, $v) = ($1, $2);
    if ($lang =~ /lang="?(\w+)/) {
        $lang = $1;
        if ($lang eq 'text') {
            undef $lang;
        }

    } else {
        undef $lang;
    }
    if ($v =~ /^ {0,3}\S/m) { $v =~ s/^/    /gm }
    my $out = "\n$v";
    if ($lang) {
        $out = "```$lang\n$out```";
    }
    $out;
    !gmse;
$s =~ s{^https?://[^\s)(]+}{<$&>}gms;
$s =~ s/^'''([^\n]*?)'''/(my $v = $1) =~ s{<}{\&lt;}g; $v =~ s{>}{\&gt;}g; "**$v**"/egms;
while ($s =~ s/^(\S[^\n]*?)'''([^\n]*?)'''/$1**$2**/gms) {}
$s =~ s/^''([^\n]*?)''/my $v = $1; $v =~ s{<}{\&lt;}g; $v =~ s{>}{\&gt;}g; "*$v*"/egms;
while ($s =~ s/^(\S[^\n]*?)''([^\n]*?)''/my ($p, $v) = ($1, $2); $v =~ s{<}{\&lt;}g; $v =~ s{>}{\&gt;}g; "$p*$v*"/egms) {}
$s =~ s{^<code>([^\n]*?)</code>}{`$1`}gms;
while ($s =~ s{^(\S[^\n]*?)<code>([^\n]*?)</code>}{$1`$2`}gms) {}
$s =~ s! \[\[ (\# [^\|\]\[\n]*) \| ( [^\]\n]+ ) \]\]!
    my ($link, $tag) = ($1, $2);
    $link = gen_anchor($link);
    if ($link eq 'name') {
        $link = "readme";
    }
    #$link =~ s/[\$\(\)]/sprintf(".%02x", ord($&))/ge;
    "[$tag](#$link)"
    !gmsxe;
$s =~ s{ \[ (https?://[^\|\]\[\s]*) \s+ ( [^\]]+ ) \]}
    {[$2]($1)}gmsx;

$s =~ s! \[\[ ([^\|\]\[]*) \| ( [^\]]+ ) \]\]
    !
        my ($tag, $link) = ($2, $1);
        my ($newlink, $modname) = gen_link($link);
        if (defined $newlink) {
            #warn "$tag $newlink";
            "[$tag]($newlink)";

        } else {
            warn "$tag $link";
            $link =~ s/ /_/g;
            $link =~ s/[\$\(\)]/sprintf(".%02x", ord($&))/ge;
            #warn "link $link $name";
            if ($link =~ /^\#/) {
                if ($name) {
                    "[$tag](http://wiki.nginx.org/$name$link)"
                } else {
                    "`$tag`"
                }

            } else {
                "[$tag](http://wiki.nginx.org/$link)"
            }
        }
    !gmsxe;

while ($s =~ s{^(\S[^\n]*?)?([^\(\<\n])(https?://[^\s)(\n]+)}{$1$2<$3>}gms) {}
#$s =~ s{^\[\[(\w+)\]\]}{my $name = $1; my $link = gen_link($name); warn "!!! $name"; defined($link) ? "[$name]($link)" : "[$name](http://wiki.nginx.org/$name)"}gsme;
while ($s =~ s{^(\S[^\n]*?)\[\[(\w+)\]\]}{
    my ($prefix, $name) = ($1, $2);
    my ($link, $modname) = gen_link($name);
    if (!defined $link) {
        warn "$name";
    }
    defined($link) ? "$prefix\[$modname]($link)" : "$prefix\[$name](http://wiki.nginx.org/$name)"
}smge) {}
$s =~ s{^(https?://[^\s)(\n]+)}{<$1>}gms;
$s =~ s/^\# (\S)/1. $1/gms;
$s =~ s/^: (\S)/\t$1/gms;
$s =~ s/^\*\* (\S)/\t* $1/gms;
$s =~ s/^\*\*\* (\S)/\t\t* $1/gms;
$s =~ s/\&#91;/[/g;
$s =~ s{^<(https?://\S+\/([^/\s]+)\.(?:png|jpg|gif))>$}{my ($name, $url) = ($2, $1); $name =~ s/[^a-zA-Z0-9]+/ /; qq/![$name]($url "$name")/}gmse;

if (!($s =~ s/^(Name\n=+\n)(.*?)(^[^\n]+\n=+\n)/$1$2Table of Contents\n=================\n\n$toc\n$3/smi)) {
    warn "WARNING: Failed to insert TOC.\n";

} else {
    my $i = 0;
    $s =~ s{^[^\n]+\n[=-]+\n}{ ++$i > 5 ? "[Back to TOC](#table-of-contents)\n\n$&" : $&}gesm;
}

$s =~ s{^```(\w+)\n(.*?)^```\n}{
    my ($lang, $out) = ($1, $2);
    $out =~ s/^    //gm;
    "```$lang\n" . $out . "```\n"
}gesm;

print "<!---\nDon't edit this file manually! Instead you should generate it ",
    "by using:\n    wiki2markdown.pl $infile\n-->\n\n";
print $s;

