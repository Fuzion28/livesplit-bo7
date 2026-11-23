// Livesplit BO7: Livesplit BO7 plus declared RNG changes (zm_locust_extra.gsc). Own store (kronos\livesplit_bo7), so patched runs never touch the unpatched PBs.
#using scripts\common\utility;
#using scripts\common\weapon;
#using scripts\common\callbacks;
#using scripts\common\status_effects\effect_charm;
#using scripts\mp\zm\systems\zm_armor;
#using scripts\mp\zm\systems\agent_manager;
// hashed game scripts, same list as ProjectNexus: perks, points, overrides, bgb, round flags
#using script_3b64eb40368c1450;
#using script_6995a3eb7d571a9f;
#using script_4e3b2b1d9542e66b;
#using script_4fca32f463c5e4fa;
#using script_25a8fa2ac8997425;
#using script_3a9d7a7cfee99885;
#using script_2301d27669c5a079;
#using script_aa3bac81ad4fc8e;
#using script_427ce33ec0c820cf;
#using script_4f24ca7a470a5fa8;
#using script_4ccf8f7e270f2426;
#using script_4b576523c81e6ee3;
#using script_27623f7ac600060c;
#using script_54198e0a02e4a0cd;
#using script_7bef99a2b184bfd5;
#using script_46fecad419c065b2;
// crafting_table, gobblegum machine (both loaded by the zm core script, like magicbox)
#using script_23131bd305bbd11b;
#using script_4478f81b31480314;
#using script_724b8f06df0c96b1;
#using script_734dce84c468439b;
// armor (namespace armor), public game script
#using script_1f6b7243f8d72fef;
#using script_53d9b43dfecd95ed;
// doorbuy (door purchase), public game script
#using script_681a06cc8e9fcb34;
// zone manager (spawn zones), public game script
#using script_7b92812967b04687;
// ai move speed stack (walk/run/sprint by priority), public game script
#using script_6c2f6a14fa53759e;
// equipment give (lethal/tactical slots), public game script
#using script_6b0663a111030b30;
// zm_quest: main quest steps, jump-to-step used by the boss fight option
#using script_c1369b1abe9a0d1;
// lastStand: self revive count, public game script
#using script_8c8e132af264960;
// loot (namespace_952965bfef60cff8): loot ID <-> ref, used by the saved builds
#using script_1ade2fa7cae9593d;

#namespace zm_speedrun;

// Kinds: 0 close, 1 back, 2 submenu, 4 toggle, 5 action, 6 round, 7 powerup, 8 give weapon, 9 action with a value.

autoexec init()
{
    if ( !utility::iszm() )
    {
        return;
    }
    // Livesplit-menu shares this guard: the first script loaded wins, so never let both run
    if ( isdefined( level.zmm_initialized ) )
    {
        level thread menu_both_warn();
        return;
    }
    level.zmm_initialized = 1;
    level.zmm_name = "Livesplit BO7";
    // read by zm_locust_extra.gsc: only this mod turns the practice options on
    level.zmm_practice = 1;
    level.zmm_footer = "[{+speed_throw}] Up   [{+attack}] Down   [{+activate}] OK   [{+melee}] Back";
    level.zmm_visible = 12;
    level.zmm_themes = [ ( 0, 0.6, 1 ), ( 1, 0.2, 0.2 ), ( 0.2, 1, 0.35 ), ( 0.7, 0.3, 1 ), ( 1, 0.6, 0 ), ( 1, 0.85, 0.2 ) ];
    level.zmm_theme_names = [ "blue", "red", "green", "purple", "orange", "gold" ];
    // zm_mod_menu_post.lua draws the menu from zmm_view and sets zmm_lua to "1"
    setdvar( @"zmm_view", "" );
    setdvar( @"zmm_lua", "" );
    setdvar( @"zmm_exec", "" ); setdvar( @"zmm_ptimer", "" ); setdvar( @"zmm_pgums", "" ); setdvar( @"zmm_paction", "" ); setdvar( @"zmm_pshow", "" ); setdvar( @"zmm_pmode", "" ); setdvar( @"zmm_pfov", "" ); setdvar( @"zmm_splice", "" );
    // RNG fixes (zm_locust_extra.gsc), each on/off in the pause menu: saved in kronos\livesplit_bo7, and kept in the
    // dvars over a map restart. Fish, ravagers, symbols and radio code are read at the start of a match; the crate live.
    // the saved choices are loaded in menu_sr_setup (the store is read once a player is in); until then these
    // defaults, and zm_locust_extra.gsc waits for level.zmm_rng_ready
    if ( getdvar( @"zmm_ofish" ) == "" )
    {
        setdvar( @"zmm_ofish", "1" );
    }
    if ( getdvar( @"zmm_orav" ) == "" )
    {
        setdvar( @"zmm_orav", "1" );
    }
    if ( getdvar( @"zmm_ocrate" ) == "" )
    {
        setdvar( @"zmm_ocrate", "1" );
    }
    if ( getdvar( @"zmm_opyre" ) == "" )
    {
        setdvar( @"zmm_opyre", "1" );
    }
    if ( getdvar( @"zmm_oradio" ) == "" )
    {
        setdvar( @"zmm_oradio", "1" );
    }
    // Astra Malorum: O.S.C.A.R. planet code 3-4-6 (zm_ruby_extra.gsc)
    if ( getdvar( @"zmm_oastra" ) == "" )
    {
        setdvar( @"zmm_oastra", "1" );
    }
    // set by zm_locust_extra.gsc: "1" when a fix is active this match (the watermark then says RNG)
    setdvar( @"zmm_rngon", "0" );
    // orrery line in the pause menu: only filled by livesplit_astra.gsc (Astra + RNG: PATCHED)
    setdvar( "ls_orrery", "" );
    // sub-splits per quest step, the PB ghost and the Glocke counter, drawn by zm_mod_menu_post.lua
    setdvar( @"zmm_sub", "" );
    setdvar( @"zmm_ghost", "" );
    setdvar( @"zmm_glocke", "" );
    // statistics for the pause menu panel ("attempts|finishes|pb ms|average ms|play ms"), and the ghost run toggle
    setdvar( @"zmm_stats", "" );
    if ( getdvar( @"zmm_pghost" ) == "" )
    {
        setdvar( @"zmm_pghost", "1" );
    }
    // font test: shown once per game start, the Lua sets it to "2" afterwards
    if ( getdvar( @"zmm_fontdemo" ) == "" )
    {
        setdvar( @"zmm_fontdemo", "1" );
    }
    setdvar( @"zmm_hud", "" );
    setdvar( @"zmm_big", "" );
    setdvar( @"hash_3c05d1d16d772c9e", -1 );
    setdvar( @"hash_8054c9327575fd95", 0 );
    // the Lua can only write dvars that already exist
    setdvar( @"zmm_up", "0" );
    setdvar( @"zmm_down", "0" );
    setdvar( @"zmm_enter", "0" );
    setdvar( @"zmm_back", "0" );
    setdvar( @"zmm_open", "0" );
    setdvar( @"zmm_pad", "0" );
    // Old School parts that are on, read by the game-wide hooks
    level.zmm_cl = [];
    menu_build_pages();
    level callback::add( #"player_spawned", &menu_on_spawned );
    level callback::add( #"player_death", &menu_on_death );
    level callback::add( #"player_disconnect", &menu_on_disconnect );
    level thread menu_scan_players();
    level thread menu_sr_loop();
    // splitter layout (zm_splitter_post.lua) reads the speedrun data through dvars
    level thread zmsplit_bridge();
}

function menu_rng_load( key, def )
{
    nengine_store_load( "livesplit_bo7", "speedrun" );
    level.zmm_rng_v = nengine_store_get( "livesplit_bo7", key );
    if ( !( level.zmm_rng_v === "0" || level.zmm_rng_v === "1" ) )
    {
        level.zmm_rng_v = def;
    }
    return level.zmm_rng_v;
}

// pause menu changes of the RNG fixes go to the store
function menu_rng_sync( sr )
{
    menu_rng_save( sr, "rng_fish", getdvar( @"zmm_ofish" ) );
    menu_rng_save( sr, "rng_rav", getdvar( @"zmm_orav" ) );
    menu_rng_save( sr, "rng_crate", getdvar( @"zmm_ocrate" ) );
    menu_rng_save( sr, "rng_pyre", getdvar( @"zmm_opyre" ) );
    menu_rng_save( sr, "rng_radio", getdvar( @"zmm_oradio" ) );
    menu_rng_save( sr, "rng_astra", getdvar( @"zmm_oastra" ) );
    menu_rng_save( sr, "ghost", getdvar( @"zmm_pghost" ) );
}

function menu_rng_save( sr, key, value )
{
    if ( !isdefined( sr.rng_last ) )
    {
        sr.rng_last = [];
    }
    if ( sr.rng_last[ key ] === value )
    {
        return;
    }
    if ( isdefined( sr.rng_last[ key ] ) )
    {
        menu_pause_save( key, value );
    }
    sr.rng_last[ key ] = value;
}

function menu_build_pages()
{
    level.zmm_pages = [];
    level.zmm_labels = [];
    level.zmm_toggle_keys = [];

    menu_add_page( "Main", "SPEEDRUN", [
        [ "Start speedrun", 9, "restart", 0 ],
        [ "Timer", 4, "speedrun" ],
        [ "Infinite gums", 4, "gums" ],
        [ "Close", 0, "" ]
    ] );
}

function menu_add_page( id, title, items )
{
    page = spawnstruct();
    page.title = title;
    page.items = items;
    level.zmm_pages[ id ] = page;
    foreach ( entry in items )
    {
        if ( entry[ 1 ] == 4 || entry[ 1 ] == 5 )
        {
            // literal strings: the profiles cannot rely on getarraykeys, which hashes some keys
            if ( entry[ 1 ] == 4 && !isdefined( level.zmm_labels[ entry[ 2 ] ] ) )
            {
                level.zmm_toggle_keys[ level.zmm_toggle_keys.size ] = entry[ 2 ];
            }
            level.zmm_labels[ entry[ 2 ] ] = entry[ 0 ];
        }
    }
}

function menu_scan_players()
{
    for ( i = 0; i < 480; i++ )
    {
        found = false;
        if ( isdefined( level.players ) )
        {
            foreach ( player in level.players )
            {
                if ( isdefined( player ) && isplayer( player ) && isalive( player ) && player.sessionstate == "playing" )
                {
                    found = true;
                    player thread menu_on_spawned( undefined );
                }
            }
        }
        if ( found )
        {
            return;
        }
        wait 0.25;
    }
}

function menu_on_spawned( params )
{
    if ( !isdefined( self ) || !isplayer( self ) )
    {
        return;
    }
    if ( isdefined( self.zmm ) && self.zmm.running )
    {
        return;
    }

    state = spawnstruct();
    state.running = true;
    state.is_open = false;
    state.page = "Main";
    state.cursor = 0;
    state.top = 0;
    state.stack = [];
    state.depth = 0;
    state.toggles = [];
    state.toggles[ "menu_right" ] = 1;
    state.equip_loop = 0;
    state.upgrade_loop = 0;
    state.god_loop = 0;
    state.hornet_loop = 0;
    state.points_loop = 0;
    state.has_save = 0;
    state.theme = 0;
    state.lua = 0;
    state.nav_open = getdvar( @"zmm_open" );
    state.spawn_origin = self.origin;
    state.spawn_angles = self getplayerangles();
    self.zmm = state;
    
    self thread menu_welcome();
}

function menu_on_death( params )
{
    if ( isdefined( self ) && isdefined( self.zmm ) )
    {
        menu_close();
    }
}

function menu_on_disconnect( params )
{
    if ( isdefined( self ) && isdefined( self.zmm ) )
    {
        self.zmm.running = false;
        menu_close();
    }
}

function menu_close()
{
    state = self.zmm;
    state.is_open = false;
    state.nav_open = getdvar( @"zmm_open" );
    state.stack = [];
    state.depth = 0;
    if ( istrue( state.lua ) )
    {
        setdvar( @"zmm_view", "" );
    }
    menu_hud_destroy();
}

function menu_notify( label, ok )
{
    if ( !isdefined( self ) || !isdefined( self.zmm ) )
    {
        return;
    }
    if ( ok )
    {
        text = label + " ^2OK";
    }
    else
    {
        text = label + " ^1failed";
    }
    if ( self.zmm.is_open )
    {
        menu_render();
    }
    // hud mode shows results in the kill feed: one hud string per result would fill the 256 text slots
    if ( !self.zmm.is_open || isdefined( self.zmm.hud ) )
    {
        self iprintln( text );
    }
}

function menu_is_host()
{
    // a guest can sit at level.players[ 0 ], so index 0 only counts when no player reports being host
    foreach ( player in level.players )
    {
        if ( istrue( player function_b36623eefe0028c8() ) )
        {
            return self == player;
        }
    }
    return isdefined( level.players[ 0 ] ) && self == level.players[ 0 ];
}

function menu_line_text( entry, on )
{
    if ( entry[ 1 ] == 2 )
    {
        return entry[ 0 ] + "  ^3>";
    }
    if ( entry[ 1 ] == 4 )
    {
        return entry[ 0 ] + ( on ? "  ^2ON" : "  OFF" );
    }
    return entry[ 0 ];
}

function menu_text_rows( page, cursor )
{
    count = page.items.size;
    line = "^3> " + menu_item_label( page.items[ cursor ] ) + " ^3<";
    if ( cursor > 0 )
    {
        line = "^7" + menu_item_label( page.items[ cursor - 1 ] ) + "   " + line;
    }
    if ( cursor + 1 < count )
    {
        line = line + "   ^7" + menu_item_label( page.items[ cursor + 1 ] );
    }
    return line;
}

function menu_page_list( page, top )
{
    list = "";
    for ( i = 0; i < level.zmm_visible && top + i < page.items.size; i++ )
    {
        entry = page.items[ top + i ];
        if ( i > 0 )
        {
            list += "
";
        }
        list += menu_line_text( entry, entry[ 1 ] == 4 && menu_toggle_state( entry[ 2 ] ) );
    }
    return list;
}

function menu_welcome()
{
    // spawn happens during the intro, and the intro teleports the player: wait for real walking
    // (small steps several ticks in a row) or a button press
    prev = self.origin;
    steps = 0;
    for ( i = 0; i < 600 && steps < 5; i++ )
    {
        wait 0.05;
        if ( !isdefined( self ) )
        {
            return;
        }
        if ( self adsbuttonpressed() || self attackbuttonpressed() || self usebuttonpressed() || self meleebuttonpressed() )
        {
            break;
        }
        // no distance builtin: an unknown builtin would stop the whole script from linking
        d = self.origin - prev;
        prev = self.origin;
        moved = d[ 0 ] * d[ 0 ] + d[ 1 ] * d[ 1 ];
        if ( moved > 2 && moved < 2500 )
        {
            steps++;
        }
        else
        {
            steps = 0;
        }
    }
    wait 0.5;
    if ( !isdefined( self ) || !isdefined( self.zmm ) )
    {
        return;
    }
    // startmelding (Livesplit BO7 v1.8 - All Gums / No Gums) uitgezet op verzoek
}

function menu_hud_destroy()
{
    state = self.zmm;
    if ( isdefined( state.hud ) && isdefined( level.zmm_hud_destroy ) )
    {
        self [[ level.zmm_hud_destroy ]]();
    }
    state.hud = undefined;
}

function menu_hud_set( key, elem, text )
{
    hud = self.zmm.hud;
    if ( isdefined( hud.cache[ key ] ) && hud.cache[ key ] == text )
    {
        return 0;
    }
    self [[ level.zmm_hud_set ]]( key, elem, text );
    return 1;
}

function menu_item_label( entry )
{
    if ( entry[ 1 ] == 2 )
    {
        return entry[ 0 ] + "  ^3>";
    }
    if ( entry[ 1 ] == 4 )
    {
        if ( menu_toggle_state( entry[ 2 ] ) )
        {
            return entry[ 0 ] + "  ^2[ON]";
        }
        return entry[ 0 ] + "  ^1[OFF]";
    }
    return entry[ 0 ];
}

function menu_render()
{
    state = self.zmm;
    if ( !state.is_open )
    {
        return;
    }
    page = level.zmm_pages[ state.page ];
    count = page.items.size;
    position = "(" + ( state.cursor + 1 ) + "/" + count + ")";

    vis = level.zmm_visible;
    if ( state.cursor < state.top )
    {
        state.top = state.cursor;
    }
    else if ( state.cursor >= state.top + vis )
    {
        state.top = state.cursor - vis + 1;
    }

    if ( state.lua )
    {
        rows = "";
        n = 0;
        for ( ; n < vis && state.top + n < count; n++ )
        {
            rows += menu_view_row( page.items[ state.top + n ] ) + "|";
        }
        right = menu_toggle_state( "menu_right" ) ? "1" : "0";
        setdvar( @"zmm_view", "ZMM|" + state.theme + "|" + right + "|" + page.title + "|" + ( state.cursor - state.top ) + "|" + n + "|" + ( state.cursor + 1 ) + "/" + count + "|" + rows + "END" );
        return;
    }

    if ( !isdefined( state.hud ) )
    {
        // BO7 shows one centre line at a time and drops line breaks: previous / current / next on one line
        self iprintlnbold( "^5" + page.title + " ^7" + position + "   " + menu_text_rows( page, state.cursor ) );
        return;
    }

    hud = state.hud;
    menu_hud_set( "name", hud.name, level.zmm_name );
    menu_hud_set( "subtitle", hud.subtitle, page.title );
    // the whole list is one text element: 12 line elements only showed new text when it was
    // sent again ~0.3 s later, a single element (like the subtitle) shows it at once
    menu_hud_set( "list", hud.list, menu_page_list( page, state.top ) );
    bar_y = hud.line_y + ( state.cursor - state.top ) * hud.spacing;
    hud.bar.y = bar_y;
    hud.accent.y = bar_y;
    menu_hud_set( "footer", hud.footer, level.zmm_footer );
}

function menu_view_row( entry )
{
    if ( entry[ 1 ] == 2 )
    {
        return ">" + entry[ 0 ];
    }
    if ( entry[ 1 ] == 4 )
    {
        return ( menu_toggle_state( entry[ 2 ] ) ? "+" : "-" ) + entry[ 0 ];
    }
    return " " + entry[ 0 ];
}

function menu_toggle( key )
{
    state = self.zmm;
    now_on = !menu_toggle_state( key );
    state.toggles[ key ] = now_on ? 1 : 0;
    menu_apply_toggle( key );
    // "Start speedrun" restarts the map, which would forget both rows
    if ( menu_is_host() )
    {
        nengine_store_load( "livesplit_bo7", "speedrun" );
        nengine_store_set( "livesplit_bo7", key == "gums" ? "gums" : "timer", now_on ? "1" : "0" );
        nengine_store_save( "livesplit_bo7", "speedrun" );
    }
    menu_render();
}

function menu_toggle_state( key )
{
    state = self.zmm;
    if ( !isdefined( state.toggles[ key ] ) )
    {
        return false;
    }
    return istrue( state.toggles[ key ] );
}

function menu_apply_toggle( key )
{
    state = self.zmm;
    if ( key == "speedrun" && menu_toggle_state( key ) && !istrue( state.hud_loop ) )
    {
        state.hud_loop = 1;
        self thread menu_hud_loop();
    }
    if ( key == "gums" && menu_toggle_state( key ) && !istrue( state.gum_loop ) )
    {
        state.gum_loop = 1;
        self thread menu_gum_refill();
    }
    return true;
}

function menu_hud_loop()
{
    state = self.zmm;
    while ( isdefined( self ) && menu_loop_active( "speedrun" ) )
    {
        if ( menu_is_host() )
        {
            // the splitter layout (zm_splitter_post.lua) draws the timer and splits now: no text line
            setdvar( @"zmm_hud", "" );
        }
        wait 0.1;
    }
    state.hud_loop = 0;
    if ( menu_is_host() )
    {
        setdvar( @"zmm_hud", "" );
    }
}

function menu_sr_setup()
{
    map = "";
    if ( isdefined( level.mapname ) )
    {
        map = level.mapname;
    }
    sr = spawnstruct();
    if ( map == "zm_sat_ruby" )
    {
        sr.names = [ "Ligmaaa", "Brain", "Mars", "Ritual", "Caltheris" ];
        sr.flags = [ "ruby_wwq_complete", "ruby_mq_s2_defend_success", "ruby_mq_s3_orrery_defend_success", "ruby_mq_all_5_melody_pillars_on", "ruby_boss_fight_complete" ];
    }
    else if ( map == "zm_sat_firefly" )
    {
        // fixed splits: Gauntlet, lab lockdown (serum trial) end, keys cinematic start, challenges, boss arena
        // Gauntlet = the wonder weapon quest complete ("ash_ww" in menu_sr_done: zm_quest::is_quest_complete; the old
        // quest-object lookup gave no split at all on Ashes, 22-11)
        sr.names = [ "Gauntlet", "Lockdown end", "Keys", "Challenges", "Veytarion" ];
        sr.flags = [ "ash_ww", "serum_t_finished", "mid_igc_started", "MQ_STEP_18_COMPLETE", "firefly_boss_fight_complete" ];
    }
    else if ( map == "zm_sat_hornet" )
    {
        // fixed splits, in quest order; step 29 is the banners placed on the right spots
        sr.names = [ "Cat", "Mask", "Noble", "Poisons", "Locations", "Boss", "End" ];
        sr.flags = [ "nekomata_acquired", "mq_step_5_complete", "mq_acc_n_killed", "mq_step_21_complete", "mq_step_29_complete", "hornet_boss_fight_start", "hornet_boss_fight_complete" ];
    }
    else if ( map == "zm_sat_locust" )
    {
        // fixed splits, in quest order
        sr.names = [ "JOTUNN Star", "Atomkraft core", "Boss enter", "End" ];
        sr.flags = [ "ww_step_08", "mq_rp_step_03", "boss_fight_start", "boss_fight_end" ];
    }
    else if ( map == "zm_sat_mantis" )
    {
        // fixed splits, in quest order
        sr.names = [ "Chalk", "Sundergat", "Symbols", "Soulbox", "Boss enter", "End" ];
        sr.flags = [ "chalk_picked_up", "wwu_weapon_retrieved", "music_notes_puzzle_completed", "sheet_music_delivered", "start_boss_fight", "boss_fight_done" ];
    }
    else if ( map == "zm_sat_scarab" )
    {
        // fixed splits, in quest order; the PaP quest has no end flag, so split 1 reads the quest itself
        sr.quest = zm_quest::function_bf48db63228e7ef( #"hash_fbb52a4fe83b2f5c" );
        if ( !isdefined( sr.quest ) )
        {
            return false;
        }
        sr.names = [ "Pap", "House", "Vey Finish", "Boss Enter", "End" ];
        sr.flags = [ sr.quest, "wanna_wingo_eh", "vey_temples", "enter_boss_fight_done", "scarab_boss_fight_complete" ];
    }
    else
    {
        return false;
    }
    sr.map = map;
    sr.host = level.players[ 0 ];
    foreach ( player in level.players )
    {
        if ( player menu_is_host() )
        {
            sr.host = player;
        }
    }
    sr.index = 0;
    sr.times = [];
    sr.pb = [];
    // PB = split times of the fastest finished run, "ms,ms,..." in kronos/livesplit_bo7/speedrun.json
    nengine_store_load( "livesplit_bo7", "speedrun" );
    sr.pb_str = nengine_store_get( "livesplit_bo7", map );
    if ( isdefined( sr.pb_str ) && sr.pb_str != "" )
    {
        foreach ( part in strtok( sr.pb_str, "," ) )
        {
            sr.pb[ sr.pb.size ] = int( part );
        }
    }
    if ( sr.flags.size == 0 )
    {
        return false;
    }
    if ( sr.pb.size != sr.flags.size )
    {
        sr.pb = [];
    }
    sr.gums = nengine_store_get( "livesplit_bo7", "gums" );
    sr.timer = nengine_store_get( "livesplit_bo7", "timer" );
    sr.show = nengine_store_get( "livesplit_bo7", "show" );
    if ( !( sr.show === "0" ) )
    {
        sr.show = "1";
    }
    // pause menu FOV: "0" game default, "1" wide, "2" extra wide
    sr.fov = nengine_store_get( "livesplit_bo7", "fov" );
    if ( !( sr.fov === "1" || sr.fov === "2" ) )
    {
        sr.fov = "0";
    }
    sr.mode = nengine_store_get( "livesplit_bo7", "mode" );
    if ( !( sr.mode === "pap" || sr.mode === "r5" || sr.mode === "r15" || sr.mode === "r30" || sr.mode === "r50" || sr.mode === "r70" || sr.mode === "r100" ) )
    {
        sr.mode = "ee";
    }
    // "Start speedrun" asked before the restart, cleared so the next restart is a normal run
    sr.restart = nengine_store_get( "livesplit_bo7", "restart" );
    if ( sr.restart === "1" )
    {
        nengine_store_set( "livesplit_bo7", "restart", "0" );
        nengine_store_save( "livesplit_bo7", "speedrun" );
    }
    menu_sr_mode( sr );
    // RNG fixes from the store (pause menu choices), then zm_locust_extra.gsc may read them
    setdvar( @"zmm_ofish", menu_rng_load( "rng_fish", "1" ) );
    setdvar( @"zmm_orav", menu_rng_load( "rng_rav", "1" ) );
    setdvar( @"zmm_ocrate", menu_rng_load( "rng_crate", "1" ) );
    setdvar( @"zmm_opyre", menu_rng_load( "rng_pyre", "1" ) );
    setdvar( @"zmm_oradio", menu_rng_load( "rng_radio", "1" ) );
    setdvar( @"zmm_oastra", menu_rng_load( "rng_astra", "1" ) );
    // spook: "1" PB, "2" friend, "0" off
    sr.gh_saved = menu_rng_load( "ghost", "1" );
    nengine_store_load( "livesplit_bo7", "speedrun" );
    sr.gh_v = nengine_store_get( "livesplit_bo7", "ghost" );
    if ( sr.gh_v === "2" || sr.gh_v === "3" )
    {
        sr.gh_saved = sr.gh_v;
    }
    setdvar( @"zmm_pghost", sr.gh_saved );
    level.zmm_rng_ready = 1;
    level.zmm_sr = sr;
    return true;
}

function menu_sr_done( index )
{
    sr = level.zmm_sr;
    if ( sr.flags[ index ] === "pap" )
    {
        return istrue( sr.pap_done );
    }
    // round mode: the split ends when round N starts
    if ( istrue( sr.by_round ) )
    {
        return menu_current_round() >= sr.flags[ index ];
    }
    if ( sr.flags[ index ] === "ash_ww" )
    {
        if ( isdefined( level.zm_quests ) && isdefined( level.zm_quests[ #"firefly_ww_quest" ] ) && istrue( level.zm_quests[ #"firefly_ww_quest" ].completed ) )
        {
            return true;
        }
        // the wonder weapon (or its upgrade) in hand also counts: given straight away the quest never completes
        foreach ( player in level.players )
        {
            foreach ( w in player getweaponslistprimaries() )
            {
                if ( isdefined( w ) && ( w.basename == "sat_ww_firefly_zm" || w.basename == "sat_ww_firefly_ee_zm" ) )
                {
                    return true;
                }
            }
        }
        return false;
    }
    if ( sr.flags[ index ] === "vey_temples" )
    {
        return namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "sst_made_nice1" ) && namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "sst_made_nice2" ) && namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "sst_made_nice3" ) && namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "sst_made_nice4" );
    }
    if ( isstring( sr.flags[ index ] ) )
    {
        return namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( sr.flags[ index ] );
    }
    return sr.flags[ index ].var_cb2962eb3d2eb963 == 1;
}

function menu_sr_restart()
{
    if ( !isdefined( level.zmm_sr ) || !menu_is_host() || getdvar( @"zmm_lua" ) != "1" )
    {
        return 0;
    }
    nengine_store_load( "livesplit_bo7", "speedrun" );
    nengine_store_set( "livesplit_bo7", "restart", "1" );
    nengine_store_save( "livesplit_bo7", "speedrun" );
    setdvar( @"zmm_exec", "map_restart " + gettime() );
    return 1;
}

function menu_sr_wait_move()
{
    sr = level.zmm_sr;
    sr.from = sr.host.origin;
    sr.steps = 0;
    sr.moved_at = zm_rt_now();
    // 5 steps in a row filter out the spawn settling, but the run is timed from the first one
    while ( isdefined( sr.host ) && sr.steps < 5 )
    {
        waitframe();
        sr.delta = sr.host.origin - sr.from;
        sr.from = sr.host.origin;
        sr.moved = sr.delta[ 0 ] * sr.delta[ 0 ] + sr.delta[ 1 ] * sr.delta[ 1 ];
        if ( sr.moved > 2 && sr.moved < 2500 )
        {
            if ( sr.steps == 0 )
            {
                sr.moved_at = zm_rt_now();
            }
            sr.steps++;
        }
        else
        {
            sr.steps = 0;
        }
    }
}

function menu_sr_loop()
{
    level endon( #"game_ended" );
    while ( !menu_sr_someone_playing() )
    {
        wait 0.05;
    }
    // level.mapname is read once the map is up
    if ( !menu_sr_setup() )
    {
        return;
    }
    sr = level.zmm_sr;
    level thread menu_sr_restore_gums();
    level thread menu_pause_cmds();
    menu_sr_live( "idle" );
    // "Start speedrun" restarted the map: show the splits
    if ( sr.restart === "1" )
    {
        menu_sr_show();
    }
    menu_sr_count_attempt();
    menu_stats_push( sr );
    menu_avg_push( sr );
    // the run starts when the host moves, not at the spawn (the spawn comes ~30 s before control)
    menu_sr_wait_move();
    sr.start = sr.moved_at;
    // spookrun: de PB-run loopt als figuur mee
    level thread menu_ghost( sr );
    // run-logboek: elke queststap, ronde en split met tijd, per poging een eigen bestand in kronos\livesplit_bo7_runlog
    level thread menu_runlog( sr );
    menu_sr_live( "running" );
    while ( sr.index < sr.flags.size )
    {
        // last EE split: the end flag comes with the cutscene, but the run ends when the boss dies
        if ( sr.mode == "ee" && sr.index == sr.flags.size - 1 )
        {
            if ( menu_sr_boss_alive() )
            {
                sr.boss_dead_at = undefined;
            }
            else if ( !isdefined( sr.boss_dead_at ) && istrue( sr.boss_seen ) )
            {
                sr.boss_dead_at = zm_rt_now();
            }
        }
        if ( menu_sr_done( sr.index ) )
        {
            sr.times[ sr.index ] = menu_sr_now() - sr.start;
            menu_gold_track( sr, sr.index );
            iprintlnbold( "^2Split " + ( sr.index + 1 ) + "/" + sr.flags.size + " ^7" + sr.names[ sr.index ] + "  ^3" + menu_sr_time( sr.times[ sr.index ] ) + menu_sr_delta( sr.index ) );
            sr.index++;
            menu_sr_live( "running" );
        }
        else
        {
            waitframe();
        }
    }
    menu_sr_live( "done" );
    if ( sr.pb.size == 0 || sr.times[ sr.times.size - 1 ] < sr.pb[ sr.pb.size - 1 ] || !isdefined( sr.sub_ref_k ) || sr.sub_ref_k.size == 0 )
    {
        menu_sub_save( sr );
    }
    if ( sr.pb.size == 0 || sr.times[ sr.times.size - 1 ] < sr.pb[ sr.pb.size - 1 ] )
    {
        sr.pb = sr.times;
        sr.pb_str = "" + sr.times[ 0 ];
        for ( i = 1; i < sr.times.size; i++ )
        {
            sr.pb_str = sr.pb_str + "," + sr.times[ i ];
        }
        nengine_store_load( "livesplit_bo7", "speedrun" );
        nengine_store_set( "livesplit_bo7", sr.pb_key, sr.pb_str );
        // which attempt is the PB: its run log holds the route for the ghost run
        nengine_store_set( "livesplit_bo7", "pbatt_" + sr.pb_key, "" + sr.att );
        nengine_store_save( "livesplit_bo7", "speedrun" );
        menu_ghost_save( sr );
        iprintlnbold( "^2New PB: " + menu_sr_time( sr.times[ sr.times.size - 1 ] ) );
    }
    menu_stats_finish( sr, sr.times[ sr.times.size - 1 ] );
}

// the clock, frozen from the boss death until the end flag
function menu_sr_now()
{
    sr = level.zmm_sr;
    if ( isdefined( sr.boss_dead_at ) && sr.mode == "ee" && sr.index == sr.flags.size - 1 )
    {
        return sr.boss_dead_at;
    }
    return zm_rt_now();
}

// the boss AIs Livesplit-menu knows, per map; Astra's Uranus dies before Neptune spawns, so a later boss resets the death time
function menu_sr_boss_alive()
{
    sr = level.zmm_sr;
    // the game's boss health bar: while it is up, each player points at the boss it shows
    // (cleared when the bar hides, before the AI itself dies and the cutscene starts)
    foreach ( player in level.players )
    {
        if ( isdefined( player.var_7fa280bb4c563541 ) )
        {
            sr.bar_seen = 1;
            sr.boss_seen = 1;
            return true;
        }
    }
    if ( istrue( sr.bar_seen ) )
    {
        return false;
    }
    bosses = [];
    if ( isdefined( level.var_302bd0b94da202e7 ) )
    {
        bosses[ bosses.size ] = level.var_302bd0b94da202e7.entity;
    }
    if ( isdefined( level.var_703ffbe28e244b74 ) )
    {
        bosses[ bosses.size ] = level.var_703ffbe28e244b74.entity;
    }
    if ( isdefined( level.var_4630353ece991c26 ) )
    {
        bosses[ bosses.size ] = level.var_4630353ece991c26.entity;
    }
    if ( isdefined( level.var_d61ad599a05754c7 ) )
    {
        bosses[ bosses.size ] = level.var_d61ad599a05754c7.var_469a4c6b75d9c6cd;
    }
    bosses[ bosses.size ] = level.var_99042256ee32a16d;
    bosses[ bosses.size ] = level.zombie_neptune;
    team = "team_two_hundred";
    if ( isdefined( level.zombie_team ) )
    {
        team = level.zombie_team;
    }
    foreach ( ai in getaiarray( team ) )
    {
        if ( isdefined( ai ) && ai.var_e4312c2c1a4a2190 === "boss" )
        {
            bosses[ bosses.size ] = ai;
        }
    }
    foreach ( boss in bosses )
    {
        if ( isdefined( boss ) && isalive( boss ) )
        {
            sr.boss_seen = 1;
            return true;
        }
    }
    return false;
}

function menu_sr_someone_playing()
{
    if ( !isdefined( level.players ) )
    {
        return false;
    }
    foreach ( player in level.players )
    {
        if ( isdefined( player ) && isalive( player ) && player.sessionstate == "playing" )
        {
            return true;
        }
    }
    return false;
}

function menu_sr_time( ms )
{
    sr = level.zmm_sr;
    sr.f_ms = ms;
    sr.f_min = 0;
    sr.f_sec = 0;
    sr.f_tenth = 0;
    while ( sr.f_ms >= 60000 )
    {
        sr.f_min++;
        sr.f_ms -= 60000;
    }
    while ( sr.f_ms >= 1000 )
    {
        sr.f_sec++;
        sr.f_ms -= 1000;
    }
    while ( sr.f_ms >= 100 )
    {
        sr.f_tenth++;
        sr.f_ms -= 100;
    }
    return sr.f_min + ":" + ( sr.f_sec < 10 ? "0" : "" ) + sr.f_sec + "." + sr.f_tenth;
}

function menu_sr_delta( index )
{
    sr = level.zmm_sr;
    if ( sr.pb.size == 0 )
    {
        return "";
    }
    if ( sr.times[ index ] <= sr.pb[ index ] )
    {
        return "  ^2-" + menu_sr_time( sr.pb[ index ] - sr.times[ index ] );
    }
    return "  ^1+" + menu_sr_time( sr.times[ index ] - sr.pb[ index ] );
}

function menu_sr_text()
{
    sr = level.zmm_sr;
    if ( !isdefined( sr ) )
    {
        return "Splits: map not supported yet";
    }
    if ( !isdefined( sr.start ) )
    {
        return "0:00.0";
    }
    if ( sr.index >= sr.flags.size )
    {
        return "^2DONE " + menu_sr_time( sr.times[ sr.times.size - 1 ] ) + menu_sr_delta( sr.times.size - 1 );
    }
    sr.text = "^7#" + sr.att + " ^3" + menu_sr_time( menu_sr_now() - sr.start ) + "  ^7" + ( sr.index + 1 ) + "/" + sr.flags.size + " " + sr.names[ sr.index ];
    if ( sr.index > 0 )
    {
        sr.text = sr.text + "   ^7" + sr.names[ sr.index - 1 ] + " " + menu_sr_time( sr.times[ sr.index - 1 ] ) + menu_sr_delta( sr.index - 1 );
    }
    if ( sr.show == "0" )
    {
        return "^7#" + sr.att + " ^3" + menu_sr_time( menu_sr_now() - sr.start );
    }
    return sr.text;
}

function menu_sr_show()
{
    sr = level.zmm_sr;
    while ( isdefined( sr.host ) && !isdefined( sr.host.zmm ) )
    {
        waitframe();
    }
    if ( isdefined( sr.host ) && !( sr.timer === "0" ) && !sr.host menu_toggle_state( "speedrun" ) )
    {
        sr.host.zmm.toggles[ "speedrun" ] = 1;
        sr.host menu_apply_toggle( "speedrun" );
    }
}

function menu_loop_active( key )
{
    if ( !isdefined( self ) || !isplayer( self ) || !isdefined( self.zmm ) || !self.zmm.running )
    {
        return false;
    }
    return istrue( self.zmm.toggles[ key ] );
}

function menu_gum_ok( name )
{
    if ( !isdefined( name ) || name == "" || name == "none" || name == "empty" || name == "weapon_null" || name == "mr_peeks" )
    {
        return 0;
    }
    if ( !isdefined( level.bgb[ name ] ) || !isdefined( level.bgb[ name ].name ) || istrue( level.bgb[ name ].banned ) )
    {
        return 0;
    }
    gum_hash = getxhash( name );
    if ( !isdefined( level.gobblegums[ gum_hash ] ) || !isdefined( level.gobblegums[ gum_hash ].index ) )
    {
        return 0;
    }
    return 1;
}

function menu_gum_slot_busy( slot )
{
    if ( isdefined( self.var_f1dccd054c74a27e ) && istrue( self.var_f1dccd054c74a27e[ slot ] ) )
    {
        return 1;
    }
    if ( isdefined( self.bgb_activation_in_progress ) && istrue( self.bgb_activation_in_progress[ slot ] ) )
    {
        return 1;
    }
    return 0;
}

function menu_gum_in_other_slot( name, slot )
{
    for ( other = 1; other <= 3; other++ )
    {
        if ( other != slot && self.var_b02f6e7abbbc8a84[ other ] === name )
        {
            return 1;
        }
    }
    return 0;
}

function menu_write_gum_slot( slot, name )
{
    if ( !menu_gum_ok( name ) )
    {
        return 0;
    }
    index = level.gobblegums[ getxhash( name ) ].index;
    self.var_b02f6e7abbbc8a84[ slot ] = name;
    if ( slot == 2 )
    {
        self setclientomnvar( "ui_gobblegum_slot_2", index );
    }
    else if ( slot == 3 )
    {
        self setclientomnvar( "ui_gobblegum_slot_3", index );
    }
    else
    {
        self setclientomnvar( "ui_gobblegum_slot_1", index );
    }
    self setclientomnvar( "ui_focused_gobblegum_slot_index", slot );
    self setclientomnvar( "ui_gobblegum_slot_acquired_notify", slot );
    return 1;
}

function menu_param( label, action, value )
{
    ok = 0;
    if ( action == "restart" )
    {
        ok = menu_sr_restart();
    }
    menu_notify( label, ok );
}

function menu_both_warn()
{
    wait 20;
    iprintlnbold( "^1Livesplit BO7: another menu is enabled. Keep only one in the Workshop." );
}

function menu_pause_cmds()
{
    sr = level.zmm_sr;
    while ( isdefined( sr.host ) && !isdefined( sr.host.zmm ) )
    {
        waitframe();
    }
    setdvar( @"zmm_pgums", "0" );
    if ( sr.gums === "1" )
    {
        setdvar( @"zmm_pgums", "1" );
    }
    setdvar( @"zmm_pshow", sr.show );
    setdvar( @"zmm_pmode", sr.mode );
    setdvar( @"zmm_pfov", sr.fov );
    if ( sr.fov != "0" )
    {
        // the game resets the view on a new map: put the saved choice back
        level thread menu_fov_apply( 4 );
    }
    // set last: Lua waits for this dvar before adding the rows
    setdvar( @"zmm_ptimer", "1" );
    if ( sr.timer === "0" )
    {
        setdvar( @"zmm_ptimer", "0" );
    }
    while ( isdefined( sr.host ) )
    {
        menu_pause_sync( "speedrun", getdvar( @"zmm_ptimer" ) );
        menu_pause_sync( "gums", getdvar( @"zmm_pgums" ) );
        if ( !( getdvar( @"zmm_pshow" ) === sr.show ) )
        {
            sr.show = getdvar( @"zmm_pshow" );
            menu_pause_save( "show", sr.show );
        }
        if ( !( getdvar( @"zmm_pfov" ) === sr.fov ) )
        {
            sr.fov = getdvar( @"zmm_pfov" );
            menu_pause_save( "fov", sr.fov );
            level thread menu_fov_apply( 0 );
        }
        if ( !( getdvar( @"zmm_pmode" ) === sr.mode ) )
        {
            sr.mode = getdvar( @"zmm_pmode" );
            menu_pause_save( "mode", sr.mode );
            // before the first split the new mode takes over this run, after it the next run
            if ( sr.index == 0 )
            {
                menu_sr_mode( sr );
            }
            else
            {
                sr.host iprintlnbold( "^3New mode starts with the next run (Start speedrun)" );
            }
        }
        menu_rng_sync( sr );
        sr.p_cmd = getdvar( @"zmm_paction" );
        if ( sr.p_cmd != "" && !( sr.p_cmd === sr.p_last ) )
        {
            sr.p_last = sr.p_cmd;
            if ( issubstr( sr.p_cmd, "start" ) )
            {
                sr.host thread menu_param( "Start speedrun", "restart", 0 );
            }
        }
        wait 0.1;
    }
}

// the console route Livesplit-menu uses: set from GSC and through zmm_exec (one command per value)
function menu_fov_apply( delay )
{
    sr = level.zmm_sr;
    if ( delay > 0 )
    {
        wait delay;
    }
    // on the struct like Livesplit-menu does (locals came back undefined here)
    sr.fov_a = "65";
    sr.fov_b = "1";
    if ( sr.fov === "1" )
    {
        sr.fov_a = "110";
        sr.fov_b = "1.1";
    }
    else if ( sr.fov === "2" )
    {
        sr.fov_a = "110";
        sr.fov_b = "1.3";
    }
    setdvar( @"cg_fov", sr.fov_a );
    setdvar( @"cg_fovscale", sr.fov_b );
    setdvar( @"zmm_exec", "cg_fov " + sr.fov_a + " " + gettime() );
    wait 0.25;
    setdvar( @"zmm_exec", "cg_fovscale " + sr.fov_b + " " + gettime() );
}

// ---- run-logboek -------------------------------------------------------------
// Schrijft naar kronos\livesplit_bo7_runlog\<map>_<poging>.json: "count" en "e1001".. als "<ms sinds start> | <wat>".
// Alleen lezen, raakt de splits en de timer niet.
function menu_runlog( sr )
{
    level endon( #"game_ended" );
    sr.log_att = sr.att;
    sr.log_file = sr.map + "_" + sr.att;
    sr.log_n = 0;
    sr.log_prev = [];
    sr.log_round = -1;
    sr.log_split = 0;
    sr.log_tick = 0;
    sr.log_pos = "";
    sr.log_chunk = 0;
    // zm_locust_extra.gsc (Totenreich only) writes the Tyr's Head landings through this
    level.zmm_runlog_add = &menu_runlog_add;
    menu_sub_init( sr );
    menu_runlog_add( sr, 0, "START " + sr.map + " attempt " + sr.att + " mode " + sr.mode );
    while ( sr.log_att === sr.att )
    {
        menu_runlog_tick( sr );
        menu_sub_ghost( sr, zm_rt_now() - sr.start );
        menu_runlog_pos( sr );
        if ( isdefined( level.zmm_landing_fn ) )
        {
            [[ level.zmm_landing_fn ]]( sr, zm_rt_now() - sr.start );
        }
        if ( sr.index >= sr.flags.size )
        {
            menu_runlog_flush( sr );
            menu_runlog_add( sr, zm_rt_now() - sr.start, "FINISHED" );
            return;
        }
        wait 0.25;
    }
}

function menu_runlog_tick( sr )
{
    t = zm_rt_now() - sr.start;
    if ( sr.index != sr.log_split )
    {
        sr.log_split = sr.index;
        if ( sr.index > 0 && sr.index <= sr.names.size )
        {
            // de tijd die de timer zelf vastlegde (bij de laatste split: het moment dat de health bar verdween)
            st = t;
            if ( isdefined( sr.times ) && isdefined( sr.times[ sr.index - 1 ] ) )
            {
                st = sr.times[ sr.index - 1 ];
            }
            menu_runlog_add( sr, st, "SPLIT " + sr.index + " " + sr.names[ sr.index - 1 ] + " (log " + t + ")" );
        }
    }
    r = menu_current_round();
    if ( r != sr.log_round )
    {
        sr.log_round = r;
        menu_runlog_add( sr, t, "ROUND " + r );
    }
    if ( !isdefined( level.var_d5276f667352396b ) )
    {
        return;
    }
    i = 0;
    foreach ( q in level.var_d5276f667352396b )
    {
        i++;
        if ( isdefined( q ) )
        {
            bits = "";
            if ( isdefined( q.var_541f59354e1e2ddd ) )
            {
                foreach ( qstep in q.var_541f59354e1e2ddd )
                {
                    if ( isdefined( qstep ) && istrue( qstep.var_cb2962eb3d2eb963 ) )
                    {
                        bits = bits + "1";
                    }
                    else
                    {
                        bits = bits + "0";
                    }
                }
            }
            on = "-";
            if ( isdefined( q.var_7be076c9078045aa ) )
            {
                on = "" + q.var_7be076c9078045aa;
            }
            dn = "0";
            if ( istrue( q.var_cb2962eb3d2eb963 ) )
            {
                dn = "1";
            }
            line = "step " + on + " done " + dn + " " + bits;
            if ( !( sr.log_prev[ i ] === line ) )
            {
                if ( isdefined( sr.log_prev[ i ] ) )
                {
                    menu_runlog_add( sr, t, "Q" + i + " " + line );
                    menu_sub_step( sr, t, i, bits );
                }
                sr.log_prev[ i ] = line;
                sr.log_cnt[ i ] = menu_sub_count( bits );
            }
        }
    }
}

// positie van de host elke seconde ("<tiende s>,x,y,z;"), elke 20 s weggeschreven als p1001, p1002..
function menu_runlog_pos( sr )
{
    sr.log_tick++;
    if ( sr.log_tick % 4 == 0 && isdefined( sr.host ) && isdefined( sr.host.origin ) )
    {
        o = sr.host.origin;
        sr.log_pos = sr.log_pos + int( ( zm_rt_now() - sr.start ) / 100 ) + "," + int( o[ 0 ] ) + "," + int( o[ 1 ] ) + "," + int( o[ 2 ] ) + ";";
    }
    if ( sr.log_tick % 80 == 0 )
    {
        menu_stats_play( sr, 20000 );
        menu_runlog_flush( sr );
    }
}

function menu_runlog_flush( sr )
{
    if ( sr.log_pos == "" )
    {
        return;
    }
    sr.log_chunk++;
    nengine_store_load( "livesplit_bo7_runlog", sr.log_file );
    nengine_store_set( "livesplit_bo7_runlog", "p" + ( 1000 + sr.log_chunk ), sr.log_pos );
    nengine_store_set( "livesplit_bo7_runlog", "pcount", "" + sr.log_chunk );
    nengine_store_save( "livesplit_bo7_runlog", sr.log_file );
    sr.log_pos = "";
}

function menu_runlog_add( sr, t, text )
{
    sr.log_n++;
    nengine_store_load( "livesplit_bo7_runlog", sr.log_file );
    nengine_store_set( "livesplit_bo7_runlog", "e" + ( 1000 + sr.log_n ), "" + t + " | " + text );
    nengine_store_set( "livesplit_bo7_runlog", "count", "" + sr.log_n );
    nengine_store_save( "livesplit_bo7_runlog", sr.log_file );
}

function menu_pause_save( key, value )
{
    nengine_store_load( "livesplit_bo7", "speedrun" );
    nengine_store_set( "livesplit_bo7", key, value );
    nengine_store_save( "livesplit_bo7", "speedrun" );
}

function menu_sr_mode( sr )
{
    // the map's EE splits, kept so the pause menu can switch back to them
    if ( !isdefined( sr.ee_names ) )
    {
        sr.ee_names = sr.names;
        sr.ee_flags = sr.flags;
    }
    sr.names = sr.ee_names;
    sr.flags = sr.ee_flags;
    sr.by_round = undefined;
    sr.pb_key = sr.map;
    if ( sr.mode == "pap" )
    {
        sr.pb_key = sr.map + "_pap";
        sr.names = [ "PaP Taken" ];
        sr.flags = [ "pap" ];
        // fired by the Pack-a-Punch machine when it upgrades a weapon
        if ( !istrue( sr.pap_hooked ) )
        {
            sr.pap_hooked = 1;
            level callback::add( #"hash_eee96f780807d870", &menu_sr_on_pap );
        }
    }
    else if ( sr.mode != "ee" )
    {
        sr.pb_key = sr.map + "_" + sr.mode;
        // "r30" = reach round 30: R5 splits every round, R15 / R30 every 5, the longer ones every 10
        target = int( getsubstr( sr.mode, 1 ) );
        step = 10;
        if ( target <= 5 )
        {
            step = 1;
        }
        else if ( target <= 30 )
        {
            step = 5;
        }
        sr.by_round = 1;
        sr.names = [];
        sr.flags = [];
        for ( r = step; r <= target; r += step )
        {
            if ( r < 2 )
            {
                continue;
            }
            sr.names[ sr.names.size ] = "Round " + r;
            sr.flags[ sr.flags.size ] = r;
        }
    }
    sr.pb = [];
    sr.pb_str = nengine_store_get( "livesplit_bo7", sr.pb_key );
    if ( isdefined( sr.pb_str ) && sr.pb_str != "" )
    {
        foreach ( part in strtok( sr.pb_str, "," ) )
        {
            sr.pb[ sr.pb.size ] = int( part );
        }
    }
    if ( sr.pb.size != sr.flags.size )
    {
        sr.pb = [];
    }
}

function menu_current_round()
{
    if ( isdefined( level.round_number ) )
    {
        return level.round_number;
    }
    if ( isdefined( level.var_6781718da4f78d1c ) && isdefined( level.var_6781718da4f78d1c.roundnumber ) )
    {
        return level.var_6781718da4f78d1c.roundnumber;
    }
    return 1;
}

function menu_sr_on_pap( params )
{
    level.zmm_sr.pap_done = 1;
}

function menu_sr_splice()
{
    sr = level.zmm_sr;
    // the dvar outlives map restarts: one id per game session, like the BO3 mod
    sr.sid = getdvar( @"zmm_session" );
    if ( !isdefined( sr.sid ) || sr.sid == "" )
    {
        sr.sid = "";
        sr.sid_chars = strtok( "A,B,C,D,E,F,G,H,J,K,L,M,N,P,Q,R,S,T,U,V,W,X,Y,Z,2,3,4,5,6,7,8,9", "," );
        for ( sr.sid_i = 0; sr.sid_i < 10; sr.sid_i++ )
        {
            sr.sid += sr.sid_chars[ randomint( sr.sid_chars.size ) ];
        }
        setdvar( @"zmm_session", sr.sid );
    }
    setdvar( @"zmm_splice", sr.sid + " ^5#" + sr.att + " ^7Livesplit BO7 alpha by Redouan B & Fuzion28" );
}

function menu_pause_sync( key, value )
{
    sr = level.zmm_sr;
    sr.p_on = sr.host menu_toggle_state( key );
    if ( ( value == "1" && !sr.p_on ) || ( value == "0" && sr.p_on ) )
    {
        sr.host menu_toggle( key );
    }
}

function menu_sr_restore_gums()
{
    sr = level.zmm_sr;
    while ( isdefined( sr.host ) && !isdefined( sr.host.zmm ) )
    {
        waitframe();
    }
    if ( isdefined( sr.host ) && sr.gums === "1" )
    {
        sr.host.zmm.toggles[ "gums" ] = 1;
        sr.host menu_apply_toggle( "gums" );
    }
}

function menu_gum_refill()
{
    state = self.zmm;
    state.gum_keep = [];
    while ( isdefined( self ) && menu_loop_active( "gums" ) )
    {
        if ( isdefined( level.bgb ) && isdefined( level.gobblegums ) && isdefined( self.var_b02f6e7abbbc8a84 ) )
        {
            for ( slot = 1; slot <= 3; slot++ )
            {
                if ( menu_gum_ok( self.var_b02f6e7abbbc8a84[ slot ] ) )
                {
                    state.gum_keep[ slot ] = self.var_b02f6e7abbbc8a84[ slot ];
                }
                else if ( isdefined( state.gum_keep[ slot ] ) && !menu_gum_slot_busy( slot ) && !menu_gum_in_other_slot( state.gum_keep[ slot ], slot ) )
                {
                    menu_write_gum_slot( slot, state.gum_keep[ slot ] );
                }
            }
        }
        wait 0.5;
    }
    state.gum_loop = 0;
}

function menu_sr_count_attempt()
{
    sr = level.zmm_sr;
    nengine_store_load( "livesplit_bo7", "speedrun" );
    sr.att_str = nengine_store_get( "livesplit_bo7", "att_" + sr.map );
    sr.att = 1;
    if ( isdefined( sr.att_str ) && sr.att_str != "" )
    {
        sr.att = int( sr.att_str ) + 1;
    }
    nengine_store_set( "livesplit_bo7", "att_" + sr.map, "" + sr.att );
    nengine_store_save( "livesplit_bo7", "speedrun" );
    menu_sr_splice();
}

function menu_sr_live( status )
{
    sr = level.zmm_sr;
    nengine_store_load( "livesplit_bo7", "live" );
    nengine_store_set( "livesplit_bo7", "status", status );
    nengine_store_set( "livesplit_bo7", "split", "" + sr.index );
    nengine_store_save( "livesplit_bo7", "live" );
}


// ---------------------------------------------------------------- splitter layout bridge
// Hands the speedrun data to zm_splitter_post.lua through dvars:
//   zm_sr 1 = splits from this mod, 2 = still waiting, 0 = no splits for this map (own clock, F6 splits)
//   zm_srmap map name, zm_srnames split names (|), zm_srpb PB times in ms (,), zm_srt finished split times in ms (,)
//   zm_tms real time in ms (0 until you move, stays at the last split when done), zm_trun 1 while it counts
//   zm_rt / zm_rtq are written by the Lua: wall clock in ms, 1 when it is finer than a second
function zmsplit_join( arr, sep )
{
    out = "";
    if ( !isdefined( arr ) )
    {
        return out;
    }
    for ( i = 0; i < arr.size; i++ )
    {
        if ( i > 0 )
        {
            out = out + sep;
        }
        out = out + arr[ i ];
    }
    return out;
}

// best segments: kept per key in the store ("<map>_best", "<map>_pap_best", "<map>_r30_best"...) as "ms,ms,..."
// and updated each time a split ends faster than ever before
function zmsplit_best_key( sr )
{
    key = sr.map;
    if ( isdefined( sr.pb_key ) )
    {
        key = sr.pb_key;
    }
    return key + "_best";
}

function zmsplit_best_load( sr, st )
{
    st.bkey = zmsplit_best_key( sr );
    st.best = [];
    nengine_store_load( "livesplit_bo7", "speedrun" );
    st.bstr = nengine_store_get( "livesplit_bo7", st.bkey );
    if ( isdefined( st.bstr ) && st.bstr != "" )
    {
        foreach ( part in strtok( st.bstr, "," ) )
        {
            st.best[ st.best.size ] = int( part );
        }
    }
    if ( st.best.size != sr.flags.size )
    {
        st.best = [];
    }
    st.nd = sr.times.size;
}

function zmsplit_best_text( sr, st )
{
    out = "";
    for ( i = 0; i < sr.flags.size; i++ )
    {
        if ( i > 0 )
        {
            out = out + ",";
        }
        if ( isdefined( st.best[ i ] ) )
        {
            out = out + st.best[ i ];
        }
        else
        {
            out = out + "0";
        }
    }
    return out;
}

function zmsplit_best_update( sr, st )
{
    st.dirty = 0;
    while ( st.nd < sr.times.size )
    {
        st.seg = sr.times[ st.nd ];
        if ( st.nd > 0 )
        {
            st.seg = st.seg - sr.times[ st.nd - 1 ];
        }
        if ( !isdefined( st.best[ st.nd ] ) || st.best[ st.nd ] <= 0 || st.seg < st.best[ st.nd ] )
        {
            st.best[ st.nd ] = st.seg;
            st.dirty = 1;
        }
        st.nd++;
    }
    if ( st.dirty )
    {
        nengine_store_load( "livesplit_bo7", "speedrun" );
        nengine_store_set( "livesplit_bo7", st.bkey, zmsplit_best_text( sr, st ) );
        nengine_store_save( "livesplit_bo7", "speedrun" );
    }
}

function zmsplit_bridge()
{
    level endon( #"game_ended" );
    st = spawnstruct();
    st.active = 0;
    st.manual = 0;
    st.sent = "";
    st.nm_sent = "";
    st.pb_sent = "";
    st.bt_sent = "";

    setdvar( "zm_tms", 0 );
    setdvar( "zm_sr", 2 );
    setdvar( "zm_srmap", "" );
    setdvar( "zm_srnames", "" );
    setdvar( "zm_srpb", "" );
    setdvar( "zm_srbest", "" );
    setdvar( "zm_srt", "" );
    setdvar( "zm_sravg", "" );
    setdvar( "zm_srsub", "" );
    setdvar( "zm_split", 0 );
    setdvar( "zm_trun", 0 );
    setdvar( @"zm_rt", "0" );
    setdvar( @"zm_rtq", "0" );

    while ( !isdefined( level.players ) || level.players.size == 0 )
    {
        waitframe();
    }
    st.t0 = zm_rt_now();

    while ( true )
    {
        sr = level.zmm_sr;
        if ( isdefined( sr ) && isdefined( sr.names ) && isdefined( sr.flags ) )
        {
            if ( !st.active )
            {
                st.active = 1;
                setdvar( "zm_srmap", sr.map );
                setdvar( "zm_sr", 1 );
            }
            // names and PB are re-sent when they change (PaP mode swaps the split list, a new PB replaces the old)
            st.nm = zmsplit_join( sr.names, "|" );
            if ( st.nm != st.nm_sent )
            {
                st.nm_sent = st.nm;
                setdvar( "zm_srnames", st.nm );
            }
            st.pbs = zmsplit_join( sr.pb, "," );
            if ( st.pbs != st.pb_sent )
            {
                st.pb_sent = st.pbs;
                setdvar( "zm_srpb", st.pbs );
            }
            st.key = "" + sr.index;
            st.times = zmsplit_join( sr.times, "," );
            if ( !isdefined( st.bkey ) || st.bkey != zmsplit_best_key( sr ) )
            {
                zmsplit_best_load( sr, st );
            }
            zmsplit_best_update( sr, st );
            st.bt = zmsplit_best_text( sr, st );
            if ( st.bt != st.bt_sent )
            {
                st.bt_sent = st.bt;
                setdvar( "zm_srbest", st.bt );
            }
            if ( st.key != st.sent )
            {
                st.sent = st.key;
                setdvar( "zm_srt", st.times );
            }
            if ( !isdefined( sr.start ) )
            {
                setdvar( "zm_tms", 0 );
                setdvar( "zm_trun", 0 );
            }
            else if ( sr.index >= sr.flags.size )
            {
                setdvar( "zm_tms", sr.times[ sr.times.size - 1 ] );
                setdvar( "zm_trun", 0 );
            }
            else
            {
                setdvar( "zm_tms", menu_sr_now() - sr.start );
                setdvar( "zm_trun", !isdefined( sr.boss_dead_at ) );
            }
        }
        else if ( zm_rt_now() - st.t0 > 15000 )
        {
            // no splits for this map: own clock from the spawn, split by hand with F6
            if ( !st.manual )
            {
                st.manual = 1;
                setdvar( "zm_sr", 0 );
                setdvar( "zm_trun", 1 );
            }
            setdvar( "zm_tms", zm_rt_now() - st.t0 );
        }
        waitframe();
    }
}

// real time (speedruns are timed in real time): gettime() stops while the game is paused,
// so it follows the Lua wall clock zm_rt (every frame with a fine clock, past a 1.2 s slack with a whole-second one)
// shortcut: a whole-second clock is off by up to 1.2 s, and gettime() alone is used without the Lua
function zm_rt_now()
{
    if ( !isdefined( level.zm_rt_add ) )
    {
        level.zm_rt_add = 0;
    }
    level.zm_rt_wall = int( getdvar( @"zm_rt" ) );
    if ( level.zm_rt_wall > 0 )
    {
        level.zm_rt_lag = level.zm_rt_wall - gettime();
        if ( !isdefined( level.zm_rt_base ) )
        {
            level.zm_rt_base = level.zm_rt_lag;
        }
        level.zm_rt_off = level.zm_rt_lag - level.zm_rt_base - level.zm_rt_add;
        level.zm_rt_slack = getdvar( @"zm_rtq" ) == "1" ? 0 : 1200;
        if ( level.zm_rt_off > level.zm_rt_slack || level.zm_rt_off < 0 - level.zm_rt_slack )
        {
            level.zm_rt_add = level.zm_rt_lag - level.zm_rt_base;
        }
    }
    return gettime() + level.zm_rt_add;
}


// ---------------------------------------------------------------- sub-splits per quest step + PB ghost
// Every finished quest step is a sub-split "Q<quest>.<steps done>". The PB run's steps are kept in the store as
// <map>_sub = "Q6.2:423009,Q6.3:449121,..." (ms from the start). zmm_sub shows the last step with its delta to
// the PB, zmm_ghost what the PB run had done at this moment and how long until its next step.
function menu_sub_init( sr )
{
    sr.log_cnt = [];
    sr.sub_k = [];
    sr.sub_t = [];
    sr.sub_ref_k = [];
    sr.sub_ref_t = [];
    sr.sub_gi = -2;
    nengine_store_load( "livesplit_bo7", "speedrun" );
    sr.sub_str = nengine_store_get( "livesplit_bo7", sr.map + "_sub" );
    if ( isdefined( sr.sub_str ) && sr.sub_str != "" )
    {
        sr.sub_parts = strtok( sr.sub_str, "," );
        for ( sr.sub_j = 0; sr.sub_j < sr.sub_parts.size; sr.sub_j++ )
        {
            sr.sub_kv = strtok( sr.sub_parts[ sr.sub_j ], ":" );
            if ( sr.sub_kv.size == 2 )
            {
                sr.sub_ref_k[ sr.sub_ref_k.size ] = sr.sub_kv[ 0 ];
                sr.sub_ref_t[ sr.sub_ref_t.size ] = int( sr.sub_kv[ 1 ] );
            }
        }
    }
    setdvar( @"zmm_sub", "" );
    setdvar( @"zmm_ghost", "" );
}

function menu_sub_count( bits )
{
    level.zmm_sub_n = 0;
    for ( level.zmm_sub_c = 0; level.zmm_sub_c < bits.size; level.zmm_sub_c++ )
    {
        if ( bits[ level.zmm_sub_c ] == "1" )
        {
            level.zmm_sub_n++;
        }
    }
    return level.zmm_sub_n;
}

// readable name of a sub-split key, with the step count of that quest when known
function menu_sub_label( key )
{
    level.zmm_sub_lp = strtok( key, "." );
    if ( level.zmm_sub_lp.size != 2 )
    {
        return key;
    }
    level.zmm_sub_q = level.zmm_sub_lp[ 0 ];
    level.zmm_sub_name = level.zmm_sub_q;
    if ( isdefined( level.mapname ) && level.mapname == "zm_sat_locust" )
    {
        switch ( level.zmm_sub_q )
        {
            case "Q5":
                level.zmm_sub_name = "Pack-a-Punch";
                break;
            case "Q6":
                level.zmm_sub_name = "JOTUNN";
                break;
            case "Q10":
                level.zmm_sub_name = "Boss";
                break;
            case "Q11":
                level.zmm_sub_name = "Main quest";
                break;
            case "Q12":
                level.zmm_sub_name = "Reactor";
                break;
            case "Q13":
                level.zmm_sub_name = "Compass";
                break;
        }
    }
    level.zmm_sub_tot = "";
    if ( isdefined( level.var_d5276f667352396b ) )
    {
        level.zmm_sub_qi = 0;
        foreach ( q in level.var_d5276f667352396b )
        {
            level.zmm_sub_qi++;
            if ( "Q" + level.zmm_sub_qi == level.zmm_sub_q && isdefined( q ) && isdefined( q.var_541f59354e1e2ddd ) )
            {
                level.zmm_sub_tot = "/" + q.var_541f59354e1e2ddd.size;
            }
        }
    }
    return level.zmm_sub_name + " " + level.zmm_sub_lp[ 1 ] + level.zmm_sub_tot;
}

function menu_sub_step( sr, t, i, bits )
{
    sr.sub_n = menu_sub_count( bits );
    if ( !isdefined( sr.log_cnt[ i ] ) || sr.sub_n <= sr.log_cnt[ i ] )
    {
        return;
    }
    sr.sub_key = "Q" + i + "." + sr.sub_n;
    sr.sub_k[ sr.sub_k.size ] = sr.sub_key;
    sr.sub_t[ sr.sub_t.size ] = t;
    sr.sub_text = menu_sub_label( sr.sub_key ) + "  ^7" + menu_sr_time( t );
    for ( sr.sub_j = 0; sr.sub_j < sr.sub_ref_k.size; sr.sub_j++ )
    {
        if ( sr.sub_ref_k[ sr.sub_j ] == sr.sub_key )
        {
            sr.sub_d = t - sr.sub_ref_t[ sr.sub_j ];
            if ( sr.sub_d <= 0 )
            {
                sr.sub_text = sr.sub_text + "  ^2-" + menu_sub_secs( 0 - sr.sub_d );
            }
            else
            {
                sr.sub_text = sr.sub_text + "  ^1+" + menu_sub_secs( sr.sub_d );
            }
            break;
        }
    }
    setdvar( @"zmm_sub", sr.sub_text );
}

// 12345 ms -> "12.3"
function menu_sub_secs( ms )
{
    level.zmm_sub_ds = int( ms / 100 );
    return "" + int( level.zmm_sub_ds / 10 ) + "." + ( level.zmm_sub_ds % 10 );
}

function menu_sub_ghost( sr, t )
{
    menu_sub_list( sr );
    if ( sr.sub_ref_k.size == 0 )
    {
        return;
    }
    sr.sub_g = -1;
    for ( sr.sub_j = 0; sr.sub_j < sr.sub_ref_t.size; sr.sub_j++ )
    {
        if ( sr.sub_ref_t[ sr.sub_j ] <= t )
        {
            sr.sub_g = sr.sub_j;
        }
    }
    // the text changes every second (countdown to the next PB step)
    sr.sub_gs = int( t / 1000 );
    if ( sr.sub_g == sr.sub_gi && sr.sub_gs === sr.sub_gsl )
    {
        return;
    }
    sr.sub_gi = sr.sub_g;
    sr.sub_gsl = sr.sub_gs;
    sr.sub_gt = "^5PB^7: start";
    if ( sr.sub_g >= 0 )
    {
        sr.sub_gt = "^5PB^7: " + menu_sub_label( sr.sub_ref_k[ sr.sub_g ] );
    }
    if ( sr.sub_g + 1 < sr.sub_ref_t.size )
    {
        sr.sub_gt = sr.sub_gt + "  ^7(next in " + int( ( sr.sub_ref_t[ sr.sub_g + 1 ] - t ) / 1000 ) + " s)";
    }
    setdvar( @"zmm_ghost", sr.sub_gt );
}

function menu_sub_save( sr )
{
    if ( !isdefined( sr.sub_k ) || sr.sub_k.size == 0 )
    {
        return;
    }
    sr.sub_save = "";
    for ( sr.sub_j = 0; sr.sub_j < sr.sub_k.size; sr.sub_j++ )
    {
        if ( sr.sub_j > 0 )
        {
            sr.sub_save = sr.sub_save + ",";
        }
        sr.sub_save = sr.sub_save + sr.sub_k[ sr.sub_j ] + ":" + sr.sub_t[ sr.sub_j ];
    }
    nengine_store_load( "livesplit_bo7", "speedrun" );
    nengine_store_set( "livesplit_bo7", sr.map + "_sub", sr.sub_save );
    nengine_store_save( "livesplit_bo7", "speedrun" );
}


// ---------------------------------------------------------------- statistics (pause menu panel)
// Kept per map in kronos\livesplit_bo7\speedrun.json: fin_<map> finished runs, sum_<map> their total time (for the
// average), play_<map> ms played in logged runs. att_<map> (attempts) and the PB already exist.
function menu_stats_get( key )
{
    nengine_store_load( "livesplit_bo7", "speedrun" );
    level.zmm_st_v = nengine_store_get( "livesplit_bo7", key );
    if ( !isdefined( level.zmm_st_v ) || level.zmm_st_v == "" )
    {
        return 0;
    }
    return int( level.zmm_st_v );
}

function menu_stats_push( sr )
{
    sr.st_fin = menu_stats_get( "fin_" + sr.map );
    sr.st_sum = menu_stats_get( "sum_" + sr.map );
    sr.st_play = menu_stats_get( "play_" + sr.map );
    sr.st_avg = 0;
    if ( sr.st_fin > 0 )
    {
        sr.st_avg = int( sr.st_sum / sr.st_fin );
    }
    sr.st_pb = 0;
    if ( isdefined( sr.pb ) && sr.pb.size > 0 )
    {
        sr.st_pb = sr.pb[ sr.pb.size - 1 ];
    }
    sr.st_att = 0;
    if ( isdefined( sr.att ) )
    {
        sr.st_att = sr.att;
    }
    setdvar( @"zmm_stats", "" + sr.st_att + "|" + sr.st_fin + "|" + sr.st_pb + "|" + sr.st_avg + "|" + sr.st_play );
    ls_pbs_push();
}

// ---------------------------------------------------------------- het menupaneel: PB's van alle maps voor het menu
// dvar ls_pbs = "map:pb:sob:pogingen:uitgespeeld;..." (ms; 0 = onbekend). Het vak van het menupaneel (menu-lua) leest dit in
// het pauzemenu en onthoudt het voor het hoofdmenu. Alleen lezen uit de store, er wordt niets opgeslagen.
function ls_pbs_num( v )
{
    if ( !isdefined( v ) || v == "" )
    {
        return 0;
    }
    return int( v );
}

function ls_pbs_push()
{
    f = spawnstruct();
    f.maps = [ "zm_sat_ruby", "zm_sat_locust", "zm_sat_firefly", "zm_sat_hornet", "zm_sat_mantis", "zm_sat_scarab" ];
    f.out = "";
    nengine_store_load( "livesplit_bo7", "speedrun" );
    foreach ( m in f.maps )
    {
        f.pb = 0;
        f.v = nengine_store_get( "livesplit_bo7", m );
        if ( isdefined( f.v ) && f.v != "" )
        {
            f.parts = strtok( f.v, "," );
            if ( f.parts.size > 0 )
            {
                f.pb = int( f.parts[ f.parts.size - 1 ] );
            }
        }
        // sum of best: alle beste segmenten opgeteld; een segment zonder beste tijd (0) telt met zijn PB-segment
        f.sob = 0;
        f.v = nengine_store_get( "livesplit_bo7", m + "_best" );
        if ( f.pb > 0 && isdefined( f.v ) && f.v != "" )
        {
            f.best = strtok( f.v, "," );
            if ( f.best.size == f.parts.size )
            {
                f.prev = 0;
                for ( i = 0; i < f.best.size; i++ )
                {
                    f.n = int( f.best[ i ] );
                    f.seg = int( f.parts[ i ] ) - f.prev;
                    f.prev = int( f.parts[ i ] );
                    if ( f.n <= 0 || f.n > f.seg )
                    {
                        f.n = f.seg;
                    }
                    f.sob = f.sob + f.n;
                }
            }
        }
        f.att = ls_pbs_num( nengine_store_get( "livesplit_bo7", "att_" + m ) );
        f.fin = ls_pbs_num( nengine_store_get( "livesplit_bo7", "fin_" + m ) );
        f.out = f.out + m + ":" + f.pb + ":" + f.sob + ":" + f.att + ":" + f.fin + ";";
    }
    setdvar( "ls_pbs", f.out );
}

function menu_stats_play( sr, ms )
{
    nengine_store_load( "livesplit_bo7", "speedrun" );
    sr.st_v = nengine_store_get( "livesplit_bo7", "play_" + sr.map );
    sr.st_n = 0;
    if ( isdefined( sr.st_v ) && sr.st_v != "" )
    {
        sr.st_n = int( sr.st_v );
    }
    nengine_store_set( "livesplit_bo7", "play_" + sr.map, "" + ( sr.st_n + ms ) );
    nengine_store_save( "livesplit_bo7", "speedrun" );
    menu_stats_push( sr );
}

function menu_stats_finish( sr, final_ms )
{
    sr.st_f = menu_stats_get( "fin_" + sr.map ) + 1;
    sr.st_s = menu_stats_get( "sum_" + sr.map ) + final_ms;
    nengine_store_load( "livesplit_bo7", "speedrun" );
    nengine_store_set( "livesplit_bo7", "fin_" + sr.map, "" + sr.st_f );
    nengine_store_set( "livesplit_bo7", "sum_" + sr.map, "" + sr.st_s );
    nengine_store_save( "livesplit_bo7", "speedrun" );
    menu_stats_push( sr );
}

// ---------------------------------------------------------------- ghost run
// A run log (p1001.. = "tenths,x,y,z;" every second) is replayed: a zombie walks that route at the same run time.
// Routes are kept in their own store, kronos\livesplit_bo7_ghost\<map>_<attempt>.json (copied from the run log when a run
// sets a PB or a gold segment): reading them through the run log store mixed old runs into new run logs.
// Pause menu row SPOOK: "1" PB = your PB run;
// "3" GOUD = your best segments: each segment walked by the run that set it, one after the other (sum of best);
// "2" VRIEND = a friend's run (his run log for this map as kronos\livesplit_bo7_friend\<map>.json); "0" off.
function menu_ghost( sr )
{
    level endon( #"game_ended" );
    sr.gh_mode = getdvar( @"zmm_pghost" );
    if ( !isdefined( sr.pb_key ) || !( sr.gh_mode === "1" || sr.gh_mode === "2" || sr.gh_mode === "3" ) )
    {
        return;
    }
    sr.gh_runs = [];
    sr.gh_seg_run = [];
    sr.gh_seg_st = [];
    sr.gh_seg_end = [];
    if ( sr.gh_mode == "2" )
    {
        sr.gh_r = menu_ghost_load( "livesplit_bo7_friend", sr.map );
        if ( !isdefined( sr.gh_r ) )
        {
            return;
        }
        sr.gh_runs[ 0 ] = sr.gh_r;
    }
    else if ( sr.gh_mode == "1" )
    {
        nengine_store_load( "livesplit_bo7", "speedrun" );
        sr.gh_att = nengine_store_get( "livesplit_bo7", "pbatt_" + sr.pb_key );
        if ( !isdefined( sr.gh_att ) || sr.gh_att == "" )
        {
            return;
        }
        sr.gh_r = menu_ghost_load( "livesplit_bo7_ghost", sr.map + "_" + sr.gh_att );
        if ( !isdefined( sr.gh_r ) )
        {
            return;
        }
        sr.gh_runs[ 0 ] = sr.gh_r;
    }
    else
    {
        nengine_store_load( "livesplit_bo7", "speedrun" );
        sr.gh_ga = nengine_store_get( "livesplit_bo7", "goldatt_" + sr.pb_key );
        sr.gh_gs = nengine_store_get( "livesplit_bo7", "goldst_" + sr.pb_key );
        sr.gh_gd = nengine_store_get( "livesplit_bo7", "golddur_" + sr.pb_key );
        if ( !isdefined( sr.gh_ga ) || !isdefined( sr.gh_gs ) || !isdefined( sr.gh_gd ) )
        {
            return;
        }
        sr.gh_ga = strtok( sr.gh_ga, "," );
        sr.gh_gs = strtok( sr.gh_gs, "," );
        sr.gh_gd = strtok( sr.gh_gd, "," );
        if ( sr.gh_ga.size == 0 || sr.gh_ga.size != sr.gh_gs.size || sr.gh_ga.size != sr.gh_gd.size )
        {
            return;
        }
        sr.gh_byatt = [];
        sr.gh_cum = 0;
        for ( sr.gh_s = 0; sr.gh_s < sr.gh_ga.size; sr.gh_s++ )
        {
            sr.gh_key = "a" + sr.gh_ga[ sr.gh_s ];
            if ( !isdefined( sr.gh_byatt[ sr.gh_key ] ) )
            {
                sr.gh_r = menu_ghost_load( "livesplit_bo7_ghost", sr.map + "_" + sr.gh_ga[ sr.gh_s ] );
                if ( !isdefined( sr.gh_r ) )
                {
                    // no route for this segment: the ghost waits out that segment hidden
                    sr.gh_r = spawnstruct();
                    sr.gh_r.missing = 1;
                }
                sr.gh_byatt[ sr.gh_key ] = sr.gh_runs.size;
                sr.gh_runs[ sr.gh_runs.size ] = sr.gh_r;
            }
            sr.gh_seg_run[ sr.gh_s ] = sr.gh_byatt[ sr.gh_key ];
            sr.gh_seg_st[ sr.gh_s ] = int( sr.gh_gs[ sr.gh_s ] );
            sr.gh_cum = sr.gh_cum + int( sr.gh_gd[ sr.gh_s ] );
            sr.gh_seg_end[ sr.gh_s ] = sr.gh_cum;
        }
    }
    if ( !isdefined( sr.host ) )
    {
        return;
    }
    // the ghost looks like a zombie: the model of the first zombie that is alive (none yet at the start: wait)
    sr.gh_att_wait = 0;
    sr.gh_model = undefined;
    while ( !isdefined( sr.gh_model ) && sr.gh_att_wait < 1200 )
    {
        foreach ( gh_ai in getaiarray() )
        {
            if ( !isdefined( sr.gh_model ) && isdefined( gh_ai ) && isalive( gh_ai ) && isdefined( gh_ai.model ) && !istrue( gh_ai.isboss ) )
            {
                sr.gh_model = gh_ai.model;
            }
        }
        if ( !isdefined( sr.gh_model ) )
        {
            sr.gh_att_wait++;
            wait 0.5;
        }
    }
    if ( !isdefined( sr.gh_model ) )
    {
        return;
    }
    sr.gh_spawnpos = sr.host.origin;
    foreach ( gh_run in sr.gh_runs )
    {
        if ( !istrue( gh_run.missing ) )
        {
            sr.gh_spawnpos = gh_run.p[ 0 ];
        }
    }
    sr.ghost = utility::spawn_model( sr.gh_model, sr.gh_spawnpos, ( 0, 0, 0 ) );
    if ( !isdefined( sr.ghost ) )
    {
        return;
    }
    sr.ghost notsolid();
    sr.gh_att_run = sr.att;
    while ( sr.gh_att_run === sr.att && sr.index < sr.flags.size && isdefined( sr.ghost ) )
    {
        if ( getdvar( @"zmm_pghost" ) == "0" )
        {
            sr.ghost hide();
        }
        else
        {
            sr.ghost show();
            sr.gh_now = zm_rt_now() - sr.start;
            sr.gh_run = sr.gh_runs[ 0 ];
            sr.gh_tt = sr.gh_now;
            if ( sr.gh_seg_end.size > 0 )
            {
                // gold: the segment the ghost is in, and the time inside the run that set it
                sr.gh_s = sr.gh_seg_end.size - 1;
                for ( sr.gh_k = sr.gh_seg_end.size - 1; sr.gh_k >= 0; sr.gh_k-- )
                {
                    if ( sr.gh_now < sr.gh_seg_end[ sr.gh_k ] )
                    {
                        sr.gh_s = sr.gh_k;
                    }
                }
                sr.gh_prev = 0;
                if ( sr.gh_s > 0 )
                {
                    sr.gh_prev = sr.gh_seg_end[ sr.gh_s - 1 ];
                }
                sr.gh_run = sr.gh_runs[ sr.gh_seg_run[ sr.gh_s ] ];
                sr.gh_tt = sr.gh_seg_st[ sr.gh_s ] + ( sr.gh_now - sr.gh_prev );
            }
            if ( istrue( sr.gh_run.missing ) )
            {
                sr.ghost hide();
            }
            else
            {
                menu_ghost_step( sr, sr.gh_run, sr.gh_tt );
            }
        }
        wait 0.25;
    }
    if ( isdefined( sr.ghost ) )
    {
        sr.ghost delete();
    }
}

// one run log -> struct with .t (ms) and .p (positions), or undefined
function menu_ghost_load( store, file )
{
    run = spawnstruct();
    nengine_store_load( store, file );
    run.cnt = nengine_store_get( store, "pcount" );
    if ( !isdefined( run.cnt ) || run.cnt == "" )
    {
        return undefined;
    }
    run.t = [];
    run.p = [];
    run.j = 0;
    for ( run.c = 1; run.c <= int( run.cnt ); run.c++ )
    {
        run.chunk = nengine_store_get( store, "p" + ( 1000 + run.c ) );
        if ( !isdefined( run.chunk ) )
        {
            continue;
        }
        run.pts = strtok( run.chunk, ";" );
        for ( run.i = 0; run.i < run.pts.size; run.i++ )
        {
            run.v = strtok( run.pts[ run.i ], "," );
            if ( run.v.size == 4 )
            {
                run.t[ run.t.size ] = int( run.v[ 0 ] ) * 100;
                run.p[ run.p.size ] = ( float( run.v[ 1 ] ), float( run.v[ 2 ] ), float( run.v[ 3 ] ) );
            }
        }
        if ( run.c % 10 == 0 )
        {
            waitframe();
        }
    }
    if ( run.t.size < 2 )
    {
        return undefined;
    }
    return run;
}

// put the ghost where the run was at time tt (ms), between the two logged points around it
function menu_ghost_step( sr, run, tt )
{
    if ( run.j > 0 && run.t[ run.j ] > tt )
    {
        run.j = 0;
    }
    while ( run.j < run.t.size - 2 && run.t[ run.j + 1 ] <= tt )
    {
        run.j++;
    }
    sr.gh_a = run.p[ run.j ];
    sr.gh_b = run.p[ run.j + 1 ];
    sr.gh_span = run.t[ run.j + 1 ] - run.t[ run.j ];
    sr.gh_f = 0;
    if ( sr.gh_span > 0 )
    {
        sr.gh_f = ( tt - run.t[ run.j ] ) / sr.gh_span;
    }
    if ( sr.gh_f < 0 )
    {
        sr.gh_f = 0;
    }
    if ( sr.gh_f > 1 )
    {
        sr.gh_f = 1;
    }
    sr.gh_pos = sr.gh_a + ( sr.gh_b - sr.gh_a ) * sr.gh_f;
    if ( distance2d( sr.gh_a, sr.gh_b ) > 8 )
    {
        sr.gh_ang = vectortoangles( sr.gh_b - sr.gh_a );
        sr.ghost.angles = ( 0, sr.gh_ang[ 1 ], 0 );
    }
    sr.ghost moveto( sr.gh_pos, 0.25 );
}

// a split just finished: if its segment is the fastest so far, remember which run set it and where it started
// (goldatt_ / goldst_ / golddur_<pb key>, one value per split) for the GOUD ghost
function menu_gold_track( sr, i )
{
    sr.gt_start = 0;
    if ( i > 0 )
    {
        sr.gt_start = sr.times[ i - 1 ];
    }
    sr.gt_seg = sr.times[ i ] - sr.gt_start;
    if ( sr.gt_seg <= 0 )
    {
        return;
    }
    menu_avg_add( sr, i, sr.gt_seg );
    nengine_store_load( "livesplit_bo7", "speedrun" );
    sr.gt_a = menu_gold_list( nengine_store_get( "livesplit_bo7", "goldatt_" + sr.pb_key ), sr.flags.size );
    sr.gt_s = menu_gold_list( nengine_store_get( "livesplit_bo7", "goldst_" + sr.pb_key ), sr.flags.size );
    sr.gt_d = menu_gold_list( nengine_store_get( "livesplit_bo7", "golddur_" + sr.pb_key ), sr.flags.size );
    if ( int( sr.gt_d[ i ] ) > 0 && sr.gt_seg >= int( sr.gt_d[ i ] ) )
    {
        return;
    }
    sr.gt_a[ i ] = "" + sr.att;
    sr.gt_s[ i ] = "" + sr.gt_start;
    sr.gt_d[ i ] = "" + sr.gt_seg;
    nengine_store_set( "livesplit_bo7", "goldatt_" + sr.pb_key, zmsplit_join( sr.gt_a, "," ) );
    nengine_store_set( "livesplit_bo7", "goldst_" + sr.pb_key, zmsplit_join( sr.gt_s, "," ) );
    nengine_store_set( "livesplit_bo7", "golddur_" + sr.pb_key, zmsplit_join( sr.gt_d, "," ) );
    nengine_store_save( "livesplit_bo7", "speedrun" );
    menu_ghost_save( sr );
}

// copy this run's route (p1001.. from the run log) to kronos\livesplit_bo7_ghost\<map>_<attempt>.json for the ghost
function menu_ghost_save( sr )
{
    if ( !isdefined( sr.log_file ) )
    {
        return;
    }
    menu_runlog_flush( sr );
    nengine_store_load( "livesplit_bo7_runlog", sr.log_file );
    sr.gs_cnt = nengine_store_get( "livesplit_bo7_runlog", "pcount" );
    if ( !isdefined( sr.gs_cnt ) || sr.gs_cnt == "" )
    {
        return;
    }
    nengine_store_load( "livesplit_bo7_ghost", sr.map + "_" + sr.att );
    for ( sr.gs_c = 1; sr.gs_c <= int( sr.gs_cnt ); sr.gs_c++ )
    {
        sr.gs_v = nengine_store_get( "livesplit_bo7_runlog", "p" + ( 1000 + sr.gs_c ) );
        if ( isdefined( sr.gs_v ) )
        {
            nengine_store_set( "livesplit_bo7_ghost", "p" + ( 1000 + sr.gs_c ), sr.gs_v );
        }
    }
    nengine_store_set( "livesplit_bo7_ghost", "pcount", sr.gs_cnt );
    nengine_store_save( "livesplit_bo7_ghost", sr.map + "_" + sr.att );
}

// ---------------------------------------------------------------- average segments (run prediction)
// avgsum_ / avgcnt_<pb key>: per split the sum and count of all finished segments; zm_sravg = averages in ms
function menu_avg_add( sr, i, seg )
{
    nengine_store_load( "livesplit_bo7", "speedrun" );
    sr.av_s = menu_gold_list( nengine_store_get( "livesplit_bo7", "avgsum_" + sr.pb_key ), sr.flags.size );
    sr.av_c = menu_gold_list( nengine_store_get( "livesplit_bo7", "avgcnt_" + sr.pb_key ), sr.flags.size );
    sr.av_s[ i ] = "" + ( int( sr.av_s[ i ] ) + seg );
    sr.av_c[ i ] = "" + ( int( sr.av_c[ i ] ) + 1 );
    nengine_store_set( "livesplit_bo7", "avgsum_" + sr.pb_key, zmsplit_join( sr.av_s, "," ) );
    nengine_store_set( "livesplit_bo7", "avgcnt_" + sr.pb_key, zmsplit_join( sr.av_c, "," ) );
    nengine_store_save( "livesplit_bo7", "speedrun" );
    menu_avg_push( sr );
}

function menu_avg_push( sr )
{
    if ( !isdefined( sr.pb_key ) )
    {
        return;
    }
    nengine_store_load( "livesplit_bo7", "speedrun" );
    sr.av_s = menu_gold_list( nengine_store_get( "livesplit_bo7", "avgsum_" + sr.pb_key ), sr.flags.size );
    sr.av_c = menu_gold_list( nengine_store_get( "livesplit_bo7", "avgcnt_" + sr.pb_key ), sr.flags.size );
    sr.av_out = [];
    for ( sr.av_i = 0; sr.av_i < sr.flags.size; sr.av_i++ )
    {
        sr.av_out[ sr.av_i ] = "0";
        if ( int( sr.av_c[ sr.av_i ] ) > 0 )
        {
            sr.av_out[ sr.av_i ] = "" + int( int( sr.av_s[ sr.av_i ] ) / int( sr.av_c[ sr.av_i ] ) );
        }
    }
    setdvar( "zm_sravg", zmsplit_join( sr.av_out, "," ) );
}

// "a,b,c" -> array of n strings ("0" where nothing is known yet)
function menu_gold_list( str, n )
{
    level.zmm_gl = [];
    if ( isdefined( str ) && str != "" )
    {
        level.zmm_gl = strtok( str, "," );
    }
    while ( level.zmm_gl.size < n )
    {
        level.zmm_gl[ level.zmm_gl.size ] = "0";
    }
    return level.zmm_gl;
}


// subsplits under the current split (like LiveSplit): the PB run's quest steps inside this segment, with this run's
// time where done. zm_srsub = "label,pb ms,this run ms (0 = not yet);..."
function menu_sub_list( sr )
{
    sr.sl_out = "";
    if ( isdefined( sr.pb ) && sr.pb.size > sr.index && sr.sub_ref_k.size > 0 )
    {
        sr.sl_lo = 0;
        if ( sr.index > 0 )
        {
            sr.sl_lo = sr.pb[ sr.index - 1 ];
        }
        sr.sl_hi = sr.pb[ sr.index ];
        for ( sr.sl_j = 0; sr.sl_j < sr.sub_ref_k.size; sr.sl_j++ )
        {
            if ( sr.sub_ref_t[ sr.sl_j ] > sr.sl_lo && sr.sub_ref_t[ sr.sl_j ] <= sr.sl_hi )
            {
                sr.sl_cur = 0;
                for ( sr.sl_m = 0; sr.sl_m < sr.sub_k.size; sr.sl_m++ )
                {
                    if ( sr.sub_k[ sr.sl_m ] == sr.sub_ref_k[ sr.sl_j ] )
                    {
                        sr.sl_cur = sr.sub_t[ sr.sl_m ];
                    }
                }
                if ( sr.sl_out != "" )
                {
                    sr.sl_out = sr.sl_out + ";";
                }
                sr.sl_out = sr.sl_out + menu_sub_label( sr.sub_ref_k[ sr.sl_j ] ) + "," + sr.sub_ref_t[ sr.sl_j ] + "," + sr.sl_cur;
            }
        }
    }
    if ( !( sr.sl_out === sr.sl_sent ) )
    {
        sr.sl_sent = sr.sl_out;
        setdvar( "zm_srsub", sr.sl_out );
    }
}
