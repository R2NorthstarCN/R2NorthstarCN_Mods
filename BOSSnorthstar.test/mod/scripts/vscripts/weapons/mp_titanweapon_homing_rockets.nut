untyped

global function OnWeaponOwnerChanged_titanweapon_homing_rockets
global function OnWeaponPrimaryAttack_titanweapon_homing_rockets
global function OnWeaponPrimaryAttack_homingbarrage
#if SERVER
global function OnWeaponNpcPrimaryAttack_titanweapon_homing_rockets
#endif

const HOMINGROCKETS_NUM_ROCKETS_PER_SHOT	= 3
const HOMINGROCKETS_MISSILE_SPEED			= 1250
const HOMINGROCKETS_APPLY_RANDOM_SPREAD		= true
const HOMINGROCKETS_LAUNCH_OUT_ANG 			= 17
const HOMINGROCKETS_LAUNCH_OUT_TIME 		= 0.15
const HOMINGROCKETS_LAUNCH_IN_LERP_TIME 	= 0.2
const HOMINGROCKETS_LAUNCH_IN_ANG 			= -12
const HOMINGROCKETS_LAUNCH_IN_TIME 			= 0.10
const HOMINGROCKETS_LAUNCH_STRAIGHT_LERP_TIME = 0.1
global entity viper_homingbarrage_lasttarget

var function OnWeaponPrimaryAttack_homingbarrage( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	bool shouldPredict = weapon.ShouldPredictProjectiles()
	
	entity target = null
	
	float speed = 2500
	
	entity weaponOwner = weapon.GetWeaponOwner()
	vector eyePosition = weaponOwner.EyePosition();
	vector viewVector = weaponOwner.GetViewVector();
	TraceResults traceResults = TraceLineHighDetail( eyePosition, eyePosition + viewVector * 10000, weaponOwner, TRACE_MASK_PLAYERSOLID, TRACE_COLLISION_GROUP_PLAYER );
	if( traceResults.hitEnt )
	{
		if ( traceResults.hitEnt.IsTitan() )
		{
			target = traceResults.hitEnt
			viper_homingbarrage_lasttarget = traceResults.hitEnt
		}
		else
		{
			target = viper_homingbarrage_lasttarget
		}
	}
	
	if ( target == null )

	#if CLIENT
		if ( !shouldPredict )
			return 1
	#endif

	SmartAmmo_SetMissileSpeedLimit( weapon, 9000 )
	SmartAmmo_SetMissileSpeed( weapon, speed )
	SmartAmmo_SetMissileHomingSpeed( weapon, speed )

	weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )

	vector upVec = AnglesToUp( VectorToAngles( attackParams.dir ) )
	
	//put another one because weird bug
	
	#if CLIENT
		if ( !shouldPredict )
			return 1
	#endif

	entity missile = weapon.FireWeaponMissile( attackParams.pos, attackParams.dir + upVec * 1.5, speed, damageTypes.projectileImpact | DF_IMPACT, damageTypes.explosive, false, shouldPredict )

	if ( missile )
	{
		#if SERVER
		missile.kv.lifetime = 10
		missile.SetSpeed( speed )
		missile.SetHomingSpeeds( speed, 0 )

		if ( IsValid( target ) )
			missile.SetMissileTarget( target, <0,0,0> )

			missile.SetOwner( weaponOwner )
		#endif
	}
	
	return 10
}


void function OnWeaponOwnerChanged_titanweapon_homing_rockets( entity weapon, WeaponOwnerChangedParams changeParams )
{
	Init_titanweapon_homing_rockets( weapon )
}

function Init_titanweapon_homing_rockets( entity weapon )
{
	if ( !( "initialized" in weapon.s ) )
	{
		weapon.s.initialized <- true
		SmartAmmo_SetMissileSpeed( weapon, HOMINGROCKETS_MISSILE_SPEED )
		SmartAmmo_SetMissileHomingSpeed( weapon, 250 )
		SmartAmmo_SetUnlockAfterBurst( weapon, true )
		SmartAmmo_SetDisplayKeybinding( weapon, false )
		SmartAmmo_SetExpandContract( weapon, HOMINGROCKETS_NUM_ROCKETS_PER_SHOT, HOMINGROCKETS_APPLY_RANDOM_SPREAD, HOMINGROCKETS_LAUNCH_OUT_ANG, HOMINGROCKETS_LAUNCH_OUT_TIME, HOMINGROCKETS_LAUNCH_IN_LERP_TIME, HOMINGROCKETS_LAUNCH_IN_ANG, HOMINGROCKETS_LAUNCH_IN_TIME, HOMINGROCKETS_LAUNCH_STRAIGHT_LERP_TIME )
	}
}

var function OnWeaponPrimaryAttack_titanweapon_homing_rockets( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	return SmartAmmo_FireWeapon( weapon, attackParams, damageTypes.projectileImpact, damageTypes.explosive )
}


#if SERVER
var function OnWeaponNpcPrimaryAttack_titanweapon_homing_rockets( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	return OnWeaponPrimaryAttack_titanweapon_homing_rockets( weapon, attackParams )
}
#endif