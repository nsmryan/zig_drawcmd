load zig-out/lib/libzigdrawcmd.so

package require drawcmd

puts [namespace children drawcmd]
drawcmd::State fromBytes state [drawcmd::State call init 800 600]

puts pos
set pos [drawcmd::Pos call init 10 10]
puts color
set color [drawcmd::Color call init 0 128 0 255]
puts push
state call push [drawcmd::DrawCmd call fill $pos $color]
puts filled
set sprite [drawcmd::Sprite call init 0 0]
puts sprite
set pos [drawcmd::Pos call init 4 4]
set white [drawcmd::Color call init 255 255 255 255]
state call push [drawcmd::DrawCmd call sprite $sprite $white $pos]
puts present
state call present

after 1000

