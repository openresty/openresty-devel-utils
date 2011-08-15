#!/usr/bin/env perl

use strict;
use warnings;

my $infile = shift or
    die "usage: $0 <infile>\n";

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
$s =~ s!<geshi[^\n>]*>\n*(.*?)</geshi>!
    my $v = $1; if ($v =~ /^ {0,3}\S/m) { $v =~ s/^/    /gm } "\n$v"!gmse;
$s =~ s{^https?://[^\s)(]+}{<$&>}gms;
$s =~ s/^'''([^\n]*?)'''/**$1**/gms;
while ($s =~ s/^(\S[^\n]*?)'''([^\n]*?)'''/$1**$2**/gms) {}
$s =~ s/^''([^\n]*?)''/*$1*/gms;
while ($s =~ s/^(\S[^\n]*?)''([^\n]*?)''/$1*$2*/gms) {}
$s =~ s{^<code>([^\n]*?)</code>}{`$1`}gms;
while ($s =~ s{^(\S[^\n]*?)<code>([^\n]*?)</code>}{$1`$2`}gms) {}
$s =~ s/ \[\[ \# [^\|\]\[\n]* \| ( [^\]\n]+ ) \]\]/`$1`/gmsx;
$s =~ s{ \[ (https?://[^\|\]\[\s]*) \s+ ( [^\]]+ ) \]}
    {[$2]($1)}gmsx;
$s =~ s/ \[\[ [^\|\]\[]* \| ( [^\]]+ ) \]\]/`$1`/gmsx;
while ($s =~ s{^(\S[^\n]*?)?([^\(\<\n])(https?://[^\s)(\n]+)}{$1$2<$3>}gms) {}
$s =~ s/^\[\[(\w+)\]\]/`$1`/gsm;
while ($s =~ s/^(\S[^\n]*?)\[\[(\w+)\]\]/$1`$2`/smg) {}
$s =~ s{^(https?://[^\s)(\n]+)}{<$1>}gms;
$s =~ s/^\# (\S)/1. $1/gms;
$s =~ s/^: (\S)/\t$1/gms;
$s =~ s/^\*\* (\S)/\t* $1/gms;
$s =~ s/^\*\*\* (\S)/\t\t* $1/gms;


print $s;

