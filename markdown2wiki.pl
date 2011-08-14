#!/usr/bin/env perl

use strict;
use warnings;

my $infile = shift or
    die "Usage: $0 <infile>\n";

open my $in, $infile or
    die "Cannot open $infile for reading: $!\n";

my $s = do { local $/; <$in> };

$s =~ s/^([^\s=][^\n]*?)\n=+\n/= $1 =\n/smg;
$s =~ s/^([^\s=][^\n]*?)\n-+\n/== $1 ==\n/smg;
$s =~ s{^\* \*\*(Syntax|Default|Context|Phase):\*\* ([^\n]+)}
        {my ($k, $v) = ($1, $2); $v =~ s/`//g; "'''" . lcfirst($k) . ":''' ''$v''\n"}smge;
$s =~ s{^`([^`\n]*)`}{<code>$1</code>}smg;
while ($s =~ s{^([^`\n\s].*?)`([^\`\n]*)`}{$1<code>$2</code>}smg) {}
while ($s =~ s{^([^\*\s\n].*?)\*\*([^\n\*]*)\*\*}{$1'''$2'''}smg) {}
while ($s =~ s{^([^\*\s\n].*?)\*([-\w]*)\*}{$1''$2''}smg) {}
$s =~ s/^\t([^*\s])/: $1/gsm;
$s =~ s/^(?:\t\t\* )/*** /gsm;
$s =~ s/^(?:\t\* )/** /gsm;
$s =~ s{^[ \t]+\S[^\n]*(?:\n(?:\n+|[ \t]+[^\n]*))*}
    {my $v = $&; $v =~ s/\n+$/\n/; qq[<geshi lang="nginx">\n$v</geshi>\n]}smge;
$s =~ s{\n\n+<geshi}{\n<geshi}gsm;
$s =~ s{<code>(lua_need_request_body)</code>}{[[#$1|$1]]}gsm;
$s =~ s{<code>((?:content|rewrite|access|set)_by_lua(?:_file|\*)?)</code>}
    {my $v = $1; $v =~ s/\*$//; "[[#$v|$v]]"}gesm;
$s =~ s{<code>ngx\.(say|print|time|http_time|exit|send_header|redirect|exec|var\.VARIABLE|location\.capture(?:_multi)?)(?:\(\))?</code>}{[[#ngx.$1|ngx.$1]]}gsm;
$s =~ s/\n\n\n+/\n\n/gs;
$s =~ s{<(https?://[^>]+)>[ \t]*}{$1 }mgs;

print $s;

close $in;

