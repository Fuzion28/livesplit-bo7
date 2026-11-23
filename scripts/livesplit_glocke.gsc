#using scripts\common\utility;
#using scripts\common\callbacks;

// Livesplit BO7: Glocke counter. While a Glocke minigame runs (Totenreich, "delivery_loot" drop), zmm_glocke
// holds "light x/3, kills y/z, time left" for zm_mod_menu_post.lua. Display only: it changes nothing in the game.
// The game's own rules (zm_sat_locust_glocke_drop.gsc): per light a kill requirement and a duration from
// level.robot_glocke_drop.types[ "delivery_loot" ].tier, only kills of floating zombies count, 3 s pause between lights.
autoexec zm_glk_init()
{
    level thread zm_glk_main();
}

zm_glk_main()
{
    level endon( #"game_ended" );
    // only in Livesplit BO7 (sets level.zmm_practice), never in the normal mod
    level.zmg_wait = 0;
    while ( !isdefined( level.zmm_practice ) && level.zmg_wait < 900 )
    {
        level.zmg_wait++;
        wait 0.1;
    }
    if ( !isdefined( level.zmm_practice ) )
    {
        return;
    }
    level.zmg = spawnstruct();
    level.zmg.active = 0;
    level.zmg.text = "";
    level.zmg.clear_at = 0;
    level callback::add( #"glocke_drop_created", &zm_glk_created );
    level callback::add( #"glocke_drop_complete", &zm_glk_complete );
    level callback::add( "on_zombie_ai_killed", &zm_glk_on_kill );
    while ( true )
    {
        zm_glk_tick();
        wait 0.1;
    }
}

zm_glk_created( params )
{
    if ( !isdefined( params ) || !isdefined( params.type ) || params.type != "delivery_loot" )
    {
        return;
    }
    level.zmg.active = 1;
    level.zmg.tier = 0;
    level.zmg.kills = 0;
    level.zmg.win_at = 0;
    level.zmg.failed = 0;
    level.zmg.done = 0;
}

zm_glk_complete( params )
{
    if ( !level.zmg.active )
    {
        return;
    }
    level.zmg.active = 0;
    if ( level.zmg.done )
    {
        zm_glk_set( "^3GLOCKE ^2done: all 3 lights" );
    }
    else
    {
        zm_glk_set( "^3GLOCKE ^1failed ^7at light " + ( level.zmg.tier + 1 ) );
    }
    level.zmg.clear_at = gettime() + 6000;
}

zm_glk_on_kill( params )
{
    if ( !isdefined( level.zmg ) || !level.zmg.active || level.zmg.win_at == 0 || level.zmg.done )
    {
        return;
    }
    if ( !isdefined( params ) || !isplayer( params.eattacker ) )
    {
        return;
    }
    if ( !self utility::ent_flag( "floating" ) )
    {
        return;
    }
    level.zmg.kills++;
    if ( level.zmg.kills >= zm_glk_req( level.zmg.tier ) )
    {
        level.zmg.tier++;
        level.zmg.kills = 0;
        if ( level.zmg.tier >= zm_glk_tiers() )
        {
            level.zmg.done = 1;
            return;
        }
        // the game waits 3 s, then the next light starts its own duration
        level.zmg.win_at = gettime() + 3000;
    }
}

zm_glk_data()
{
    if ( !isdefined( level.robot_glocke_drop ) || !isdefined( level.robot_glocke_drop.types ) )
    {
        return undefined;
    }
    level.zmg.data = level.robot_glocke_drop.types[ "delivery_loot" ];
    if ( !isdefined( level.zmg.data ) )
    {
        return undefined;
    }
    return level.zmg.data.tier;
}

zm_glk_tiers()
{
    level.zmg.td = zm_glk_data();
    if ( !isdefined( level.zmg.td ) || !isdefined( level.zmg.td.duration ) )
    {
        return 3;
    }
    return level.zmg.td.duration.size;
}

zm_glk_req( tier )
{
    level.zmg.td = zm_glk_data();
    level.zmg.np = level.players.size;
    if ( level.zmg.np < 1 )
    {
        level.zmg.np = 1;
    }
    if ( isdefined( level.zmg.td ) && isdefined( level.zmg.td.kill_req ) && isdefined( level.zmg.td.kill_req[ level.zmg.np - 1 ] ) && isdefined( level.zmg.td.kill_req[ level.zmg.np - 1 ][ tier ] ) )
    {
        return level.zmg.td.kill_req[ level.zmg.np - 1 ][ tier ];
    }
    level.zmg.solo = [ 5, 8, 10 ];
    if ( tier > 2 )
    {
        tier = 2;
    }
    return level.zmg.solo[ tier ];
}

zm_glk_dur( tier )
{
    level.zmg.td = zm_glk_data();
    if ( isdefined( level.zmg.td ) && isdefined( level.zmg.td.duration ) && isdefined( level.zmg.td.duration[ tier ] ) )
    {
        return level.zmg.td.duration[ tier ];
    }
    level.zmg.solod = [ 15, 18, 20 ];
    if ( tier > 2 )
    {
        tier = 2;
    }
    return level.zmg.solod[ tier ];
}

zm_glk_floating()
{
    level.zmg.nf = 0;
    foreach ( ai in getaiarray() )
    {
        if ( isdefined( ai ) && isalive( ai ) && ai utility::ent_flag( "floating" ) )
        {
            level.zmg.nf++;
        }
    }
    return level.zmg.nf;
}

zm_glk_tick()
{
    if ( !level.zmg.active )
    {
        if ( level.zmg.text != "" && gettime() > level.zmg.clear_at )
        {
            zm_glk_set( "" );
        }
        return;
    }
    if ( level.zmg.done )
    {
        zm_glk_set( "^3GLOCKE ^2done: all 3 lights" );
        return;
    }
    // the first light starts when the first zombies float up
    if ( level.zmg.win_at == 0 )
    {
        if ( zm_glk_floating() == 0 )
        {
            zm_glk_set( "^3GLOCKE ^7light 1/" + zm_glk_tiers() + "  kills 0/" + zm_glk_req( 0 ) + "  ^7waiting for landing" );
            return;
        }
        level.zmg.win_at = gettime();
    }
    level.zmg.now = gettime();
    if ( level.zmg.now < level.zmg.win_at )
    {
        zm_glk_set( "^3GLOCKE ^2light " + level.zmg.tier + " cleared! ^7next one starts soon" );
        return;
    }
    level.zmg.left = zm_glk_dur( level.zmg.tier ) * 1000 - ( level.zmg.now - level.zmg.win_at );
    if ( level.zmg.left < 0 )
    {
        level.zmg.left = 0;
    }
    level.zmg.col = "^2";
    if ( level.zmg.left < 6000 )
    {
        level.zmg.col = "^1";
    }
    zm_glk_set( "^3GLOCKE ^7light " + ( level.zmg.tier + 1 ) + "/" + zm_glk_tiers() + "  kills ^3" + level.zmg.kills + "/" + zm_glk_req( level.zmg.tier ) + "  " + level.zmg.col + "" + int( level.zmg.left / 1000 ) + " s left" );
}

zm_glk_set( text )
{
    if ( level.zmg.text === text )
    {
        return;
    }
    level.zmg.text = text;
    setdvar( @"zmm_glocke", text );
}
