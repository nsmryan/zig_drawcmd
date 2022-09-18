load zig-out/lib/libzigdrawcmd.so

package require drawcmd
namespace import drawcmd::*

drawcmd::State fromBytes state [drawcmd::State call init 800 600]

set delay 500
for { set i 0 } { $i < 10 } { incr i } {
    set pos [drawcmd::Pos call init 10 10]
    set color [drawcmd::Color call init 0 128 0 255]
    state call push [drawcmd::DrawCmd call fill $pos $color]

    set key [state call lookupSpritekey player_standing_right]
    set numSprites [state call numSprites player_standing_right]
    set index [expr $i % $numSprites]
    set sprite [drawcmd::Sprite call init $index $key]
    set pos [drawcmd::Pos call init $i 4]
    set white [drawcmd::Color call init 255 255 255 255]
    state call push [drawcmd::DrawCmd call sprite $sprite $white $pos]

    state call present
    after $delay
}

