#!/usr/bin/perl
# check a directory or ARGV for a list of mp3 and ogg
# group mp3 and ogg into coherent units
# generate an HTML full of audio tag

#   Copyright 2014 Abram Hindle
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governin permissions and
#   limitations under the License.

use strict;
use JSON;
use HTML::Template;

my $json = JSON->new->allow_nonref;
my $playlistjson = "playlist.json";
my $playlist = undef;
my $dontwrite = 0;
if (@ARGV && $ARGV[0] =~ 'json') {
    local $/;
    open( my $fh, '<', $playlistjson );
    my $json_text   = <$fh>;
    $playlist = decode_json( $json_text );
    close($fh);
    $dontwrite = 1;
} else {
    $playlist = (@ARGV)?import_files(@ARGV):import_files(<*.ogg>,<*.mp3>);
}

unless ($dontwrite) {
    open(my $fd,">", $playlistjson);
    print  $fd $json->pretty->encode( $playlist ); # pretty-printi
    close($fd);
}

open(my $fd,">", "index.html");
my $t = HTML::Template->new( filehandle => *DATA, die_on_bad_params => 0,  default_escape => "HTML");
$t->param(%{$playlist});
print $fd $t->output;
close($fd);

sub import_files { 
    my @files = @_;
    warn join("\t",@files);
    my %out = ();
    my @order = ();
    my %seen = ();
    for my $file (@files) {
        if ($file =~ /^(.*)\.(ogg|mp3)$/i) {
            my $bname = $1;
            my $base = $2;
            warn $bname;
            $out{$bname}->{$base} = $file;
            $out{$bname}->{bname} = $bname;
            unless (exists $seen{$bname}) {
                $seen{$bname} = 1;
                push @order, $bname;
            }
        }
    }
    for my $key (keys %out) {
        my $name = $key;
        $name =~ s/[_\-.]/ /g;
        $out{$key}->{description} = $name;
    }
    my @list = ();
    for my $key (@order) {
        push @list, $out{$key};
    }
    return {
            name => "",
            tracks => \@list
           }
}
1;
__DATA__
<!DOCTYPE html>
<html>
<head>
<title><TMPL_VAR NAME="name"></title>
<meta charset="UTF-8"/>
</head>
<!--
#   Copyright 2014 Abram Hindle
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governin permissions and
#   limitations under the License.
-->
<style>
.box {
    padding: 0.5em;
    margin-left: auto;
    margin-right: auto;
}
.track {
    background: linear-gradient(white, grey); /* Standard syntax */
    padding: 0.5em;
    margin-left: auto;
    margin-right: auto;
}
audio {

}
.tracktitle {
    margin-left: auto;
    margin-right: auto;
}
.dl {
    margin-left: auto;
    margin-right: auto;
}
.box {
    margin-left: auto;
    margin-right: auto;
    width: 20em;
}
.tbox {
    margin-left: auto;
    margin-right: auto;
    border: 0.1em dashed;
    padding: 1em;
}
</style>
<script>
window.onload = function() {
    var playAll = document.getElementById("playall");
    var playContext = undefined;
    function audioListener(audio) {
        return function() {
            var audios = document.getElementsByTagName("audio");
            for (var i = 0; i < audios.length; i++) {
                if (audios[i]===audio) {
                    var j = i+1;
                    if (j < audios.length) {
                        audios[j].play();
                        break;
                    }
                }
            }
        };
    };
    playAll.onclick = function() {
        var audios = document.getElementsByTagName("audio");
        // install play listeners
        for (var i = 0; i < audios.length; i++) {
            audios[i].onended = audioListener(audios[i]);
        }
        audios[0].play();
    };
};
</script>
<body>
   <div class="metadata">
      <h1><TMPL_VAR NAME="name"></h1>
      <div class="metadesc">
      <TMPL_VAR ESCAPE="NONE" NAME="description">
      </div>
   </div>
   <div class="box">
   <div class="track">
        <button id="playall">Play all tracks</button>
   </div>
   <TMPL_LOOP NAME="tracks">
      <div class="track">
        <div class="tracktitle">
            <TMPL_VAR name="description">
        </div>
        <audio id="<TMPL_VAR name="bname">" controls  preload="none">
           <TMPL_IF name="mp3">
           <source src="<TMPL_VAR name="mp3">" type="audio/mpeg" />
           </TMPL_IF>
           <TMPL_IF name="ogg">
           <source src="<TMPL_VAR name="ogg">" type="audio/ogg" />
           </TMPL_IF>
        </audio>
        <div class="dl">
           Shift-click to DL the 
           <TMPL_IF name="ogg">
           <a href="<TMPL_VAR name="ogg">">OGG</a>
           </TMPL_IF>

           <TMPL_IF name="mp3">
           <a href="<TMPL_VAR name="mp3">">MP3</a>
           </TMPL_IF>
        </div>
      </div>
   </TMPL_LOOP>
   </div>
   <div class="tbox">
   <h3>Downloads</h3>
   <div>
   <TMPL_LOOP NAME="tracks">
           <TMPL_IF name="ogg">
           <a href="<TMPL_VAR name="ogg">"><TMPL_VAR name="ogg"></a><br/>
           </TMPL_IF>
   </TMPL_LOOP>
   </div>
   <div>
   <TMPL_LOOP NAME="tracks">
           <TMPL_IF name="mp3">
           <a href="<TMPL_VAR name="mp3">"><TMPL_VAR name="mp3"></a><br/>
           </TMPL_IF>
   </TMPL_LOOP>
   </div>
   </div>
</body>
</html>
