global function MpTitanAbilityHover_Init
global function OnWeaponPrimaryAttack_TitanHover
const LERP_IN_FLOAT = 0.7
global bool flying_rn = false
global float zvel = 0 //height
global string name = ""
#if SERVER
global function NPC_OnWeaponPrimaryAttack_TitanHover
global function FlyerHovers
global function PlayerPressed_up
global function PlayerReleased_up
global function StopflyUp
global function PlayerPressed_down
global function flyUp
global function flyDown
#endif

bool function flyUp( entity player, array<string> args )
{
	if ( name == "" )
	{
		name = player.GetPlayerName()
		zvel = 300
		print ( "first flyUp!" )
		print ( "flyer is " + name )
		print ( "function flyup() called" )
		return true
	}	
	else if ( name == player.GetPlayerName() )
	{	
		zvel = 300
		print ( "flying up! flyer is " + name )
		print ( "function flyup() called" )
		return true
	}
	return true
}
bool function flyDown( entity player, array<string> args )
{
	if ( name == "" )
	{
		name = player.GetPlayerName()
		zvel = -263
		print( "first flyDown!" )
		print ( "flyer is " + name )
		print ( "function flydown() called" )
		return true
	}
	else if ( name == player.GetPlayerName() )
	{
		zvel = -263
		print ( "flying down! flyer is " + name )
		print ( "function flydown() called" )
		return true
	}
	return true
}

void function PlayerPressed_up( entity player )
{
#if CLIENT
	player.ClientCommand( "PlayerPressed_up" )
#endif
}

void function PlayerPressed_down( entity player )
{
#if CLIENT
	player.ClientCommand( "PlayerPressed_down" )
#endif
}

void function PlayerReleased_up( entity player )
{
#if CLIENT
	player.ClientCommand( "PlayerReleased_up" )
#endif
}

bool function StopflyUp( entity player, array<string> args )
{
	if ( name == "" )
	{
		name = player.GetPlayerName()
		zvel = 37
		print( "StopflyUp!" )
		print( "flyer is " + name )
		print ( "function StopflyUp() called" )
		return true
	}
	else if ( name == player.GetPlayerName() )
	{
		print( "StopflyUp" )
		print( "flyer is " + name )
		print ( "function StopflyUp() called" )
		zvel = 37
		return true
	}
	return true
}

void function MpTitanAbilityHover_Init()
{
#if CLIENT
	RegisterButtonPressedCallback(KEY_SPACE,		PlayerPressed_up)
	RegisterButtonReleasedCallback(KEY_SPACE,		PlayerReleased_up)
	RegisterButtonPressedCallback(KEY_LCONTROL,		PlayerPressed_down)
	RegisterButtonReleasedCallback(KEY_LCONTROL,		PlayerReleased_up)
#endif
	PrecacheParticleSystem( $"P_xo_jet_fly_large" )
	PrecacheParticleSystem( $"P_xo_jet_fly_small" )
#if SERVER
	AddClientCommandCallback( "PlayerPressed_up", flyUp )
	AddClientCommandCallback( "PlayerReleased_up", StopflyUp )
	AddClientCommandCallback( "PlayerPressed_down", flyDown )
#endif
}

var function OnWeaponPrimaryAttack_TitanHover( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	entity flyer = weapon.GetWeaponOwner()
	if ( !IsAlive( flyer ) )
		return
	if(flyer.IsOnGround() == false)
	{
		flying_rn = false
		return
	}
	if ( flyer.IsPlayer() )
		PlayerUsedOffhand( flyer, weapon )

	#if SERVER
		HoverSounds soundInfo
		soundInfo.liftoff_1p = "titan_flight_liftoff_1p"
		soundInfo.liftoff_3p = "titan_flight_liftoff_3p"
		soundInfo.hover_1p = "titan_flight_hover_1p"
		soundInfo.hover_3p = "titan_flight_hover_3p"
		soundInfo.descent_1p = "titan_flight_descent_1p"
		soundInfo.descent_3p = "titan_flight_descent_3p"
		soundInfo.landing_1p = "core_ability_land_1p"
		soundInfo.landing_3p = "core_ability_land_3p"
		float horizontalVelocity
		entity soul = flyer.GetTitanSoul()
		if ( IsValid( soul ) && SoulHasPassive( soul, ePassives.PAS_NORTHSTAR_FLIGHTCORE ) )
			horizontalVelocity = 1000.0
		else
			horizontalVelocity = 1000.0
		flying_rn = !flying_rn
		if( flying_rn )
		{
			thread FlyerHovers( flyer, soundInfo, 3.0, horizontalVelocity )
		}
	#endif

	return 1
}

#if SERVER

var function NPC_OnWeaponPrimaryAttack_TitanHover( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	OnWeaponPrimaryAttack_TitanHover( weapon, attackParams )
}

void function FlyerHovers( entity player, HoverSounds soundInfo, float flightTime = 3.0, float horizVel = 200.0 )
{
	player.EndSignal( "OnDeath" )
	player.EndSignal( "TitanEjectionStarted" )

	thread AirborneThink( player, soundInfo )
	if ( player.IsPlayer() )
	{
		player.Server_TurnDodgeDisabledOn()
	    player.kv.airSpeed = horizVel
	    player.kv.airAcceleration = 600
	    player.kv.gravity = 0.0
	}

	CreateShake( player.GetOrigin(), 16, 150, 1.00, 400 )
	PlayFX( FLIGHT_CORE_IMPACT_FX, player.GetOrigin() )

	float startTime = Time()

	array<entity> activeFX

	player.SetGroundFrictionScale( 0 )

	OnThreadEnd(
		function() : ( activeFX, player, soundInfo )
		{
			if ( IsValid( player ) )
			{
				StopSoundOnEntity( player, soundInfo.hover_1p )
				StopSoundOnEntity( player, soundInfo.hover_3p )
				player.SetGroundFrictionScale( 1 )
				if ( player.IsPlayer() )
				{
					player.Server_TurnDodgeDisabledOff()
					player.kv.airSpeed = player.GetPlayerSettingsField( "airSpeed" )
					player.kv.airAcceleration = player.GetPlayerSettingsField( "airAcceleration" )
					player.kv.gravity = player.GetPlayerSettingsField( "gravityScale" )
					if ( player.IsOnGround() )
					{
						EmitSoundOnEntityOnlyToPlayer( player, player, soundInfo.landing_1p )
						EmitSoundOnEntityExceptToPlayer( player, player, soundInfo.landing_3p )
					}
				}
				else
				{
					if ( player.IsOnGround() )
						EmitSoundOnEntity( player, soundInfo.landing_3p )
				}
			}

			foreach ( fx in activeFX )
			{
				if ( IsValid( fx ) )
					fx.Destroy()
			}
		}
	)

	if ( player.LookupAttachment( "FX_L_BOT_THRUST" ) != 0 ) // BT doesn't have this attachment
	{
		activeFX.append( StartParticleEffectOnEntity_ReturnEntity( player, GetParticleSystemIndex( $"P_xo_jet_fly_large" ), FX_PATTACH_POINT_FOLLOW, player.LookupAttachment( "FX_L_BOT_THRUST" ) ) )
		activeFX.append( StartParticleEffectOnEntity_ReturnEntity( player, GetParticleSystemIndex( $"P_xo_jet_fly_large" ), FX_PATTACH_POINT_FOLLOW, player.LookupAttachment( "FX_R_BOT_THRUST" ) ) )
		activeFX.append( StartParticleEffectOnEntity_ReturnEntity( player, GetParticleSystemIndex( $"P_xo_jet_fly_small" ), FX_PATTACH_POINT_FOLLOW, player.LookupAttachment( "FX_L_TOP_THRUST" ) ) )
		activeFX.append( StartParticleEffectOnEntity_ReturnEntity( player, GetParticleSystemIndex( $"P_xo_jet_fly_small" ), FX_PATTACH_POINT_FOLLOW, player.LookupAttachment( "FX_R_TOP_THRUST" ) ) )
	}

	EmitSoundOnEntityOnlyToPlayer( player, player,  soundInfo.liftoff_1p )
	EmitSoundOnEntityExceptToPlayer( player, player, soundInfo.liftoff_3p )
	EmitSoundOnEntityOnlyToPlayer( player, player,  soundInfo.hover_1p )
	EmitSoundOnEntityExceptToPlayer( player, player, soundInfo.hover_3p )

	float RISE_VEL = 450
	float movestunEffect = 1.0 - StatusEffect_Get( player, eStatusEffect.dodge_speed_slow )

	entity soul = player.GetTitanSoul()
	if ( soul == null )
		soul = player

	float fadeTime = 0.75
	StatusEffect_AddTimed( soul, eStatusEffect.dodge_speed_slow, 0.65, flightTime + fadeTime, fadeTime )

	vector startOrigin
	vector endOrigin
	float midTime = Time()
	for ( ;; )
	{
		float timePassed = Time() - startTime
		if ( !flying_rn)
			break
		if(Time() - midTime > 3.0)
		{
			midTime = Time()
			EmitSoundOnEntityOnlyToPlayer( player, player,  soundInfo.hover_1p )
			EmitSoundOnEntityExceptToPlayer( player, player, soundInfo.hover_3p )
		}
		float height
		if ( timePassed < LERP_IN_FLOAT )
		{
		 	height = GraphCapped( timePassed, 0, LERP_IN_FLOAT, RISE_VEL * 0.5, RISE_VEL )
		}
		else
		{
			if(player.IsOnGround())
				flying_rn = false
		 	height = zvel
		}
		height *= movestunEffect

		vector vel = player.GetVelocity()
		vel.z = height
		vel = LimitVelocityHorizontal( vel, horizVel + 150 )
		player.SetVelocity( vel )
		WaitFrame()
		startOrigin = player.GetOrigin()
	}
	
	EmitSoundOnEntityOnlyToPlayer( player, player, soundInfo.descent_1p )
	EmitSoundOnEntityExceptToPlayer( player, player, soundInfo.descent_3p )
	var collisionGroup = player.kv.CollisionGroup
	var solid = player.kv.solid
	while(true)
	{
		if ( player.IsOnGround())
		{
			//player.kv.solid = solid
			//player.Solid()
			break
		}	
		endOrigin = player.GetOrigin()
		//player.NotSolid()
		//player.kv.solid = 1
		vector vel = player.GetVelocity()
		vel = LimitVelocityHorizontal( vel, 100 )
		player.SetVelocity( vel )
		WaitFrame()
	}
	
	if (startOrigin.z - endOrigin.z > 100)
	{
		PlayHotdropImpactFX( player )
		EmitDifferentSoundsAtPositionForPlayerAndWorld( "Titan_1P_Warpfall_WarpToLanding_fast", "Titan_3P_Warpfall_WarpToLanding_fast", endOrigin, player, player.GetTeam())
	}

	printt( startOrigin.z - endOrigin.z)
}

void function AirborneThink( entity player, HoverSounds soundInfo )
{
	player.EndSignal( "OnDeath" )
	player.EndSignal( "TitanEjectionStarted" )
	player.EndSignal( "DisembarkingTitan" )

	if ( player.IsPlayer() )
		player.SetTitanDisembarkEnabled( false )

	OnThreadEnd(
	function() : ( player )
		{
			if ( IsValid( player ) && player.IsPlayer() )
				player.SetTitanDisembarkEnabled( true )
		}
	)
	wait 0.1

	while( !player.IsOnGround() )
	{
		wait 0.1
	}

	if ( player.IsPlayer() )
	{
		EmitSoundOnEntityOnlyToPlayer( player, player, soundInfo.landing_1p )
		EmitSoundOnEntityExceptToPlayer( player, player, soundInfo.landing_3p )
	}
	else
	{
		EmitSoundOnEntity( player, soundInfo.landing_3p )
	}
}

vector function LimitVelocityHorizontal( vector vel, float speed )
{
	vector horzVel = <vel.x, vel.y, 0>
	if ( Length( horzVel ) <= speed )
		return vel

	horzVel = Normalize( horzVel )
	horzVel *= speed
	vel.x = horzVel.x
	vel.y = horzVel.y
	return vel
}
#endif // SERVER
