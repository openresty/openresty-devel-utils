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

#warn sprintf "%02x (%s)", ord(substr($s, 0, 1)), substr($s, 0, 1);
#warn sprintf "%02x (%s)", ord(substr($s, 1, 1)), substr($s, 1, 1);
#warn sprintf "%02x (%s)", ord(substr($s, 2, 1)), substr($s, 2, 1);
$s =~ s/^\x{ef}\x{bb}\x{bf}//s;

$s =~ s/^=\s+(\S[^\n]*?)\s+=$/"$1\n" . ("=" x length $1)/gmse;
$s =~ s/^==\s+(\S[^\n]*?)\s+==$/"$1\n" . ("-" x length $1)/gmse;
$s =~ s/^===\s+(\S[^\n]*?)\s+===$/### $1\n/gms;
$s =~ s/^====\s+(\S[^\n]*?)\s+====$/#### $1\n/gms;
$s =~ s/^=====\s+(\S[^\n]*?)\s+=====$/##### $1\n/gms;
$s =~ s!<geshi[^\n>]*>\n*(.*?)</geshi>!
    my $v = $1; if ($v =~ /^ {0,3}\S/m) { $v =~ s/^/    /gm } "\n$v"!gmse;
$s =~ s{^https?://[^\s)(]+}{<$&>}gms;
$s =~ s/^'''([^\n]*?)'''/**$1**/gms;
while ($s =~ s/^(\S[^\n]*?)'''([^\n]*?)'''/$1**$2**/gms) {}
$s =~ s/^''([^\n]*?)''/*$1*/gms;
while ($s =~ s/^(\S[^\n]*?)''([^\n]*?)''/$1*$2*/gms) {}
$s =~ s{^<code>([^\n]*?)</code>}{`$1`}gms;
while ($s =~ s{^(\S[^\n]*?)<code>([^\n]*?)</code>}{$1`$2`}gms) {}
$s =~ s! \[\[ (\# [^\|\]\[\n]*) \| ( [^\]\n]+ ) \]\]!
    my ($link, $tag) = ($1, $2);
    $link =~ s/ /_/g;
    $link =~ s/[\$\(\)]/sprintf(".%02x", ord($&))/ge;
    if ($name) {
        "[$tag](http://wiki.nginx.org/$name$link)"
    } else {
        "`$tag`"
    }
    !gmsxe;
$s =~ s{ \[ (https?://[^\|\]\[\s]*) \s+ ( [^\]]+ ) \]}
    {[$2]($1)}gmsx;

$s =~ s! \[\[ ([^\|\]\[]*) \| ( [^\]]+ ) \]\]
    !
        my ($tag, $link) = ($2, $1);
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
    !gmsxe;

while ($s =~ s{^(\S[^\n]*?)?([^\(\<\n])(https?://[^\s)(\n]+)}{$1$2<$3>}gms) {}
$s =~ s{^\[\[(\w+)\]\]}{\[$1](http://wiki.nginx.org/$1)}gsm;
while ($s =~ s{^(\S[^\n]*?)\[\[(\w+)\]\]}{$1\[$2](http://wiki.nginx.org/$2)}smg) {}
$s =~ s{^(https?://[^\s)(\n]+)}{<$1>}gms;
$s =~ s/^\# (\S)/1. $1/gms;
$s =~ s/^: (\S)/\t$1/gms;
$s =~ s/^\*\* (\S)/\t* $1/gms;
$s =~ s/^\*\*\* (\S)/\t\t* $1/gms;


print $s;

