#using scripts\common\utility;
#using scripts\common\math;
#using scripts\mp\zm\systems\zone_manager;
#using scripts\mp\zm\systems\zm_quest;
#using scripts\mp\zm\maps\zm_sat_locust\zm_sat_locust_rej;
#using script_6d876fa941c49c7;

// Totenreich only: links against the map's own scripts (robot ejection, power quest),
// so it does not load on other maps.
// 1. Run log: when the host enters Tyr's Head, every ejection landing is written to the run log
//    with its zone, whether that zone is open and whether the landing is taken.
// 2. Patched options (only with Livesplit BO7, which sets level.zmm_practice):
//    - irradiated fish always on spot 1, at the latest on the first round start after the Jotunn Star
//    - after that fish is caught, the first irradiated ravagers always come at the spawn
//    - every cargo crate can hold the AA shell (pause menu row KIST)
//    - radio code (transmitter in Tyr's Head) always 1-1 then 1-1 (amplitude lamps - frequency lamps)
// 3. Run log (patched only): the 8 pyres (compass step) with zone, symbol and which are the targets, in order.
// The map keeps its quest objects in level.quest_objects[ ref ]; this file only reorders or swaps them.
autoexec zm_locust_extra_init()
{
    level.zmm_landing_fn = &zm_locust_log_landings;
    level thread zm_practice_main();
}

// ---- run log ----------------------------------------------------------------
zm_locust_in_head( origin )
{
    return distance2d( origin, ( 3100, 9720, 0 ) ) < 600 && origin[ 2 ] > 1400;
}

zm_locust_log_landings( sr, t )
{
    zm_locust_log_pyres( sr, t );
    if ( !isdefined( sr.host ) || !isdefined( level.zmm_runlog_add ) || !isdefined( level.robot_ejection_tubes ) || !isdefined( level.robot_ejection_tubes.random_landings ) )
    {
        return;
    }
    inhead = zm_locust_in_head( sr.host.origin );
    if ( inhead && !istrue( sr.log_inhead ) )
    {
        sr.log_inhead = 1;
        sr.log_li = 0;
        foreach ( l in level.robot_ejection_tubes.random_landings )
        {
            sr.log_li++;
            if ( !isdefined( l.zone ) )
            {
                l.zone = zone_manager::function_90e5c3e2272b0130( l.origin );
            }
            zn = "?";
            en = "?";
            if ( isdefined( l.zone ) )
            {
                if ( isdefined( l.zone.zone_name ) )
                {
                    zn = "" + l.zone.zone_name;
                }
                en = "0";
                if ( istrue( l.zone.is_enabled ) )
                {
                    en = "1";
                }
            }
            used = "0";
            if ( istrue( l.in_use ) )
            {
                used = "1";
            }
            [[ level.zmm_runlog_add ]]( sr, t, "LANDING " + sr.log_li + " " + int( l.origin[ 0 ] ) + "," + int( l.origin[ 1 ] ) + "," + int( l.origin[ 2 ] ) + " zone " + zn + " open " + en + " taken " + used );
        }
    }
    else if ( !inhead && istrue( sr.log_inhead ) )
    {
        sr.log_inhead = 0;
    }
}

// the compass step: 8 pyres at fixed spots get a random symbol (1-8); the compass picks 3 symbols to hit in order.
// Logged once per run so the spots can be learned (and later fixed in a good route order).
zm_locust_log_pyres( sr, t )
{
    if ( istrue( sr.log_pyres ) || !isdefined( level.zmm_runlog_add ) )
    {
        return;
    }
    // patched: log after the fixed order is applied
    if ( isdefined( level.zmm_practice ) && ( !isdefined( level.zmp ) || !level.zmp.pyre_checked ) )
    {
        return;
    }
    pyres = zm_qobj( #"hash_fe8af74b7a14db1e" );
    compass = zm_qobj( #"hash_e254894438a37f89" );
    if ( !isdefined( pyres ) || !isdefined( compass ) || !isdefined( compass.full_code ) )
    {
        return;
    }
    sr.log_pyres = 1;
    [[ level.zmm_runlog_add ]]( sr, t, "COMPASS order " + compass.full_code[ 0 ] + " " + compass.full_code[ 1 ] + " " + compass.full_code[ 2 ] );
    foreach ( pyre in pyres )
    {
        pos = "?";
        if ( isdefined( pyre.base ) && isdefined( pyre.base.script_noteworthy ) )
        {
            pos = "" + pyre.base.script_noteworthy;
        }
        zn = "?";
        zone = zone_manager::function_90e5c3e2272b0130( pyre.origin );
        if ( isdefined( zone ) && isdefined( zone.zone_name ) )
        {
            zn = "" + zone.zone_name;
        }
        sr.log_doel = 0;
        for ( sr.log_k = 0; sr.log_k < compass.full_code.size; sr.log_k++ )
        {
            if ( isdefined( pyre.code ) && compass.full_code[ sr.log_k ] == pyre.code )
            {
                sr.log_doel = sr.log_k + 1;
            }
        }
        sym = "?";
        if ( isdefined( pyre.code ) )
        {
            sym = "" + pyre.code;
        }
        [[ level.zmm_runlog_add ]]( sr, t, "PYRE spot " + pos + " " + int( pyre.origin[ 0 ] ) + "," + int( pyre.origin[ 1 ] ) + "," + int( pyre.origin[ 2 ] ) + " zone " + zn + " symbol " + sym + " target " + sr.log_doel );
    }
}

// ---- patched ----------------------------------------------------------------
zm_qobj( ref )
{
    if ( !isdefined( level.quest_objects ) )
    {
        return undefined;
    }
    return level.quest_objects[ ref ];
}

zm_practice_main()
{
    level endon( #"game_ended" );
    // the normal mod never sets level.zmm_practice: then nothing below runs
    level.zmp_wait = 0;
    while ( !isdefined( level.zmm_practice ) && level.zmp_wait < 900 )
    {
        level.zmp_wait++;
        wait 0.1;
    }
    if ( !isdefined( level.zmm_practice ) )
    {
        return;
    }
    // the pause menu choices are loaded once a player is in (zm_speedrun.gsc menu_sr_setup)
    level.zmp_wait = 0;
    while ( !isdefined( level.zmm_rng_ready ) && level.zmp_wait < 1200 )
    {
        level.zmp_wait++;
        wait 0.1;
    }
    level.zmp = spawnstruct();
    // each fix on or off from the pause menu (Livesplit BO7, zm_speedrun.gsc); read once at the start of the match,
    // only the crate follows the menu live
    level.zmp.on_fish = getdvar( @"zmm_ofish" ) == "1";
    level.zmp.on_rav = getdvar( @"zmm_orav" ) == "1";
    level.zmp.on_pyre = getdvar( @"zmm_opyre" ) == "1";
    level.zmp.on_radio = getdvar( @"zmm_oradio" ) == "1";
    level.zmp.rngon = "";
    level.zmp.fish_ordered = 0;
    level.zmp.fish_forced = 0;
    level.zmp.guard = 0;
    level.zmp.round_seen = -1;
    level.zmp.round_at = 0;
    level.zmp.rav_set = 0;
    level.zmp.rav_done = 0;
    level.zmp.crate_applied = "0";
    level.zmp.radio_done = 0;
    level.zmp.pyre_checked = 0;
    if ( !level.zmp.on_pyre )
    {
        level.zmp.pyre_checked = 1;
    }
    if ( !level.zmp.on_radio )
    {
        level.zmp.radio_done = 1;
    }
    if ( !level.zmp.on_rav )
    {
        level.zmp.rav_done = 1;
    }
    // compass order: for symbol 1, 2 and 3 the pyre nearest to these map points (x, y), read off the user's map
    // (scale ~7.9 units/px, anchored on the spawn and Tyr's Head): Eidskallen Market, above Pack-a-Punch, Tyr's Foot.
    level.zmp.pyre_route = [ ( 6400, 6350, 0 ), ( 2050, 6900, 0 ), ( -1050, 8450, 0 ) ];
    while ( true )
    {
        zm_practice_fish_tick();
        zm_practice_ravager_tick();
        zm_practice_crate_tick();
        zm_practice_radio_tick();
        zm_practice_pyre_tick();
        zm_practice_rngon();
        wait 0.25;
    }
}

zm_practice_say( text )
{
    // no on-screen messages (kept as a hook for testing)
}

// the game shuffles fish spots 1, 4 and 9 at the start and uses the first: spot 1 is put first.
// After the Jotunn Star the game rolls for the fish at every round start (round*(round+1)/2 percent).
// On the first round start after the Jotunn Star: if the game's roll missed, the fish is shown on spot 1 anyway.
// The game's own roll then stays armed; if it hits on a later round start it would light the same spot again,
// so that one re-light is undone.
zm_practice_fish_tick()
{
    if ( !level.zmp.on_fish )
    {
        return;
    }
    spots = zm_qobj( #"hash_e14c6ea2335d2754" );
    if ( !isdefined( spots ) )
    {
        return;
    }
    if ( !level.zmp.fish_ordered )
    {
        level.zmp.fish_ordered = 1;
        level.zmp.order = [];
        foreach ( s in spots )
        {
            if ( isdefined( s.idx ) && s.idx == 1 )
            {
                level.zmp.order[ level.zmp.order.size ] = s;
            }
        }
        foreach ( s in spots )
        {
            if ( !isdefined( s.idx ) || s.idx != 1 )
            {
                level.zmp.order[ level.zmp.order.size ] = s;
            }
        }
        level.quest_objects[ #"hash_e14c6ea2335d2754" ] = level.zmp.order;
        if ( isdefined( level.power_quest ) )
        {
            level.power_quest.var_e29658758f888ffd = 0;
        }
        return;
    }
    if ( !isdefined( level.fishing_struct ) || !isdefined( level.power_quest ) || !isdefined( level.round_number ) )
    {
        return;
    }
    if ( level.zmp.round_seen != level.round_number )
    {
        level.zmp.round_seen = level.round_number;
        level.zmp.round_at = gettime();
    }
    if ( level.zmp.fish_forced )
    {
        zm_practice_fish_reroll_guard();
        return;
    }
    if ( istrue( level.fishing_struct.var_cbec9bf7ad43437e ) )
    {
        // the game rolled the fish itself (on spot 1): its roll is now finished
        level.zmp.fish_forced = 1;
        return;
    }
    if ( !isdefined( level.zmp.jotunn_round ) )
    {
        if ( zm_quest::is_quest_complete( #"hash_709d77ab2b2005c5" ) )
        {
            level.zmp.jotunn_round = level.round_number;
        }
        return;
    }
    // first round start after the Jotunn Star; give the game's own roll a second first
    if ( level.round_number > level.zmp.jotunn_round && gettime() - level.zmp.round_at > 1000 )
    {
        level.zmp.fish_forced = 1;
        level.zmp.guard = 1;
        level.power_quest.var_e29658758f888ffd = 0;
        namespace_7acb35c452673b3::function_5826c8ca68de9fc1();
        level.zmp.g_idx = 0;
        level.zmp.g_on = 1;
        zm_practice_say( "fish on spot 1" );
    }
}

// after a forced fish: a re-light of the same spot right at a round start comes from the game's leftover roll
zm_practice_fish_reroll_guard()
{
    if ( !level.zmp.guard )
    {
        return;
    }
    if ( utility::flag( "mq_rp_step_01_b" ) )
    {
        level.zmp.guard = 0;
        return;
    }
    spots = zm_qobj( #"hash_e14c6ea2335d2754" );
    idx = level.power_quest.var_e29658758f888ffd;
    if ( !isdefined( idx ) || !isdefined( spots[ idx ] ) || !isdefined( spots[ idx ].scriptable ) )
    {
        return;
    }
    on = 0;
    if ( spots[ idx ].scriptable getscriptablepartstate( "vfx" ) == "enabled_irradiated" )
    {
        on = 1;
    }
    if ( on && !level.zmp.g_on && idx == level.zmp.g_idx && gettime() - level.zmp.round_at < 3000 )
    {
        spots[ idx ].scriptable setscriptablepartstate( #"vfx", #"disabled" );
        spots[ idx ].scriptable.active_fish = 0;
        level.zmp.guard = 0;
        on = 0;
    }
    level.zmp.g_idx = idx;
    level.zmp.g_on = on;
}

// after the fish is caught the game sorts the first ravager spots by distance to the catch and picks one of the two
// closest (spot 1: spawn or Melee Macchiato). Until the first ravager is out, only the spot nearest the spawn is offered.
zm_practice_ravager_tick()
{
    if ( level.zmp.rav_done || !isdefined( level.power_quest ) || !isdefined( level.power_quest.var_9ce2644b06c95783 ) )
    {
        return;
    }
    locs = zm_qobj( #"hash_b7b3993133f11424" );
    if ( !isdefined( locs ) )
    {
        return;
    }
    if ( !level.zmp.rav_set )
    {
        level.zmp.rav_set = 1;
        level.zmp.rav_orig = locs;
        level.zmp.rav_best = undefined;
        level.zmp.rav_bestd = 0;
        foreach ( l in locs )
        {
            d = distance2d( l.origin, ( 3873, -465, 0 ) );
            if ( !isdefined( level.zmp.rav_best ) || d < level.zmp.rav_bestd )
            {
                level.zmp.rav_best = l;
                level.zmp.rav_bestd = d;
            }
        }
        if ( isdefined( level.zmp.rav_best ) )
        {
            level.quest_objects[ #"hash_b7b3993133f11424" ] = [ level.zmp.rav_best ];
            zm_practice_say( "ravagers come to the spawn" );
        }
        return;
    }
    if ( isdefined( zm_qobj( #"quest_ravager" ) ) )
    {
        level.quest_objects[ #"hash_b7b3993133f11424" ] = level.zmp.rav_orig;
        level.zmp.rav_done = 1;
    }
}

// cargo crates: the note picks which crate holds the AA shell; with the option on every crate holds it
// (the original contents are kept and put back when the option is turned off)
zm_practice_crate_tick()
{
    crates = zm_qobj( #"hash_66bc71bf51846d35" );
    if ( !isdefined( crates ) )
    {
        return;
    }
    want = getdvar( @"zmm_ocrate" );
    if ( want != "1" )
    {
        want = "0";
    }
    if ( want == level.zmp.crate_applied )
    {
        return;
    }
    level.zmp.crate_applied = want;
    foreach ( crate in crates )
    {
        if ( isdefined( crate ) )
        {
            if ( !isdefined( crate.zmp_orig ) )
            {
                crate.zmp_orig = crate.contents;
            }
            if ( want == "1" )
            {
                crate.contents = "shell";
            }
            else
            {
                crate.contents = crate.zmp_orig;
            }
        }
    }
    if ( want == "1" )
    {
        zm_practice_say( "every crate holds the AA round" );
    }
    else
    {
        zm_practice_say( "crates back to normal" );
    }
}

// radio code: the game picks 2 codes (amplitude 1-7, frequency 1-8), shows them with the lamps in Tyr's Head
// and checks the puzzle against cypher_keys. Set once, before the first code is solved.
zm_practice_radio_tick()
{
    if ( level.zmp.radio_done )
    {
        return;
    }
    puzzle = zm_qobj( #"radio_tower_puzzle" );
    if ( !isdefined( puzzle ) || !isdefined( puzzle.cypher_keys ) )
    {
        return;
    }
    level.zmp.radio_done = 1;
    if ( isdefined( puzzle.solved_count ) && puzzle.solved_count > 0 )
    {
        return;
    }
    puzzle.var_c60823282e971ebb = [ 1, 1 ];
    puzzle.var_dd4ec9a0e7aabfe3 = [ 1, 1 ];
    level.zmp.keys = [];
    for ( level.zmp.k = 0; level.zmp.k < 2; level.zmp.k++ )
    {
        level.zmp.key = spawnstruct();
        level.zmp.key.amp = math::lerp_fraction( 1, 7, puzzle.var_c60823282e971ebb[ level.zmp.k ] );
        level.zmp.key.freq = math::lerp_fraction( 1, 8, puzzle.var_dd4ec9a0e7aabfe3[ level.zmp.k ] );
        level.zmp.keys[ level.zmp.keys.size ] = level.zmp.key;
    }
    puzzle.cypher_keys = level.zmp.keys;
}

// compass step: the compass shows 3 symbols, the pyres holding them must be hit in that order.
// With a route set, the compass order becomes the symbols of those 3 spots, and those 3 plus 2 decoys are the pyres shown.
// Only before the step starts (no pyre lit, code_index 0).
zm_practice_pyre_tick()
{
    if ( level.zmp.pyre_checked )
    {
        return;
    }
    pyres = zm_qobj( #"hash_fe8af74b7a14db1e" );
    compass = zm_qobj( #"hash_e254894438a37f89" );
    if ( !isdefined( pyres ) || !isdefined( compass ) || !isdefined( compass.full_code ) )
    {
        return;
    }
    level.zmp.pyre_checked = 1;
    if ( level.zmp.pyre_route.size != 3 || ( isdefined( compass.code_index ) && compass.code_index > 0 ) )
    {
        return;
    }
    level.zmp.pt = [];
    foreach ( spot in level.zmp.pyre_route )
    {
        level.zmp.best = undefined;
        level.zmp.bestd = 0;
        foreach ( pyre in pyres )
        {
            if ( isdefined( pyre.code ) && !arraycontains( level.zmp.pt, pyre ) )
            {
                level.zmp.d = distance2d( pyre.origin, spot );
                if ( !isdefined( level.zmp.best ) || level.zmp.d < level.zmp.bestd )
                {
                    level.zmp.best = pyre;
                    level.zmp.bestd = level.zmp.d;
                }
            }
        }
        if ( isdefined( level.zmp.best ) )
        {
            level.zmp.pt[ level.zmp.pt.size ] = level.zmp.best;
        }
    }
    if ( level.zmp.pt.size != 3 )
    {
        return;
    }
    level.zmp.code = [];
    level.zmp.shown = [];
    foreach ( pyre in level.zmp.pt )
    {
        level.zmp.code[ level.zmp.code.size ] = pyre.code;
        level.zmp.shown[ level.zmp.shown.size ] = pyre;
    }
    // 2 decoys: other pyres, not targets
    level.zmp.decoys = 0;
    foreach ( pyre in array_randomize_copy( pyres ) )
    {
        if ( level.zmp.decoys < 2 && !arraycontains( level.zmp.pt, pyre ) )
        {
            level.zmp.shown[ level.zmp.shown.size ] = pyre;
            level.zmp.decoys++;
        }
    }
    compass.full_code = level.zmp.code;
    compass.code_index = 0;
    compass.pyres = level.zmp.shown;
}

array_randomize_copy( arr )
{
    return arrayrandomize( arraycopy( arr ) );
}

// "1" while any fix is active: the watermark then shows RNG
zm_practice_rngon()
{
    level.zmp.rng_now = "0";
    if ( level.zmp.on_fish || level.zmp.on_rav || level.zmp.on_pyre || level.zmp.on_radio || getdvar( @"zmm_ocrate" ) == "1" )
    {
        level.zmp.rng_now = "1";
    }
    if ( level.zmp.rng_now != level.zmp.rngon )
    {
        level.zmp.rngon = level.zmp.rng_now;
        setdvar( @"zmm_rngon", level.zmp.rngon );
    }
}
