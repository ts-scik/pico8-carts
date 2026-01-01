pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--head trauma champ!!
--by scik

--main

--globals
--stage vars
curr_stage = 1  -- current level
curr_blocks = 0 -- current stage blocks
curr_score = 0  -- current stage score
start_stage = 1 -- start stage
num_stages = 10 -- # of stages
cleared = false -- beat game
--scoring
time_value = 0.50 -- pnts/second
life_value = 50.0 --pnts/life
ball_value = 5.0 -- pnts/ball
diff_mult  = 1.0 -- diff mult
diff_pen   = 0.0 -- diff penalty
--general state flags
playing = false  -- playing flag
menu = false     -- menu flag
startup = true   -- start screen
starttimer = 0
starttime = 2.5
--player values
---difficulty-modifiers
def_max_stg_time = 50
def_max_lives = 2
def_max_balls = 2
player_speed = 1.0 -- spd mult
ball_speed = 1.0   -- spd mult
max_stg_time = def_max_stg_time
max_lives = def_max_lives
max_balls = def_max_balls
---other
p_score = 0        --total score
stg_timer = max_stg_time+.99
p_lives = max_lives--curr lives
p_balls = max_balls--curr balls
last_balls =p_balls--ball holdr
last_lives =p_lives--life holdr
----map vars
ceil_y = 8 * 1  -- ceil map-y
floor_y= 8 * 14 -- floor map-y
l_wall = 8 * 1  -- lwall map-x
r_wall = 8 * 10 -- rwall map-x
----input vars
xin = 0 -- x-axis input
yin = 0 -- y-axis input
j_cancel = false -- jump cancel


--initialize stuff
function _init()
 sfx(14)
 --menu_init() --load menu
 --game_start() --start game
end


--handles per-frame update
function _update60()
 --force_clear() --tmp
 --update
 input()
 --flag switch
 if startup then
  starttimer += 1/60
  if starttimer > starttime then
   startup = false
   menu_init()
  end
 elseif playing then
  --game is happening...
  --let's check freeze stuff!
  frozen = false
  for fl_nam, fl_dat in pairs(frz_flags) do
   --iterate over frz flags
   if fl_dat.frz_flag then
    --current flag is true
    frz_helper(fl_nam)
    frozen = true
    break
   end
  end
  if not frozen then
   --normal gameplay
   player_update()
   ball_update()
   stage_timer_update()
  end
 elseif menu then
  --menu stuff
  menu_update()
 else
 --gameover screen
 --todo: add delay before exit
  if confirm then
   menu_init()
   menu_rdy = false
  end
 end
end


--handles all draw calls
function _draw()
 if startup then
  start_draw()
 elseif playing then
	 game_draw()
	elseif menu then
	 --menu draw
	 menu_draw()
	else
	--game over screen
	 game_over_draw()
	end
end


--updates stage timer
function stage_timer_update()
 stg_timer -= 1/60
 if stg_timer < 0 then
  p_balls = 0
  respawn()
 end
end


--gets input each frame
--stores result in xin / yin
function input()
 --confirm/cancel
 confirm = btn(4)
 cancel = btn(5)
 --x-axis
 xin = -tonum(btn(0)) + tonum(btn(1))
 --y-axis
 j_cancel = btn(2) or btn(5)
 if menu then
  --menu inputs
  yin = -tonum(btn(3)) + tonum(btn(2))
  -- menu_rdy
  if not menu_rdy
    and xin == 0 and yin == 0
    and not confirm
    and not cancel
    then
    -- if not menu_rdy,
    -- and not pressing buttons
   menu_rdy = true
  elseif not menu_rdy then
   yin = 0
   xin = 0
   confirm = false
   cancel = false
  elseif menu_rdy and(
    xin != 0 or yin != 0
    or confirm
    or cancel)
    then
    -- if menu_rdy,
    -- and pressing anything
   menu_rdy = false
  end
 else
  yin = -tonum(
   not j_cancel and (
     btn(3) or btn(4))
  )
 end
end


--draw the game!! hahaha
function game_draw()
 if not frz_flags.life.frz_flag then
  --normal gameplay
  --boilerplate
  cls(1)
  camera(0,0)
  map(0,0)
 
  --draw entities
  player_draw()
  ball_draw()
 
  --debug
  --debug_print()
  
  --score/life/ball display
  value_print()
 else
  --life frz screen
  cls(0)
  life_screen_draw()
 end
end


--returns current score mult
--is based on dip switch
--configurations
function get_score_mult()
 return (
  ball_speed_ind/4
  * (8-player_speed_ind)/4
 ) - ((p_x_hit_buff - 2)*0.1)
end


--returns current score penalty
--is based on dip switch
--configurations
function get_score_penalty()
 return (
  life_value * (def_max_lives - max_lives)
  + ball_value * (def_max_balls - max_balls)
 )
end


function start_draw()
 cls(0)
 rrectfill(28,40,69,50,2,13)
 print('scik gaming',
  42, 52, 7)
 print('make this for u',
  33, 60, 7)
 print('♥ 🐱🐱 ♥',
  43, 72, 14)
 print('  🐱 ',
  47, 72, 5)
  print('    🐱 ',
  47, 72, 0)
end


--for nulling out gamestate
function force_clear()
 playing = false --tmp
 menu = false --tmp
 p_score = 600 --tmp
 startup = false --tmp
 music(-1) --tmp
end
-->8
--player script

--sets up player variables
---takes optional start-map pos
def_p_x_hit_buff=2
p_x_hit_buff=2 --x hitbox-pad
function player_init()
 --coordinates
 sx = 5
 sy = 14
 p_x = sx * 8-- x-pos
 p_y = sy * 8-- y-pos
 p_xrem = 0  -- x-pos subpixel
 p_yrem = 0  -- y-pos subpixel
 --collisions
 p_width = 8    --x hitbox
 p_height = 8   --y hitbox
 p_y_hit_buff=0 --y hitbox-pad
 --anim
 p_spr = 1      --curr sprite
 p_state = 0    --curr state
 p_flip = false --spr flip flag
 p_frm = 0      --anim frame
 p_animtimer = 0--anim timer
 p_xoff = 0     --spr x offset
 --movement
 ----holders
 p_xvel = 0       --curr x-vel
 p_yvel = 0       --curr y-vel
 ---caps
 p_w_speed = 1.5  --walk x-spd
 p_jx_speed =0.75 --jump x-spd
 p_max_yvel = 3.5 --max y-vel
 ---accels
 p_w_acc = 0.5    --walk x-acc
 p_jx_acc = 0.1   --jump x-acc
 p_frict = 0.20   --x-friction
 p_upgrav = 0.2   --asc grav
 p_downgrav = 0.75--desc grav
 ---charge
 p_chrg_timer = 0 --chrg timer
 p_chrg_spd = 2.5 --chrg rate
 p_last_chrg = 0  --last y-vel
 --etc
 p_combo = 0
end


--per-frame player update
function player_update()
 --flip our sprite
 if xin < 0 then
  p_flip = true
 elseif xin > 0 then
  p_flip = false
 end
 
 --state machine
 ---- :states:
 ---- 0 -> stand
 ---- 1 -> walk
 ---- 2 -> charge
 ---- 3 -> jump
 if p_state == 0 then
  stand_state()
 elseif p_state == 1 then
  walk_state()
 elseif p_state == 2 then
  charge_state()
 elseif p_state ==3 then
  jump_state()
 end
end


--draws player on screen
function player_draw()
 spr(
  p_spr, p_x + p_xoff, p_y,
  1,1, p_flip
 )
end


--state for motionless player
function stand_state()
 --default sprite
 p_spr = 1
 
 --cancel update
 if not j_cancel and yin == 0 then
  block_jump = false
 end
 
 --transitions
 ----walk
 if xin != 0 then
  p_state = 1
 ----charge
 elseif yin == -1
   and not block_jump then
  p_state = 2
 end
end


--handle player walking
function walk_state()
 ----animation----
 --local anim constants
 walk_anim_fps = 5
 walk_anim_frms = 2
 walk_frm_1 = 2
 --frame timer
 p_anim_update(
  walk_anim_fps,
  walk_anim_frms
 )
 --update sprite
 p_spr = (p_frm + walk_frm_1)
 
 ----movement----
 --cancel update
 if not j_cancel and yin == 0then
  block_jump = false
 end
 
 if xin != 0 then
  p_xvel = mid(
    -p_w_speed,
    p_xvel + (xin * p_w_acc),
    p_w_speed)
 else
  p_friction()
 end
 p_xmove(p_xvel * player_speed)
 
 ----state transitions----
 --stand
 if p_xvel == 0 and xin == 0 then
  p_state = 0
  state_reset()
 --charge
 elseif yin == -1
   and not block_jump then
  p_state = 2
  state_reset()
 end
end


--player charging jump
function charge_state()
 ----animation----
 --local anim constants
 chrg_anim_fps = 15
 chrg_anim_frms = 4
 chrg_frm_1 = 4
 --frame timer
 p_anim_update(
  chrg_anim_fps,
  chrg_anim_frms
 )
 --update sprite
 p_spr = chrg_frm_1
 if(p_frm == 3) then
  p_xoff = 0
 else
  p_xoff = p_frm-1
 end
 
 ----movement----
 p_chrg_timer += (p_chrg_spd/60)
 p_friction()
 p_xmove(p_xvel * player_speed)
 
 ----state transitions----
 --jump
 if yin == 0 then
  if not frz_flags.start.frz_flag then
	  sfx(0)
	  p_state = 3
	  p_last_chrg = mid(
	    2.0,
	    (1+p_chrg_timer)^1.8,
	    p_max_yvel)
	  p_yvel = p_last_chrg
	  state_reset()
	 else
	  sfx(7)
	  p_state = 1
   p_last_chrg = 0
   state_reset()
	 end
 elseif j_cancel then
  p_state = 1
  p_last_chrg = 0
  state_reset()
  block_jump = true
 end
end


--handle jump state
function jump_state()
 ----animation----
 p_spr = 5
 
 ----movement----
 --y-accel
 if p_yvel < 0
   or j_cancel
   or yin != 0 then
  p_yvel -= p_downgrav
 else
  p_yvel -= p_upgrav
 end
 --x-accel
 if xin != 0 then
  p_xvel = mid(
    -p_jx_speed,
    p_xvel + (xin * p_jx_acc),
    p_jx_speed)
 end
 --move
 p_xmove(p_xvel * player_speed)
 p_ymove(-p_yvel)
 
 ----transitions----
 if p_y >= floor_y then
  --landing
  p_state = 1
  p_y = floor_y
  p_yvel = 0
  sfx(4)
  state_reset()
 end
end


-- updates player animation
-- takes two params:
-- anim_fps -> animation fps
-- anim_len -> # of anim frames
function p_anim_update(
  anim_fps, anim_len)
 -- increment timer
 p_animtimer += anim_fps/60
 -- if over, increment frame
 if p_animtimer > 1 then
  overage = flr(p_animtimer)
  p_animtimer -= overage
  p_frm += overage
 end
 -- constrain p_frm to anim_len
 p_frm = p_frm % (anim_len)
end


--apply player friction
function p_friction()
 --todo: this sucks
 sn = sgn(p_xvel)
 p_xvel -= (
   p_frict * sgn(p_xvel))
 if sgn(p_xvel) != sn then
  p_xvel = 0
 end
end


--move player on x-axis
-- amt -> movement amount in px
function p_xmove(amt)
 p_xrem += amt
 move = round(p_xrem)
 if move != 0 then
  p_xrem -= move
  sign = sgn(move)
  while move != 0 do
   if not p_collide_at(
     p_x+sign, p_y) then
    --no collision! moving
    p_x += sign
    move -= sign
   else
    --collision! break
    break
   end
  end
 end
end


--move player on x-axis
-- amt -> movement amount in px
function p_ymove(amt)
 p_yrem += amt
 move = round(p_yrem)
 if move != 0 then
  p_yrem -= move
  sign = sgn(move)
  while move != 0 do
   if not p_collide_at(
     p_x, p_y+sign) then
    --no collision! moving
    p_y += sign
    move -= sign
   else
    --collision! break
    break
   end
  end
 end
end


--check for collisions
function p_collide_at(x, y)
 --todo: is this bad?
 tile_tl = mget(x\8, y\8)
 tile_tr = mget((7+x)\8, y\8)
 tile_bl = mget(x\8, (7+y)\8)
 tile_br = mget((7+x)\8, (7+y)\8)
 if (
   tile_tl != 0
   or tile_tr != 0
   or tile_bl != 0
   or tile_br != 0) then
  --return to ground if head hit
  if p_yvel > 0
   and p_state == 3
   and (tile_tl == 32
     or tile_tr == 32
   ) then
   p_yvel = 0
  end
  return true
 end
 return false
end


--clears variables
--for end-of-state
function state_reset()
 p_chrg_timer = 0
 p_animtimer = 0
 p_xoff = 0
end
-->8
--ball script

--sets up the ball
---takes optional start-map pos
function ball_init(spos)
 --coordinates
 if spos == nil then
  spos = {6,8}
 end
 b_x = spos[1]*8 -- x-pos
 b_y = spos[2]*8 -- y-pos
 l_b_x = b_x  -- last x-pos
 b_xrem = 0   -- x-pos subpixel
 b_yrem = 0   -- y-pos subpixel
 --animation
 b_spr = 16   -- display sprite
 --collisions
 b_width = 8  -- x-width
 b_height = 8 -- y-height
 --movement
 ---holders
 b_vx = -0.5  -- x-velocity
 b_vy = 1     -- y-velocity
 ---caps
 b_maxfall = 3.5  --max y-speed
 b_x_minvel = 0.2 --min x-vel
 ---accels
 b_upgrav = 0.09   --asc grav
 b_downgrav = 0.09 --desc grav
 b_x_decc = 0.003 --x deccel
 ---rebound forces
 blk_top_bounce = -1.25
 blk_bottom_bounce = 0.05
 blk_min_x_bounce = 0.5
 min_x_head_frc = 1.0
 min_jump_frc = 2.5
 min_stand_frc = 2.0
 jump_frc_mult = 1.1
 ceil_bounce_frc = 0.1
end


--per-frame update for ball
function ball_update()
 ----movement--
 --store last x
 l_b_x = b_x
 
 --gravity
 if b_vy < 0 then
  b_vy += b_upgrav * ball_speed
 else
  b_vy += b_downgrav * ball_speed
 end
 b_vy = min(b_vy, b_maxfall)
 --move
 b_xmove(b_vx * ball_speed)
 b_ymove(b_vy * ball_speed)
 
 --wallbounce
 if ( ( b_x >= r_wall
        and b_vx > 0)
    or (b_x <= l_wall 
        and b_vx < 0) )
    then
  b_vx = -b_vx
  sfx(3)
 end
 --ceilbounce
 if b_y <= ceil_y then
  b_vy = ceil_bounce_frc
  sfx(3)
 end
 
 --x deccel
 sn = sgn(b_vx)
 b_vx = sn * max(
   b_x_minvel,
   abs(b_vx) - b_x_decc * ball_speed)

 --wall unstick
 --if b_x == l_b_x then
  --if b_x >= r_wall then
   --b_x -= 1
  --elseif b_x <= l_wall then
   --b_x += 1
  --end
 --end
end


--draws ball
function ball_draw()
 spr(b_spr, b_x, b_y)
end


--move ball on x-axis
-- amt -> movement amount in px
function b_xmove(amt)
 --get whole-px movement
 b_xrem += amt
 move = round(b_xrem)
 if move != 0 then
  --move if any whole-px
  b_xrem -= move
  sign = sgn(move)
  while move != 0 do
   --move one px at a time
   if not b_collide_at(
     b_x+sign, b_y) then
    --no collision! moving
    b_x += sign
    move -= sign
   else
    --collision! break
    break
   end
  end
 end
end


--move ball on y-axis
-- amt -> movement amount in px
function b_ymove(amt)
 b_yrem += amt
 b_move = round(b_yrem)
 if b_move != 0 then
  --move if any whole-px
  b_yrem -= b_move
  sign = sgn(b_move)
  while b_move != 0 do
   --move one px at a time
   if not b_collide_at(
     b_x, b_y+sign) then
    --no collision! moving
    b_y += sign
    b_move -= sign
   else
    --collision! break
    break
   end
  end
 end
end


--check for collisions
function b_collide_at(cx, cy)
 ----boilerplate----
 result = false --is_colliding
 b_coll = {
   x = cx,
   y = cy,
   w = b_width,
   h = b_height,
 }
 ----player collision----
 --local var
 p_coll = {
   x = p_x - p_x_hit_buff,
   y = p_y,
   w = p_width+(2*p_x_hit_buff),
   h = p_height,
 }
 --check player overlap
 if rect_rect_collision(
   p_coll, b_coll) then
  --reset combo
  p_combo = 0
  --if above, mark collision
  if cy + b_height-1 < p_y then
   result = true
  end
  --y-vel update
  if p_state == 3 then
   --player jumping
   b_vy = -max(
    min_jump_frc,
    p_last_chrg * jump_frc_mult
   )
   p_yvel = -0.01
  else
   --player grounded
   b_vy = -min_stand_frc
  end
  --x-vel update
  b_vx = (b_x - p_x)/8
  b_vx = (
    min(
     min_x_head_frc,
     abs(b_vx)
    ) * sgn(b_vx))
  --sfx
  sfx(2)
 end
 --check for map collision
 tiles = {
  {--tl
   ttype = mget(cx\8, cy\8),
   t_x = cx\8,
   t_y = cy\8,
  },
  {--tr
   ttype = mget((7+cx)\8, cy\8),
   t_x = (7+cx)\8,
   t_y = cy\8,
  },
  {--bl
   ttype = mget(cx\8, (7+cy)\8),
   t_x = cx\8,
   t_y = (7+cy)\8,
  }, 
  {--br
   ttype = mget(
     (7+cx)\8, (7+cy)\8),
   t_x = (7+cx)\8,
   t_y = (7+cy)\8,
  },
 }
 --check for duplicates
 --todo: why????
 dupe = {}
 for i = 1, #tiles-1, 1 do
  --for each tile exc. last,
  --store our tile
  c_t = tiles[i]
  for j = i+1, #tiles, 1 do
   --for each tile after c_t,
   --check dupe
   n_t = tiles[j]
   if c_t.t_x == n_t.t_x
     and c_t.t_y == n_t.t_y then
    add(dupe,n_t)
   end
  end
 end
 
 --delete the duplicates
 for d_t in all(dupe) do
  del(tiles, d_t)
 end
 
 for tile in all(tiles) do
  --tile is block
  if tile.ttype == 32 then
   --create block collider
   blk_coll = {
    x=tile.t_x*8,
    y=(tile.t_y*8)+2,
    w=8,
    h=4,
   }
   --check block collision
   if rect_rect_collision(
     blk_coll,b_coll) then
    --flag
    result = true
    p_combo += 1
    p_score += p_combo
    curr_score += 1
    --remove block
    --todo: animation
    mset(
     tile.t_x,
     tile.t_y,
     0
    )
    --sound
    sfx(1)
    --rebound if above
    if blk_coll.y > cy then
     b_vy = blk_top_bounce
    elseif blk_coll.y+2 < cy then
     b_vy = blk_bottom_bounce
    end
    --rebound lateral
    --check if lateral right
    if blk_coll.x >= cx+7
      and b_vx > 0 then
     b_vx = min(
      -blk_min_x_bounce, -b_vx)
    --check if lateral left
    elseif blk_coll.x+7 <= cx
      and b_vx < 0 then
      b_vx = max(
       blk_min_x_bounce, -b_vx)
    end
    --check if stage cleared
			 if curr_score >= curr_blocks then
			  frz_flags.clear.frz_flag = true
			  sfx(12)
			  music(-1)
			 end
   end 
  elseif tile.ttype > 32 then
   result = true
   if cy >= floor_y then
    respawn()
   elseif cy <= ceil_y then
    b_vy = ceil_bounce_frc
   end
  end
 end
 return result
end
-->8
--screen-freeze functions

---freeze timing
freeze_timer = 0 --frz timer
---freeze animations
flick_timer =0  -- b_flckr timer
flick_spd=0.08  -- b_flckr rate
---state-specific frz stuff
l_upd_time = 1.0-- addtl eol frz
q_upd = l_upd_time/4--eol update point
pc_upd_time =1.0-- addtl pc frz
time_clr = 7 --time disp color

--general freeze function
---takes name of a freeze flag
function frz_helper(fl_name)
 --define vars
 c_frz_time = frz_flags[fl_name].frz_time
 end_update = frz_flags[fl_name].end_upd
 flick_update = frz_flags[fl_name].flck_upd
 tick_update = frz_flags[fl_name].tick_upd
 
 freeze_timer += 1/60
 if tick_update != nil then
  tick_update()
 end
 if freeze_timer > c_frz_time then
  --anim reset
  flick_timer = 0
  --game update
  end_update()
 elseif flick_update != nil then
  --flash anim
  flick_timer += 1/60
  if flick_timer >= flick_spd then
   flick_timer = 0
   flick_update()
  end
 end
end


--ball loss end-of-freeze upd
function ball_res_end_upd()
 --freeze reset
 freeze_timer = 0
 --custom update
 frz_flags.ball.frz_flag = false
 b_spr = 16
 time_clr = 7
 if p_balls > 0 then
   p_balls -= 1
   player_init()
   ball_init(b_startxy)
   frz_flags.start.frz_flag = true
   music(0)
 else
  frz_flags.life.frz_flag = true
  if p_lives > 0 then
   sfx(10)
  else
   sfx(11)
  end
 end
end


--ball loss flicker anim
function ball_res_flck_upd()
 if stg_timer <= 0 then
   --timer ran out
   if time_clr == 7 then
    time_clr = 8
   else
    time_clr = 7
   end
 else
  --ball hit ground
  if b_spr == 16 then
   b_spr = 17
  else
   b_spr = 16
  end
 end
end


--life loss end-of-freeze upd
function life_res_end_upd()
 --past initial freeze
 if last_lives <= 0 then
  --game over
  frz_flags.life.frz_flag = false
  frz_flags.ball.frz_flag = false
  freeze_timer = 0
  playing = false
 elseif freeze_timer >
   (frz_flags.life.frz_time + l_upd_time) then
  --update complete
  --freeze reset
  frz_flags.life.frz_flag = false
  frz_flags.ball.frz_flag = false
  freeze_timer = 0
  --game update
  level_reload()
  last_lives = p_lives
  p_balls = max_balls
  level_start(curr_stage)
 elseif freeze_timer >
   (frz_flags.life.frz_time + q_upd)
   and p_lives == last_lives then
  --do update
  p_lives -= 1
  sfx(1)
 end
end


--clear stage end-of-freeze upd
function clear_stg_end_upd()
 --freeze reset
 frz_flags.clear.frz_flag = false
 frz_flags.pclear.frz_flag = true
 freeze_timer = 0
 b_spr = 16
 --store ticks for pclear upd
 last_balls = p_balls
 ball_ticks = last_balls*ball_value
 time_ticks = max(0,flr(time_value * stg_timer))
 pc_ticks = ball_ticks + time_ticks
end


--clear stage flicker anim
function clear_stg_flck_upd()
 if b_spr == 16 then
  b_spr = 18
 else
  b_spr = 16
 end
end


--post-clear end-of-freeze upd
function pclear_stg_end_upd()
 if (
   freeze_timer >
   frz_flags.pclear.frz_time + pc_upd_time
   ) then
	 frz_flags.pclear.frz_flag = false
	 freeze_timer = 0
	 --game update
	 curr_stage += 1
	 p_balls = max_balls
	 level_start(curr_stage)
	end
end


--post-clear per-tick anim
pc_ticks = 0 --# scoreupd ticks
ball_ticks = 0 --ball ticks
last_tick = 0 --last int tick
function pclear_stg_tick_upd()
 if round(p_balls + stg_timer) > 0 then
	 --get length of tick in secs
	 tick_len = frz_flags.pclear.frz_time/pc_ticks
	 --get our current tick as int
	 c_tick = freeze_timer\tick_len
	 --do cool score update anim
	 if c_tick > last_tick then
	  --we've passed a tick
	  if c_tick <= ball_ticks then
	   --we have balls remaining
	   if c_tick%ball_value == 1 then
	    p_balls -= 1
	    p_score += ball_value
	    sfx(6)
	   end
	  else
	   stg_timer -= 1/time_value
	   p_score += 1
	   sfx(5)
	  end
	 end
	 last_tick = c_tick
	end
end


--start stage end-of-freeze upd
function start_stg_end_upd()
 --freeze reset
 frz_flags.start.frz_flag = false
 freeze_timer = 0
 b_spr = 16
end


--start stage flicker anim
function start_stg_flck_upd()
 if b_spr == 16 then
  b_spr = 19
 else
  b_spr = 16
 end
end


--start stage let player move
function start_tick_upd()
 player_update()
end


---
---
---
--all our freeze flags
----order matters!!
----if an earlier flag is true,
----later flags have to wait.
frz_flags = {
 start = { -- stage start frz
  frz_flag = false,
  frz_time = 0.75,
  end_upd  = start_stg_end_upd,
  flck_upd = start_stg_flck_upd,
  tick_upd = start_tick_upd,
 },
 clear = { -- stage clear frz
  frz_flag = false,
  frz_time = 2.75,
  end_upd  = clear_stg_end_upd,
  flck_upd = clear_stg_flck_upd,
 },
 pclear = {-- post-clear frz
  frz_flag = false,
  frz_time = 1.8,
  end_upd  = pclear_stg_end_upd,
  tick_upd = pclear_stg_tick_upd,
 },
 ball = { -- ball loss rz
  frz_flag = false,
  frz_time = 1.75,
  end_upd  = ball_res_end_upd,
  flck_upd = ball_res_flck_upd, 
 },
 life = { -- life loss frz
  frz_flag = false,
  frz_time = 2.75,
  end_upd  = life_res_end_upd,
 }
}
-->8
--ui display


--print debug data
function debug_print()
 print(p_xvel..','..p_yvel)
 --print(p_x..','..p_y)
 print(p_last_chrg)
 --print(block_jump)
 print(b_vx..','..b_vy)
 --print(b_x..','..b_y)
 --print(beeb)
 --print(#dupe)
	--print(#tiles)
end


--print score, lives, etc
function value_print()
 --strings
 stagestr = int_stringify(
   curr_stage, 2)
 stg_timerstr = int_stringify(
   max(0,flr(stg_timer)), 2)
 scorestr = int_stringify(
   flr(diff_mult*p_score) + diff_pen, 3)
 livestr = int_stringify(
   p_lives, 2)
 ballstr = int_stringify(
   p_balls, 2)
 c_blockstr = int_stringify(
   curr_blocks, 2)
 c_scorestr = int_stringify(
   curr_score, 2)
 combostr = int_stringify(
   p_combo, 2)
 --todo: this is kinda messy
 if p_state == 3 then
  true_charge = p_last_chrg-1
 else
  true_charge = min(
	  (1+p_chrg_timer)^1.8,
	  p_max_yvel
	 )-1
 end
 --stage
 l_edge = 12*8
 l_ind = 13*8
 print(
  '⌂', l_edge, my_to_py(1), 14)
 print(
  '  '..stagestr,
  l_ind, my_to_py(1), 7
 )
 --stage timer
 print(
  '⧗', l_edge, my_to_py(2), 14)
 print(
  '  '..stg_timerstr,
  l_ind, my_to_py(2), time_clr
 )
 --blocks required/remaining
 print(
  '░', l_edge, my_to_py(3), 13
 )
 print(
  'x '..c_scorestr,
  l_ind, my_to_py(3), 7
 )
 print(
  '▒ ', l_edge, my_to_py(4), 13
 )
 print(
  '/ '..c_blockstr,
  l_ind, my_to_py(4), 7
 )
 --combo
 print(
  '웃', l_edge, my_to_py(6), 10)
 print(
  'x '..combostr,
  l_ind, my_to_py(6), 7
 )
 --score
 print(
  '◆', l_edge, my_to_py(7), 10
 )
 print(
  'x'..scorestr,
  l_ind, my_to_py(7), 7
 )
 --lives
 print(
  '♥', l_edge, my_to_py(9), 8
 )
 print(
  'x '..livestr,
  l_ind, my_to_py(9), 7
 )
 --balls
 print(
  '●', l_edge, my_to_py(10), 13
 )
 print(
  'x '..ballstr,
  l_ind, my_to_py(10), 7
 )
 --charge meter
 print('charge',
  l_edge, my_to_py(12), 7)
 ----do a lil' math
 c_bot  = 15*8 - 3
 c_ymax = 8*2 - 4
 c_chrg_ratio = true_charge / (p_max_yvel-1)
 ----draw a rectangle
 l_x_off = 2
 rectfill(
  l_edge+l_x_off,
  c_bot,
  l_edge + 23 - l_x_off,
  c_bot - c_chrg_ratio*c_ymax,
  14
 )
end


--draw on the life screen
function life_screen_draw()
 --draw big guy
 spr(14, 5*8, 6*8,2,2)
 --spr(15, 6*8, 6*8)
 --spr(30, 5*8, 7*8)
 --spr(31, 6*8, 7*8)
 livestr = int_stringify(
   p_lives, 2)
 print(
  'x '..livestr,
  8*8,
  4+6*8,
  7
 )
end


--takes a map y-pos,
--returns y-pos where we
--print text on the screen
--for that y-pos
function my_to_py(x)
 return 1+8*x
end
-->8
--scene management
map_data = {}   -- map table
b_startxy = nil


--set up game
function game_start()
 cleared = false		
 p_score = 0
 p_lives = max_lives
 p_balls = max_balls
 last_lives = p_lives
 last_balls = p_balls
 playing = true
 menu = false
 diff_mult = get_score_mult()
 diff_pen = get_score_penalty()
 curr_stage = start_stage
 level_start(curr_stage)
end


--starts a stage
--takes 'level' param as int
function level_start(lvl)
 if lvl > num_stages then
  playing = false
  cleared = true
  return
 end

 music(0) --play music
 frz_flags.start.frz_flag =true
 --map update
 map_save( --save map
  16*(lvl%8),
  16*(lvl\8)
 )
 level_reload(true) --load map
 --init player/ball
 player_init()
 ball_init(b_startxy)
end


--reloads currently stored level
function level_reload(sflag)
 --reset timer/score/balls
 stg_timer = max_stg_time+.99
 curr_score = 0
 --load
 map_load(sflag)
end


--respawn after lost **ball**
function respawn()
 music(-1)
 frz_flags.ball.frz_flag = true
 sfx(9)
end


--stores map at gamestart
function map_save(x_off, y_off) 
 curr_blocks = 0
 map_data = {}
 for iy=0, 15, 1 do --column
  curr_row = {}
  for ix=0, 15, 1 do --row
   --get current row
   n_tile = mget(
    ix+x_off,
    iy+y_off
   )
   add(curr_row, n_tile)
   if n_tile == 32 then
    curr_blocks += 1
   end
  end
  --save current row
  add(map_data, curr_row)
 end
end


--reloads map from saved data
function map_load(sflag)
 --null start vars
 b_startxy = b_startxy_default
 for iy=0, 15, 1 do
  for ix=0, 15, 1 do
   c_t = map_data[iy+1][ix+1]
   if not sflag or c_t != 16 then
    mset(
     ix,
     iy,
     c_t
    )
   else
    b_startxy = {ix,iy}
    mset(
     ix,
     iy,
     0
    )
   end
  end
 end
end
-->8
--menu stuff
--this file is a nightmare		

--menu anim vars
anim_sprs = {}
start_flick_spd = 0.08
start_flick_timer = 0
start_flick_flag = false
start_timer = 0
start_secs = 1.25

--menu function vars
player_speed_ind = 4
ball_speed_ind = 4
speeds = {
 {
  name = "largo",
  value = 0.5,
 },{
  name = "adante",
  value = 0.75,
 },{
  name = "moderato",
  value = 0.85,
 },{
  name = "\'intended\'",
  value = 1.0,
 },{
  name = "presto",
  value = 1.2,
 },{
  name = "p.stissimo",
  value = 1.5,
 },{
  name = "!deranged!",
  value = 2.0,
 },
}
arrow_spr = 13
all_opts = {
 title = {
	 {
	  name = "start",
	  c_fn = function() block_jump = true game_start_anim_helper() end,
	 },{
	  name = "options",
	  c_fn = function() c_opt = 0 c_menu = "options" c_opts = all_opts[c_menu] end,
	 },
	},
	options = {
	 {
	  name = "start stage",
	  val  = function() return start_stage end,
	  c_fn = function() start_stage = mid(1,start_stage+1,num_stages) end,
	  x_fn = function(x)start_stage = mid(1,start_stage+x,num_stages) end,
	  b_fn = function() start_stage = 1 end,
	 },{
	  name = "stage time",
	  val  = function() return max_stg_time end,
	  c_fn = function() max_stg_time = mid(10,max_stg_time+10,180) end,
	  x_fn = function(x)max_stg_time= mid(10,max_stg_time+x*10,180) end,
	  b_fn = function() max_stg_time = def_max_stg_time end,
	 },{
	  name = "max lives",
	  val  = function() return max_lives end,
	  c_fn = function() max_lives = (max_lives+1)%100 end,
	  x_fn = function(x)max_lives= (max_lives+x)%100 end,
	  b_fn = function() max_lives = def_max_lives end,
	 },{
	  name = "max balls",
	  val  = function() return max_balls end,
	  c_fn = function() max_balls = (max_balls+1)%100 end,
	  x_fn = function(x)max_balls = (max_balls+x)%100 end,
	  b_fn = function() max_balls = def_max_balls end,
	 },{
	  name = "ball speed",
	  val  = function() return speeds[ball_speed_ind].name end,
	  c_fn = function() ball_speed_ind = mid(1,ball_speed_ind+1,#speeds) ball_speed = speeds[ball_speed_ind].value end,
	  x_fn = function(x)ball_speed_ind = mid(1,ball_speed_ind+x,#speeds) ball_speed = speeds[ball_speed_ind].value end,
	  b_fn = function() ball_speed = 1.0 ball_speed_ind = 4 end,
	 },{
	  name = "player speed",
	  val  = function() return speeds[player_speed_ind].name end,
	  c_fn = function() player_speed_ind = mid(1,player_speed_ind+1,#speeds) player_speed = speeds[player_speed_ind].value end,
	  x_fn = function(x)player_speed_ind = mid(1,player_speed_ind+x,#speeds) player_speed = speeds[player_speed_ind].value end,
	  b_fn = function() player_speed = 1.0 player_speed_ind = 4 end,
	 },{
	  name = "player x-padding",
	  val  = function() return '     '..tostr(p_x_hit_buff) end,
	  c_fn = function() p_x_hit_buff = (p_x_hit_buff+1)%17 end,
	  x_fn = function(x)p_x_hit_buff = (p_x_hit_buff+x)%17 end,
	  b_fn = function() p_x_hit_buff = def_p_x_hit_buff end,
	 },{
	  name = "return",
	  c_fn = function() c_opt = 0 c_menu = "title" c_opts = all_opts[c_menu] end, 
	  b_fn = function() c_opt = 0 c_menu = "title" c_opts = all_opts[c_menu] end, 
	 },
	},
}

--initializes menu
function menu_init()
 music(2)
 menu_rdy = true
 menu = true
 c_menu = "title"
 c_opt = 0
 c_opts = all_opts[c_menu]
 opt_y_min = 4
 
 menu_anim_init()
end


--sets up animated sprites
function menu_anim_init()
 anim_sprs = {}

 for j=0, 3 do
	 for i=0, 8 do
	  add(anim_sprs,
	   { --lil guy
				 p_x = (15 * i + 32 * j)%127,
				 p_y = 15 * i,
				 x_speed = 1.0,
				 y_speed = 0.0,
				 curr_spr = 2,
				 main_spr = 2,
				 alt_spr = 3,
				 anim_speed = 1,
				 timer = 0.1 * (i+j),
				 width = 1,
				 height = 1,
				}
	  )
	 end
 end
end


--per-frame menu update
function menu_update()
 if game_start_anim != true then
  menu_input_update()
  menu_anim_update()
 else
  game_start_anim_update()
 end
end


--menu input update
function menu_input_update()
 --input updates
 if yin != 0 then
  -- y input
  c_opt = (c_opt-yin)%#c_opts
  sfx(6)
 end
 if confirm and
   -- confirm input
   c_opts[c_opt+1].c_fn != nil
   then
  c_opts[c_opt+1].c_fn()
  sfx(5)
 elseif cancel and
   -- cancel input
   c_opts[c_opt+1].b_fn != nil
   then
  c_opts[c_opt+1].b_fn()
  sfx(7)
 elseif xin != 0 and
   -- x input
   c_opts[c_opt+1].x_fn != nil
   then
  c_opts[c_opt+1].x_fn(xin)
  if xin > 0 then
   sfx(5)
  else
   sfx(6)
  end
 end
end


--sprite anim update
function menu_anim_update()
 --animate sprites
 for c_spr in all(anim_sprs) do
  --iterate over each sprite
  --update positions
  c_spr.p_x += c_spr.x_speed
  c_spr.p_y += c_spr.y_speed
  --oob checks
  if c_spr.p_x > 127 then
   --offscreen right
   c_spr.p_x = -(8*c_spr.width)
  elseif c_spr.p_x < -(8*c_spr.width) then
   --offscreen left
   c_spr.p_x = 127
  elseif c_spr.p_y > 127 then
   --offscreen bottom
   c_spr.p_y = -(8*c_spr.height)
  elseif c_spr.p_y < -(8*c_spr.height) then
   --offscreen top
   c_spr.p_y -= 127
  end
  if c_spr.anim_speed != nil then
   --manage sprite anim timer
   --(if applicable)
   c_spr.timer += 1/60
   while c_spr.timer >= c_spr.anim_speed do
    --sprite timer is flagged
    c_spr.timer -= c_spr.anim_speed
    if c_spr.curr_spr == c_spr.main_spr then
     c_spr.curr_spr = c_spr.alt_spr
    else
     c_spr.curr_spr = c_spr.main_spr
    end
   end
  end
 end
end


--updates timer for game start anim
function game_start_anim_update()
 --flicker
 start_flick_timer += 1/60
 while start_flick_timer >
   start_flick_spd do
  start_flick_timer -= start_flick_spd
  start_flick_flag = (not start_flick_flag)
 end
 
 --start
 start_timer += 1/60
 if start_timer
   >= start_secs then
   start_timer = 0
   start_flick_timer = 0
   start_flick_flag = false
   game_start_anim = false
   game_start()
 end
end


--per-frame menu draw
function menu_draw()
 if game_start_anim == true then
  --game start flicker
  if start_flick_flag then
   cls(0)
   menu_anim_draw()
   menu_art_draw()
   menu_title_draw()
  else
   cls(0)
   menu_anim_draw()
   menu_title_draw()
  end
 else
  --normal menu
	 cls(0)
	 menu_anim_draw()
	 menu_rect_draw()
	 menu_arrow_draw()
	 menu_options_draw()
	 menu_nav_draw()
	 menu_art_draw()
	 menu_title_draw()
	end
end


--draws menu animated stuff
function menu_anim_draw()
 --animated sprites
 for c_spr in all(anim_sprs) do
  spr(
   c_spr.curr_spr,
   c_spr.p_x,
   c_spr.p_y,
   c_spr.width,
   c_spr.height
  )
 end
end
 

--draws menu rectangles
function menu_rect_draw()
 --flag y min, do rects
 if c_menu == "title" then
  opt_y_min = 9.75
  --rectfill(32,75,77,94,0)
  --start/options
  rrectfill(30,75,50,20,2,1)
  --controls
  rrectfill(24,101,75,20,2,1)
 else
  opt_y_min = 4
  --options
  rrectfill(12,28,101,69,2,1)
  --controls
  rrectfill(24,101,86,27,2,1)
 end
end


--draws menu arrow
function menu_arrow_draw()
 --draw selection arrow
 if c_opts[c_opt+1].val != nil then
  c_x_min = 0
 else
  c_x_min = 4
 end
 spr(
  arrow_spr,
  8*c_x_min + 2,
  8*(opt_y_min + c_opt)-1
 )
end


--draws menu options
function menu_options_draw()
 txtcolor = 6
 --draw option text
 for opt_i = 0, #c_opts-1 do
  --for each option index,
  if c_opts[opt_i+1].val != nil then
  print(
	   c_opts[opt_i+1].name,
	   8*(0 + 2),
	   8*(opt_y_min + opt_i),
	   txtcolor
	  )
   print(
   c_opts[opt_i+1].val(),
   8*9,
   8*(opt_y_min + opt_i),
	  txtcolor
  )
  else
   print(
	   c_opts[opt_i+1].name,
	   8*(4 + 2),
	   8*(opt_y_min + opt_i),
	   txtcolor
	  )
  end
 end
end


--draws menu control tips
function menu_nav_draw()
 --draw control display
 if c_menu == "title" then
  --controls display
  print(
   "navigate: ⬆️ / ⬇️",
   28,
   8*13
  )
  print(
   "  select: 🅾️",
   28,
   8*14
  )
 elseif c_menu == "options" then
  print(
   "navigate: ⬆️ / ⬇️",
   28,
   8*13
  )
  print(
   "change: ⬅️ / ➡️ / 🅾️",
   28,
   8*14
  )
  print(
   "reset: ❎",
   28,
   8*15
  )
 end
end


--draw title art
function menu_art_draw()
 if c_menu == "title" then
  --funny guy
  spr(68,49,38,4,4) --guy
  spr(64,28,40,4,4) --hand
 end
end


--draw title
function menu_title_draw()
 if c_menu == "title" then
  --titlerect
  rrectfill(26,0,71,37,2,1)
  spr(72,29,2,8,4) --title
 end
end


function menu_change(n_scr)
 menu_scrn = n_scr
end


game_start_anim=false
function game_start_anim_helper()
 game_start_anim=true
 music(-1)
 sfx(13)
end


--draws end-game screen
function game_over_draw()
 --clear screen
 cls(0)
 --get data
 score = get_final_score()
 rank = get_rank(score)
 --draw funny guy
 guy_y_offset = 42
 guy_x_offset = 72
 for i=0, rank[2]-1 do
  --funny guy
  if i+1 < 7 then
   spr(68,
    18+(i%2*guy_x_offset),
    4+(flr(i\2)*guy_y_offset),
    4,4) --guy
   spr(64,
    -3+(i%2*guy_x_offset),
    7+(flr(i\2)*guy_y_offset),
    4,4) --hand
  else
   --funny guy
   spr(68,48,65,4,4) --guy
   spr(64,27,67,4,4) --hand
  end
 end
 --print data
	if cleared==true then
	 --game won!
	 rrectfill(24,12,74,21,2,13)
	 print('zounds!!',
	  47,16,7)
	 print('you won the game!',
	  28,24,7)
	else
	 --game lost
	 rrectfill(40,12,45,20,2,13)
	 print('game over',
	  45,16,7)
	 print(':(',59,24,7)
 end
 rrectfill(17,38,89,24,2,13)
 print('final score:',
  22,42,7)
 print(score,
  90,42,7)
 print('final rank:',
  22,52,7)
 print(rank[1],
  90,52,7)
end


--returns end-game score
function get_final_score()
 return flr(
  p_score * diff_mult
  + p_lives * diff_mult * life_value
  + diff_pen
 )
end


--returns letter rank
--also returns flavor
function get_rank(scr)
 if scr < 100 then
  return {'f',0}
 elseif scr < 200 then
  return {'d',1}
 elseif scr < 300 then
  return {'c',2}
 elseif scr < 400 then
  return {'b',3}
  elseif scr < 500 then
  return {'a',4}
 elseif scr < 600 then
  return {'s',5}
 elseif scr < 700 then
  return {'ss',6}
 else
  return {'sss',7}
 end
end
-->8
--utils


--collision for rect and circle
function rect_circle_collision(r,c)
	local dx,dy=c.x-mid(c.x,r.x,r.x+r.w),c.y-mid(c.y,r.y,r.y+r.h)
	return dx*dx+dy*dy<=c.r*c.r
end


--collision for rect and rect
function rect_rect_collision( r1, r2 )
  return r1.x < r2.x+r2.w and
         r1.x+r1.w > r2.x and
         r1.y < r2.y+r2.h and
         r1.y+r1.h > r2.y
end


--takes an int and stringifies
--params:
-- num:
--   input integer
-- [min_digits]
--   minimum # of digits.
--   preserved w/ leading zeroes
function int_stringify(
  num, min_digits)
 result = tostr(num)
 if min_digits != nil then
  while #result < min_digits do
   result = '0'..result
  end
 end
 return result
end


--round to nearest integer
function round(x)
 if ceil(x)-x <= 0.5 then
  return ceil(x)
 end
 return flr(x)
end
__gfx__
0000000000bbb00000bbb00000bbb00000000000000bb000000000000000000000000000000000000000000000000000000000000ddd0000000000bbb0000000
000000000bbbbb000bbbbb000bbbbb0000bbb00000bbbb0000000000000000000000000000000000000000000000000000000000d66ddd000000bbbbbbb00000
007007000bbbbbbb0bbbbbbb0bbbbbbb0bbbbb0000bbbbb000000000000000000000000000000000000000000000000000000000d6666dd0000bbbbbbbbb0000
000770000ffcffc00ffcffc00ffcffc00bbbbbbb00fcfc0000000000000000000000000000000000000000000000000000000000d666666d00bbbbbbbbbbb000
000770000ffffff00ffffff55ffffff00ffcffc000ffff0000000000000000000000000000000000000000000000000000000000d666666d00bbbbbbbbbbbb00
007007005333333553333335533333350ffffff00053350000000000000000000000000000000000000000000000000000000000d6666dd000bbbbbbbbbbbbbb
00000000533333355333333003333335533333350053350000000000000000000000000000000000000000000000000000000000d66ddd0000ffffccffffcc00
000000000050050000500550005505000050050000055000000000000000000000000000000000000000000000000000000000000ddd000000ffffccffffcc00
005555000022220000333300005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffff00
056666500288882003bbbb3005eeee500000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffff00
56667665288878823bbb7bb35eee7ee5000000000000000000000000000000000000000000000000000000000000000000000000000000005533333333333355
56666765288887823bbbb7b35eeee7e5000000000000000000000000000000000000000000000000000000000000000000000000000000005533333333333355
56666665288888823bbbbbb35eeeeee5000000000000000000000000000000000000000000000000000000000000000000000000000000005533333333333355
56666665288888823bbbbbb35eeeeee5000000000000000000000000000000000000000000000000000000000000000000000000000000005533333333333355
056666500288882003bbbb3005eeee50000000000000000000000000000000000000000000000000000000000000000000000000000000000000550000550000
00555500002222000033330000555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000550000550000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
57777775000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
57777775000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22dd6d222222222222dd6d2222d66d2222222222222222222222222222dd6d220000000000000000000000000000000000000000000000000000000000000000
2dd6ddd226d66d622dddd6622d6dd6d2266dd6622d66d662266dd6622dddddd20000000000000000000000000000000000000000000000000000000000000000
2ddd6d6ddd6dd6dddddd6d622d6dd6d226dddddddddddd62dddddddddd6dd6dd0000000000000000000000000000000000000000000000000000000000000000
2dd6d6d6ddddddd6ddd6d6d226d6dd622dd6dd666dd6ddd2d6d66d66dddd6dd60000000000000000000000000000000000000000000000000000000000000000
2ddd6ddd6ddddddd6d6d6dd226dd6d622dddd6dd6d6d6d626d66d6dd6dd66ddd0000000000000000000000000000000000000000000000000000000000000000
26dddddddd6dd6ddd6d6dd622d6dd6d226dd6dddddd6dd62dddd6dddd6dddd6d0000000000000000000000000000000000000000000000000000000000000000
266dddd226d66d62266dd6622d6dd6d226d6ddd22dddddd22dd6ddd2266dd6620000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222d66d2222d66d2222d66d2222d66d22222222220000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000077000000000000000000777777000000000000000000000
000000000000000000000000000000000000000000000bbbbbbbb000000000000770007770000777777000000000777000000777777777000000000000000000
00000000000000000000000000000000000000000bbbbbbbbbbbbbb0000000000777007777000777777000000007777700000777077777700000000000000000
000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbb00000000777000777000777000000000007777770000077000077770000000000000000
00000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbb000000077777777700777007700000007707777700077700007770000000000000000
0000000000000000555500000000000000000bbbbbbbbbbbbbbbbbbbbbbb00000077777777700077777700000077700077770077700000770000000000000000
00000005555000055ff55000000000000000bbbbbbbbbbbbbbbbbbbbbbbbb0000077700007770077777700000077777777777007770000770000000000000000
00000055ff550005ffff500000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbb000007700007770007700007700077777770777000770000770000000000000000
0000055ffff55005ffff55000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbb000007700000777007770777700777777000077000777077770000000000000000
000005ffffff5005fffff50000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000007770000777007777777700770000000000000777777770000000000000000
0000055fffff5505fffff5000000000000005fffffffffffffffffffffff50000007770000077000777770000000000000000000077777000000000000770000
0000005ffffff505fffff5000000000000005ffcfffffffffffffffffcff50000000770000000000000000000000000000000000000000077000000007777000
0000005ffffff555fffff500000000000005fffffffffffffffffffffffff5000000000000000077770000000077770000000000007700077077700007777000
00000005ffffff55fffff550000000000005fffffffffffffffffffffffff5000000000007700777777000000077777000077000007700777777700007777700
000000055ffffff5ffffff50000000000005fffffffffffffffffffffffff5000000777777700777777700000777777700077700007700777777770077777700
00000000555fffffffffff50000000000005ff5fffffffffffffffffff5ff5000000777777700770077700000777077770077700077707777777770077707770
000000000555ffffff555555000000000005fff5ffffffffffffffff555ff5000000007770000777777700000770007770007700077707707777777077777777
0000000055555ffff5fffff5000000000005fff555ffffffffffff555ffff5000000000770000777777000007777777777007770777007700770777077777777
000000055fff55fff5fffff55000000000005ffff5555555555555ffffff50000000000770000777777777007777777777707777777007700770077077000077
000000055ffff5fff5555fff5000000000005fffffffffffffffffffffff50000000000770000770077777007700000077700777770000000770000000000000
00000005555555ffffffffff50000000000005fffffffffffffffffffff500000000000770000770000000007700000007700000000000000000000000000000
00000005fffffffffffffff55000000000000055fffffffffffffffff55000000000000000000000000077000000000000000000000000000000000000770770
00000005ffffffffffffff5500000000000000005fffffffffffffff500000000000000000000000000077700000000000000000000000000077777700770770
000000055ffffffffffff55000000000000000000555fffffffff555000000000000000777700077000077770000077000000007700077000777777770777777
0000000055ffffffffff550000000000000000000000555555555000000000000000077777700077700007770000777700000007770777000777007770077777
00000000055fffffff55500000000000055000000555533333335555000000000000077770000077700077777000777770000007777777700777007770077077
0000000000055fff5550000000000000055555555533333333333335500000000000077000000007777777777000777777000007777777770077777770077077
00000000000055555000000000000000000000000533333333333335555500000000077000000007777777077700770777770007777770777077777700000000
00000000000000000000000000000000000000000555555555555555000555550000077000777000777000077700777777777000777770777777700000000077
00000000000000000000000000000000000000000555000000000555000000000000077777777000777000007700777777777700770770077707700000077077
00000000000000000000000000000000000000000555000000000555000000000000007777770000077000000000770000007700770770007707700000077000
00000000000000000000000000000000000000000555000000000555000000000000007777000000000000000000770000000000770000000000000000000000
__label__
bb00000000000000000000000000111111111111111111111111111111111111111111111111111111111111111111100000000bbb0000000000000000000000
bbb000000000000000000000000111111111111111111111111111111111111111111111111111111111111111111111000000bbbbb000000000000000000000
bbbbb0000000000000000000001111111111111111111177111111111111111111777777111111111111111111111111100000bbbbbbb0000000000000000000
cffc00000000000000000000001111771117771111777777111111111777111111777777777111111111111111111111100000ffcffc00000000000000000000
ffff00000000000000000000001111777117777111777777111111117777711111777177777711111111111111111111100005ffffff00000000000000000000
33335000000000000000000000111177711177711177711111111111777777111117711117777111111111111111111110000533333350000000000000000000
33335000000000000000000000111117777777771177711771111111771777771117771111777111111111111111111110000033333350000000000000000000
50500000000000000000000000111117777777771117777771111117771117777117771111177111111111111111111110000005505000000000000000000000
00000000000000000000000000111117771111777117777771111117777777777711777111177111111111111111111110000000000000000000000000000000
00000000000000000000000000111111771111777111771111771117777777177711177111177111111111111111111110000000000000000000000000000000
00000000000000000000000000111111771111177711777177771177777711117711177717777111111111111111111110000000000000000000000000000000
00000000000000000000000000111111777111177711777777771177111111111111177777777111111111111111111110000000000000000000000000000000
00000000000000000000000000111111777111117711177777111111111111111111117777711111111111177111111110000000000000000000000000000000
00000000000000000000000000111111177111111111111111111111111111111111111111117711111111777711111110000000000000000000000000000000
00000000000000000000000000111111111111111117777111111117777111111111111771117717771111777711111110000000000000000000000000000000
00000000000000bbb00000000011111111111177117777771111111777771111771111177117777777111177777111111000000000000000000000bbb0000000
0000000000000bbbbb000000001111111777777711777777711111777777711177711117711777777771177777711111100000000000000000000bbbbb000000
0000000000000bbbbbbb0000001111111777777711771177711111777177771177711177717777777771177717771111100000000000000000000bbbbbbb0000
0000000000000ffcffc00000001111111117771111777777711111771117771117711177717717777777177777777111100000000000000000000ffcffc00000
0000000000005ffffff00000001111111111771111777777111117777777777117771777117711771777177777777111100000000000000000005ffffff00000
00000000000053333335000000111111111177111177777777711777777777771777777711771177117717711117711110000000000000000000533333350000
00000000000003333335000000111111111177111177117777711771111117771177777111111177111111111111111110000000000000000000033333350000
00000000000000550500000000111111111177111177111111111771111111771111111111111111111111111111111110000000000000000000005505000000
00000000000000000000000000111111111111111111111117711111111111111111111111111111111111177177111110000000000000000000000000000000
00000000000000000000000000111111111111111111111117771111111111111111111111111117777771177177111110000000000000000000000000000000
00000000000000000000000000111111111177771117711117777111117711111111771117711177777777177777711110000000000000000000000000000000
00000000000000000000000000111111117777771117771111777111177771111111777177711177711777117777711110000000000000000000000000000000
00000000000000000000000000111111117777111117771117777711177777111111777777771177711777117717711110000000000000000000000000000000
00000000000000000000000000111111117711111111777777777711177777711111777777777117777777117717711110000000000000000000000000000000
00000000000000000000000000111111117711111111777777717771177177777111777777177717777771111111111110000000000000000000000000000000
00000000000000000000000000111111117711177711177711117771177777777711177777177777771111111117711110000bbb000000000000000000000000
b000000000000000000000000011111111777777771117771111177117777777777117717711777177111111771771111000bbbbb00000000000000000000000
bbb0000000000000000000000011111111177777711111771111111117711111177117717711177177111111771111111000bbbbbbb000000000000000000000
fc00000000000000000000000011111111177771111111111111111117711111111117711111111111111111111111111000ffcffc0000000000000000000000
ff00000000000000000000000011111111111111111111111111111111111111111111111111111111111111111111111005ffffff0000000000000000000000
33500000000000000000000000011111111111111111111111111111111111111111111111111111111111111111111100053333335000000000000000000000
33500000000000000000000000001111111111111111111111111111111111111111111111111111111111111111111000003333335000000000000000000000
50000000000000000000000000000550500000000000000000000000000000000000055050000000000000000000000000000550500000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000bbbbbbbb0000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000
000000000000bbb0000000000000000000000000000055550000bbbbbbbbbbbbbbbbbbbbbbbbbbb00000bbb00000000000000000000000000000bbb000000000
00000000000bbbbb00000000000000000005555000055ff5500bbbbbbbbbbbbbbbbbbbbbbbbbbbb0000bbbbb000000000000000000000000000bbbbb00000000
00000000000bbbbbbb000000000000000055ff550005ffff5bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000bbbbbbb0000000000000000000000000bbbbbbb000000
00000000000ffcffc000000000000000055ffff55005ffff5500f5fffffffffffffffffffffff500000ffcffc00000000000000000000000000ffcffc0000000
00000000005ffffff00000000000000005ffffff5005fffff505f5ffcfffffffffffffffffcff500005ffffff00000000000000000000000005ffffff0000000
00000000005333333500000000000000055fffff5505fffff5055fffffffffffffffffffffffff50005333333500000000000000000000000053333335000000
00000000000333333500000000000000005ffffff505fffff5005fffffffffffffffffffffffff50000333333500000000000000000000000003333335000000
00000000000055050000000000000000005ffffff555fffff5005fffffffffffffffffffffffff50000055050000000000000000000000000000550500000000
000000000000000000000000000000000005ffffff55fffff5505ff5fffffffffffffffffff5ff50000000000000000000000000000000000000000000000000
0000000000000000000000000000000000055ffffff5ffffff505fff5ffffffffffffffff555ff50000000000000000000000000000000000000000000000000
000000000000000000000000000000000000555fffffffffff505fff555ffffffffffff555ffff50000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000555ffffff55555505ffff5555555555555ffffff500000000000000000000000000000000000000000000000000
00000000000000000000000000000000000055555ffff5fffff505fffffffffffffffffffffff500000000000000000000000000000000000000000000000000
0000000000000000000000000000000000055fff55fff5fffff5505fffffffffffffffffffff5000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000055ffff5fff5555fff50055fffffffffffffffff550000000000000000000000000000000000000000000000000000
000000000000000000000000000bbb000005555555ffffffffff500005fffffffffffffff50000000000000000000000000bbb00000000000000000000000000
00000000000000000000000000bbbbb00005fffffffffffffff5500000555fffffffff5550000000000000000000000000bbbbb0000000000000000000000000
b0000000000000000000000000bbbbbbb005ffffffffffffff55000000000555555555bbbb000000000000000000000000bbbbbbb00000000000000000000000
00000000000000000000000000ffcffc00055ffffffffffff5550000005555333333355550000000000000000000000000ffcffc000000000000000000000000
00000000000000000000000005ffffff000055ffffffffff55555555555333333333333355000000000000000000000005ffffff000000000000000000000000
500000000000000000000000053333335000055fffffff5550000000005333333333333355555000000000000000000005333333500000000000000000000000
50000000000000000000000000333333500000055fff555000000000005555555555555555005555500000000000000000333333500000000000000000000000
00000000000000000000000000055050000000005555500000000000005550000000555550000000000000000000000000055050000000000000000000000000
00000000000000000000000000000000000000000000000000000000005550000000005550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005550000000005550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000bbb00000000000000000000000000000000000000bbb00000000000000000000000000000bbb0000000000000000000000000000bbb00000000000
000000000bbbbb000000000000000000000000000000000000bbbbb000000000000000000000000000bbbbb00000000000000000000000000bbbbb0000000000
000000000bbbbbbb0000000000000000000000000000000000bbbbbbb0000000000000000000000000bbbbbbb000000000000000000000000bbbbbbb00000000
000000000ffcffc00000000000000000000000000000000000ffcffc00000000000000000000000000ffcffc0000000000000000000000000ffcffc000000000
000000005ffffff00000000000000000000000000000000005ffffff00000000000000000000000005ffffff0000000000000000000000005ffffff000000000
00000000533333350000000000000000000000000000000005333333500000000000000000000000053333335000000000000000000000005333333500000000
00000000033333350000000000000000000000000000000000333333500000000000000000000000003333335000000000000000000000000333333500000000
00000000005505000000000000000000000000000000000000055050000000000000000000000000000550500000000000000000000000000055050000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000bbb00000000000000000000000000000000000000bbb00000000000000000000000000000bbb000000000000000000000000000
000000000000000000000000bbbbb000000000000000000000000000000000000bbbbb000000000000000000000000000bbbbb00000000000000000000000000
000000000000000000000000bbbbbbb0000000000000000000000000000000000bbbbbbb0000000000000000000000000bbbbbbb000000000000000000000000
000000000000000000000000ffcffc00000000000000000000000000000000000ffcffc00000000000000000000000000ffcffc0000000000000000000000000
000000000000000000000005ffffff00000000000000000000000000000000005ffffff00000000000000000000000005ffffff0000000000000000000000005
00000000000000000000000533333350000000000000000000000000000000005333333500000000000000000000000053333335000000000000000000000005
00000000000000000000000033333350000000000000000000000000000000000333333500000000000000000000000003333335000000000000000000000000
00000000000000000000000005505000000000000000000000000000000000000055050000000000000000000000000000550500000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbb00000000000000000000000000000000000000bbb00000000000000000000000000000bbb00000000000000000000000000000bbb000000000000
0000000bbbbb000000000000000000000000000000000000bbbbb000000000000000000000000000bbbbb000000000000000000000000000bbbbb00000000000
0000000bbbbbbb0000000000000000000000000000000000bbbbbbb0000000000000000000000000bbbbbbb0000000000000000000000000bbbbbbb000000000
0000000ffcffc00000000000000000000000000000000000ffcffc00000000000000000000000000ffcffc00000000000000000000000000ffcffc0000000000
0000005ffffff00000000000000000000000000000000005ffffff00000000000000000000000005ffffff00000000000000000000000005ffffff0000000000
00000053333335000000000000000000000000000000000533333350000000000000000000000005333333500000000000000000000000053333335000000000
00000003333335000000000000000000000000000000000033333350000000000000000000000000333333500000000000000000000000003333335000000000
00000000550500000000000000000000000000000000000005505000000000000000000000000000055050000000000000000000000000000550500000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000bbb00000000000000000000000000000000000000bbb00000000000000000000000000000bbb00000000000000000000000000000
0000000000000000000000bbbbb000000000000000000000000000000000000bbbbb000000000000000000000000000bbbbb000000000000000000000000000b
0000000000000000000000bbbbbbb0000000000000000000000000000000000bbbbbbb0000000000000000000000000bbbbbbb0000000000000000000000000b
0000000000000000000000ffcffc00000000000000000000000000000000000ffcffc00000000000000000000000000ffcffc00000000000000000000000000f
0000000000000000000005ffffff00000000000000000000000000000000005ffffff00000000000000000000000005ffffff00000000000000000000000005f
00000000000000000000053333335000000000000000000000000000000000533333350000000000000000000000005333333500000000000000000000000053
00000000000000000000003333335000000000000000000000000000000000033333350000000000000000000000000333333500000000000000000000000003
00000000000000000000000550500000000000000000000000000000000000005505000000000000000000000000000055050000000000000000000000000000

__map__
3431313131313131313131363131313534313131313131313131313631313135343131313131313131313136313131353431313131313131313131363131313534313131313131313131313631313135343131313131313131313136313131353431313131313131313131363131313534313131313131313131313631313135
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000202000000000330000003333000000000000000000003300000033
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000001000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033330000002020202000000033000000333300000000000000000000330000003333000000000000000000003300000033
3300000000000000000000330000003333000000000000000010003300000033330000000000001000000033000000333300000000000000000000330000003333000020000000002000003300000033330000000000000000000033000000333300000000000010000000330000003333202020202020202020203300000033
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033330000000000100000000033000000333300000000000000000000330000003333000000000000000000003300000033
3300000000000000000000330000003333000000000000000000003300000033330020200000000020200033000000333300000000000020200000330000003333002020000000002020003300000033330000000000000000000033000000333300202000000000202000330000003333202020000010002020203300000033
3300000000000000000000330000003333000020200000202000003300000033330000000020200000000033000000333300002020000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333320200000202000002020330000003333200000000000000000203300000033332000000000000000002033000000333300200000000000002000330000003333202000000000000020203300000033
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033330020000000000000200033000000333320002000000000200020330000003333000000000000000000003300000033
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000333300000000000000000000330000003333000000000000000000003300000033
3031313131313131313131373131313230313131313131313131313731313132303131313131313131313137313131323031313131313131313131373131313230313131313131313131313731313132303131313131313131313137313131323031313131313131313131373131313230313131313131313131313731313132
3431313131313131313131363131313534313131313131313131313631313135343131313131313131313136313131350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000000000000000000330000003333000000000000000000003300000033330000000000100000000033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000000000000000000330000003333000000000000000000003300000033330000202000002020000033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000000000000000000330000003333000000000000000000003300000033330020202020202020200033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300202000000000202000330000003333000000000000000000003300000033330020200020200020200033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000020202020000000330000003333000020000000002000003300000033330020200000000020200033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000000000000000000330000003333000020202020202000003300000033330000202000002020000033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300002020202020200000330000003333000000000010000000003300000033330000002020202000000033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000000000010000000330000003333000020200000202000003300000033330000000020200000000033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000000000000000000330000003333200000000000000000203300000033330000000000000000000033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000000000000000000330000003333000000000000000000003300000033330000000000000000000033000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3031313131313131313131373131313230313131313131313131313731313132303131313131313131313137313131320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0503000018050170501c0501d0501f0502105023050240502405012000040000300002000030000f000130000500013000130001300012000110000d000100000f0000d000090000900008000070000000000000
01010000091500b1500c1500e1501115014150171501a1501d1501d1501b1501b1501d1501b1001c1001c10000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0300000e3400e34010340113401534018340183401834019300003001c2001d2001f20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200000b5500b5500b5500b5500b55006550325002e5002e5002e5002e5002b5002b5002b5002b5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00001f643386033760337603356033560335603356033360333603326033260332603326033060330603326032e6032e6032c6032b6032c603296032b603296032b603246032460324603246030060300000
910c000028040000000000018300000001c3000000018300000001c6001c6001830000000000001830018400000001d300000001830000000184000000018300000001c600000000000000000000000000000000
490c0000230402e0002e0002b0002b0002b0002b0002b0002b00029000290002b0002b0002c0002c0002c0002c0002e0002e0002c0002c0002c0002c0002c0002c0002b0002b0002b0002b000000000000000000
490c000010340033001f6001f60018300003001f6000030018300003001f6001c300183001f6001f6001f6001830000300183001f600183001f600120001f60018600003001f6001f60000000000000000000000
1910000027700277002770027700247002470022700227001f7001f70022700227001f7001f7001d7001d700207002070020700207001f7001f7001d7001d7001f7001f7001f7001f7001b7001b7001b7001b700
0108000015340153401534015340103401034010340103400c3400c3400c3400c3400934009340093400934009340093400934009340093400934009340093400000000000000000000000000000000000000000
010e00000e3400e3400e3400e34010340103401134011340133401334015340153401334013340133401334015340153001534000000153400000000000000000000000000000000000000000000000000000000
010a00001024210242102420000210242102421024200002102421024200000102420000012242122420000014242142420000000000000001524215242152421524215242000000000009242082420924209242
090800002844028400284402840028440004002b4402b4402b4402b4402b4402b4402444024440244402444529440294402940000400294400040029440284002844028440264402644024440244402444024440
0d07000028762237622a76228762237622a7622c7622c762007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702
110e0000285302853125531255312353123532285312853128531285312c5312c5312c5312c5312c5312c5312c535000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
191000003001030010320103201033010330103301033010370103701030010300103001030010370103701035010350103301033010350103501032010320102e0102e0102e0102e0102b0102b0102b0102b010
19100000277112771127711277112e7112e7112b7112b7112b7112b7112b7112b71129711297112b7112b7112c7112c7112c7112c7112e7112e7112c7112c7112c7112c7112c7112c7112b7112b7112b7112b711
01100000183330000027003000001833318433000000000018333000001c3330000018333000001c6331c6431833300000000001833318433000001d333000001834300000184330000018333000001c64500000
1910000027721277212772127721247112471122721227211f7211f72122721227211f7211f7211d7211d721207212072120721207211f7211f7211d7211d7211f7211f7211f7211f7211b7211b7211b7211b721
191000003a0103a01038010380103701037010350103501035010350103301033010320103201032010320103001030010320102e0102e0102c0102b0102c010290102b010290102b01024010240102401024010
0110000018333003031f6450030318333033031f6451f64518333003031f6450030318333003031f6051c303183331f6251f6351f6451833300303183031f645183331f635120051f65518655003031f6551f605
1910000027721277212772127721247112471122721227211f7211f72122721227211f7211f7211d7211d721207212072120721207211f7211f7211d7211d7211f7211f7211f7211f7211b7211b7211b7211b721
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19120000125521255223552235521e5521255228552125522c5522c5522c5522c552235522355228552125522355234552385523855238552385522f5522d5522f5522f552285522855219552195521955217552
011200001b77300703007031b7731b6531b77300700286441b773007001a7441b7731b6531b773007001e7731b773000001d763000001b4431b743000001b6541b7730c303157531474315763000001e77300000
011200001e1211e1211e1211e1211c1211c1211c1211c1212312123121231212312117121171211712117121201212012120121201211c1211c1211c1211c1211e1211e1211e1211e12119121191211912119121
0912000020112201121b1121b1121910219102201122011228112281122811228112231122311223112231122c1122c11234112341121c1021c1022a1122a1122c1122c1122c1122c11238112381123811238112
01120000125521255212552125521555212552145520d5520d552105521255212552175521755217552145521255212552125521255211552145521c5521c5520d5520d55219552195522c5522c5522c5522a552
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200001e1211e1211e1211e121191211912119121191211c1211c1211c1211c12117121171211712117121201212012120121201211c1211c1211c1211c121211212112121121211212012120121201211e121
09120000281122311225112251122510225102251122311228112281122c1122c11200000000002c1122a1122c1122f1122f1122c112000002c112000002a1122c11223112281122c11225112251122311223112
__music__
01 11121344
02 14151644
01 21202263
00 21242667
00 20612223
02 24212627

