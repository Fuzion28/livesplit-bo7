#using scripts\common\utility;
#using scripts\common\callbacks;
#using scripts\mp\zm\maps\zm_sat_ruby\zm_sat_ruby_quest_mq;
#using scripts\mp\zm\maps\zm_sat_ruby\zm_sat_ruby_quest_wwq;
#using scripts\mp\zm\maps\zm_sat_ruby\zm_sat_ruby_galileo;
#using scripts\common\ai\aitypes\zombie_galileo\zombie_galileo;
#using scripts\mp\loot\common_item;

// Livesplit BO7, Astra Malorum only: links against the map's main quest script, so it never loads on other maps.
// RNG PATCHED (pause menu): the O.S.C.A.R. planet code is always 3-4-6, and in the library book puzzle every bust
// (green, red, blue) needs one turn (the game picks 1 or 2 per bust: var_bf36.. green, var_cda2.. red, var_23e3.. blue;
// the terminal by the brain shows that many books per colour, so it shows 1 book each).
// And the Mars coordinate (telescope DEC, keypad in the coordinate machine) is always 5252: the game takes it from the
// random sky spot Mars gets (declination / declination_min, 2 characters each) into level.ruby_mq.mars_coordinates,
// and shows mdl_telescope_mars.dec / dec_min in the telescope once Mars is found.
// The game (zm_sat_ruby_quest_mq.gsc, setup_step_1) picks 3 different digits 1-8 into level.ruby_mq.var_483e904399b9c1eb
// (O.S.C.A.R. names the planets from these after round 10) and the safe combination
// level.ruby_mq.var_51d24fa4b956b91a = d1 * 10000 + d2 * 100 + d3 (the nixie-tube input is checked against it).
autoexec zm_ruby_extra_init()
{
    // run log hook (called every 0.25 s by zm_speedrun.gsc while a run is logged): the Neptune boss state
    level.zmm_landing_fn = &zm_ruby_log_boss;
    level thread zm_ruby_main();
}

// Neptune (second stage of the boss): 3 phases of a third of maxhealth each. Logged so a stall (no damage for
// minutes) can be traced: health, phase, phase transition, immune, and the gap to the next phase border.
zm_ruby_log_boss( sr, t )
{
    if ( !isdefined( level.zmm_runlog_add ) || !isdefined( level.zombie_neptune ) || !isalive( level.zombie_neptune ) )
    {
        return;
    }
    nep = level.zombie_neptune;
    if ( !isdefined( nep.maxhealth ) || !isdefined( nep.n_fight_phase ) )
    {
        return;
    }
    sr.nl_imm = "0";
    if ( nep getaiblackboarddynamic( "immune" ) )
    {
        sr.nl_imm = "1";
    }
    sr.nl_tr = "0";
    if ( istrue( nep.in_phase_transition ) )
    {
        sr.nl_tr = "1";
    }
    sr.nl_state = "" + nep.n_fight_phase + "/" + sr.nl_tr + "/" + sr.nl_imm;
    sr.nl_now = gettime();
    sr.nl_line = "";
    if ( !( sr.nl_state === sr.nl_last_state ) )
    {
        sr.nl_line = "NEPTUNE phase " + nep.n_fight_phase + " transition " + sr.nl_tr + " immune " + sr.nl_imm;
        sr.nl_last_state = sr.nl_state;
    }
    else if ( !( nep.health === sr.nl_last_hp ) && ( !isdefined( sr.nl_last_at ) || sr.nl_now - sr.nl_last_at >= 1000 ) )
    {
        sr.nl_line = "NEPTUNE hp";
    }
    else if ( nep.health === sr.nl_last_hp && sr.nl_tr == "0" && sr.nl_imm == "0" && isdefined( sr.nl_last_at ) && sr.nl_now - sr.nl_last_at >= 10000 )
    {
        sr.nl_line = "NEPTUNE IDLE (no damage)";
    }
    if ( sr.nl_line == "" )
    {
        return;
    }
    sr.nl_border = int( nep.maxhealth - nep.maxhealth / 3 * nep.n_fight_phase );
    [[ level.zmm_runlog_add ]]( sr, t, sr.nl_line + " hp " + nep.health + "/" + nep.maxhealth + " limit " + sr.nl_border + " left " + ( nep.health - sr.nl_border ) );
    sr.nl_last_hp = nep.health;
    sr.nl_last_at = sr.nl_now;
}

zm_ruby_main()
{
    level endon( #"game_ended" );
    level.zmr_wait = 0;
    while ( !isdefined( level.zmm_practice ) && level.zmr_wait < 900 )
    {
        level.zmr_wait++;
        wait 0.1;
    }
    if ( !isdefined( level.zmm_practice ) )
    {
        return;
    }
    // the pause menu choice is loaded once a player is in (zm_speedrun.gsc menu_sr_setup)
    level.zmr_wait = 0;
    while ( !isdefined( level.zmm_rng_ready ) && level.zmr_wait < 1200 )
    {
        level.zmr_wait++;
        wait 0.1;
    }
    if ( getdvar( @"zmm_oastra" ) != "1" )
    {
        return;
    }
    setdvar( @"zmm_rngon", "1" );
    // pause menu (STATISTICS): the patched orrery directions from the start of the run
    setdvar( "ls_orrery", "Mars SW|Saturn NW|Neptune SE" );
    level thread zm_ruby_no_time_cap();
    // where the run starts (for the Aberrant Wiring lamp)
    level.zmr_spawnpos = level.players[ 0 ].origin;
    level thread zm_ruby_orrery();
    level thread zm_ruby_valves();
    level thread zm_ruby_free_cryo();
    level thread zm_ruby_lamp();
    level thread zm_ruby_pillars();
    // keep both set until they are used up
    level.zmr_coord = "5252";
    while ( !utility::flag( "ruby_mq_platform_moved" ) || !utility::flag( "ruby_mq_book_puzzle_solved" ) || !utility::flag( "ruby_mq_s3_mars_coord_entered" ) )
    {
        // before the keypad starts (it copies the coordinate when the portal is initiated)
        if ( !utility::flag( "ruby_mq_s3_mars_coord_entered" ) && isdefined( level.ruby_mq ) && isdefined( level.ruby_mq.mars_coordinates ) && !istrue( level.zmr_coord_set ) )
        {
            level.zmr_coord_set = 1;
            level.ruby_mq.mars_coordinates = [ level.zmr_coord[ 0 ], level.zmr_coord[ 1 ], level.zmr_coord[ 2 ], level.zmr_coord[ 3 ] ];
            if ( isdefined( level.ruby_mq.mdl_telescope_mars ) )
            {
                level.ruby_mq.mdl_telescope_mars.dec = 52;
                level.ruby_mq.mdl_telescope_mars.dec_min = 52;
            }
        }
        if ( !utility::flag( "ruby_mq_platform_moved" ) && isdefined( level.ruby_mq ) && isdefined( level.ruby_mq.var_51d24fa4b956b91a ) && level.ruby_mq.var_51d24fa4b956b91a != 30406 )
        {
            level.ruby_mq.var_483e904399b9c1eb = [ 3, 4, 6 ];
            level.ruby_mq.var_51d24fa4b956b91a = 30406;
        }
        if ( isdefined( level.ruby_mq ) && isdefined( level.ruby_mq.var_bf36b8b778fbad39 ) && !utility::flag( "ruby_mq_book_puzzle_solved" ) )
        {
            level.ruby_mq.var_bf36b8b778fbad39 = 1;
            level.ruby_mq.var_cda233a53fa2c3e9 = 1;
            level.ruby_mq.var_23e333dbd46bed1e = 1;
        }
        wait 0.5;
    }
}

// Caltheris (Neptune) time cap off. The shared damage code (zombie_damage.gsc, function_e20f670a9518dbc0) draws a line
// from 100% to 0% health over var_9dd11279d5e371c7 minutes from the boss's spawn; below that line the damage is cut
// down to a minimum. With the time set to almost nothing the line is at 0% at once, so damage is never cut.
// (Must stay above 0: the code divides by it.)
zm_ruby_no_time_cap()
{
    level endon( #"game_ended" );
    while ( true )
    {
        if ( isdefined( level.zombie_neptune ) && isalive( level.zombie_neptune ) && !( level.zombie_neptune.var_9dd11279d5e371c7 === 0.001 ) )
        {
            level.zombie_neptune.var_9dd11279d5e371c7 = 0.001;
        }
        wait 0.5;
    }
}


// Orrery (main quest step 3): the game deals the four directions NE/NW/SE/SW at random (setup_orrery_puzzle_clue,
// level.ruby_mq.var_c3b8c0b85d909338: [0] Mars, [1] Saturn, [2] Neptune) and writes them on 3 papers (a planet sketch
// plus two letter models "sat_zm_note_planet_alphabet_<north|south|east|west>"). The puzzle reads the array when the
// planets are set, so fixing the array is enough; the papers are rewritten so they show the same.
// PATCHED: Mars SW, Saturn NW, Neptune SE.
zm_ruby_orrery()
{
    level endon( #"game_ended" );
    while ( !isdefined( level.ruby_mq ) || !isdefined( level.ruby_mq.var_c3b8c0b85d909338 ) )
    {
        wait 0.2;
    }
    // 3.x fix (test 18-11: no planet was ever accepted): the game's direction values are not plain strings (its own
    // switch compares them as hashes), so "SW" written by us never equalled the game's SW. Now the game's own four
    // values are reordered instead of being replaced.
    level.zmr_dirs = [];
    level.zmr_lab = [];
    foreach ( e in level.ruby_mq.var_c3b8c0b85d909338 )
    {
        lab = zm_ruby_dir_label( e );
        level.zmr_lab[ level.zmr_lab.size ] = lab;
        if ( lab != "?" )
        {
            level.zmr_dirs[ lab ] = e;
        }
    }
    zm_ruby_log( "ORRERY game dealt Mars " + level.zmr_lab[ 0 ] + " Saturn " + level.zmr_lab[ 1 ] + " Neptune " + level.zmr_lab[ 2 ] );
    if ( isdefined( level.zmr_dirs[ "SW" ] ) && isdefined( level.zmr_dirs[ "NW" ] ) && isdefined( level.zmr_dirs[ "SE" ] ) && isdefined( level.zmr_dirs[ "NE" ] ) )
    {
        level.ruby_mq.var_c3b8c0b85d909338 = [ level.zmr_dirs[ "SW" ], level.zmr_dirs[ "NW" ], level.zmr_dirs[ "SE" ], level.zmr_dirs[ "NE" ] ];
        zm_ruby_log( "ORRERY patched Mars SW Saturn NW Neptune SE" );
        // het menupaneel: geheugensteuntje in het pauzemenu (alleen tonen, verandert niets aan het spel)
        setdvar( "ls_orrery", "Mars " + zm_ruby_dir_label( level.ruby_mq.var_c3b8c0b85d909338[ 0 ] ) + "|Saturn " + zm_ruby_dir_label( level.ruby_mq.var_c3b8c0b85d909338[ 1 ] ) + "|Neptune " + zm_ruby_dir_label( level.ruby_mq.var_c3b8c0b85d909338[ 2 ] ) );
    }
    else
    {
        zm_ruby_log( "ORRERY not patched: directions not recognised" );
        setdvar( "ls_orrery", "random (not patched this run)" );
        return;
    }
    wait 1;
    zm_ruby_orrery_papers();
    level thread zm_ruby_orrery_watch();
}

// run log: where each planet stands (which of the 4 trigger zones it touches) every time that changes, and when the
// game accepts a planet, so we can compare the game's NE/NW/SE/SW with what is seen in the game
zm_ruby_orrery_watch()
{
    level endon( #"game_ended" );
    level.zmr_trg = [];
    level.zmr_trg[ "NE" ] = getent( "step3_northeast", "targetname" );
    level.zmr_trg[ "NW" ] = getent( "step3_northwest", "targetname" );
    level.zmr_trg[ "SE" ] = getent( "step3_southeast", "targetname" );
    level.zmr_trg[ "SW" ] = getent( "step3_southwest", "targetname" );
    level.zmr_pl_last = [];
    level.zmr_flag_last = [];
    while ( !utility::flag( "ruby_mq_orrey_all_planets_set" ) )
    {
        zm_ruby_orrery_check( "Mars", level.ruby_mq.mdl_mars, "ruby_mq_orrey_mars_set" );
        zm_ruby_orrery_check( "Saturn", level.ruby_mq.mdl_saturn, "ruby_mq_orrey_saturn_set" );
        zm_ruby_orrery_check( "Neptune", level.ruby_mq.var_ca2e88320264e8c, "ruby_mq_orrey_neptune_set" );
        wait 0.5;
    }
    zm_ruby_log( "ORRERY all planets set" );
}

zm_ruby_orrery_check( name, mdl, flagname )
{
    if ( !isdefined( mdl ) )
    {
        return;
    }
    zone = "none";
    foreach ( key in [ "NE", "NW", "SE", "SW" ] )
    {
        if ( isdefined( level.zmr_trg[ key ] ) && mdl istouching( level.zmr_trg[ key ] ) )
        {
            zone = key;
        }
    }
    if ( !( level.zmr_pl_last[ name ] === zone ) )
    {
        level.zmr_pl_last[ name ] = zone;
        need = zm_ruby_dir_label( mdl.triggerassigned );
        zm_ruby_log( "ORRERY " + name + " now in " + zone + " (needs " + need + ")" );
    }
    if ( utility::flag( flagname ) && !istrue( level.zmr_flag_last[ name ] ) )
    {
        level.zmr_flag_last[ name ] = 1;
        zm_ruby_log( "ORRERY " + name + " accepted" );
    }
}

// "NE" / "NW" / "SE" / "SW" for one of the game's direction values (a string or a hash), "?" if unknown
zm_ruby_dir_label( e )
{
    if ( !isdefined( e ) )
    {
        return "?";
    }
    if ( isstring( e ) )
    {
        if ( e == "NE" || e == "NW" || e == "SE" || e == "SW" )
        {
            return e;
        }
        return "?";
    }
    if ( e == #"NE" )
    {
        return "NE";
    }
    if ( e == #"NW" )
    {
        return "NW";
    }
    if ( e == #"SE" )
    {
        return "SE";
    }
    if ( e == #"SW" )
    {
        return "SW";
    }
    return "?";
}

zm_ruby_dir_words( d )
{
    if ( d == "NE" )
    {
        return [ "north", "east" ];
    }
    if ( d == "NW" )
    {
        return [ "north", "west" ];
    }
    if ( d == "SE" )
    {
        return [ "south", "east" ];
    }
    return [ "south", "west" ];
}

// the papers that got a sketch (a model exactly on the paper spot), in the order found: their old sketch and letters
// are removed and Mars / Saturn / Neptune with the fixed letters are put back on the same spots
zm_ruby_orrery_papers()
{
    level.zmr_papers = utility::getstructarray( "step3_orrey_clue_paper", "targetname" );
    level.zmr_alpha1 = utility::getstructarray( "step3_orrey_clue_alpha_1", "targetname" );
    level.zmr_alpha2 = utility::getstructarray( "step3_orrey_clue_alpha_2", "targetname" );
    level.zmr_models = getentarray( "script_model", "classname" );
    level.zmr_used = [];
    foreach ( paper in level.zmr_papers )
    {
        level.zmr_hit = 0;
        foreach ( m in level.zmr_models )
        {
            if ( isdefined( m ) && distancesquared( m.origin, paper.origin ) < 1 )
            {
                level.zmr_hit = 1;
                m delete();
            }
        }
        if ( !level.zmr_hit )
        {
            continue;
        }
        // its two letter spots share the paper's script_noteworthy
        foreach ( a in level.zmr_alpha1 )
        {
            if ( a.script_noteworthy == paper.script_noteworthy )
            {
                paper.zmr_a1 = a;
            }
        }
        foreach ( a in level.zmr_alpha2 )
        {
            if ( a.script_noteworthy == paper.script_noteworthy )
            {
                paper.zmr_a2 = a;
            }
        }
        foreach ( m in level.zmr_models )
        {
            if ( isdefined( m ) && ( ( isdefined( paper.zmr_a1 ) && distancesquared( m.origin, paper.zmr_a1.origin ) < 1 ) || ( isdefined( paper.zmr_a2 ) && distancesquared( m.origin, paper.zmr_a2.origin ) < 1 ) ) )
            {
                m delete();
            }
        }
        level.zmr_used[ level.zmr_used.size ] = paper;
    }
    zm_ruby_log( "ORRERY papers " + level.zmr_papers.size + ", with a sketch " + level.zmr_used.size + ", models " + level.zmr_models.size );
    level.zmr_sketch = [ "sat_zm_note_planet_sketches_mars_01", "sat_zm_note_planet_sketches_saturn_01", "sat_zm_note_planet_sketches_neptune_01" ];
    for ( level.zmr_i = 0; level.zmr_i < level.zmr_used.size && level.zmr_i < 3; level.zmr_i++ )
    {
        paper = level.zmr_used[ level.zmr_i ];
        utility::spawn_model( level.zmr_sketch[ level.zmr_i ], paper.origin, paper.angles );
        level.zmr_words = zm_ruby_dir_words( zm_ruby_dir_label( level.ruby_mq.var_c3b8c0b85d909338[ level.zmr_i ] ) );
        if ( isdefined( paper.zmr_a1 ) )
        {
            utility::spawn_model( "sat_zm_note_planet_alphabet_" + level.zmr_words[ 0 ], paper.zmr_a1.origin, paper.zmr_a1.angles );
        }
        if ( isdefined( paper.zmr_a2 ) )
        {
            utility::spawn_model( "sat_zm_note_planet_alphabet_" + level.zmr_words[ 1 ], paper.zmr_a2.origin, paper.zmr_a2.angles );
        }
    }
}

// LGM-1 (wonder weapon quest step 1): 9 observatory valves; one smokes ("next"), shoot it and the next one starts,
// 5 in a row within the timer (15 s + 1 s per failed try, +5 s solo). The game picks the next valve at random from
// the ones left (activate_next_panel). PATCHED: a fixed route instead, starting at the valve nearest the telescope
// and then always the nearest valve left (computed once from the valve positions). When the game picked another
// valve, it is switched off again and the route valve is lit before anyone can shoot.
zm_ruby_valves()
{
    level endon( #"game_ended" );
    while ( !isdefined( level.ruby_wwq ) || !isdefined( level.ruby_wwq.next_panel ) || !isdefined( level.ruby_wwq.var_df89fab950c8f474 ) )
    {
        if ( utility::flag( "wwq_step_1_complete" ) )
        {
            return;
        }
        wait 0.1;
    }
    // the route over all 9 (the one lit plus the ones left)
    level.zmr_all = arraycopy( level.ruby_wwq.var_df89fab950c8f474 );
    level.zmr_all[ level.zmr_all.size ] = level.ruby_wwq.next_panel;
    level.zmr_pos = utility::getstruct( "telescope_interact", "targetname" ).origin;
    level.zmr_route = [];
    while ( level.zmr_all.size > 0 )
    {
        level.zmr_best = level.zmr_all[ 0 ];
        foreach ( v in level.zmr_all )
        {
            if ( distancesquared( v.origin, level.zmr_pos ) < distancesquared( level.zmr_best.origin, level.zmr_pos ) )
            {
                level.zmr_best = v;
            }
        }
        level.zmr_route[ level.zmr_route.size ] = level.zmr_best;
        level.zmr_pos = level.zmr_best.origin;
        level.zmr_all = arrayremove( level.zmr_all, level.zmr_best );
    }
    level thread zm_ruby_oscar_to_telescope();
    while ( !utility::flag( "wwq_step_1_complete" ) )
    {
        level.zmr_k = level.ruby_wwq.panels_activated;
        if ( isdefined( level.ruby_wwq.next_panel ) && level.zmr_k < level.zmr_route.size )
        {
            level.zmr_want = level.zmr_route[ level.zmr_k ];
            if ( level.ruby_wwq.next_panel != level.zmr_want && zm_ruby_in( level.ruby_wwq.var_df89fab950c8f474, level.zmr_want ) )
            {
                level.zmr_old = level.ruby_wwq.next_panel;
                level.zmr_old setscriptablepartstate( "fx", "off" );
                level.zmr_old setscriptablepartstate( "health", "idle" );
                level.zmr_want setscriptablepartstate( "fx", "next" );
                level.zmr_want setscriptablepartstate( "health", "damageable" );
                level.ruby_wwq.var_df89fab950c8f474 = arrayremove( level.ruby_wwq.var_df89fab950c8f474, level.zmr_want );
                level.ruby_wwq.var_df89fab950c8f474[ level.ruby_wwq.var_df89fab950c8f474.size ] = level.zmr_old;
                level.ruby_wwq.next_panel = level.zmr_want;
                // the waypoint follows the new valve
                zm_sat_ruby_quest_wwq::function_af37f1cf8a3e9a22();
            }
        }
        waitframe();
    }
}


zm_ruby_in( arr, item )
{
    foreach ( x in arr )
    {
        if ( x == item )
        {
            return 1;
        }
    }
    return 0;
}

// O.S.C.A.R. to the telescope as soon as the valve step runs (what the game does after a failed try: if he is more than
// 1000 away he is moved to the heat beam target under the telescope, then he walks to the nearest player).
zm_ruby_oscar_to_telescope()
{
    level endon( #"game_ended" );
    while ( !utility::flag( "wwq_step_1_complete" ) && !isalive( level.ruby_wwq.oscar ) )
    {
        wait 0.5;
    }
    if ( utility::flag( "wwq_step_1_complete" ) )
    {
        return;
    }
    level.zmr_beam = utility::getstruct( "heat_beam_target" ).origin;
    if ( distance2d( level.ruby_wwq.oscar.origin, level.zmr_beam ) > 300 )
    {
        level.ruby_wwq.oscar zm_sat_ruby_galileo::function_84919f8f8db67077( level.zmr_beam );
    }
    level.ruby_wwq.oscar zombie_galileo::function_d317ff95fb386140( level.ruby_wwq.oscar utility::get_closest_player(), 5 );
}

// Absolute Zero fragments (wonder weapon quest, ice step): the game only drops one when an aether crystal is broken
// with the Cryo Freeze ammo mod (500 salvage). PATCHED: a free Cryo Freeze ammo mod drops at the start of the run, the
// same item the game itself drops for this step (zmloot_ammomod_cryofreeze).
zm_ruby_free_cryo()
{
    level endon( #"game_ended" );
    wait 2;
    if ( !isdefined( level.players[ 0 ] ) )
    {
        return;
    }
    spawnoptions = common_item::items_initspawnoptions_spawnfromentity( level.players[ 0 ] );
    // never despawns or gets cleared
    spawnoptions.var_fd47e835523b473f = 1;
    common_item::items_spawnitemfromscriptable( "zmloot_ammomod_cryofreeze", 1, spawnoptions );
}

// Aberrant Wiring (wonder weapon quest): the game lights a random lamp post (setup_aberrant_lamp: struct "aberrant_lamp",
// scriptable "ruby_wwq_aberrant_lamp", light world event "we_lgt_wwq_<script_noteworthy>"). PATCHED: always the lamp
// nearest to where the run starts (between the spawn and Juggernog). If the game lit another one it is swapped.
zm_ruby_lamp()
{
    level endon( #"game_ended" );
    while ( !isdefined( level.ruby_wwq ) || !isdefined( level.ruby_wwq.aberrant_lamp ) )
    {
        if ( utility::flag( "wwq_step_4_complete" ) )
        {
            return;
        }
        wait 0.2;
    }
    level.zmr_lamps = utility::getstructarray( "aberrant_lamp", "targetname" );
    level.zmr_lamp = level.zmr_lamps[ 0 ];
    foreach ( l in level.zmr_lamps )
    {
        if ( distancesquared( l.origin, level.zmr_spawnpos ) < distancesquared( level.zmr_lamp.origin, level.zmr_spawnpos ) )
        {
            level.zmr_lamp = l;
        }
    }
    if ( level.ruby_wwq.aberrant_lamp.noteworthy == level.zmr_lamp.script_noteworthy )
    {
        return;
    }
    deactivateworldevent( "we_lgt_wwq_" + level.ruby_wwq.aberrant_lamp.noteworthy );
    level.ruby_wwq.aberrant_lamp freescriptable();
    level.ruby_wwq.aberrant_lamp = spawnscriptable( "ruby_wwq_aberrant_lamp", level.zmr_lamp.origin, level.zmr_lamp.angles );
    level.ruby_wwq.aberrant_lamp.noteworthy = level.zmr_lamp.script_noteworthy;
    level.ruby_wwq.aberrant_lamp.wire_landing = utility::getstruct( level.zmr_lamp.script_noteworthy + "_landing", "targetname" ).origin;
    activateworldevent( "we_lgt_wwq_" + level.zmr_lamp.script_noteworthy );
    zm_sat_ruby_quest_wwq::function_af37f1cf8a3e9a22();
}

// Mars pillars (main quest step 4): the organ in the power station plays the order of the 5 pillar symbols
// (level.ruby_mq.var_16120e7bf8d769e9, a shuffle of 1-5 made when the Pack-a-Punch quest is done; one of the five is
// left blank on the screen, var_fe854866e33fb015). The pillar interacts are checked against the same array.
// PATCHED: always 3-4-1-2-5.
zm_ruby_pillars()
{
    level endon( #"game_ended" );
    while ( !isdefined( level.ruby_mq ) || !isdefined( level.ruby_mq.var_16120e7bf8d769e9 ) )
    {
        wait 0.5;
    }
    a = level.ruby_mq.var_16120e7bf8d769e9;
    zm_ruby_log( "PILLARS game order " + a[ 0 ] + "-" + a[ 1 ] + "-" + a[ 2 ] + "-" + a[ 3 ] + "-" + a[ 4 ] + " static " + level.ruby_mq.var_fe854866e33fb015 );
    // game numbers vs Redouan's map (test 18-11, the organ played game 3-4-1-2-5 as top, bottom left, bottom right,
    // right middle, top left): game 1 = map 5, 2 = map 4, 3 = map 3, 4 = map 2, 5 = map 1.
    // Wanted on the map: 3-4-1-2-5 = game 3-2-5-4-1.
    level.ruby_mq.var_16120e7bf8d769e9 = [ 3, 2, 5, 4, 1 ];
    zm_ruby_log( "PILLARS patched game 3-2-5-4-1 (map 3-4-1-2-5)" );
    level callback::add( "mars_pillar_symbol_pressed", &zm_ruby_pillar_pressed );
}

zm_ruby_pillar_pressed( params )
{
    if ( isdefined( params ) && isdefined( params.trigger ) && isdefined( params.trigger.num ) )
    {
        zm_ruby_log( "PILLARS pressed game pillar " + params.trigger.num );
    }
}

// run log line (kronos\livesplit_bo7_runlog\zm_sat_ruby_<attempt>.json); lines from before the log starts wait in a queue
zm_ruby_log( text )
{
    if ( !isdefined( level.zmr_logq ) )
    {
        level.zmr_logq = [];
        level thread zm_ruby_log_flush();
    }
    level.zmr_logq[ level.zmr_logq.size ] = text;
}

zm_ruby_log_flush()
{
    level endon( #"game_ended" );
    while ( true )
    {
        if ( level.zmr_logq.size > 0 && isdefined( level.zmm_runlog_add ) && isdefined( level.zmm_sr ) && isdefined( level.zmm_sr.log_file ) && isdefined( level.zmm_sr.start ) )
        {
            level.zmr_logt = gettime() - level.zmm_sr.start;
            foreach ( line in level.zmr_logq )
            {
                [[ level.zmm_runlog_add ]]( level.zmm_sr, level.zmr_logt, line );
            }
            level.zmr_logq = [];
        }
        wait 1;
    }
}
