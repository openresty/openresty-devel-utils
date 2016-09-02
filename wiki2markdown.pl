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
    HttpSetMiscModule => 'openresty/set-misc-nginx-module',
    HttpEchoModule => 'openresty/echo-nginx-module',
    HttpLuaModule => 'openresty/lua-nginx-module',
    HttpMemcModule => 'openresty/memc-nginx-module',
    HttpRedis2Module => 'openresty/redis2-nginx-module',
    HttpChunkinModule => 'agentzh/chunkin-nginx-module',
    HttpArrayVarModule => 'openresty/array-var-nginx-module',
    HttpSRCacheModule => 'openresty/srcache-nginx-module',
    HttpEncryptedSessionModule => 'openresty/encrypted-session-nginx-module',
    HttpHeadersMoreModule => 'openresty/headers-more-nginx-module',
    HttpDrizzleModule => 'openresty/drizzle-nginx-module',
    HttpRdsJsonModule => 'openresty/rds-json-nginx-module',
    HttpRdsCsvModule => 'openresty/rds-csv-nginx-module',
    LuaRdsParser => 'openresty/lua-rds-parser',
    LuaRedisParser => 'openresty/lua-redis-parser',
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
    if ($link =~ /^[A-Z][a-z]+_[A-Z][a-z]+/) {
        $link =~ s/_/-/g;
    }
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

my (%inline_toc, %inline_backtotoc);
my @inline_toc_titles;
sub gen_toc ($) {
    my $s = shift;
    while ($s =~ /^(=+)\s+(\S[^\n]*?)\s+\1\s+<!--\s*inline-toc\s*-->/gsm) {
        my ($prefix, $title) = ($1, $2);
        $inline_toc{$title} = '';
        #warn "inline toc: $prefix: $title";
        push @inline_toc_titles, $title;
    }
    my $exit_level;
    my $toc_insert_title;
    my $toc = '';
    my $prev_inline_subtitle;
    open my $in, "<", \$s or die $!;
    while (<$in>) {
        if (/^(=+)\s+(\S[^\n]*?)\s+\1$/) {
            my ($prefix, $title) = ($1, $2);

            if (defined $prev_inline_subtitle) {
                #warn "insert: $title => $toc_insert_title\n";
                $inline_backtotoc{$title} = $toc_insert_title;
                undef $prev_inline_subtitle;
            }

            my $anchor = gen_anchor($title);
            my $level = length($prefix) - 1;
            if (defined $inline_toc{$title}) {
                $exit_level = $level;
                $toc_insert_title = $title;

            } elsif (defined $exit_level) {
                if ($level <= $exit_level) {
                    undef $exit_level;

                } else {
                    my $inlined_toc = ("    " x ($level - $exit_level - 1))
                                      . "* [$title](#$anchor)\n";
                    $inline_toc{$toc_insert_title} .= $inlined_toc;
                    $prev_inline_subtitle = 1;
                    #warn "inlined toc: $inlined_toc";
                    next;
                }
            }
            $toc .= ("    " x $level) . "* [$title](#$anchor)\n";
        }
    }

    if ($prev_inline_subtitle) {
        $inline_backtotoc{"__eof__"} = $toc_insert_title;
        undef $prev_inline_subtitle;
    }
    return $toc;
}

my $toc = gen_toc($s);
#warn $toc;

#use Data::Dumper;
#warn Dumper(\%inline_backtotoc);

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
    if ($v =~ /^ {0,3}\S/ms) {
        $v =~ s/^/    /gms;
    }
    my $out = "\n$v";
    if ($lang) {
        $out = "```$lang\n$out```";
    }
    $out;
    !gmse;
$s =~ s{^(https?://[^\s\)\(]+)}{
            my $link = $1; my $punc = '';
            if ($link =~ m/[,.;:]$/) { $punc = chop $link; }
            "<$link>$punc"
        }gmse;
$s =~ s/^'''([^\n]*?)'''/(my $v = $1) =~ s{<}{\&lt;}g; $v =~ s{>}{\&gt;}g; "**$v**"/egms;
while ($s =~ s/^(\S[^\n]*?)'''([^\n]*?)'''/my ($p, $v) = ($1, $2); $v =~ s{<}{\&lt;}g; $v =~ s{>}{\&gt;}g; $v =~ s{\*}{\&#42;}g; "$p**$v**"/egms) {}
$s =~ s/^''([^\n]*?)''/my $v = $1; $v =~ s{<}{\&lt;}g; $v =~ s{>}{\&gt;}g; "*$v*"/egms;
while ($s =~ s/^(\S[^\n]*?)''([^\n]*?)''/my ($p, $v) = ($1, $2); $v =~ s{<}{\&lt;}g; $v =~ s{>}{\&gt;}g; $v =~ s{\*}{\&#42;}g; "$p*$v*"/egms) {}
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

while ($s =~ s{^(\S[^\n]*?)?([^\(\<\n])(https?://[^\s)(\n]+)}{
        my $prefix = "$1$2"; my $link = $3; my $punc = '';
        if ($link =~ /[,.;:]$/) { $punc = chop $link } "$prefix<$link>$punc"
    }egms) {}
#$s =~ s{^\[\[(\w+)\]\]}{my $name = $1; my $link = gen_link($name); warn "!!! $name"; defined($link) ? "[$name]($link)" : "[$name](http://wiki.nginx.org/$name)"}gsme;
while ($s =~ s{^(\S[^\n]*?)?\[\[(\w+|".*?")\]\]}{
    my ($prefix, $name) = ($1, $2);
    if (!defined $prefix) {
        $prefix = '';
    }
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
    $s =~ s{^([^\n]+)\n[=-]+\n}{
        my $title = $1;
        if (++$i <= 5) {
            # intact
            $&;

        } else {
            my $target = $inline_backtotoc{$title};
            if ($target) {
                #warn "HIT: $title => $target\n";

            } else {
                $target = "Table of Contents";
            }
            $target = gen_anchor($target);
            "[Back to TOC](#$target)\n\n$&";
        }
    }gesm;

    my $target = $inline_backtotoc{"__eof__"};
    if ($target) {
        $target = gen_anchor($target);
        $s .= "\n[Back to TOC](#$target)\n";
    }
}

$s =~ s{^```(\w+)\n(.*?)^```\n}{
    my ($lang, $out) = ($1, $2);
    $out =~ s/^    / /gms;
    $out =~ s/ +$//gms;
    "```$lang\n" . $out . "```\n"
}gesm;

$s =~ s{<!--\s*inline-toc\s*-->}{
    my $title = shift @inline_toc_titles;
    if (!defined $title) {
        die "Cannot find the corresponding section for the special comment \"$&\".\n";
    }
    my $toc = $inline_toc{$title};
    if (!defined $toc) {
        die "No TOC defined for section $title\n";
    }
    $toc
}egms;

while ($s =~ s{^(\S[^\n]*?)\[(\w+)\](?![\(`])}{$1\\[$2\\]}gms) {}

print "<!---\nDon't edit this file manually! Instead you should generate it ",
    "by using:\n    wiki2markdown.pl $infile\n-->\n\n";
print $s;

